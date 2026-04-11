#include <R.h>
#include <Rinternals.h>
#include <R_ext/Boolean.h>
#include <R_ext/GraphicsEngine.h>
#include <R_ext/Rdynload.h>

#include <cairo.h>
#include <mypaint-brush.h>
#include <mypaint-brush-settings.h>
#include <mypaint-surface.h>

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

enum {
  SKETCHR_FILL_SOLID = 0,
  SKETCHR_FILL_BRUSH = 1
};

typedef struct {
  MyPaintBrush *brush;
  double base_radius_log;
  double base_opaque;
} SketchBrush;

typedef struct {
  MyPaintSurface surface;
  cairo_surface_t *image_surface;
  cairo_t *cr;
  unsigned char *data;
  int width;
  int height;
  int stride;
  double res;
  double pointsize;
  int bg;
  int page;
  int fill_style;
  char *filename;
  double clip_left;
  double clip_right;
  double clip_bottom;
  double clip_top;
  SketchBrush stroke;
  SketchBrush fill;
} SketchDevice;

static inline double clamp01(double x) {
  if (x < 0.0) return 0.0;
  if (x > 1.0) return 1.0;
  return x;
}

static inline unsigned char unit_to_byte(double x) {
  double y = clamp01(x) * 255.0;
  if (y <= 0.0) return 0;
  if (y >= 255.0) return 255;
  return (unsigned char) (y + 0.5);
}

static char *sketchr_strdup(const char *src) {
  size_t n = strlen(src) + 1;
  char *out = (char *) malloc(n);
  if (!out) return NULL;
  memcpy(out, src, n);
  return out;
}

static SEXP list_element(SEXP list, const char *name) {
  SEXP names;
  R_xlen_t i;

  if (TYPEOF(list) != VECSXP) {
    return R_NilValue;
  }

  names = getAttrib(list, R_NamesSymbol);
  if (TYPEOF(names) != STRSXP) {
    return R_NilValue;
  }

  for (i = 0; i < XLENGTH(list); ++i) {
    if (strcmp(CHAR(STRING_ELT(names, i)), name) == 0) {
      return VECTOR_ELT(list, i);
    }
  }

  return R_NilValue;
}

static void rgb_to_hsv(double r, double g, double b, double *h, double *s, double *v) {
  double maxv = fmax(r, fmax(g, b));
  double minv = fmin(r, fmin(g, b));
  double delta = maxv - minv;
  double hh = 0.0;

  *v = maxv;
  if (maxv <= 0.0) {
    *s = 0.0;
    *h = 0.0;
    return;
  }

  *s = delta / maxv;
  if (delta <= 0.0) {
    *h = 0.0;
    return;
  }

  if (maxv == r) {
    hh = fmod((g - b) / delta, 6.0);
  } else if (maxv == g) {
    hh = ((b - r) / delta) + 2.0;
  } else {
    hh = ((r - g) / delta) + 4.0;
  }

  hh /= 6.0;
  if (hh < 0.0) hh += 1.0;
  *h = hh;
}

static void set_cairo_source(cairo_t *cr, int col) {
  cairo_set_source_rgba(
    cr,
    R_RED(col) / 255.0,
    R_GREEN(col) / 255.0,
    R_BLUE(col) / 255.0,
    R_ALPHA(col) / 255.0
  );
}

static double flip_y(const SketchDevice *dev, double y) {
  return (double) dev->height - y;
}

static void set_font_face(const SketchDevice *dev, const pGEcontext gc) {
  cairo_font_slant_t slant = CAIRO_FONT_SLANT_NORMAL;
  cairo_font_weight_t weight = CAIRO_FONT_WEIGHT_NORMAL;

  if (gc->fontface == 3 || gc->fontface == 4) {
    slant = CAIRO_FONT_SLANT_ITALIC;
  }
  if (gc->fontface == 2 || gc->fontface == 4) {
    weight = CAIRO_FONT_WEIGHT_BOLD;
  }

  cairo_select_font_face(
    dev->cr,
    gc->fontfamily[0] ? gc->fontfamily : "sans",
    slant,
    weight
  );
  cairo_set_font_size(dev->cr, gc->cex * gc->ps * dev->res / 72.0);
}

static void apply_cairo_clip(SketchDevice *dev) {
  cairo_reset_clip(dev->cr);
  cairo_rectangle(
    dev->cr,
    dev->clip_left,
    flip_y(dev, dev->clip_top),
    dev->clip_right - dev->clip_left,
    dev->clip_top - dev->clip_bottom
  );
  cairo_clip(dev->cr);
}

static void clear_device(SketchDevice *dev, int col) {
  cairo_save(dev->cr);
  cairo_set_operator(dev->cr, CAIRO_OPERATOR_SOURCE);
  set_cairo_source(dev->cr, col);
  cairo_paint(dev->cr);
  cairo_restore(dev->cr);
}

static char *page_filename(const SketchDevice *dev, int page) {
  size_t need;
  char *out;
  const char *dot;
  size_t stem_len;

  if (strstr(dev->filename, "%d")) {
    need = (size_t) snprintf(NULL, 0, dev->filename, page) + 1;
    out = (char *) malloc(need);
    if (!out) return NULL;
    snprintf(out, need, dev->filename, page);
    return out;
  }

  if (page == 1) {
    return sketchr_strdup(dev->filename);
  }

  dot = strrchr(dev->filename, '.');
  if (!dot || strchr(dot, '/')) {
    need = strlen(dev->filename) + 24;
    out = (char *) malloc(need);
    if (!out) return NULL;
    snprintf(out, need, "%s-%d.png", dev->filename, page);
    return out;
  }

  stem_len = (size_t) (dot - dev->filename);
  need = stem_len + strlen(dot) + 24;
  out = (char *) malloc(need);
  if (!out) return NULL;
  snprintf(out, need, "%.*s-%d%s", (int) stem_len, dev->filename, page, dot);
  return out;
}

static void save_page(SketchDevice *dev) {
  cairo_status_t status;
  char *filename;

  if (dev->page < 1) {
    return;
  }

  cairo_surface_flush(dev->image_surface);
  filename = page_filename(dev, dev->page);
  if (!filename) {
    error("failed to allocate output filename");
  }

  status = cairo_surface_write_to_png(dev->image_surface, filename);
  free(filename);

  if (status != CAIRO_STATUS_SUCCESS) {
    error("failed to write PNG: %s", cairo_status_to_string(status));
  }
}

static void brush_apply_gc(SketchBrush *brush, int col, double lwd) {
  double h, s, v;
  double alpha = R_ALPHA(col) / 255.0;
  double width_factor = fmax(lwd, 1e-3);

  rgb_to_hsv(
    R_RED(col) / 255.0,
    R_GREEN(col) / 255.0,
    R_BLUE(col) / 255.0,
    &h, &s, &v
  );

  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_COLOR_H, (float) h);
  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_COLOR_S, (float) s);
  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_COLOR_V, (float) v);
  mypaint_brush_set_base_value(
    brush->brush,
    MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC,
    (float) (brush->base_radius_log + log(width_factor))
  );
  mypaint_brush_set_base_value(
    brush->brush,
    MYPAINT_BRUSH_SETTING_OPAQUE,
    (float) clamp01(brush->base_opaque * alpha)
  );
}

static int surface_draw_dab(
  MyPaintSurface *surface,
  float x,
  float y,
  float radius,
  float color_r,
  float color_g,
  float color_b,
  float opaque,
  float hardness,
  float alpha_eraser,
  float aspect_ratio,
  float angle,
  float lock_alpha,
  float colorize
) {
  SketchDevice *dev = (SketchDevice *) surface;
  int x0, x1, y0, y1;
  int ix, iy;
  double c = cos(angle);
  double s = sin(angle);
  double a_ratio = aspect_ratio > 1e-6 ? aspect_ratio : 1.0;
  double rx = radius * a_ratio;
  double ry = radius / a_ratio;
  double maxr = fmax(rx, ry);
  double py_center = flip_y(dev, y);

  (void) lock_alpha;
  (void) colorize;

  x0 = (int) floor(x - maxr - 1.0);
  x1 = (int) ceil(x + maxr + 1.0);
  y0 = (int) floor(py_center - maxr - 1.0);
  y1 = (int) ceil(py_center + maxr + 1.0);

  if (x1 < 0 || y1 < 0 || x0 >= dev->width || y0 >= dev->height) {
    return 1;
  }

  cairo_surface_flush(dev->image_surface);

  for (iy = y0; iy <= y1; ++iy) {
    unsigned char *row;
    double ddy;

    if (iy < 0 || iy >= dev->height) continue;
    if (iy < (int) floor(flip_y(dev, dev->clip_top)) ||
        iy > (int) ceil(flip_y(dev, dev->clip_bottom))) {
      continue;
    }

    row = dev->data + (size_t) iy * (size_t) dev->stride;
    ddy = ((double) iy + 0.5) - py_center;

    for (ix = x0; ix <= x1; ++ix) {
      unsigned char *px;
      double ddx;
      double ex;
      double ey;
      double dist;
      double cover;
      double alpha;
      double dst_b, dst_g, dst_r, dst_a;
      double src_rp, src_gp, src_bp;
      double out_a;

      if (ix < 0 || ix >= dev->width) continue;
      if (ix < (int) floor(dev->clip_left) || ix > (int) ceil(dev->clip_right)) continue;

      ddx = ((double) ix + 0.5) - x;
      ex = (ddx * c + ddy * s) / rx;
      ey = (-ddx * s + ddy * c) / ry;
      dist = sqrt(ex * ex + ey * ey);
      if (dist > 1.0) continue;

      if (dist <= hardness || hardness >= 0.999) {
        cover = 1.0;
      } else {
        cover = 1.0 - (dist - hardness) / (1.0 - hardness);
      }

      alpha = clamp01(opaque * cover);
      if (alpha <= 0.0) continue;

      px = row + (size_t) ix * 4U;
      dst_b = px[0] / 255.0;
      dst_g = px[1] / 255.0;
      dst_r = px[2] / 255.0;
      dst_a = px[3] / 255.0;

      if (alpha_eraser > 0.0f) {
        double keep = 1.0 - clamp01(alpha * alpha_eraser);
        dst_b *= keep;
        dst_g *= keep;
        dst_r *= keep;
        dst_a *= keep;
      }

      src_rp = color_r * alpha;
      src_gp = color_g * alpha;
      src_bp = color_b * alpha;
      out_a = alpha + dst_a * (1.0 - alpha);

      px[0] = unit_to_byte(src_bp + dst_b * (1.0 - alpha));
      px[1] = unit_to_byte(src_gp + dst_g * (1.0 - alpha));
      px[2] = unit_to_byte(src_rp + dst_r * (1.0 - alpha));
      px[3] = unit_to_byte(out_a);
    }
  }

  cairo_surface_mark_dirty(dev->image_surface);
  return 1;
}

static void surface_get_color(
  MyPaintSurface *surface,
  float x,
  float y,
  float radius,
  float *color_r,
  float *color_g,
  float *color_b,
  float *color_a
) {
  SketchDevice *dev = (SketchDevice *) surface;
  int x0 = (int) floor(x - radius);
  int x1 = (int) ceil(x + radius);
  int y0 = (int) floor(flip_y(dev, y) - radius);
  int y1 = (int) ceil(flip_y(dev, y) + radius);
  double total = 0.0;
  double sr = 0.0;
  double sg = 0.0;
  double sb = 0.0;
  double sa = 0.0;
  int ix, iy;

  cairo_surface_flush(dev->image_surface);

  for (iy = y0; iy <= y1; ++iy) {
    if (iy < 0 || iy >= dev->height) continue;
    for (ix = x0; ix <= x1; ++ix) {
      unsigned char *px;
      double dx, dy, d2;
      double w;
      if (ix < 0 || ix >= dev->width) continue;

      dx = ((double) ix + 0.5) - x;
      dy = ((double) iy + 0.5) - flip_y(dev, y);
      d2 = dx * dx + dy * dy;
      if (d2 > radius * radius) continue;

      w = 1.0 - sqrt(d2) / fmax(radius, 1e-6);
      px = dev->data + (size_t) iy * (size_t) dev->stride + (size_t) ix * 4U;
      sb += (px[0] / 255.0) * w;
      sg += (px[1] / 255.0) * w;
      sr += (px[2] / 255.0) * w;
      sa += (px[3] / 255.0) * w;
      total += w;
    }
  }

  if (total <= 0.0) {
    *color_r = 0.0f;
    *color_g = 0.0f;
    *color_b = 0.0f;
    *color_a = 0.0f;
    return;
  }

  *color_b = (float) (sb / total);
  *color_g = (float) (sg / total);
  *color_r = (float) (sr / total);
  *color_a = (float) (sa / total);
}

static void surface_begin_atomic(MyPaintSurface *surface) {
  SketchDevice *dev = (SketchDevice *) surface;
  cairo_surface_flush(dev->image_surface);
}

static void surface_end_atomic(MyPaintSurface *surface, MyPaintRectangle *roi) {
  SketchDevice *dev = (SketchDevice *) surface;
  (void) roi;
  cairo_surface_mark_dirty(dev->image_surface);
}

static void surface_destroy(MyPaintSurface *surface) {
  (void) surface;
}

static void init_surface(SketchDevice *dev) {
  mypaint_surface_init(&dev->surface);
  dev->surface.draw_dab = surface_draw_dab;
  dev->surface.get_color = surface_get_color;
  dev->surface.begin_atomic = surface_begin_atomic;
  dev->surface.end_atomic = surface_end_atomic;
  dev->surface.destroy = surface_destroy;
}

static void render_polyline(SketchDevice *dev, SketchBrush *brush, const double *x, const double *y, int n, int col, double lwd) {
  int i;

  if (n < 2 || R_ALPHA(col) == 0) {
    return;
  }

  brush_apply_gc(brush, col, lwd);
  mypaint_brush_reset(brush->brush);
  mypaint_brush_new_stroke(brush->brush);
  mypaint_surface_begin_atomic(&dev->surface);
  mypaint_brush_stroke_to(brush->brush, &dev->surface, (float) x[0], (float) y[0], 0.0f, 0.0f, 0.0f, 0.01);
  mypaint_brush_stroke_to(brush->brush, &dev->surface, (float) x[0], (float) y[0], 1.0f, 0.0f, 0.0f, 0.001);

  for (i = 1; i < n; ++i) {
    double dx = x[i] - x[i - 1];
    double dy = y[i] - y[i - 1];
    double dt = fmax(sqrt(dx * dx + dy * dy) / 240.0, 0.001);
    mypaint_brush_stroke_to(brush->brush, &dev->surface, (float) x[i], (float) y[i], 1.0f, 0.0f, 0.0f, dt);
  }

  mypaint_brush_stroke_to(brush->brush, &dev->surface, (float) x[n - 1], (float) y[n - 1], 0.0f, 0.0f, 0.0f, 0.01);
  mypaint_surface_end_atomic(&dev->surface, NULL);
}

static void cairo_polygon_path(SketchDevice *dev, int n, const double *x, const double *y) {
  int i;
  cairo_new_path(dev->cr);
  cairo_move_to(dev->cr, x[0], flip_y(dev, y[0]));
  for (i = 1; i < n; ++i) {
    cairo_line_to(dev->cr, x[i], flip_y(dev, y[i]));
  }
  cairo_close_path(dev->cr);
}

static void solid_fill_polygon(SketchDevice *dev, int n, const double *x, const double *y, int fill, int rule) {
  if (R_ALPHA(fill) == 0) {
    return;
  }
  cairo_polygon_path(dev, n, x, y);
  cairo_set_fill_rule(dev->cr, rule == R_GE_nonZeroWindingRule ? CAIRO_FILL_RULE_WINDING : CAIRO_FILL_RULE_EVEN_ODD);
  set_cairo_source(dev->cr, fill);
  cairo_fill(dev->cr);
}

static int cmp_double(const void *lhs, const void *rhs) {
  double a = *(const double *) lhs;
  double b = *(const double *) rhs;
  return (a > b) - (a < b);
}

static void hatch_fill_polygon(SketchDevice *dev, SketchBrush *brush, int n, const double *x, const double *y, int fill) {
  double radius = exp(brush->base_radius_log);
  double spacing = fmax(2.0, radius * 1.5);
  double min_y = y[0];
  double max_y = y[0];
  int i;
  double *cuts;

  if (n < 3 || R_ALPHA(fill) == 0) {
    return;
  }

  cuts = (double *) malloc((size_t) n * sizeof(double));
  if (!cuts) {
    error("failed to allocate polygon fill buffer");
  }

  for (i = 1; i < n; ++i) {
    if (y[i] < min_y) min_y = y[i];
    if (y[i] > max_y) max_y = y[i];
  }

  for (double yy = min_y; yy <= max_y; yy += spacing) {
    int count = 0;
    for (i = 0; i < n; ++i) {
      int j = (i + 1) % n;
      double y0 = y[i];
      double y1 = y[j];
      if ((yy >= fmin(y0, y1)) && (yy < fmax(y0, y1)) && (y0 != y1)) {
        cuts[count++] = x[i] + (yy - y0) * (x[j] - x[i]) / (y[j] - y[i]);
      }
    }
    qsort(cuts, (size_t) count, sizeof(double), cmp_double);
    for (i = 0; i + 1 < count; i += 2) {
      double segx[2] = {cuts[i], cuts[i + 1]};
      double segy[2] = {yy, yy};
      render_polyline(dev, brush, segx, segy, 2, fill, 1.0);
    }
  }

  free(cuts);
}

static void hatch_fill_rect(SketchDevice *dev, SketchBrush *brush, double x0, double y0, double x1, double y1, int fill) {
  double radius = exp(brush->base_radius_log);
  double spacing = fmax(2.0, radius * 1.5);
  double left = fmin(x0, x1);
  double right = fmax(x0, x1);
  double bottom = fmin(y0, y1);
  double top = fmax(y0, y1);

  for (double yy = bottom; yy <= top; yy += spacing) {
    double xx[2] = {left, right};
    double yyv[2] = {yy, yy};
    render_polyline(dev, brush, xx, yyv, 2, fill, 1.0);
  }
}

static void hatch_fill_circle(SketchDevice *dev, SketchBrush *brush, double x, double y, double r, int fill) {
  double radius = exp(brush->base_radius_log);
  double spacing = fmax(2.0, radius * 1.5);

  for (double yy = y - r; yy <= y + r; yy += spacing) {
    double dy = yy - y;
    double dx = sqrt(fmax(r * r - dy * dy, 0.0));
    double xx[2] = {x - dx, x + dx};
    double yyv[2] = {yy, yy};
    render_polyline(dev, brush, xx, yyv, 2, fill, 1.0);
  }
}

static void fill_rect(SketchDevice *dev, double x0, double y0, double x1, double y1, int fill) {
  if (R_ALPHA(fill) == 0) {
    return;
  }

  if (dev->fill_style == SKETCHR_FILL_BRUSH) {
    hatch_fill_rect(dev, &dev->fill, x0, y0, x1, y1, fill);
    return;
  }

  cairo_new_path(dev->cr);
  cairo_rectangle(
    dev->cr,
    fmin(x0, x1),
    flip_y(dev, fmax(y0, y1)),
    fabs(x1 - x0),
    fabs(y1 - y0)
  );
  set_cairo_source(dev->cr, fill);
  cairo_fill(dev->cr);
}

static void fill_circle(SketchDevice *dev, double x, double y, double r, int fill) {
  if (R_ALPHA(fill) == 0) {
    return;
  }

  if (dev->fill_style == SKETCHR_FILL_BRUSH) {
    hatch_fill_circle(dev, &dev->fill, x, y, r, fill);
    return;
  }

  cairo_new_path(dev->cr);
  cairo_arc(dev->cr, x, flip_y(dev, y), r, 0.0, 2.0 * M_PI);
  set_cairo_source(dev->cr, fill);
  cairo_fill(dev->cr);
}

static void configure_brush(MyPaintBrush *brush, SEXP spec) {
  SEXP json = R_NilValue;
  SEXP settings = R_NilValue;
  R_xlen_t i;

  mypaint_brush_from_defaults(brush);

  if (spec == R_NilValue) {
    return;
  }

  json = list_element(spec, "json");
  if (TYPEOF(json) == STRSXP && XLENGTH(json) == 1 && strlen(CHAR(STRING_ELT(json, 0))) > 0) {
    if (!mypaint_brush_from_string(brush, CHAR(STRING_ELT(json, 0)))) {
      error("invalid libmypaint brush JSON");
    }
  }

  settings = list_element(spec, "settings");
  if (settings == R_NilValue || XLENGTH(settings) == 0) {
    return;
  }

  if (!(TYPEOF(settings) == REALSXP || TYPEOF(settings) == INTSXP)) {
    error("brush settings must be numeric");
  }
  if (TYPEOF(getAttrib(settings, R_NamesSymbol)) != STRSXP) {
    error("brush settings must be named");
  }

  for (i = 0; i < XLENGTH(settings); ++i) {
    const char *name = CHAR(STRING_ELT(getAttrib(settings, R_NamesSymbol), i));
    MyPaintBrushSetting id = mypaint_brush_setting_from_cname(name);
    double value = TYPEOF(settings) == REALSXP ? REAL(settings)[i] : INTEGER(settings)[i];
    if (id < 0) {
      error("unknown libmypaint setting '%s'", name);
    }
    mypaint_brush_set_base_value(brush, id, (float) value);
  }
}

static void init_brushes(SketchDevice *dev, SEXP stroke_spec, SEXP fill_spec) {
  dev->stroke.brush = mypaint_brush_new();
  dev->fill.brush = mypaint_brush_new();
  if (!dev->stroke.brush || !dev->fill.brush) {
    error("failed to allocate libmypaint brushes");
  }

  configure_brush(dev->stroke.brush, stroke_spec);
  configure_brush(dev->fill.brush, fill_spec == R_NilValue ? stroke_spec : fill_spec);

  dev->stroke.base_radius_log = mypaint_brush_get_base_value(dev->stroke.brush, MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC);
  dev->stroke.base_opaque = mypaint_brush_get_base_value(dev->stroke.brush, MYPAINT_BRUSH_SETTING_OPAQUE);
  dev->fill.base_radius_log = mypaint_brush_get_base_value(dev->fill.brush, MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC);
  dev->fill.base_opaque = mypaint_brush_get_base_value(dev->fill.brush, MYPAINT_BRUSH_SETTING_OPAQUE);
}

static void destroy_device_state(SketchDevice *dev) {
  if (!dev) {
    return;
  }
  if (dev->stroke.brush) mypaint_brush_unref(dev->stroke.brush);
  if (dev->fill.brush) mypaint_brush_unref(dev->fill.brush);
  if (dev->cr) cairo_destroy(dev->cr);
  if (dev->image_surface) cairo_surface_destroy(dev->image_surface);
  free(dev->filename);
  free(dev);
}

static void sketchr_activate(const pDevDesc dd) {
  (void) dd;
}

static void sketchr_deactivate(const pDevDesc dd) {
  (void) dd;
}

static void sketchr_close(pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;

  if (!dev) {
    return;
  }

  save_page(dev);
  destroy_device_state(dev);
  dd->deviceSpecific = NULL;
}

static void sketchr_clip(double x0, double x1, double y0, double y1, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  dev->clip_left = fmax(0.0, fmin(x0, x1));
  dev->clip_right = fmin(dd->right, fmax(x0, x1));
  dev->clip_bottom = fmax(0.0, fmin(y0, y1));
  dev->clip_top = fmin(dd->top, fmax(y0, y1));
  apply_cairo_clip(dev);
}

static void sketchr_size(double *left, double *right, double *bottom, double *top, pDevDesc dd) {
  *left = 0.0;
  *right = dd->right;
  *bottom = 0.0;
  *top = dd->top;
}

static void sketchr_new_page(const pGEcontext gc, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  (void) gc;
  if (dev->page > 0) {
    save_page(dev);
  }
  dev->page += 1;
  dev->clip_left = 0.0;
  dev->clip_right = dd->right;
  dev->clip_bottom = 0.0;
  dev->clip_top = dd->top;
  apply_cairo_clip(dev);
  clear_device(dev, dev->bg);
}

static void sketchr_line(double x1, double y1, double x2, double y2, const pGEcontext gc, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  double xs[2] = {x1, x2};
  double ys[2] = {y1, y2};
  render_polyline(dev, &dev->stroke, xs, ys, 2, gc->col, gc->lwd);
}

static void sketchr_polyline(int n, double *x, double *y, const pGEcontext gc, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  render_polyline(dev, &dev->stroke, x, y, n, gc->col, gc->lwd);
}

static void sketchr_polygon(int n, double *x, double *y, const pGEcontext gc, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  double *cx;
  double *cy;

  if (n < 2) return;

  if (gc->fill != NA_INTEGER) {
    if (dev->fill_style == SKETCHR_FILL_BRUSH) {
      hatch_fill_polygon(dev, &dev->fill, n, x, y, gc->fill);
    } else {
      solid_fill_polygon(dev, n, x, y, gc->fill, R_GE_nonZeroWindingRule);
    }
  }

  if (gc->col == NA_INTEGER || R_ALPHA(gc->col) == 0) {
    return;
  }

  cx = (double *) malloc((size_t) (n + 1) * sizeof(double));
  cy = (double *) malloc((size_t) (n + 1) * sizeof(double));
  if (!cx || !cy) {
    free(cx);
    free(cy);
    error("failed to allocate polygon stroke buffer");
  }

  memcpy(cx, x, (size_t) n * sizeof(double));
  memcpy(cy, y, (size_t) n * sizeof(double));
  cx[n] = x[0];
  cy[n] = y[0];
  render_polyline(dev, &dev->stroke, cx, cy, n + 1, gc->col, gc->lwd);
  free(cx);
  free(cy);
}

static void sketchr_rect(double x0, double y0, double x1, double y1, const pGEcontext gc, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  double xs[5] = {x0, x1, x1, x0, x0};
  double ys[5] = {y0, y0, y1, y1, y0};

  fill_rect(dev, x0, y0, x1, y1, gc->fill);

  if (gc->col != NA_INTEGER && R_ALPHA(gc->col) > 0) {
    render_polyline(dev, &dev->stroke, xs, ys, 5, gc->col, gc->lwd);
  }
}

static void sketchr_circle(double x, double y, double r, const pGEcontext gc, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  int segments;
  double *xs;
  double *ys;
  int i;

  fill_circle(dev, x, y, r, gc->fill);

  if (gc->col == NA_INTEGER || R_ALPHA(gc->col) == 0) {
    return;
  }

  segments = (int) fmax(24.0, ceil(2.0 * M_PI * r / 6.0));
  xs = (double *) malloc((size_t) (segments + 1) * sizeof(double));
  ys = (double *) malloc((size_t) (segments + 1) * sizeof(double));
  if (!xs || !ys) {
    free(xs);
    free(ys);
    error("failed to allocate circle stroke buffer");
  }

  for (i = 0; i <= segments; ++i) {
    double t = 2.0 * M_PI * (double) i / (double) segments;
    xs[i] = x + r * cos(t);
    ys[i] = y + r * sin(t);
  }

  render_polyline(dev, &dev->stroke, xs, ys, segments + 1, gc->col, gc->lwd);
  free(xs);
  free(ys);
}

static void sketchr_path(double *x, double *y, int npoly, int *nper, Rboolean winding, const pGEcontext gc, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  int offset = 0;
  int i;

  if (gc->fill != NA_INTEGER && R_ALPHA(gc->fill) > 0) {
    if (dev->fill_style == SKETCHR_FILL_BRUSH && npoly == 1) {
      hatch_fill_polygon(dev, &dev->fill, nper[0], x, y, gc->fill);
    } else {
      cairo_new_path(dev->cr);
      for (i = 0; i < npoly; ++i) {
        int j;
        cairo_move_to(dev->cr, x[offset], flip_y(dev, y[offset]));
        for (j = 1; j < nper[i]; ++j) {
          cairo_line_to(dev->cr, x[offset + j], flip_y(dev, y[offset + j]));
        }
        cairo_close_path(dev->cr);
        offset += nper[i];
      }
      cairo_set_fill_rule(dev->cr, winding ? CAIRO_FILL_RULE_WINDING : CAIRO_FILL_RULE_EVEN_ODD);
      set_cairo_source(dev->cr, gc->fill);
      cairo_fill(dev->cr);
    }
  }

  if (gc->col != NA_INTEGER && R_ALPHA(gc->col) > 0) {
    offset = 0;
    for (i = 0; i < npoly; ++i) {
      int n = nper[i];
      double *cx = (double *) malloc((size_t) (n + 1) * sizeof(double));
      double *cy = (double *) malloc((size_t) (n + 1) * sizeof(double));
      if (!cx || !cy) {
        free(cx);
        free(cy);
        error("failed to allocate path stroke buffer");
      }
      memcpy(cx, x + offset, (size_t) n * sizeof(double));
      memcpy(cy, y + offset, (size_t) n * sizeof(double));
      cx[n] = x[offset];
      cy[n] = y[offset];
      render_polyline(dev, &dev->stroke, cx, cy, n + 1, gc->col, gc->lwd);
      free(cx);
      free(cy);
      offset += n;
    }
  }
}

static void raster_to_cairo(unsigned int *raster, unsigned char *out, int w, int h, int stride) {
  int row, col;
  for (row = 0; row < h; ++row) {
    unsigned char *dst = out + (size_t) row * (size_t) stride;
    for (col = 0; col < w; ++col) {
      int rc = (int) raster[(size_t) row * (size_t) w + (size_t) col];
      double a = R_ALPHA(rc) / 255.0;
      dst[col * 4 + 0] = unit_to_byte((R_BLUE(rc) / 255.0) * a);
      dst[col * 4 + 1] = unit_to_byte((R_GREEN(rc) / 255.0) * a);
      dst[col * 4 + 2] = unit_to_byte((R_RED(rc) / 255.0) * a);
      dst[col * 4 + 3] = unit_to_byte(a);
    }
  }
}

static void sketchr_raster(unsigned int *raster, int w, int h, double x, double y, double width, double height, double rot, Rboolean interpolate, const pGEcontext gc, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  cairo_surface_t *tmp_surface;
  cairo_t *tmp_cr;
  unsigned char *tmp_data;
  int stride;

  (void) gc;

  stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, w);
  tmp_data = (unsigned char *) calloc((size_t) stride, (size_t) h);
  if (!tmp_data) {
    error("failed to allocate raster buffer");
  }

  raster_to_cairo(raster, tmp_data, w, h, stride);
  tmp_surface = cairo_image_surface_create_for_data(tmp_data, CAIRO_FORMAT_ARGB32, w, h, stride);
  tmp_cr = dev->cr;

  cairo_save(tmp_cr);
  cairo_translate(tmp_cr, x, flip_y(dev, y));
  cairo_rotate(tmp_cr, -rot * M_PI / 180.0);
  cairo_scale(tmp_cr, width / w, -height / h);
  cairo_set_source_surface(tmp_cr, tmp_surface, 0.0, -h);
  cairo_pattern_set_filter(cairo_get_source(tmp_cr), interpolate ? CAIRO_FILTER_BILINEAR : CAIRO_FILTER_NEAREST);
  cairo_paint(tmp_cr);
  cairo_restore(tmp_cr);

  cairo_surface_destroy(tmp_surface);
  free(tmp_data);
}

static double sketchr_str_width_impl(const char *str, const pGEcontext gc, SketchDevice *dev) {
  cairo_text_extents_t extents;
  set_font_face(dev, gc);
  cairo_text_extents(dev->cr, str, &extents);
  return extents.x_advance;
}

static double sketchr_str_width(const char *str, const pGEcontext gc, pDevDesc dd) {
  return sketchr_str_width_impl(str, gc, (SketchDevice *) dd->deviceSpecific);
}

static void sketchr_metric_info(int c, const pGEcontext gc, double *ascent, double *descent, double *width, pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  cairo_font_extents_t fe;
  cairo_text_extents_t te;
  char buf[8];

  if (c < 32 || c > 126) {
    buf[0] = 'M';
    buf[1] = '\0';
  } else {
    buf[0] = (char) c;
    buf[1] = '\0';
  }

  set_font_face(dev, gc);
  cairo_font_extents(dev->cr, &fe);
  cairo_text_extents(dev->cr, buf, &te);
  *ascent = fe.ascent;
  *descent = fe.descent;
  *width = te.x_advance;
}

static void sketchr_text_impl(double x, double y, const char *str, double rot, double hadj, const pGEcontext gc, SketchDevice *dev) {
  cairo_text_extents_t extents;

  if (gc->col == NA_INTEGER || R_ALPHA(gc->col) == 0) {
    return;
  }

  set_font_face(dev, gc);
  cairo_text_extents(dev->cr, str, &extents);

  cairo_save(dev->cr);
  cairo_translate(dev->cr, x, flip_y(dev, y));
  cairo_rotate(dev->cr, -rot * M_PI / 180.0);
  set_cairo_source(dev->cr, gc->col);
  cairo_move_to(dev->cr, -hadj * extents.x_advance, 0.0);
  cairo_show_text(dev->cr, str);
  cairo_restore(dev->cr);
}

static void sketchr_text(double x, double y, const char *str, double rot, double hadj, const pGEcontext gc, pDevDesc dd) {
  sketchr_text_impl(x, y, str, rot, hadj, gc, (SketchDevice *) dd->deviceSpecific);
}

static void sketchr_text_utf8(double x, double y, const char *str, double rot, double hadj, const pGEcontext gc, pDevDesc dd) {
  sketchr_text_impl(x, y, str, rot, hadj, gc, (SketchDevice *) dd->deviceSpecific);
}

static double sketchr_str_width_utf8(const char *str, const pGEcontext gc, pDevDesc dd) {
  return sketchr_str_width_impl(str, gc, (SketchDevice *) dd->deviceSpecific);
}

static SEXP sketchr_cap(pDevDesc dd) {
  SketchDevice *dev = (SketchDevice *) dd->deviceSpecific;
  SEXP out = PROTECT(allocMatrix(INTSXP, dev->height, dev->width));
  int row, col;

  cairo_surface_flush(dev->image_surface);
  for (row = 0; row < dev->height; ++row) {
    for (col = 0; col < dev->width; ++col) {
      unsigned char *px = dev->data + (size_t) row * (size_t) dev->stride + (size_t) col * 4U;
      int idx = row + dev->height * col;
      INTEGER(out)[idx] = R_RGBA(px[2], px[1], px[0], px[3]);
    }
  }

  UNPROTECT(1);
  return out;
}

static SEXP sketchr_capabilities(SEXP cap) {
  SEXP out = PROTECT(allocVector(LGLSXP, XLENGTH(cap)));
  R_xlen_t i;
  for (i = 0; i < XLENGTH(cap); ++i) {
    int what = INTEGER(cap)[i];
    LOGICAL(out)[i] = 0;
    if (what == R_GE_capability_semiTransparency ||
        what == R_GE_capability_transparentBackground ||
        what == R_GE_capability_rasterImage ||
        what == R_GE_capability_capture ||
        what == R_GE_capability_paths) {
      LOGICAL(out)[i] = 1;
    }
  }
  UNPROTECT(1);
  return out;
}

static void init_dev_desc(pDevDesc dd, SketchDevice *dev) {
  memset(dd, 0, sizeof(*dd));

  dd->left = 0.0;
  dd->right = dev->width;
  dd->bottom = 0.0;
  dd->top = dev->height;
  dd->clipLeft = 0.0;
  dd->clipRight = dev->width;
  dd->clipBottom = 0.0;
  dd->clipTop = dev->height;
  dd->xCharOffset = 0.4900;
  dd->yCharOffset = 0.3333;
  dd->yLineBias = 0.1;
  dd->ipr[0] = 1.0 / dev->res;
  dd->ipr[1] = 1.0 / dev->res;
  dd->cra[0] = 0.9 * dev->pointsize * dev->res / 72.0;
  dd->cra[1] = 1.2 * dev->pointsize * dev->res / 72.0;
  dd->gamma = 1.0;
  dd->canClip = TRUE;
  dd->canChangeGamma = FALSE;
  dd->canHAdj = 2;
  dd->startps = dev->pointsize;
  dd->startcol = R_RGBA(0, 0, 0, 255);
  dd->startfill = dev->bg;
  dd->startlty = LTY_SOLID;
  dd->startfont = 1;
  dd->startgamma = 1.0;
  dd->deviceSpecific = dev;
  dd->displayListOn = TRUE;
  dd->canGenMouseDown = FALSE;
  dd->canGenMouseMove = FALSE;
  dd->canGenMouseUp = FALSE;
  dd->canGenKeybd = FALSE;
  dd->canGenIdle = FALSE;
  dd->activate = sketchr_activate;
  dd->circle = sketchr_circle;
  dd->clip = sketchr_clip;
  dd->close = sketchr_close;
  dd->deactivate = sketchr_deactivate;
  dd->line = sketchr_line;
  dd->metricInfo = sketchr_metric_info;
  dd->mode = NULL;
  dd->newPage = sketchr_new_page;
  dd->polygon = sketchr_polygon;
  dd->polyline = sketchr_polyline;
  dd->rect = sketchr_rect;
  dd->path = sketchr_path;
  dd->raster = sketchr_raster;
  dd->cap = sketchr_cap;
  dd->size = sketchr_size;
  dd->strWidth = sketchr_str_width;
  dd->text = sketchr_text;
  dd->onExit = NULL;
  dd->getEvent = NULL;
  dd->newFrameConfirm = NULL;
  dd->hasTextUTF8 = TRUE;
  dd->textUTF8 = sketchr_text_utf8;
  dd->strWidthUTF8 = sketchr_str_width_utf8;
  dd->wantSymbolUTF8 = FALSE;
  dd->useRotatedTextInContour = TRUE;
  dd->deviceVersion = R_GE_glyphs;
  dd->deviceClip = FALSE;
  dd->capabilities = sketchr_capabilities;
}

static SketchDevice *make_device(const char *filename, int width, int height, double res, double pointsize, int bg, int fill_style, SEXP stroke_spec, SEXP fill_spec) {
  SketchDevice *dev = (SketchDevice *) calloc(1, sizeof(SketchDevice));
  cairo_status_t status;

  if (!dev) {
    error("failed to allocate device state");
  }

  dev->width = width;
  dev->height = height;
  dev->res = res;
  dev->pointsize = pointsize;
  dev->bg = bg;
  dev->fill_style = fill_style;
  dev->filename = sketchr_strdup(filename);
  if (!dev->filename) {
    free(dev);
    error("failed to allocate filename");
  }

  dev->image_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
  status = cairo_surface_status(dev->image_surface);
  if (status != CAIRO_STATUS_SUCCESS) {
    free(dev->filename);
    free(dev);
    error("failed to create Cairo surface: %s", cairo_status_to_string(status));
  }

  dev->data = cairo_image_surface_get_data(dev->image_surface);
  dev->stride = cairo_image_surface_get_stride(dev->image_surface);
  dev->cr = cairo_create(dev->image_surface);
  if (cairo_status(dev->cr) != CAIRO_STATUS_SUCCESS) {
    cairo_surface_destroy(dev->image_surface);
    free(dev->filename);
    free(dev);
    error("failed to create Cairo context");
  }

  init_surface(dev);
  init_brushes(dev, stroke_spec, fill_spec);
  clear_device(dev, bg);
  return dev;
}

SEXP mypaintr_device_open(SEXP filename, SEXP width, SEXP height, SEXP res, SEXP pointsize, SEXP bg_rgba, SEXP stroke_spec, SEXP fill_spec, SEXP fill_style) {
  pDevDesc dd;
  pGEDevDesc gdd;
  SketchDevice *dev;
  int pixel_width;
  int pixel_height;
  int bg;

  if (TYPEOF(filename) != STRSXP || XLENGTH(filename) != 1) {
    error("filename must be a character scalar");
  }
  if (TYPEOF(bg_rgba) != INTSXP || XLENGTH(bg_rgba) != 4) {
    error("background colour must be an RGBA integer vector");
  }

  pixel_width = (int) llround(asReal(width) * asReal(res));
  pixel_height = (int) llround(asReal(height) * asReal(res));
  bg = R_RGBA(INTEGER(bg_rgba)[0], INTEGER(bg_rgba)[1], INTEGER(bg_rgba)[2], INTEGER(bg_rgba)[3]);

  R_GE_checkVersionOrDie(R_GE_version);
  R_CheckDeviceAvailable();

  dev = make_device(
    CHAR(STRING_ELT(filename, 0)),
    pixel_width,
    pixel_height,
    asReal(res),
    asReal(pointsize),
    bg,
    asInteger(fill_style),
    stroke_spec,
    fill_spec
  );

  dd = (pDevDesc) calloc(1, sizeof(DevDesc));
  if (!dd) {
    destroy_device_state(dev);
    error("failed to allocate device descriptor");
  }

  init_dev_desc(dd, dev);
  gdd = GEcreateDevDesc(dd);
  GEaddDevice2f(gdd, "mypaintr", CHAR(STRING_ELT(filename, 0)));
  GEinitDisplayList(gdd);

  return R_NilValue;
}

SEXP mypaintr_brush_settings_info(void) {
  SEXP out = PROTECT(allocVector(VECSXP, 7));
  SEXP names = PROTECT(allocVector(STRSXP, 7));
  SEXP cname = PROTECT(allocVector(STRSXP, MYPAINT_BRUSH_SETTINGS_COUNT));
  SEXP label = PROTECT(allocVector(STRSXP, MYPAINT_BRUSH_SETTINGS_COUNT));
  SEXP minimum = PROTECT(allocVector(REALSXP, MYPAINT_BRUSH_SETTINGS_COUNT));
  SEXP deflt = PROTECT(allocVector(REALSXP, MYPAINT_BRUSH_SETTINGS_COUNT));
  SEXP maximum = PROTECT(allocVector(REALSXP, MYPAINT_BRUSH_SETTINGS_COUNT));
  SEXP constant = PROTECT(allocVector(LGLSXP, MYPAINT_BRUSH_SETTINGS_COUNT));
  SEXP tooltip = PROTECT(allocVector(STRSXP, MYPAINT_BRUSH_SETTINGS_COUNT));
  int i;

  for (i = 0; i < MYPAINT_BRUSH_SETTINGS_COUNT; ++i) {
    const MyPaintBrushSettingInfo *info = mypaint_brush_setting_info((MyPaintBrushSetting) i);
    SET_STRING_ELT(cname, i, mkChar(info->cname));
    SET_STRING_ELT(label, i, mkChar(info->name));
    REAL(minimum)[i] = info->min;
    REAL(deflt)[i] = info->def;
    REAL(maximum)[i] = info->max;
    LOGICAL(constant)[i] = info->constant;
    SET_STRING_ELT(tooltip, i, mkChar(info->tooltip));
  }

  SET_VECTOR_ELT(out, 0, cname);
  SET_VECTOR_ELT(out, 1, label);
  SET_VECTOR_ELT(out, 2, minimum);
  SET_VECTOR_ELT(out, 3, deflt);
  SET_VECTOR_ELT(out, 4, maximum);
  SET_VECTOR_ELT(out, 5, constant);
  SET_VECTOR_ELT(out, 6, tooltip);

  SET_STRING_ELT(names, 0, mkChar("cname"));
  SET_STRING_ELT(names, 1, mkChar("name"));
  SET_STRING_ELT(names, 2, mkChar("min"));
  SET_STRING_ELT(names, 3, mkChar("default"));
  SET_STRING_ELT(names, 4, mkChar("max"));
  SET_STRING_ELT(names, 5, mkChar("constant"));
  SET_STRING_ELT(names, 6, mkChar("tooltip"));
  setAttrib(out, R_NamesSymbol, names);
  UNPROTECT(9);
  return out;
}

SEXP mypaintr_brush_inputs_info(void) {
  SEXP out = PROTECT(allocVector(VECSXP, 7));
  SEXP names = PROTECT(allocVector(STRSXP, 7));
  SEXP cname = PROTECT(allocVector(STRSXP, MYPAINT_BRUSH_INPUTS_COUNT));
  SEXP hard_min = PROTECT(allocVector(REALSXP, MYPAINT_BRUSH_INPUTS_COUNT));
  SEXP soft_min = PROTECT(allocVector(REALSXP, MYPAINT_BRUSH_INPUTS_COUNT));
  SEXP normal = PROTECT(allocVector(REALSXP, MYPAINT_BRUSH_INPUTS_COUNT));
  SEXP soft_max = PROTECT(allocVector(REALSXP, MYPAINT_BRUSH_INPUTS_COUNT));
  SEXP hard_max = PROTECT(allocVector(REALSXP, MYPAINT_BRUSH_INPUTS_COUNT));
  SEXP tooltip = PROTECT(allocVector(STRSXP, MYPAINT_BRUSH_INPUTS_COUNT));
  int i;

  for (i = 0; i < MYPAINT_BRUSH_INPUTS_COUNT; ++i) {
    const MyPaintBrushInputInfo *info = mypaint_brush_input_info((MyPaintBrushInput) i);
    SET_STRING_ELT(cname, i, mkChar(info->cname));
    REAL(hard_min)[i] = info->hard_min;
    REAL(soft_min)[i] = info->soft_min;
    REAL(normal)[i] = info->normal;
    REAL(soft_max)[i] = info->soft_max;
    REAL(hard_max)[i] = info->hard_max;
    SET_STRING_ELT(tooltip, i, mkChar(info->tooltip));
  }

  SET_VECTOR_ELT(out, 0, cname);
  SET_VECTOR_ELT(out, 1, hard_min);
  SET_VECTOR_ELT(out, 2, soft_min);
  SET_VECTOR_ELT(out, 3, normal);
  SET_VECTOR_ELT(out, 4, soft_max);
  SET_VECTOR_ELT(out, 5, hard_max);
  SET_VECTOR_ELT(out, 6, tooltip);

  SET_STRING_ELT(names, 0, mkChar("cname"));
  SET_STRING_ELT(names, 1, mkChar("hard_min"));
  SET_STRING_ELT(names, 2, mkChar("soft_min"));
  SET_STRING_ELT(names, 3, mkChar("normal"));
  SET_STRING_ELT(names, 4, mkChar("soft_max"));
  SET_STRING_ELT(names, 5, mkChar("hard_max"));
  SET_STRING_ELT(names, 6, mkChar("tooltip"));
  setAttrib(out, R_NamesSymbol, names);
  UNPROTECT(9);
  return out;
}
