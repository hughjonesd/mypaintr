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
#include <stdint.h>
#include <time.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

enum {
  MYPAINTR_RENDER_SOLID = 0,
  MYPAINTR_RENDER_BRUSH = 1,
  MYPAINTR_FILL_SOLID = 0,
  MYPAINTR_FILL_BRUSH = 1
};

#define MYPAINTR_MAGIC 0x6d797074U

typedef struct {
  MyPaintBrush *brush;
  double base_radius_log;
  double base_opaque;
  double base_smudge;
  double base_opaque_multiply;
  int pure_smudge;
} MypaintrBrush;

typedef struct {
  double x;
  int delta;
} HatchIntersection;

typedef struct {
  int enabled;
  uint64_t rng_state;
  double bow;
  double wobble;
  int multi_stroke;
  double width_jitter;
  double endpoint_jitter;
  double pressure;
  double pressure_taper;
  double hachure_gap;
  int has_hachure_gap;
  double hachure_angle_jitter;
  double hachure_gap_jitter;
  int hachure_cross;
} MypaintrHand;

typedef struct {
  double *x;
  double *y;
  int n;
} PointBuffer;

typedef struct {
  MyPaintSurface2 surface;
  unsigned int magic;
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
  int stroke_style;
  int fill_style;
  int auto_solid_bg;
  char *filename;
  double clip_left;
  double clip_right;
  double clip_bottom;
  double clip_top;
  MypaintrBrush stroke;
  MypaintrBrush fill;
  MypaintrHand stroke_hand;
  MypaintrHand fill_hand;
  SEXP stroke_spec;
  SEXP fill_spec;
  SEXP stroke_hand_spec;
  SEXP fill_hand_spec;
} MypaintrDevice;

static void configure_brush(MyPaintBrush *brush, SEXP spec);
static void surface_get_color(
  MyPaintSurface *surface,
  float x,
  float y,
  float radius,
  float *color_r,
  float *color_g,
  float *color_b,
  float *color_a
);
static void surface_get_color_pigment(
  MyPaintSurface2 *surface,
  float x,
  float y,
  float radius,
  float *color_r,
  float *color_g,
  float *color_b,
  float *color_a,
  float paint
);
static double flip_y(const MypaintrDevice *dev, double y);

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

static inline int colors_close(int lhs, int rhs, int tol) {
  return abs(R_RED(lhs) - R_RED(rhs)) <= tol &&
         abs(R_GREEN(lhs) - R_GREEN(rhs)) <= tol &&
         abs(R_BLUE(lhs) - R_BLUE(rhs)) <= tol &&
         abs(R_ALPHA(lhs) - R_ALPHA(rhs)) <= tol;
}

static uint64_t mix64(uint64_t x) {
  x += 0x9e3779b97f4a7c15ULL;
  x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
  x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
  return x ^ (x >> 31);
}

static double hand_uniform(MypaintrHand *hand) {
  hand->rng_state = mix64(hand->rng_state ? hand->rng_state : 1ULL);
  return (double) (hand->rng_state >> 11) * (1.0 / 9007199254740992.0);
}

static double hand_normal(MypaintrHand *hand, double sd) {
  double u1;
  double u2;
  double r;
  double theta;

  if (sd <= 0.0) {
    return 0.0;
  }

  u1 = fmax(hand_uniform(hand), 1e-12);
  u2 = hand_uniform(hand);
  r = sqrt(-2.0 * log(u1));
  theta = 2.0 * M_PI * u2;
  return sd * r * cos(theta);
}

static double hand_offset(double t, double c1, double c2) {
  if (t <= 0.33) {
    return c1 * (t / 0.33);
  }
  if (t <= 0.66) {
    return c1 + (c2 - c1) * ((t - 0.33) / 0.33);
  }
  return c2 * (1.0 - (t - 0.66) / 0.34);
}

static void point_buffer_free(PointBuffer *buf) {
  free(buf->x);
  free(buf->y);
  buf->x = NULL;
  buf->y = NULL;
  buf->n = 0;
}

static void point_buffer_alloc(PointBuffer *buf, int n) {
  buf->x = (double *) malloc((size_t) n * sizeof(double));
  buf->y = (double *) malloc((size_t) n * sizeof(double));
  buf->n = n;
  if (!buf->x || !buf->y) {
    point_buffer_free(buf);
    error("failed to allocate rough path buffer");
  }
}

static char *mypaintr_strdup(const char *src) {
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

static void replace_preserved(SEXP *slot, SEXP value) {
  if (*slot && *slot != R_NilValue) {
    R_ReleaseObject(*slot);
  }

  if (value == R_NilValue) {
    *slot = R_NilValue;
    return;
  }

  *slot = Rf_duplicate(value);
  R_PreserveObject(*slot);
}

static SEXP duplicate_or_nil(SEXP value) {
  if (!value || value == R_NilValue) {
    return R_NilValue;
  }
  return Rf_duplicate(value);
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

static void hsv_to_rgb(double h, double s, double v, double *r, double *g, double *b) {
  double hh;
  double c;
  double x;
  double m;
  double rr = 0.0;
  double gg = 0.0;
  double bb = 0.0;

  if (s <= 0.0) {
    *r = v;
    *g = v;
    *b = v;
    return;
  }

  hh = h - floor(h);
  c = v * s;
  hh *= 6.0;
  x = c * (1.0 - fabs(fmod(hh, 2.0) - 1.0));
  m = v - c;

  if (hh < 1.0) {
    rr = c; gg = x; bb = 0.0;
  } else if (hh < 2.0) {
    rr = x; gg = c; bb = 0.0;
  } else if (hh < 3.0) {
    rr = 0.0; gg = c; bb = x;
  } else if (hh < 4.0) {
    rr = 0.0; gg = x; bb = c;
  } else if (hh < 5.0) {
    rr = x; gg = 0.0; bb = c;
  } else {
    rr = c; gg = 0.0; bb = x;
  }

  *r = rr + m;
  *g = gg + m;
  *b = bb + m;
}

static const double spectral_r_small[10] = {
  0.009281362787953, 0.009732627042016, 0.011254252737167, 0.015105578649573,
  0.024797924177217, 0.083622585502406, 0.977865045723212, 1.000000000000000,
  0.999961046144372, 0.999999992756822
};

static const double spectral_g_small[10] = {
  0.002854127435775, 0.003917589679914, 0.012132151699187, 0.748259205918013,
  1.000000000000000, 0.865695937531795, 0.037477469241101, 0.022816789725717,
  0.021747419446456, 0.021384940572308
};

static const double spectral_b_small[10] = {
  0.537052150373386, 0.546646402401469, 0.575501819073983, 0.258778829633924,
  0.041709923751716, 0.012662638828324, 0.007485593127390, 0.006766900622462,
  0.006699764779016, 0.006676219883241
};

static const double t_matrix_small[3][10] = {
  {
    0.026595621243689, 0.049779426257903, 0.022449850859496, -0.218453689278271,
    -0.256894883201278, 0.445881722194840, 0.772365886289756, 0.194498761382537,
    0.014038157587820, 0.007687264480513
  },
  {
    -0.032601672674412, -0.061021043498478, -0.052490001018404, 0.206659098273522,
    0.572496335158169, 0.317837248815438, -0.021216624031211, -0.019387668756117,
    -0.001521339050858, -0.000835181622534
  },
  {
    0.339475473216284, 0.635401374177222, 0.771520797089589, 0.113222640692379,
    -0.055251113343776, -0.048222578468680, -0.012966666339586, -0.001523814504223,
    -0.000094718948810, -0.000051604594741
  }
};

static double safe_pow01(double base, double exponent) {
  return pow(fmax(clamp01(base), 1e-6), exponent);
}

static void rgb_to_spectral10(double r, double g, double b, double *spectral) {
  int i;
  for (i = 0; i < 10; ++i) {
    spectral[i] = spectral_r_small[i] * clamp01(r) +
                  spectral_g_small[i] * clamp01(g) +
                  spectral_b_small[i] * clamp01(b);
  }
}

static void spectral10_to_rgb(const double *spectral, double *r, double *g, double *b) {
  double tmp_r = 0.0;
  double tmp_g = 0.0;
  double tmp_b = 0.0;
  int i;

  for (i = 0; i < 10; ++i) {
    tmp_r += t_matrix_small[0][i] * spectral[i];
    tmp_g += t_matrix_small[1][i] * spectral[i];
    tmp_b += t_matrix_small[2][i] * spectral[i];
  }

  *r = clamp01(tmp_r);
  *g = clamp01(tmp_g);
  *b = clamp01(tmp_b);
}

static void mix_rgb_paint_mode(
  double top_r,
  double top_g,
  double top_b,
  double bottom_r,
  double bottom_g,
  double bottom_b,
  double top_weight,
  double paint_mode,
  double *out_r,
  double *out_g,
  double *out_b
) {
  double weight = clamp01(top_weight);
  double additive_r;
  double additive_g;
  double additive_b;
  double spectral_r;
  double spectral_g;
  double spectral_b;
  double top_spec[10];
  double bottom_spec[10];
  double mixed_spec[10];
  double pigment = clamp01(paint_mode);
  int i;

  if (weight <= 0.0) {
    *out_r = clamp01(bottom_r);
    *out_g = clamp01(bottom_g);
    *out_b = clamp01(bottom_b);
    return;
  }
  if (weight >= 1.0) {
    *out_r = clamp01(top_r);
    *out_g = clamp01(top_g);
    *out_b = clamp01(top_b);
    return;
  }

  additive_r = clamp01(top_r) * weight + clamp01(bottom_r) * (1.0 - weight);
  additive_g = clamp01(top_g) * weight + clamp01(bottom_g) * (1.0 - weight);
  additive_b = clamp01(top_b) * weight + clamp01(bottom_b) * (1.0 - weight);

  if (pigment <= 0.0) {
    *out_r = additive_r;
    *out_g = additive_g;
    *out_b = additive_b;
    return;
  }

  rgb_to_spectral10(top_r, top_g, top_b, top_spec);
  rgb_to_spectral10(bottom_r, bottom_g, bottom_b, bottom_spec);
  for (i = 0; i < 10; ++i) {
    mixed_spec[i] = safe_pow01(top_spec[i], weight) * safe_pow01(bottom_spec[i], 1.0 - weight);
  }
  spectral10_to_rgb(mixed_spec, &spectral_r, &spectral_g, &spectral_b);

  *out_r = clamp01((1.0 - pigment) * additive_r + pigment * spectral_r);
  *out_g = clamp01((1.0 - pigment) * additive_g + pigment * spectral_g);
  *out_b = clamp01((1.0 - pigment) * additive_b + pigment * spectral_b);
}

static double posterize_channel(double value, double levels) {
  double v = clamp01(value);
  double steps = fmax(levels, 1.0);
  return clamp01(round(v * steps) / steps);
}

static void apply_posterize_rgb(
  double posterize,
  double posterize_num,
  double *r,
  double *g,
  double *b
) {
  double strength = clamp01(posterize);
  double levels;
  double post_r;
  double post_g;
  double post_b;

  if (strength <= 0.0) {
    return;
  }

  levels = fmax(1.0, round(fmax(posterize_num, 0.01) * 100.0));
  post_r = posterize_channel(*r, levels);
  post_g = posterize_channel(*g, levels);
  post_b = posterize_channel(*b, levels);

  *r = (1.0 - strength) * *r + strength * post_r;
  *g = (1.0 - strength) * *g + strength * post_g;
  *b = (1.0 - strength) * *b + strength * post_b;
}

static void load_pixel_rgba(const unsigned char *px, double *r, double *g, double *b, double *a) {
  double pa = px[3] / 255.0;
  double pr = px[2] / 255.0;
  double pg = px[1] / 255.0;
  double pb = px[0] / 255.0;

  *a = pa;
  if (pa <= 1e-6) {
    *r = 0.0;
    *g = 0.0;
    *b = 0.0;
    return;
  }

  *r = clamp01(pr / pa);
  *g = clamp01(pg / pa);
  *b = clamp01(pb / pa);
}

static void store_pixel_rgba(unsigned char *px, double r, double g, double b, double a) {
  double pa = clamp01(a);
  px[0] = unit_to_byte(clamp01(b) * pa);
  px[1] = unit_to_byte(clamp01(g) * pa);
  px[2] = unit_to_byte(clamp01(r) * pa);
  px[3] = unit_to_byte(pa);
}

static void blend_dab_pixel(
  double src_r,
  double src_g,
  double src_b,
  double alpha,
  double alpha_eraser,
  double lock_alpha,
  double colorize,
  double *dst_r,
  double *dst_g,
  double *dst_b,
  double *dst_a
) {
  double base_r = *dst_r;
  double base_g = *dst_g;
  double base_b = *dst_b;
  double base_a = *dst_a;
  double normal_a;
  double normal_pr;
  double normal_pg;
  double normal_pb;
  double normal_r = 0.0;
  double normal_g = 0.0;
  double normal_b = 0.0;
  double final_a;
  double final_r;
  double final_g;
  double final_b;

  if (alpha_eraser > 0.0) {
    double keep = 1.0 - clamp01(alpha * alpha_eraser);
    base_a *= keep;
  }

  normal_a = alpha + base_a * (1.0 - alpha);
  normal_pr = src_r * alpha + base_r * base_a * (1.0 - alpha);
  normal_pg = src_g * alpha + base_g * base_a * (1.0 - alpha);
  normal_pb = src_b * alpha + base_b * base_a * (1.0 - alpha);

  if (normal_a > 1e-6) {
    normal_r = clamp01(normal_pr / normal_a);
    normal_g = clamp01(normal_pg / normal_a);
    normal_b = clamp01(normal_pb / normal_a);
  }

  final_a = normal_a;
  final_r = normal_r;
  final_g = normal_g;
  final_b = normal_b;

  if (colorize > 0.0 && base_a > 1e-6) {
    double src_h;
    double src_s;
    double src_v;
    double dst_h;
    double dst_s;
    double dst_v;
    double colorized_r;
    double colorized_g;
    double colorized_b;

    rgb_to_hsv(src_r, src_g, src_b, &src_h, &src_s, &src_v);
    rgb_to_hsv(base_r, base_g, base_b, &dst_h, &dst_s, &dst_v);
    hsv_to_rgb(src_h, src_s, dst_v, &colorized_r, &colorized_g, &colorized_b);

    final_r = (1.0 - colorize) * final_r + colorize * colorized_r;
    final_g = (1.0 - colorize) * final_g + colorize * colorized_g;
    final_b = (1.0 - colorize) * final_b + colorize * colorized_b;
    final_a = (1.0 - colorize) * final_a + colorize * base_a;
  }

  if (lock_alpha > 0.0) {
    final_a = (1.0 - lock_alpha) * final_a + lock_alpha * base_a;
  }

  *dst_r = clamp01(final_r);
  *dst_g = clamp01(final_g);
  *dst_b = clamp01(final_b);
  *dst_a = clamp01(final_a);
}

static void blend_dab_pixel_pigment(
  double src_r,
  double src_g,
  double src_b,
  double alpha,
  double alpha_eraser,
  double lock_alpha,
  double colorize,
  double posterize,
  double posterize_num,
  double paint,
  double *dst_r,
  double *dst_g,
  double *dst_b,
  double *dst_a
) {
  double base_r = *dst_r;
  double base_g = *dst_g;
  double base_b = *dst_b;
  double base_a = *dst_a;
  double out_a;
  double top_weight;
  double final_r;
  double final_g;
  double final_b;
  double final_a;

  if (alpha_eraser > 0.0) {
    double keep = 1.0 - clamp01(alpha * alpha_eraser);
    base_a *= keep;
  }

  out_a = alpha + base_a * (1.0 - alpha);
  if (out_a <= 1e-6) {
    *dst_r = 0.0;
    *dst_g = 0.0;
    *dst_b = 0.0;
    *dst_a = 0.0;
    return;
  }

  top_weight = clamp01(alpha / out_a);
  mix_rgb_paint_mode(
    src_r,
    src_g,
    src_b,
    base_r,
    base_g,
    base_b,
    top_weight,
    paint,
    &final_r,
    &final_g,
    &final_b
  );
  final_a = out_a;

  apply_posterize_rgb(posterize, posterize_num, &final_r, &final_g, &final_b);

  if (colorize > 0.0 && base_a > 1e-6) {
    double src_h;
    double src_s;
    double src_v;
    double dst_h;
    double dst_s;
    double dst_v;
    double colorized_r;
    double colorized_g;
    double colorized_b;

    rgb_to_hsv(src_r, src_g, src_b, &src_h, &src_s, &src_v);
    rgb_to_hsv(base_r, base_g, base_b, &dst_h, &dst_s, &dst_v);
    hsv_to_rgb(src_h, src_s, dst_v, &colorized_r, &colorized_g, &colorized_b);

    final_r = (1.0 - colorize) * final_r + colorize * colorized_r;
    final_g = (1.0 - colorize) * final_g + colorize * colorized_g;
    final_b = (1.0 - colorize) * final_b + colorize * colorized_b;
    final_a = (1.0 - colorize) * final_a + colorize * base_a;
  }

  if (lock_alpha > 0.0) {
    final_a = (1.0 - lock_alpha) * final_a + lock_alpha * base_a;
  }

  *dst_r = clamp01(final_r);
  *dst_g = clamp01(final_g);
  *dst_b = clamp01(final_b);
  *dst_a = clamp01(final_a);
}

static void sample_surface_color(
  MypaintrDevice *dev,
  float x,
  float y,
  float radius,
  float *color_r,
  float *color_g,
  float *color_b,
  float *color_a
) {
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
      double dx;
      double dy;
      double d2;
      double w;
      double r;
      double g;
      double b;
      double a;

      if (ix < 0 || ix >= dev->width) continue;

      dx = ((double) ix + 0.5) - x;
      dy = ((double) iy + 0.5) - flip_y(dev, y);
      d2 = dx * dx + dy * dy;
      if (d2 > radius * radius) continue;

      w = 1.0 - sqrt(d2) / fmax(radius, 1e-6);
      px = dev->data + (size_t) iy * (size_t) dev->stride + (size_t) ix * 4U;
      load_pixel_rgba(px, &r, &g, &b, &a);
      sr += (r * a) * w;
      sg += (g * a) * w;
      sb += (b * a) * w;
      sa += a * w;
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

  *color_a = (float) (sa / total);
  if (*color_a <= 1e-6f) {
    *color_r = 0.0f;
    *color_g = 0.0f;
    *color_b = 0.0f;
    *color_a = 0.0f;
    return;
  }

  *color_r = (float) clamp01((sr / total) / *color_a);
  *color_g = (float) clamp01((sg / total) / *color_a);
  *color_b = (float) clamp01((sb / total) / *color_a);
}

static void sample_surface_color_pigment(
  MypaintrDevice *dev,
  float x,
  float y,
  float radius,
  float paint,
  float *color_r,
  float *color_g,
  float *color_b,
  float *color_a
) {
  int x0;
  int x1;
  int y0;
  int y1;
  double total = 0.0;
  double alpha_sum = 0.0;
  double avg_r = 0.0;
  double avg_g = 0.0;
  double avg_b = 0.0;
  int have_rgb = 0;
  int ix;
  int iy;

  if (paint < 0.0f || paint <= 1e-6f) {
    sample_surface_color(dev, x, y, radius, color_r, color_g, color_b, color_a);
    return;
  }

  x0 = (int) floor(x - radius);
  x1 = (int) ceil(x + radius);
  y0 = (int) floor(flip_y(dev, y) - radius);
  y1 = (int) ceil(flip_y(dev, y) + radius);

  cairo_surface_flush(dev->image_surface);

  for (iy = y0; iy <= y1; ++iy) {
    if (iy < 0 || iy >= dev->height) continue;
    for (ix = x0; ix <= x1; ++ix) {
      unsigned char *px;
      double dx;
      double dy;
      double d2;
      double w;
      double r;
      double g;
      double b;
      double a;
      double weighted_alpha;

      if (ix < 0 || ix >= dev->width) continue;

      dx = ((double) ix + 0.5) - x;
      dy = ((double) iy + 0.5) - flip_y(dev, y);
      d2 = dx * dx + dy * dy;
      if (d2 > radius * radius) continue;

      w = 1.0 - sqrt(d2) / fmax(radius, 1e-6);
      total += w;

      px = dev->data + (size_t) iy * (size_t) dev->stride + (size_t) ix * 4U;
      load_pixel_rgba(px, &r, &g, &b, &a);
      weighted_alpha = w * a;
      if (weighted_alpha <= 1e-9) {
        continue;
      }

      if (!have_rgb) {
        avg_r = r;
        avg_g = g;
        avg_b = b;
        have_rgb = 1;
      } else {
        double fac_new = weighted_alpha / (alpha_sum + weighted_alpha);
        mix_rgb_paint_mode(
          r,
          g,
          b,
          avg_r,
          avg_g,
          avg_b,
          fac_new,
          paint,
          &avg_r,
          &avg_g,
          &avg_b
        );
      }

      alpha_sum += weighted_alpha;
    }
  }

  if (total <= 0.0 || alpha_sum <= 1e-9) {
    *color_r = 0.0f;
    *color_g = 0.0f;
    *color_b = 0.0f;
    *color_a = 0.0f;
    return;
  }

  *color_a = (float) clamp01(alpha_sum / total);
  if (*color_a <= 1e-6f) {
    *color_r = 0.0f;
    *color_g = 0.0f;
    *color_b = 0.0f;
    *color_a = 0.0f;
    return;
  }

  *color_r = (float) clamp01(avg_r);
  *color_g = (float) clamp01(avg_g);
  *color_b = (float) clamp01(avg_b);
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

static void init_hand_defaults(MypaintrHand *hand, uint64_t salt) {
  memset(hand, 0, sizeof(*hand));
  hand->rng_state = mix64(salt ? salt : 1ULL);
  hand->bow = 0.0;
  hand->wobble = 0.0;
  hand->multi_stroke = 1;
  hand->width_jitter = 0.0;
  hand->endpoint_jitter = 0.0;
  hand->pressure = 1.0;
  hand->pressure_taper = 0.0;
  hand->hachure_angle_jitter = 12.0;
  hand->hachure_gap_jitter = 0.15;
}

static void configure_hand(MypaintrHand *hand, SEXP spec, uint64_t salt) {
  SEXP value;
  init_hand_defaults(hand, salt);

  if (spec == R_NilValue) {
    return;
  }
  if (TYPEOF(spec) != VECSXP) {
    error("hand spec must be a hand() object or NULL");
  }

  hand->enabled = 1;
  value = list_element(spec, "seed");
  if (value != R_NilValue && XLENGTH(value) == 1) {
    hand->rng_state = mix64((uint64_t) llround(asReal(value)) ^ salt);
  }
  value = list_element(spec, "bow");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->bow = asReal(value);
  value = list_element(spec, "wobble");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->wobble = asReal(value);
  value = list_element(spec, "multi_stroke");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->multi_stroke = asInteger(value);
  value = list_element(spec, "width_jitter");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->width_jitter = asReal(value);
  value = list_element(spec, "endpoint_jitter");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->endpoint_jitter = asReal(value);
  value = list_element(spec, "pressure");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->pressure = clamp01(asReal(value));
  value = list_element(spec, "pressure_taper");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->pressure_taper = clamp01(asReal(value));
  value = list_element(spec, "hachure_gap");
  if (value != R_NilValue && XLENGTH(value) == 1) {
    hand->has_hachure_gap = 1;
    hand->hachure_gap = asReal(value);
  }
  value = list_element(spec, "hachure_angle_jitter");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->hachure_angle_jitter = asReal(value);
  value = list_element(spec, "hachure_gap_jitter");
  if (value != R_NilValue && XLENGTH(value) == 1) hand->hachure_gap_jitter = asReal(value);
  value = list_element(spec, "hachure_method");
  if (TYPEOF(value) == STRSXP && XLENGTH(value) == 1) {
    hand->hachure_cross = strcmp(CHAR(STRING_ELT(value, 0)), "cross") == 0;
  }

  if (hand->multi_stroke < 1) {
    hand->multi_stroke = 1;
  }
}

static double stroke_pressure_at(const MypaintrHand *hand, double t, double turn_factor) {
  double base = hand ? clamp01(hand->pressure) : 1.0;
  double taper = hand ? clamp01(hand->pressure_taper) : 0.0;
  double tt = clamp01(t);
  double profile = sin(M_PI * tt);
  double pressure = base * ((1.0 - taper) + taper * profile);

  if (taper > 0.0 && turn_factor > 0.0) {
    pressure *= 1.0 - 0.35 * taper * clamp01(turn_factor);
  }

  return clamp01(pressure);
}

static double polyline_turn_factor(const double *x, const double *y, int n, int i) {
  if (i <= 0 || i + 1 >= n) {
    return 0.0;
  }

  {
    double prev_dx = x[i] - x[i - 1];
    double prev_dy = y[i] - y[i - 1];
    double next_dx = x[i + 1] - x[i];
    double next_dy = y[i + 1] - y[i];
    double prev_len = sqrt(prev_dx * prev_dx + prev_dy * prev_dy);
    double next_len = sqrt(next_dx * next_dx + next_dy * next_dy);

    if (prev_len > 1e-9 && next_len > 1e-9) {
      double cosang = (prev_dx * next_dx + prev_dy * next_dy) / (prev_len * next_len);
      cosang = fmax(-1.0, fmin(1.0, cosang));
      return 0.5 * (1.0 - cosang);
    }
  }

  return 0.0;
}

static void rough_segment_path(double x0, double y0, double x1, double y1, MypaintrHand *hand, PointBuffer *buf) {
  double dx = x1 - x0;
  double dy = y1 - y0;
  double len = sqrt(dx * dx + dy * dy);
  double ux;
  double uy;
  double px;
  double py;
  double endpoint_sd;
  double bow_amp;
  double wobble_amp;
  double start_para;
  double end_para;
  double start_perp;
  double end_perp;
  double sx;
  double sy;
  double ex;
  double ey;
  double ctrl1;
  double ctrl2;
  int i;
  int n;

  if (!isfinite(len) || len <= 0.0) {
    point_buffer_alloc(buf, 1);
    buf->x[0] = x0;
    buf->y[0] = y0;
    return;
  }

  ux = dx / len;
  uy = dy / len;
  px = -uy;
  py = ux;
  endpoint_sd = hand->endpoint_jitter * len;
  bow_amp = hand_normal(hand, hand->bow * len);
  wobble_amp = hand->wobble * len;
  start_para = hand_normal(hand, endpoint_sd);
  end_para = hand_normal(hand, endpoint_sd);
  start_perp = hand_normal(hand, endpoint_sd);
  end_perp = hand_normal(hand, endpoint_sd);
  sx = x0 + ux * start_para + px * start_perp;
  sy = y0 + uy * start_para + py * start_perp;
  ex = x1 + ux * end_para + px * end_perp;
  ey = y1 + uy * end_para + py * end_perp;
  ctrl1 = hand_normal(hand, wobble_amp);
  ctrl2 = hand_normal(hand, wobble_amp);
  n = (int) fmax(6.0, ceil(len * 12.0));

  point_buffer_alloc(buf, n);
  for (i = 0; i < n; ++i) {
    double t = n == 1 ? 0.0 : (double) i / (double) (n - 1);
    double base_x = sx + (ex - sx) * t;
    double base_y = sy + (ey - sy) * t;
    double offset = bow_amp * sin(M_PI * t) + hand_offset(t, ctrl1, ctrl2) * sin(M_PI * t);
    buf->x[i] = base_x + px * offset;
    buf->y[i] = base_y + py * offset;
  }
}

static void roughen_vertex_path(const double *x, const double *y, int n, MypaintrHand *hand, int closed, PointBuffer *out) {
  int seg_n;
  int total = 0;
  int offset = 0;
  int i;

  if (n < 2) {
    point_buffer_alloc(out, n > 0 ? n : 1);
    if (n > 0) {
      memcpy(out->x, x, (size_t) n * sizeof(double));
      memcpy(out->y, y, (size_t) n * sizeof(double));
      out->n = n;
    } else {
      out->x[0] = 0.0;
      out->y[0] = 0.0;
      out->n = 1;
    }
    return;
  }

  seg_n = closed ? n : (n - 1);
  for (i = 0; i < seg_n; ++i) {
    int j = (i + 1 == n) ? 0 : (i + 1);
    double dx = x[j] - x[i];
    double dy = y[j] - y[i];
    double len = sqrt(dx * dx + dy * dy);
    int seg_pts = (int) fmax(6.0, ceil(len * 12.0));
    total += seg_pts - (i > 0 ? 1 : 0);
  }

  point_buffer_alloc(out, total);
  for (i = 0; i < seg_n; ++i) {
    int j = (i + 1 == n) ? 0 : (i + 1);
    PointBuffer seg = {0};
    int start = (i > 0) ? 1 : 0;
    int k;
    rough_segment_path(x[i], y[i], x[j], y[j], hand, &seg);
    for (k = start; k < seg.n; ++k) {
      out->x[offset] = seg.x[k];
      out->y[offset] = seg.y[k];
      offset += 1;
    }
    point_buffer_free(&seg);
  }
  out->n = offset;
}

static double flip_y(const MypaintrDevice *dev, double y) {
  return (double) dev->height - y;
}

static void set_font_face_for_context(cairo_t *cr, double res, const pGEcontext gc) {
  cairo_font_slant_t slant = CAIRO_FONT_SLANT_NORMAL;
  cairo_font_weight_t weight = CAIRO_FONT_WEIGHT_NORMAL;

  if (gc->fontface == 3 || gc->fontface == 4) {
    slant = CAIRO_FONT_SLANT_ITALIC;
  }
  if (gc->fontface == 2 || gc->fontface == 4) {
    weight = CAIRO_FONT_WEIGHT_BOLD;
  }

  cairo_select_font_face(
    cr,
    gc->fontfamily[0] ? gc->fontfamily : "sans",
    slant,
    weight
  );
  cairo_set_font_size(cr, gc->cex * gc->ps * res / 72.0);
}

static void set_font_face(const MypaintrDevice *dev, const pGEcontext gc) {
  set_font_face_for_context(dev->cr, dev->res, gc);
}

static void apply_cairo_clip(MypaintrDevice *dev) {
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

static void clear_device(MypaintrDevice *dev, int col) {
  cairo_save(dev->cr);
  cairo_set_operator(dev->cr, CAIRO_OPERATOR_SOURCE);
  set_cairo_source(dev->cr, col);
  cairo_paint(dev->cr);
  cairo_restore(dev->cr);
}

static char *page_filename(const MypaintrDevice *dev, int page) {
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
    return mypaintr_strdup(dev->filename);
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

static void save_page(MypaintrDevice *dev) {
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

static void brush_apply_gc(MypaintrBrush *brush, int col, double lwd) {
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
  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_SMUDGE, (float) brush->base_smudge);
  mypaint_brush_set_base_value(
    brush->brush,
    MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY,
    (float) brush->base_opaque_multiply
  );
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

static void brush_seed_from_surface(MypaintrDevice *dev, MypaintrBrush *brush, double x, double y) {
  double sample_radius = exp(brush->base_radius_log);
  double smudge_radius_log = mypaint_brush_get_base_value(brush->brush, MYPAINT_BRUSH_SETTING_SMUDGE_RADIUS_LOG);
  float r, g, b, a;
  double h, s, v;

  sample_radius *= exp(smudge_radius_log);
  if (!isfinite(sample_radius) || sample_radius <= 1e-6) {
    sample_radius = exp(brush->base_radius_log);
  }
  if (!isfinite(sample_radius) || sample_radius <= 1e-6) {
    sample_radius = 1.0;
  }

  sample_surface_color(dev, (float) x, (float) y, (float) sample_radius, &r, &g, &b, &a);
  if (a <= 1e-6f) {
    r = g = b = 1.0f;
    a = 1.0f;
  }

  rgb_to_hsv(r, g, b, &h, &s, &v);
  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_COLOR_H, (float) h);
  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_COLOR_S, (float) s);
  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_COLOR_V, (float) v);
  mypaint_brush_set_state(brush->brush, MYPAINT_BRUSH_STATE_SMUDGE_RA, r * a);
  mypaint_brush_set_state(brush->brush, MYPAINT_BRUSH_STATE_SMUDGE_GA, g * a);
  mypaint_brush_set_state(brush->brush, MYPAINT_BRUSH_STATE_SMUDGE_BA, b * a);
  mypaint_brush_set_state(brush->brush, MYPAINT_BRUSH_STATE_SMUDGE_A, a);
  /* Pure smudge brushes are approximated as surface-sampled paint strokes. */
  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_SMUDGE, 0.0f);
  mypaint_brush_set_base_value(brush->brush, MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY, 1.0f);
}

static int brush_is_pure_smudge(const MypaintrBrush *brush) {
  (void) brush;
  return 0;
}

static void brush_apply_spec(MypaintrBrush *slot, SEXP spec) {
  configure_brush(slot->brush, spec);
  slot->base_radius_log = mypaint_brush_get_base_value(slot->brush, MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC);
  slot->base_opaque = mypaint_brush_get_base_value(slot->brush, MYPAINT_BRUSH_SETTING_OPAQUE);
  slot->base_smudge = mypaint_brush_get_base_value(slot->brush, MYPAINT_BRUSH_SETTING_SMUDGE);
  slot->base_opaque_multiply = mypaint_brush_get_base_value(slot->brush, MYPAINT_BRUSH_SETTING_OPAQUE_MULTIPLY);
  slot->pure_smudge = brush_is_pure_smudge(slot);
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
  MypaintrDevice *dev = (MypaintrDevice *) surface;
  double src_r = clamp01(color_r);
  double src_g = clamp01(color_g);
  double src_b = clamp01(color_b);
  int x0, x1, y0, y1;
  int ix, iy;
  double c = cos(angle);
  double s = sin(angle);
  double a_ratio = aspect_ratio > 1e-6 ? aspect_ratio : 1.0;
  double rx = radius * a_ratio;
  double ry = radius / a_ratio;
  double maxr = fmax(rx, ry);
  double py_center = flip_y(dev, y);

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
      double dst_b;
      double dst_g;
      double dst_r;
      double dst_a;

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
      load_pixel_rgba(px, &dst_r, &dst_g, &dst_b, &dst_a);
      blend_dab_pixel(
        src_r,
        src_g,
        src_b,
        alpha,
        alpha_eraser,
        clamp01(lock_alpha),
        clamp01(colorize),
        &dst_r,
        &dst_g,
        &dst_b,
        &dst_a
      );
      store_pixel_rgba(px, dst_r, dst_g, dst_b, dst_a);
    }
  }

  cairo_surface_mark_dirty(dev->image_surface);
  return 1;
}

static int surface_draw_dab_pigment(
  MyPaintSurface2 *surface,
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
  float colorize,
  float posterize,
  float posterize_num,
  float paint
) {
  MypaintrDevice *dev = (MypaintrDevice *) surface;
  double src_r = clamp01(color_r);
  double src_g = clamp01(color_g);
  double src_b = clamp01(color_b);
  int x0, x1, y0, y1;
  int ix, iy;
  double c = cos(angle);
  double s = sin(angle);
  double a_ratio = aspect_ratio > 1e-6 ? aspect_ratio : 1.0;
  double rx = radius * a_ratio;
  double ry = radius / a_ratio;
  double maxr = fmax(rx, ry);
  double py_center = flip_y(dev, y);

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
      double dst_b;
      double dst_g;
      double dst_r;
      double dst_a;

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
      load_pixel_rgba(px, &dst_r, &dst_g, &dst_b, &dst_a);
      blend_dab_pixel_pigment(
        src_r,
        src_g,
        src_b,
        alpha,
        alpha_eraser,
        clamp01(lock_alpha),
        clamp01(colorize),
        clamp01(posterize),
        posterize_num,
        clamp01(paint),
        &dst_r,
        &dst_g,
        &dst_b,
        &dst_a
      );
      store_pixel_rgba(px, dst_r, dst_g, dst_b, dst_a);
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
  MypaintrDevice *dev = (MypaintrDevice *) surface;
  sample_surface_color(dev, x, y, radius, color_r, color_g, color_b, color_a);
}

static void surface_get_color_pigment(
  MyPaintSurface2 *surface,
  float x,
  float y,
  float radius,
  float *color_r,
  float *color_g,
  float *color_b,
  float *color_a,
  float paint
) {
  sample_surface_color_pigment((MypaintrDevice *) surface, x, y, radius, paint, color_r, color_g, color_b, color_a);
}

static void surface_begin_atomic(MyPaintSurface *surface) {
  MypaintrDevice *dev = (MypaintrDevice *) surface;
  cairo_surface_flush(dev->image_surface);
}

static void surface_end_atomic(MyPaintSurface *surface, MyPaintRectangle *roi) {
  MypaintrDevice *dev = (MypaintrDevice *) surface;
  (void) roi;
  cairo_surface_mark_dirty(dev->image_surface);
}

static void surface_end_atomic_multi(MyPaintSurface2 *surface, MyPaintRectangles *roi) {
  MypaintrDevice *dev = (MypaintrDevice *) surface;
  (void) roi;
  cairo_surface_mark_dirty(dev->image_surface);
}

static void surface_destroy(MyPaintSurface *surface) {
  (void) surface;
}

static void init_surface(MypaintrDevice *dev) {
  mypaint_surface_init(&dev->surface.parent);
  dev->surface.parent.draw_dab = surface_draw_dab;
  dev->surface.parent.get_color = surface_get_color;
  dev->surface.parent.begin_atomic = surface_begin_atomic;
  dev->surface.parent.end_atomic = surface_end_atomic;
  dev->surface.parent.destroy = surface_destroy;
  dev->surface.draw_dab_pigment = surface_draw_dab_pigment;
  dev->surface.get_color_pigment = surface_get_color_pigment;
  dev->surface.end_atomic_multi = surface_end_atomic_multi;
}

static void render_polyline_solid(MypaintrDevice *dev, MypaintrBrush *brush, const double *x, const double *y, int n, int col, double lwd) {
  int i;
  double start_dx;
  double start_dy;
  double start_len;
  double preroll;
  double start_x;
  double start_y;
  double radius;
  MypaintrHand neutral_hand;
  const MypaintrHand *pressure_hand;

  if (n < 2 || R_ALPHA(col) == 0) {
    return;
  }

  init_hand_defaults(&neutral_hand, 1ULL);
  pressure_hand = &neutral_hand;
  if (brush == &dev->stroke) {
    pressure_hand = &dev->stroke_hand;
  } else if (brush == &dev->fill) {
    pressure_hand = &dev->fill_hand;
  }

  brush_apply_gc(brush, col, lwd);
  start_dx = x[1] - x[0];
  start_dy = y[1] - y[0];
  start_len = sqrt(start_dx * start_dx + start_dy * start_dy);
  radius = exp(mypaint_brush_get_base_value(brush->brush, MYPAINT_BRUSH_SETTING_RADIUS_LOGARITHMIC));
  preroll = fmax(4.0, 6.0 * radius);
  if (start_len > 1e-9) {
    start_x = x[0] - preroll * start_dx / start_len;
    start_y = y[0] - preroll * start_dy / start_len;
  } else {
    start_x = x[0];
    start_y = y[0];
  }

  mypaint_brush_reset(brush->brush);
  mypaint_brush_new_stroke(brush->brush);
  if (brush->pure_smudge) {
    brush_seed_from_surface(dev, brush, x[0], y[0]);
  }
  mypaint_surface_begin_atomic((MyPaintSurface *) &dev->surface);
  mypaint_brush_stroke_to_2(brush->brush, &dev->surface, (float) start_x, (float) start_y, 0.0f, 0.0f, 0.0f, 0.01, 1.0f, 0.0f, 0.0f);
  if (start_len > 1e-9) {
    double dt0 = fmax(preroll / 240.0, 0.001);
    mypaint_brush_stroke_to_2(brush->brush, &dev->surface, (float) x[0], (float) y[0], 0.0f, 0.0f, 0.0f, dt0, 1.0f, 0.0f, 0.0f);
  }
  mypaint_brush_stroke_to_2(
    brush->brush,
    &dev->surface,
    (float) x[0],
    (float) y[0],
    (float) stroke_pressure_at(pressure_hand, 0.0, 0.0),
    0.0f,
    0.0f,
    0.001,
    1.0f,
    0.0f,
    0.0f
  );

  for (i = 1; i < n; ++i) {
    double dx = x[i] - x[i - 1];
    double dy = y[i] - y[i - 1];
    double dt = fmax(sqrt(dx * dx + dy * dy) / 240.0, 0.001);
    double t = (n > 1) ? (double) i / (double) (n - 1) : 1.0;
    double turn_factor = polyline_turn_factor(x, y, n, i);

    mypaint_brush_stroke_to_2(
      brush->brush,
      &dev->surface,
      (float) x[i],
      (float) y[i],
      (float) stroke_pressure_at(pressure_hand, t, turn_factor),
      0.0f,
      0.0f,
      dt,
      1.0f,
      0.0f,
      0.0f
    );
  }

  mypaint_brush_stroke_to_2(brush->brush, &dev->surface, (float) x[n - 1], (float) y[n - 1], 0.0f, 0.0f, 0.0f, 0.01, 1.0f, 0.0f, 0.0f);
  mypaint_surface_end_atomic((MyPaintSurface *) &dev->surface, NULL);
}

static int decode_lty(int lty, double lwd, double *pattern, int max_pattern) {
  int count = 0;
  double unit = fmax(2.0, 4.0 * lwd);

  if (lty == LTY_SOLID || lty == 0) {
    return 0;
  }
  if (lty == LTY_BLANK) {
    pattern[0] = 0.0;
    return -1;
  }

  while (lty != 0 && count < max_pattern) {
    int nibble = lty & 15;
    pattern[count++] = unit * (double) (nibble > 0 ? nibble : 1);
    lty >>= 4;
  }

  return count > 0 ? count : 0;
}

static void cairo_set_lty(cairo_t *cr, int lty, double lwd) {
  double pattern[8];
  int pattern_n = decode_lty(lty, lwd, pattern, 8);

  if (pattern_n > 0) {
    cairo_set_dash(cr, pattern, pattern_n, 0.0);
  } else {
    cairo_set_dash(cr, NULL, 0, 0.0);
  }
}

static void solid_stroke_polyline(MypaintrDevice *dev, const double *x, const double *y, int n, int col, double lwd, int lty, int closed, const MypaintrHand *hand) {
  int i;
  double total_len = 0.0;
  int emulate_pressure = 0;

  if (n < 2 || R_ALPHA(col) == 0 || lty == LTY_BLANK) {
    return;
  }

  if (hand && !closed && lty == LTY_SOLID) {
    emulate_pressure =
      fabs(clamp01(hand->pressure) - 1.0) > 1e-9 ||
      clamp01(hand->pressure_taper) > 1e-9;
  }

  if (emulate_pressure) {
    for (i = 1; i < n; ++i) {
      double dx = x[i] - x[i - 1];
      double dy = y[i] - y[i - 1];
      total_len += sqrt(dx * dx + dy * dy);
    }
  }

  if (emulate_pressure && total_len > 1e-9) {
    double cumulative = 0.0;

    cairo_save(dev->cr);
    set_cairo_source(dev->cr, col);
    cairo_set_line_cap(dev->cr, CAIRO_LINE_CAP_ROUND);
    cairo_set_line_join(dev->cr, CAIRO_LINE_JOIN_ROUND);

    for (i = 1; i < n; ++i) {
      double sx = x[i - 1];
      double sy = y[i - 1];
      double ex = x[i];
      double ey = y[i];
      double dx = ex - sx;
      double dy = ey - sy;
      double seg_len = sqrt(dx * dx + dy * dy);
      int pieces;
      int j;

      if (seg_len <= 1e-9) {
        continue;
      }

      pieces = (int) fmax(1.0, ceil(seg_len / 6.0));
      for (j = 0; j < pieces; ++j) {
        double u0 = (double) j / (double) pieces;
        double u1 = (double) (j + 1) / (double) pieces;
        double x0 = sx + dx * u0;
        double y0 = sy + dy * u0;
        double x1 = sx + dx * u1;
        double y1 = sy + dy * u1;
        double mid = cumulative + seg_len * (u0 + u1) * 0.5;
        double t = mid / total_len;
        double width = fmax(1e-3, lwd * stroke_pressure_at(hand, t, polyline_turn_factor(x, y, n, i - 1)));

        cairo_new_path(dev->cr);
        cairo_move_to(dev->cr, x0, flip_y(dev, y0));
        cairo_line_to(dev->cr, x1, flip_y(dev, y1));
        cairo_set_line_width(dev->cr, width);
        cairo_stroke(dev->cr);
      }

      cumulative += seg_len;
    }

    cairo_restore(dev->cr);
    return;
  }

  cairo_save(dev->cr);
  cairo_new_path(dev->cr);
  cairo_move_to(dev->cr, x[0], flip_y(dev, y[0]));
  for (i = 1; i < n; ++i) {
    cairo_line_to(dev->cr, x[i], flip_y(dev, y[i]));
  }
  if (closed) {
    cairo_close_path(dev->cr);
  }
  set_cairo_source(dev->cr, col);
  cairo_set_line_width(dev->cr, fmax(lwd, 1e-3));
  cairo_set_line_cap(dev->cr, CAIRO_LINE_CAP_ROUND);
  cairo_set_line_join(dev->cr, CAIRO_LINE_JOIN_ROUND);
  cairo_set_lty(dev->cr, lty, lwd);
  cairo_stroke(dev->cr);
  cairo_restore(dev->cr);
}

static void render_polyline(MypaintrDevice *dev, MypaintrBrush *brush, const double *x, const double *y, int n, int col, double lwd, int lty) {
  double pattern[8];
  int pattern_n = decode_lty(lty, lwd, pattern, 8);
  int pattern_i = 0;
  double remaining;
  int draw_on = 1;
  int i;

  if (n < 2 || R_ALPHA(col) == 0 || lty == LTY_BLANK) {
    return;
  }

  if (pattern_n <= 0) {
    render_polyline_solid(dev, brush, x, y, n, col, lwd);
    return;
  }

  remaining = pattern[0];

  for (i = 1; i < n; ++i) {
    double sx = x[i - 1];
    double sy = y[i - 1];
    double ex = x[i];
    double ey = y[i];
    double dx = ex - sx;
    double dy = ey - sy;
    double seg_len = sqrt(dx * dx + dy * dy);

    while (seg_len > 1e-9) {
      double step = fmin(remaining, seg_len);
      double ux = (ex - sx) / seg_len;
      double uy = (ey - sy) / seg_len;
      double nx = sx + ux * step;
      double ny = sy + uy * step;

      if (draw_on && step > 1e-9) {
        double segx[2] = {sx, nx};
        double segy[2] = {sy, ny};
        render_polyline_solid(dev, brush, segx, segy, 2, col, lwd);
      }

      sx = nx;
      sy = ny;
      seg_len -= step;
      remaining -= step;

      if (remaining <= 1e-9) {
        pattern_i = (pattern_i + 1) % pattern_n;
        remaining = pattern[pattern_i];
        draw_on = !draw_on;
      }
    }
  }
}

static void render_polyline_mode(MypaintrDevice *dev, MypaintrBrush *brush, int render_style, const double *x, const double *y, int n, int col, double lwd, int lty, int closed) {
  if (render_style == MYPAINTR_RENDER_BRUSH) {
    render_polyline(dev, brush, x, y, n, col, lwd, lty);
  } else {
    solid_stroke_polyline(dev, x, y, n, col, lwd, lty, closed, NULL);
  }
}

static void render_polyline_mode_hand(MypaintrDevice *dev, MypaintrBrush *brush, int render_style, const double *x, const double *y, int n, int col, double lwd, int lty, int closed, const MypaintrHand *hand) {
  if (render_style == MYPAINTR_RENDER_BRUSH) {
    render_polyline(dev, brush, x, y, n, col, lwd, lty);
  } else {
    solid_stroke_polyline(dev, x, y, n, col, lwd, lty, closed, hand);
  }
}

static void render_polyline_hand(MypaintrDevice *dev, MypaintrBrush *brush, int render_style, const double *x, const double *y, int n, int col, double lwd, int lty, int closed, MypaintrHand *hand) {
  int i;

  if (!hand->enabled) {
    render_polyline_mode(dev, brush, render_style, x, y, n, col, lwd, lty, closed);
    return;
  }

  for (i = 0; i < hand->multi_stroke; ++i) {
    PointBuffer path = {0};
    double jittered_lwd;
    roughen_vertex_path(x, y, n, hand, closed, &path);
    jittered_lwd = fmax(0.01, lwd * (1.0 + hand_normal(hand, hand->width_jitter)));
    render_polyline_mode_hand(dev, brush, render_style, path.x, path.y, path.n, col, jittered_lwd, lty, 0, hand);
    point_buffer_free(&path);
  }
}

static void cairo_polygon_path(MypaintrDevice *dev, int n, const double *x, const double *y) {
  int i;
  cairo_new_path(dev->cr);
  cairo_move_to(dev->cr, x[0], flip_y(dev, y[0]));
  for (i = 1; i < n; ++i) {
    cairo_line_to(dev->cr, x[i], flip_y(dev, y[i]));
  }
  cairo_close_path(dev->cr);
}

static void solid_fill_polygon(MypaintrDevice *dev, int n, const double *x, const double *y, int fill, int rule) {
  if (R_ALPHA(fill) == 0) {
    return;
  }
  cairo_polygon_path(dev, n, x, y);
  cairo_set_fill_rule(dev->cr, rule == R_GE_nonZeroWindingRule ? CAIRO_FILL_RULE_WINDING : CAIRO_FILL_RULE_EVEN_ODD);
  set_cairo_source(dev->cr, fill);
  cairo_fill(dev->cr);
}

static int cmp_intersection(const void *lhs, const void *rhs) {
  double a = ((const HatchIntersection *) lhs)->x;
  double b = ((const HatchIntersection *) rhs)->x;
  return (a > b) - (a < b);
}

static void hatch_fill_path(MypaintrDevice *dev, MypaintrBrush *brush, int npoly, const int *nper, const double *x, const double *y, int fill, int rule) {
  double radius = exp(brush->base_radius_log);
  double spacing = fmax(2.0, radius * 1.5);
  double min_y = y[0];
  double max_y = y[0];
  int total_points = 0;
  int offset = 0;
  int i;
  HatchIntersection *cuts;

  if (R_ALPHA(fill) == 0) {
    return;
  }

  for (i = 0; i < npoly; ++i) {
    total_points += nper[i];
  }
  if (total_points < 3) {
    return;
  }

  cuts = (HatchIntersection *) malloc((size_t) total_points * sizeof(HatchIntersection));
  if (!cuts) {
    error("failed to allocate polygon fill buffer");
  }

  for (i = 1; i < total_points; ++i) {
    if (y[i] < min_y) min_y = y[i];
    if (y[i] > max_y) max_y = y[i];
  }

  for (double yy = min_y; yy <= max_y; yy += spacing) {
    int count = 0;
    offset = 0;

    for (i = 0; i < npoly; ++i) {
      int j;
      int n = nper[i];
      for (j = 0; j < n; ++j) {
        int k = (j + 1) % n;
        double x0 = x[offset + j];
        double y0 = y[offset + j];
        double x1 = x[offset + k];
        double y1 = y[offset + k];
        if ((yy >= fmin(y0, y1)) && (yy < fmax(y0, y1)) && (y0 != y1)) {
          cuts[count].x = x0 + (yy - y0) * (x1 - x0) / (y1 - y0);
          cuts[count].delta = (y1 > y0) ? 1 : -1;
          count += 1;
        }
      }
      offset += n;
    }

    qsort(cuts, (size_t) count, sizeof(HatchIntersection), cmp_intersection);

    if (rule == R_GE_evenOddRule) {
      for (i = 0; i + 1 < count; i += 2) {
        double segx[2] = {cuts[i].x, cuts[i + 1].x};
        double segy[2] = {yy, yy};
        render_polyline(dev, brush, segx, segy, 2, fill, 1.0, LTY_SOLID);
      }
    } else {
      int winding = 0;
      for (i = 0; i + 1 < count; ++i) {
        winding += cuts[i].delta;
        if (winding != 0 && cuts[i + 1].x > cuts[i].x) {
          double segx[2] = {cuts[i].x, cuts[i + 1].x};
          double segy[2] = {yy, yy};
          render_polyline(dev, brush, segx, segy, 2, fill, 1.0, LTY_SOLID);
        }
      }
    }
  }

  free(cuts);
}

static void hatch_fill_polygon(MypaintrDevice *dev, MypaintrBrush *brush, int n, const double *x, const double *y, int fill) {
  hatch_fill_path(dev, brush, 1, &n, x, y, fill, R_GE_nonZeroWindingRule);
}

static void hatch_fill_rect(MypaintrDevice *dev, MypaintrBrush *brush, double x0, double y0, double x1, double y1, int fill) {
  double radius = exp(brush->base_radius_log);
  double spacing = fmax(2.0, radius * 1.5);
  double left = fmin(x0, x1);
  double right = fmax(x0, x1);
  double bottom = fmin(y0, y1);
  double top = fmax(y0, y1);

  for (double yy = bottom; yy <= top; yy += spacing) {
    double xx[2] = {left, right};
    double yyv[2] = {yy, yy};
    render_polyline(dev, brush, xx, yyv, 2, fill, 1.0, LTY_SOLID);
  }
}

static void hatch_fill_circle(MypaintrDevice *dev, MypaintrBrush *brush, double x, double y, double r, int fill) {
  double radius = exp(brush->base_radius_log);
  double spacing = fmax(2.0, radius * 1.5);

  for (double yy = y - r; yy <= y + r; yy += spacing) {
    double dy = yy - y;
    double dx = sqrt(fmax(r * r - dy * dy, 0.0));
    double xx[2] = {x - dx, x + dx};
    double yyv[2] = {yy, yy};
    render_polyline(dev, brush, xx, yyv, 2, fill, 1.0, LTY_SOLID);
  }
}

static void fill_polygon_mode(MypaintrDevice *dev, int n, const double *x, const double *y, int fill, int rule, MypaintrHand *hand) {
  if (R_ALPHA(fill) == 0) {
    return;
  }

  if (hand->enabled) {
    PointBuffer rough = {0};
    roughen_vertex_path(x, y, n, hand, 1, &rough);
    if (dev->fill_style == MYPAINTR_FILL_BRUSH && !dev->fill.pure_smudge) {
      hatch_fill_polygon(dev, &dev->fill, rough.n, rough.x, rough.y, fill);
    } else {
      solid_fill_polygon(dev, rough.n, rough.x, rough.y, fill, rule);
    }
    point_buffer_free(&rough);
    return;
  }

  if (dev->fill_style == MYPAINTR_FILL_BRUSH && !dev->fill.pure_smudge) {
    hatch_fill_polygon(dev, &dev->fill, n, x, y, fill);
  } else {
    solid_fill_polygon(dev, n, x, y, fill, rule);
  }
}

static int should_solid_fill_rect(const MypaintrDevice *dev, double x0, double y0, double x1, double y1, int fill) {
  double area;
  double device_area;

  if (R_ALPHA(fill) == 0) {
    return 1;
  }
  if (!dev->auto_solid_bg) {
    return 0;
  }

  area = fabs(x1 - x0) * fabs(y1 - y0);
  device_area = (double) dev->width * (double) dev->height;

  if (area < 0.10 * device_area) {
    return 0;
  }

  return colors_close(fill, dev->bg, 12);
}

static void fill_rect(MypaintrDevice *dev, double x0, double y0, double x1, double y1, int fill) {
  double xs[4] = {x0, x1, x1, x0};
  double ys[4] = {y0, y0, y1, y1};

  if (R_ALPHA(fill) == 0) {
    return;
  }

  if (dev->fill_style == MYPAINTR_FILL_BRUSH && !dev->fill.pure_smudge && !should_solid_fill_rect(dev, x0, y0, x1, y1, fill)) {
    if (dev->fill_hand.enabled) {
      fill_polygon_mode(dev, 4, xs, ys, fill, R_GE_nonZeroWindingRule, &dev->fill_hand);
    } else {
      hatch_fill_rect(dev, &dev->fill, x0, y0, x1, y1, fill);
    }
    return;
  }

  if (dev->fill_hand.enabled) {
    fill_polygon_mode(dev, 4, xs, ys, fill, R_GE_nonZeroWindingRule, &dev->fill_hand);
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

static void fill_circle(MypaintrDevice *dev, double x, double y, double r, int fill) {
  int i;
  int segments;
  double *xs;
  double *ys;

  if (R_ALPHA(fill) == 0) {
    return;
  }

  if (dev->fill_hand.enabled) {
    segments = (int) fmax(24.0, ceil(2.0 * M_PI * r / 6.0));
    xs = (double *) malloc((size_t) segments * sizeof(double));
    ys = (double *) malloc((size_t) segments * sizeof(double));
    if (!xs || !ys) {
      free(xs);
      free(ys);
      error("failed to allocate circle fill buffer");
    }
    for (i = 0; i < segments; ++i) {
      double t = 2.0 * M_PI * (double) i / (double) segments;
      xs[i] = x + r * cos(t);
      ys[i] = y + r * sin(t);
    }
    fill_polygon_mode(dev, segments, xs, ys, fill, R_GE_nonZeroWindingRule, &dev->fill_hand);
    free(xs);
    free(ys);
    return;
  }

  if (dev->fill_style == MYPAINTR_FILL_BRUSH && !dev->fill.pure_smudge) {
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

static void init_brushes(MypaintrDevice *dev, SEXP stroke_spec, SEXP fill_spec) {
  SEXP actual_fill_spec = fill_spec == R_NilValue ? stroke_spec : fill_spec;
  dev->stroke.brush = mypaint_brush_new_with_buckets(64);
  dev->fill.brush = mypaint_brush_new_with_buckets(64);
  if (!dev->stroke.brush || !dev->fill.brush) {
    error("failed to allocate libmypaint brushes");
  }

  brush_apply_spec(&dev->stroke, stroke_spec);
  brush_apply_spec(&dev->fill, actual_fill_spec);
  replace_preserved(&dev->stroke_spec, stroke_spec);
  replace_preserved(&dev->fill_spec, actual_fill_spec);
}

static void init_hands(MypaintrDevice *dev, SEXP stroke_hand, SEXP fill_hand) {
  configure_hand(&dev->stroke_hand, stroke_hand, ((uint64_t) (uintptr_t) dev) ^ (uint64_t) time(NULL));
  configure_hand(&dev->fill_hand, fill_hand, (((uint64_t) (uintptr_t) dev) << 1) ^ ((uint64_t) time(NULL) + 17ULL));
  replace_preserved(&dev->stroke_hand_spec, stroke_hand);
  replace_preserved(&dev->fill_hand_spec, fill_hand);
}

static MypaintrDevice *current_mypaintr_device(void) {
  pGEDevDesc gdd = GEcurrentDevice();
  pDevDesc dd;
  MypaintrDevice *dev;

  if (!gdd || !gdd->dev) {
    error("no active graphics device");
  }

  dd = gdd->dev;
  dev = (MypaintrDevice *) dd->deviceSpecific;
  if (!dev || dev->magic != MYPAINTR_MAGIC) {
    error("current device is not a mypaintr device");
  }

  return dev;
}

static void destroy_device_state(MypaintrDevice *dev) {
  if (!dev) {
    return;
  }
  if (dev->stroke_spec && dev->stroke_spec != R_NilValue) R_ReleaseObject(dev->stroke_spec);
  if (dev->fill_spec && dev->fill_spec != R_NilValue) R_ReleaseObject(dev->fill_spec);
  if (dev->stroke_hand_spec && dev->stroke_hand_spec != R_NilValue) R_ReleaseObject(dev->stroke_hand_spec);
  if (dev->fill_hand_spec && dev->fill_hand_spec != R_NilValue) R_ReleaseObject(dev->fill_hand_spec);
  if (dev->stroke.brush) mypaint_brush_unref(dev->stroke.brush);
  if (dev->fill.brush) mypaint_brush_unref(dev->fill.brush);
  if (dev->cr) cairo_destroy(dev->cr);
  if (dev->image_surface) cairo_surface_destroy(dev->image_surface);
  free(dev->filename);
  free(dev);
}

static void mypaintr_activate(const pDevDesc dd) {
  (void) dd;
}

static void mypaintr_deactivate(const pDevDesc dd) {
  (void) dd;
}

static void mypaintr_close(pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;

  if (!dev) {
    return;
  }

  save_page(dev);
  destroy_device_state(dev);
  dd->deviceSpecific = NULL;
}

static void mypaintr_clip(double x0, double x1, double y0, double y1, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
  dev->clip_left = fmax(0.0, fmin(x0, x1));
  dev->clip_right = fmin(dd->right, fmax(x0, x1));
  dev->clip_bottom = fmax(0.0, fmin(y0, y1));
  dev->clip_top = fmin(dd->top, fmax(y0, y1));
  apply_cairo_clip(dev);
}

static void mypaintr_size(double *left, double *right, double *bottom, double *top, pDevDesc dd) {
  *left = 0.0;
  *right = dd->right;
  *bottom = 0.0;
  *top = dd->top;
}

static void mypaintr_new_page(const pGEcontext gc, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
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

static void mypaintr_line(double x1, double y1, double x2, double y2, const pGEcontext gc, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
  double xs[2] = {x1, x2};
  double ys[2] = {y1, y2};
  render_polyline_hand(dev, &dev->stroke, dev->stroke_style, xs, ys, 2, gc->col, gc->lwd, gc->lty, 0, &dev->stroke_hand);
}

static void mypaintr_polyline(int n, double *x, double *y, const pGEcontext gc, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
  render_polyline_hand(dev, &dev->stroke, dev->stroke_style, x, y, n, gc->col, gc->lwd, gc->lty, 0, &dev->stroke_hand);
}

static void mypaintr_polygon(int n, double *x, double *y, const pGEcontext gc, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
  double *cx;
  double *cy;

  if (n < 2) return;

  if (gc->fill != NA_INTEGER) {
    fill_polygon_mode(dev, n, x, y, gc->fill, R_GE_nonZeroWindingRule, &dev->fill_hand);
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
  render_polyline_hand(dev, &dev->stroke, dev->stroke_style, cx, cy, n + 1, gc->col, gc->lwd, gc->lty, 1, &dev->stroke_hand);
  free(cx);
  free(cy);
}

static void mypaintr_rect(double x0, double y0, double x1, double y1, const pGEcontext gc, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
  double xs[5] = {x0, x1, x1, x0, x0};
  double ys[5] = {y0, y0, y1, y1, y0};

  fill_rect(dev, x0, y0, x1, y1, gc->fill);

  if (gc->col != NA_INTEGER && R_ALPHA(gc->col) > 0) {
    render_polyline_hand(dev, &dev->stroke, dev->stroke_style, xs, ys, 5, gc->col, gc->lwd, gc->lty, 1, &dev->stroke_hand);
  }
}

static void mypaintr_circle(double x, double y, double r, const pGEcontext gc, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
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

  render_polyline_hand(dev, &dev->stroke, dev->stroke_style, xs, ys, segments + 1, gc->col, gc->lwd, gc->lty, 1, &dev->stroke_hand);
  free(xs);
  free(ys);
}

static void mypaintr_path(double *x, double *y, int npoly, int *nper, Rboolean winding, const pGEcontext gc, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
  int offset = 0;
  int i;

  if (gc->fill != NA_INTEGER && R_ALPHA(gc->fill) > 0) {
    if (dev->fill_hand.enabled) {
      if (npoly == 1) {
        fill_polygon_mode(dev, nper[0], x, y, gc->fill, winding ? R_GE_nonZeroWindingRule : R_GE_evenOddRule, &dev->fill_hand);
      } else if (dev->fill_style == MYPAINTR_FILL_BRUSH && !dev->fill.pure_smudge) {
        hatch_fill_path(dev, &dev->fill, npoly, nper, x, y, gc->fill, winding ? R_GE_nonZeroWindingRule : R_GE_evenOddRule);
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
    } else if (dev->fill_style == MYPAINTR_FILL_BRUSH && !dev->fill.pure_smudge) {
      hatch_fill_path(dev, &dev->fill, npoly, nper, x, y, gc->fill, winding ? R_GE_nonZeroWindingRule : R_GE_evenOddRule);
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
      render_polyline_hand(dev, &dev->stroke, dev->stroke_style, cx, cy, n + 1, gc->col, gc->lwd, gc->lty, 1, &dev->stroke_hand);
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

static void mypaintr_raster(unsigned int *raster, int w, int h, double x, double y, double width, double height, double rot, Rboolean interpolate, const pGEcontext gc, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
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

static double mypaintr_str_width_impl(const char *str, const pGEcontext gc, MypaintrDevice *dev) {
  cairo_text_extents_t extents;
  set_font_face(dev, gc);
  cairo_text_extents(dev->cr, str, &extents);
  return extents.x_advance;
}

static double mypaintr_str_width(const char *str, const pGEcontext gc, pDevDesc dd) {
  return mypaintr_str_width_impl(str, gc, (MypaintrDevice *) dd->deviceSpecific);
}

static void mypaintr_metric_info(int c, const pGEcontext gc, double *ascent, double *descent, double *width, pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
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

static void mypaintr_text_impl(double x, double y, const char *str, double rot, double hadj, const pGEcontext gc, MypaintrDevice *dev) {
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

static void mypaintr_text(double x, double y, const char *str, double rot, double hadj, const pGEcontext gc, pDevDesc dd) {
  mypaintr_text_impl(x, y, str, rot, hadj, gc, (MypaintrDevice *) dd->deviceSpecific);
}

static void mypaintr_text_utf8(double x, double y, const char *str, double rot, double hadj, const pGEcontext gc, pDevDesc dd) {
  mypaintr_text_impl(x, y, str, rot, hadj, gc, (MypaintrDevice *) dd->deviceSpecific);
}

static double mypaintr_str_width_utf8(const char *str, const pGEcontext gc, pDevDesc dd) {
  return mypaintr_str_width_impl(str, gc, (MypaintrDevice *) dd->deviceSpecific);
}

static SEXP mypaintr_cap(pDevDesc dd) {
  MypaintrDevice *dev = (MypaintrDevice *) dd->deviceSpecific;
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

static SEXP mypaintr_capabilities(SEXP cap) {
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

static SEXP mypaintr_set_pattern(SEXP pattern, pDevDesc dd) {
  (void) pattern;
  (void) dd;
  return R_NilValue;
}

static void mypaintr_release_pattern(SEXP ref, pDevDesc dd) {
  (void) ref;
  (void) dd;
}

static SEXP mypaintr_set_clip_path(SEXP path, SEXP ref, pDevDesc dd) {
  (void) path;
  (void) ref;
  (void) dd;
  return R_NilValue;
}

static void mypaintr_release_clip_path(SEXP ref, pDevDesc dd) {
  (void) ref;
  (void) dd;
}

static SEXP mypaintr_set_mask(SEXP path, SEXP ref, pDevDesc dd) {
  (void) path;
  (void) ref;
  (void) dd;
  return R_NilValue;
}

static void mypaintr_release_mask(SEXP ref, pDevDesc dd) {
  (void) ref;
  (void) dd;
}

static SEXP mypaintr_define_group(SEXP source, int op, SEXP destination, pDevDesc dd) {
  (void) source;
  (void) op;
  (void) destination;
  (void) dd;
  return R_NilValue;
}

static void mypaintr_use_group(SEXP ref, SEXP trans, pDevDesc dd) {
  (void) ref;
  (void) trans;
  (void) dd;
}

static void mypaintr_release_group(SEXP ref, pDevDesc dd) {
  (void) ref;
  (void) dd;
}

static void init_dev_desc(pDevDesc dd, MypaintrDevice *dev) {
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
  dd->haveTransparency = 2;
  dd->haveTransparentBg = 3;
  dd->haveRaster = 2;
  dd->haveCapture = 2;
  dd->haveLocator = 1;
  dd->activate = mypaintr_activate;
  dd->circle = mypaintr_circle;
  dd->clip = mypaintr_clip;
  dd->close = mypaintr_close;
  dd->deactivate = mypaintr_deactivate;
  dd->line = mypaintr_line;
  dd->metricInfo = mypaintr_metric_info;
  dd->mode = NULL;
  dd->newPage = mypaintr_new_page;
  dd->polygon = mypaintr_polygon;
  dd->polyline = mypaintr_polyline;
  dd->rect = mypaintr_rect;
  dd->path = mypaintr_path;
  dd->raster = mypaintr_raster;
  dd->cap = mypaintr_cap;
  dd->size = mypaintr_size;
  dd->strWidth = mypaintr_str_width;
  dd->text = mypaintr_text;
  dd->onExit = NULL;
  dd->getEvent = NULL;
  dd->newFrameConfirm = NULL;
  dd->setPattern = mypaintr_set_pattern;
  dd->releasePattern = mypaintr_release_pattern;
  dd->setClipPath = mypaintr_set_clip_path;
  dd->releaseClipPath = mypaintr_release_clip_path;
  dd->setMask = mypaintr_set_mask;
  dd->releaseMask = mypaintr_release_mask;
  dd->hasTextUTF8 = TRUE;
  dd->textUTF8 = mypaintr_text_utf8;
  dd->strWidthUTF8 = mypaintr_str_width_utf8;
  dd->wantSymbolUTF8 = FALSE;
  dd->useRotatedTextInContour = TRUE;
  dd->deviceVersion = R_GE_glyphs;
  dd->deviceClip = FALSE;
  dd->defineGroup = mypaintr_define_group;
  dd->useGroup = mypaintr_use_group;
  dd->releaseGroup = mypaintr_release_group;
  dd->capabilities = mypaintr_capabilities;
}

static MypaintrDevice *make_device(const char *filename, int width, int height, double res, double pointsize, int bg, int stroke_style, int fill_style, int auto_solid_bg, SEXP stroke_spec, SEXP fill_spec, SEXP stroke_hand, SEXP fill_hand) {
  MypaintrDevice *dev = (MypaintrDevice *) calloc(1, sizeof(MypaintrDevice));
  cairo_status_t status;

  if (!dev) {
    error("failed to allocate device state");
  }

  dev->magic = MYPAINTR_MAGIC;
  dev->width = width;
  dev->height = height;
  dev->res = res;
  dev->pointsize = pointsize;
  dev->bg = bg;
  dev->stroke_style = stroke_style;
  dev->fill_style = fill_style;
  dev->auto_solid_bg = auto_solid_bg;
  dev->filename = mypaintr_strdup(filename);
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
  init_hands(dev, stroke_hand, fill_hand);
  clear_device(dev, bg);
  return dev;
}

SEXP mypaintr_device_open(SEXP filename, SEXP width, SEXP height, SEXP res, SEXP pointsize, SEXP bg_rgba, SEXP stroke_spec, SEXP fill_spec, SEXP stroke_style, SEXP fill_style, SEXP auto_solid_bg, SEXP stroke_hand, SEXP fill_hand) {
  pDevDesc dd;
  pGEDevDesc gdd;
  MypaintrDevice *dev;
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
    asInteger(stroke_style),
    asInteger(fill_style),
    asLogical(auto_solid_bg),
    stroke_spec,
    fill_spec,
    stroke_hand,
    fill_hand
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

SEXP mypaintr_device_set_style(SEXP stroke_spec, SEXP fill_spec, SEXP stroke_style, SEXP fill_style, SEXP auto_solid_bg) {
  MypaintrDevice *dev = current_mypaintr_device();

  if (stroke_spec != R_NilValue) {
    brush_apply_spec(&dev->stroke, stroke_spec);
    replace_preserved(&dev->stroke_spec, stroke_spec);
  }
  if (fill_spec != R_NilValue) {
    brush_apply_spec(&dev->fill, fill_spec);
    replace_preserved(&dev->fill_spec, fill_spec);
  }
  if (stroke_style != R_NilValue) {
    dev->stroke_style = asInteger(stroke_style);
  }
  if (fill_style != R_NilValue) {
    dev->fill_style = asInteger(fill_style);
  }
  if (auto_solid_bg != R_NilValue) {
    dev->auto_solid_bg = asLogical(auto_solid_bg);
  }

  return R_NilValue;
}

SEXP mypaintr_device_set_brush(SEXP stroke_spec, SEXP fill_spec, SEXP stroke_style, SEXP fill_style, SEXP auto_solid_bg) {
  return mypaintr_device_set_style(stroke_spec, fill_spec, stroke_style, fill_style, auto_solid_bg);
}

SEXP mypaintr_device_set_hand(SEXP stroke_hand, SEXP fill_hand, SEXP update_stroke, SEXP update_fill) {
  MypaintrDevice *dev = current_mypaintr_device();

  if (asLogical(update_stroke)) {
    configure_hand(&dev->stroke_hand, stroke_hand, ((uint64_t) (uintptr_t) dev) ^ (uint64_t) time(NULL));
    replace_preserved(&dev->stroke_hand_spec, stroke_hand);
  }
  if (asLogical(update_fill)) {
    configure_hand(&dev->fill_hand, fill_hand, (((uint64_t) (uintptr_t) dev) << 1) ^ ((uint64_t) time(NULL) + 17ULL));
    replace_preserved(&dev->fill_hand_spec, fill_hand);
  }

  return R_NilValue;
}

SEXP mypaintr_device_get_style(void) {
  MypaintrDevice *dev = current_mypaintr_device();
  SEXP out = PROTECT(allocVector(VECSXP, 7));
  SEXP names = PROTECT(allocVector(STRSXP, 7));

  SET_STRING_ELT(names, 0, mkChar("stroke_spec"));
  SET_STRING_ELT(names, 1, mkChar("fill_spec"));
  SET_STRING_ELT(names, 2, mkChar("stroke_style"));
  SET_STRING_ELT(names, 3, mkChar("fill_style"));
  SET_STRING_ELT(names, 4, mkChar("auto_solid_bg"));
  SET_STRING_ELT(names, 5, mkChar("stroke_hand"));
  SET_STRING_ELT(names, 6, mkChar("fill_hand"));

  SET_VECTOR_ELT(out, 0, duplicate_or_nil(dev->stroke_spec));
  SET_VECTOR_ELT(out, 1, duplicate_or_nil(dev->fill_spec));
  SET_VECTOR_ELT(out, 2, ScalarInteger(dev->stroke_style));
  SET_VECTOR_ELT(out, 3, ScalarInteger(dev->fill_style));
  SET_VECTOR_ELT(out, 4, ScalarLogical(dev->auto_solid_bg));
  SET_VECTOR_ELT(out, 5, duplicate_or_nil(dev->stroke_hand_spec));
  SET_VECTOR_ELT(out, 6, duplicate_or_nil(dev->fill_hand_spec));
  setAttrib(out, R_NamesSymbol, names);

  UNPROTECT(2);
  return out;
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
