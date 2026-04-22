
require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 must be installed to use mypaint theme elements", call. = FALSE)
  }
}

draw_key_mypaint_rect <- function(data, params, size) {
  data$xmin <- 0.1
  data$xmax <- 0.9
  data$ymin <- 0.1
  data$ymax <- 0.9
  build_mypaint_rect_grob(data, params, default.units = "npc")
}

GeomMypaintCol <- ggplot2::ggproto(
  "GeomMypaintCol",
  ggplot2::GeomCol,
  extra_params = c(
    "na.rm", "just", "orientation", "lineend", "linejoin",
    "fill_pattern", "brush",
    "fill_brush", "hand", "stroke_hand",
    "fill_hand", "auto_solid_bg"
  ),
  draw_panel = function(self, data, panel_params, coord, lineend = "butt",
                        linejoin = "mitre", just = 0.5, na.rm = FALSE,
                        fill_pattern = NULL,
                        brush = NULL,
                        fill_brush = NULL,
                        hand = NULL, stroke_hand = hand, fill_hand = hand,
                        auto_solid_bg = NULL) {
    if (!coord$is_linear()) {
      stop("geom_mypaint_col() currently only supports linear coordinates", call. = FALSE)
    }

    data <- getFromNamespace("fix_linewidth", "ggplot2")(data, "geom_mypaint_col")
    coords <- coord$transform(data, panel_params)
    build_mypaint_rect_grob(
      coords,
      list(
        fill_pattern = fill_pattern,
        lineend = lineend,
        linejoin = linejoin,
        brush = brush,
        fill_brush = fill_brush,
        stroke_hand = normalize_hand_spec(stroke_hand),
        fill_hand = normalize_hand_spec(fill_hand),
        auto_solid_bg = auto_solid_bg
      )
    )
  },
  draw_key = draw_key_mypaint_rect
)

GeomMypaintBar <- ggplot2::ggproto(
  "GeomMypaintBar",
  ggplot2::GeomBar,
  extra_params = GeomMypaintCol$extra_params,
  draw_panel = GeomMypaintCol$draw_panel,
  draw_key = draw_key_mypaint_rect
)

#' Draw rough, brush-rendered columns in ggplot2
#'
#' This geom owns both the bar outline and the hatch fill, so the shading lines
#' follow the same rough outline rather than the underlying true rectangle.
#'
#' @param mapping,data,position,just,lineend,linejoin,na.rm,show.legend,inherit.aes
#'   As for [ggplot2::geom_col()].
#' @param fill_pattern Optional fill pattern created with [hatch()],
#'   [crosshatch()], [zigzag()], or [jumble()].
#' @param brush Stroke brush specification created with [tweak_brush()], an
#'   installed mypaint brush name, `.myb` file path, JSON brush string, or
#'   `NULL` for solid borders.
#' @param fill_brush Fill brush specification created with [tweak_brush()], an
#'   installed mypaint brush name, `.myb` file path, JSON brush string, or
#'   `NULL` for solid fills.
#' @param hand Optional hand-drawn geometry applied to both outline and hatch by
#'   default.
#' @param stroke_hand Optional hand-drawn geometry for the outline.
#' @param fill_hand Optional hand-drawn geometry for the hatch strokes.
#' @param auto_solid_bg Reserved for future parity with device-level style
#'   controls.
#' @param ... Other arguments passed to [ggplot2::layer()].
#' @return A ggplot layer.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) +
#'     geom_mypaint_bar(fill_pattern = hatch())
#' }
#' @export
geom_mypaint_col <- function(mapping = NULL, data = NULL, position = "stack",
                             ..., just = 0.5, lineend = "butt", linejoin = "mitre",
                             na.rm = FALSE, show.legend = NA, inherit.aes = TRUE,
                             fill_pattern = NULL,
                             brush = NULL,
                             fill_brush = NULL,
                             hand = NULL, stroke_hand = hand, fill_hand = hand,
                             auto_solid_bg = NULL) {
  require_ggplot2()
  supplied_args <- names(match.call(expand.dots = FALSE))
  if (!("fill_brush" %in% supplied_args)) {
    fill_brush <- brush
  }
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = "identity",
    geom = GeomMypaintCol,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      just = just,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      fill_pattern = fill_pattern,
      brush = brush,
      fill_brush = fill_brush,
      hand = hand,
      stroke_hand = stroke_hand,
      fill_hand = fill_hand,
      auto_solid_bg = auto_solid_bg,
      ...
    )
  )
}

#' Draw rough, brush-rendered bars in ggplot2
#'
#' @inheritParams geom_mypaint_col
#' @param stat The statistical transformation to use. Defaults to `"count"`.
#' @return A ggplot layer.
#' @export
geom_mypaint_bar <- function(mapping = NULL, data = NULL, stat = "count",
                             position = "stack", ..., just = 0.5,
                             lineend = "butt", linejoin = "mitre", na.rm = FALSE,
                             show.legend = NA, inherit.aes = TRUE,
                             fill_pattern = NULL,
                             brush = NULL,
                             fill_brush = NULL,
                             hand = NULL, stroke_hand = hand, fill_hand = hand,
                             auto_solid_bg = NULL) {
  require_ggplot2()
  supplied_args <- names(match.call(expand.dots = FALSE))
  if (!("fill_brush" %in% supplied_args)) {
    fill_brush <- brush
  }
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    # GeomBar drops custom hand params on the panel path here; reuse the
    # working rect/col renderer and let the stat supply bar counts.
    geom = GeomMypaintCol,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      just = just,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      fill_pattern = fill_pattern,
      brush = brush,
      fill_brush = fill_brush,
      hand = hand,
      stroke_hand = stroke_hand,
      fill_hand = fill_hand,
      auto_solid_bg = auto_solid_bg,
      ...
    )
  )
}

new_mypaintr_element <- function(element, class_name, style) {
  attr(element, "mypaintr_style") <- style
  class(element) <- c(class_name, class(element))
  element
}

#' Theme line element with scoped mypaint rendering
#'
#' Uses the current `mypaint` device for drawing, but temporarily overrides the
#' stroke settings while the theme line is drawn. This is useful for keeping
#' axes, ticks, or panel grid lines solid while data layers use rough or brush
#' rendering.
#'
#' @param brush Stroke brush specification created with [tweak_brush()], an
#'   installed mypaint brush name, `.myb` file path, JSON brush string, or
#'   `NULL` for solid strokes.
#' @param hand Optional hand-drawn geometry created with [hand()].
#' @param colour,color,linewidth,linetype,lineend,linejoin,arrow,arrow.fill,inherit.blank,size,...
#'   Passed through to [ggplot2::element_line()].
#' @return A ggplot theme element.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::theme(axis.line = element_mypaint_line())
#' }
#' @export
element_mypaint_line <- function(brush = NULL,
                                 hand = NULL,
                                 colour = NULL,
                                 linewidth = NULL,
                                 linetype = NULL,
                                 lineend = NULL,
                                 color = NULL,
                                 linejoin = NULL,
                                 arrow = FALSE,
                                 arrow.fill = NULL,
                                 inherit.blank = FALSE,
                                 size = NULL,
                                 ...) {
  require_ggplot2()
  stroke_spec <- if (is.null(brush)) NULL else normalize_brush_spec(brush)
  style <- make_style_override(
    update_stroke = TRUE,
    stroke_spec = stroke_spec,
    stroke_style = if (is.null(stroke_spec)) 0L else 1L,
    stroke_hand = normalize_hand_spec(hand)
  )
  args <- list(
    colour = colour,
    linewidth = linewidth,
    linetype = linetype,
    lineend = lineend,
    color = color,
    linejoin = linejoin,
    arrow = arrow,
    arrow.fill = arrow.fill,
    inherit.blank = inherit.blank,
    ...
  )
  if (!is.null(size)) {
    args$size <- size
  }
  element <- do.call(ggplot2::element_line, args)
  new_mypaintr_element(element, "mypaintr_element_line", style)
}

#' Theme rectangle element with scoped mypaint rendering
#'
#' Uses the current `mypaint` device for drawing, but temporarily overrides the
#' stroke and fill settings while the rectangle is drawn. This is useful for
#' panel backgrounds, panel borders, and legend keys in ggplot2 themes.
#'
#' @param brush Stroke brush specification created with [tweak_brush()], an
#'   installed mypaint brush name, `.myb` file path, JSON brush string, or
#'   `NULL` for solid borders.
#' @param fill_brush Fill brush specification created with [tweak_brush()], an
#'   installed mypaint brush name, `.myb` file path, JSON brush string, or
#'   `NULL` for solid fills.
#' @param hand Optional hand-drawn geometry applied to both stroke and fill by
#'   default.
#' @param stroke_hand Optional hand-drawn geometry for the border.
#' @param fill_hand Optional hand-drawn geometry for the fill.
#' @param auto_solid_bg Optional override for background-like fills.
#' @param fill,colour,color,linewidth,linetype,linejoin,inherit.blank,size,...
#'   Passed through to [ggplot2::element_rect()].
#' @return A ggplot theme element.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::theme(panel.background = element_mypaint_rect())
#' }
#' @export
element_mypaint_rect <- function(brush = NULL,
                                 fill_brush = NULL,
                                 hand = NULL,
                                 stroke_hand = hand,
                                 fill_hand = hand,
                                 auto_solid_bg = NULL,
                                 fill = NULL,
                                 colour = NULL,
                                 linewidth = NULL,
                                 linetype = NULL,
                                 color = NULL,
                                 linejoin = NULL,
                                 inherit.blank = FALSE,
                                 size = NULL,
                                 ...) {
  require_ggplot2()
  supplied_args <- names(match.call(expand.dots = FALSE))
  if (!("fill_brush" %in% supplied_args)) {
    fill_brush <- brush
  }

  style <- make_mypaintr_style(
    brush = brush,
    fill_brush = fill_brush,
    stroke_hand = stroke_hand,
    fill_hand = fill_hand,
    auto_solid_bg = auto_solid_bg
  )
  args <- list(
    fill = fill,
    colour = colour,
    linewidth = linewidth,
    linetype = linetype,
    color = color,
    linejoin = linejoin,
    inherit.blank = inherit.blank,
    ...
  )
  if (!is.null(size)) {
    args$size <- size
  }
  element <- do.call(ggplot2::element_rect, args)
  new_mypaintr_element(element, "mypaintr_element_rect", style)
}

wrap_mypaintr_style_grob <- function(child, style) {
  grid::gTree(
    children = grid::gList(child),
    mypaintr_style = style,
    cl = "mypaintr_style_grob"
  )
}

make_mypaintr_pattern_grob <- function(paths, hand_spec, fill_pattern, gp, default.units = "native") {
  grid::gTree(
    expr = quote(draw_fun(paths, hand_spec, fill_pattern, gp, default.units)),
    list = list(
      draw_fun = make_mypaintr_pattern_content,
      paths = paths,
      hand_spec = hand_spec,
      fill_pattern = fill_pattern,
      gp = gp,
      default.units = default.units
    ),
    cl = "delayedgrob"
  )
}

wrap_mypaintr_style_output <- function(x, style) {
  if (inherits(x, "grob")) {
    return(wrap_mypaintr_style_grob(x, style))
  }
  if (is.list(x)) {
    x[] <- lapply(x, wrap_mypaintr_style_output, style = style)
  }
  x
}

make_mypaintr_style <- function(brush = NULL,
                                fill_brush = NULL,
                                hand = NULL,
                                stroke_hand = hand,
                                fill_hand = hand,
                                auto_solid_bg = NULL) {
  stroke_spec <- if (is.null(brush)) NULL else normalize_brush_spec(brush)
  fill_spec <- if (is.null(fill_brush)) NULL else normalize_brush_spec(fill_brush)
  make_style_override(
    update_stroke = TRUE,
    stroke_spec = stroke_spec,
    stroke_style = if (is.null(stroke_spec)) 0L else 1L,
    stroke_hand = normalize_hand_spec(stroke_hand),
    update_fill = TRUE,
    fill_spec = fill_spec,
    fill_style = if (is.null(fill_spec)) 0L else 1L,
    fill_hand = normalize_hand_spec(fill_hand),
    auto_solid_bg = auto_solid_bg
  )
}

#' Wrap a grid grob or ggplot layer with scoped mypaint styling
#'
#' `mypaint_wrap()` applies temporary mypaintr brush and hand settings while the
#' wrapped object is drawn, then restores the previous device style. It can wrap
#' either a grid grob or a ggplot2 layer. This makes it useful both for direct
#' `grid::grid.draw()` workflows and for ggplot calls such as
#' `ggplot(...) + mypaint_wrap(geom_line(...), ...)`.
#'
#' @param object A grid grob or a ggplot2 layer object.
#' @param brush Stroke brush specification created with [tweak_brush()], an
#'   installed mypaint brush name, `.myb` file path, JSON brush string, or
#'   `NULL` for solid strokes.
#' @param fill_brush Fill brush specification created with [tweak_brush()], an
#'   installed mypaint brush name, `.myb` file path, JSON brush string, or
#'   `NULL` for solid fills.
#' @param hand Optional hand-drawn geometry applied to both stroke and fill by
#'   default.
#' @param stroke_hand Optional hand-drawn geometry for strokes.
#' @param fill_hand Optional hand-drawn geometry for fills.
#' @param auto_solid_bg Optional override for background-like fills.
#' @return An object of the same general kind as `object`: a wrapped grob for
#'   grid inputs or a wrapped layer for ggplot2 inputs.
#' @examples
#' line <- grid::linesGrob(c(0.1, 0.9), c(0.2, 0.8))
#' if ("classic/pen" %in% brushes()) {
#'   wrapped <- mypaint_wrap(line, brush = "classic/pen", hand = hand())
#' }
#'
#' if (requireNamespace("ggplot2", quietly = TRUE) &&
#'     "classic/pen" %in% brushes()) {
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'     mypaint_wrap(ggplot2::geom_line(), brush = "classic/pen", hand = hand())
#' }
#' @export
mypaint_wrap <- function(object,
                         brush = NULL,
                         fill_brush = NULL,
                         hand = NULL,
                         stroke_hand = hand,
                         fill_hand = hand,
                         auto_solid_bg = NULL) {
  supplied_args <- names(match.call(expand.dots = FALSE))
  if (!("fill_brush" %in% supplied_args)) {
    fill_brush <- brush
  }

  style <- make_mypaintr_style(
    brush = brush,
    fill_brush = fill_brush,
    hand = hand,
    stroke_hand = stroke_hand,
    fill_hand = fill_hand,
    auto_solid_bg = auto_solid_bg
  )

  if (inherits(object, "Layer")) {
    old_draw_geom <- object$draw_geom
    object$draw_geom <- function(self, data, layout) {
      wrap_mypaintr_style_output(old_draw_geom(data, layout), style)
    }
    return(object)
  }

  if (inherits(object, "grob")) {
    return(wrap_mypaintr_style_grob(object, style))
  }

  stop("object must be a grid grob or ggplot2 layer", call. = FALSE)
}

base_element <- function(element, class_name) {
  out <- element
  attr(out, "mypaintr_style") <- NULL
  class(out) <- setdiff(class(out), class_name)
  out
}

#' @exportS3Method ggplot2::element_grob
element_grob.mypaintr_element_line <- function(element, ...) {
  child <- ggplot2::element_grob(base_element(element, "mypaintr_element_line"), ...)
  wrap_mypaintr_style_grob(child, attr(element, "mypaintr_style", exact = TRUE))
}

#' @exportS3Method ggplot2::element_grob
element_grob.mypaintr_element_rect <- function(element, ...) {
  child <- ggplot2::element_grob(base_element(element, "mypaintr_element_rect"), ...)
  wrap_mypaintr_style_grob(child, attr(element, "mypaintr_style", exact = TRUE))
}

#' @exportS3Method grid::preDrawDetails
preDrawDetails.mypaintr_style_grob <- function(x) {
  if (!is_mypaintr_device()) {
    return()
  }

  mypaintr_env$style_stack <- c(mypaintr_env$style_stack, list(current_device_style()))
  apply_device_style_override(x$mypaintr_style)
}

#' @exportS3Method grid::postDrawDetails
postDrawDetails.mypaintr_style_grob <- function(x) {
  if (!is_mypaintr_device()) {
    return()
  }

  n <- length(mypaintr_env$style_stack)
  if (!n) {
    return()
  }

  state <- mypaintr_env$style_stack[[n]]
  mypaintr_env$style_stack <- mypaintr_env$style_stack[-n]
  apply_device_style_state(state)
}

make_mypaintr_pattern_content <- function(paths, hand_spec, fill_pattern, gp, default.units = "native") {
  inches_per_data_unit <- function(angle = 0) {
    x_in_per_unit <- grid::convertWidth(grid::unit(1, "native"), "in", valueOnly = TRUE)
    y_in_per_unit <- grid::convertHeight(grid::unit(1, "native"), "in", valueOnly = TRUE)
    theta <- angle * pi / 180
    sqrt((x_in_per_unit * sin(theta))^2 + (y_in_per_unit * cos(theta))^2)
  }

  hatch <- if (is.null(hand_spec)) {
    rough_fill_pattern_data(
      paths,
      hand_spec = NULL,
      fill_pattern = fill_pattern,
      inches_per_data_unit = inches_per_data_unit
    )
  } else {
    with_hand_seed(hand_spec$seed, {
      rough_fill_pattern_data(
        paths,
        hand_spec = hand_spec,
        fill_pattern = fill_pattern,
        inches_per_data_unit = inches_per_data_unit
      )
    })
  }

  if (!length(hatch$x)) {
    return(grid::nullGrob())
  }

  grid::polylineGrob(
    x = hatch$x,
    y = hatch$y,
    id = hatch$id,
    default.units = default.units,
    gp = gp
  )
}

make_stroke_style <- function(brush = NULL, hand = NULL) {
  spec <- if (is.null(brush)) NULL else normalize_brush_spec(brush)
  make_style_override(
    update_stroke = TRUE,
    stroke_spec = spec,
    stroke_style = if (is.null(spec)) 0L else 1L,
    stroke_hand = normalize_hand_spec(hand),
    update_stroke_hand = !is.null(hand)
  )
}

line_gp <- function(colour, linewidth, linetype = 1, linejoin = "mitre", lineend = "butt") {
  pt <- 2.845276
  grid::gpar(
    col = colour,
    fill = NA,
    lwd = linewidth * pt,
    lty = linetype,
    linejoin = linejoin,
    lineend = lineend
  )
}

alpha_colour <- function(col, alpha = NA_real_) {
  if (is.null(col) || all(is.na(col))) {
    return(col)
  }
  if (is.list(col)) {
    stop("pattern fills are not supported by mypaint geoms", call. = FALSE)
  }
  alpha <- rep_len(alpha, length(col))
  out <- col
  keep <- !is.na(col)
  keep[keep] <- is.na(alpha[keep]) | alpha[keep] >= 0
  out[keep] <- grDevices::adjustcolor(col[keep], alpha.f = ifelse(is.na(alpha[keep]), 1, alpha[keep]))
  out
}

closed_rect_path <- function(xmin, xmax, ymin, ymax) {
  list(
    x = c(xmin, xmax, xmax, xmin, xmin),
    y = c(ymin, ymin, ymax, ymax, ymin)
  )
}

outline_path <- function(x, y, hand_spec = NULL, closed = TRUE) {
  if (is.null(hand_spec)) {
    return(list(x = x, y = y))
  }
  with_hand_seed(hand_spec$seed, {
    roughen_vertex_path(x, y, hand_spec, closed = closed)
  })
}

build_mypaint_rect_grob <- function(data, params, default.units = "native") {
  child_list <- list()
  border_brush <- params$brush
  fill_brush <- if (is.null(params$fill_brush)) params$brush else params$fill_brush
  outline_hand <- params$stroke_hand
  hatch_hand <- params$fill_hand %||% outline_hand
  fill_pattern <- as_fill_pattern(params$fill_pattern, hand_spec = hatch_hand)

  for (i in seq_len(nrow(data))) {
    row <- data[i, , drop = FALSE]
    fill_col <- alpha_colour(row$fill, row$alpha)
    border_col <- alpha_colour(row$colour, row$alpha)
    linewidth <- row$linewidth %||% 0.5
    linetype <- row$linetype %||% 1

    path <- outline_path(
      closed_rect_path(row$xmin, row$xmax, row$ymin, row$ymax)$x,
      closed_rect_path(row$xmin, row$xmax, row$ymin, row$ymax)$y,
      hand_spec = outline_hand,
      closed = FALSE
    )

    if (is_visible_col(fill_col)) {
      hatch_grob <- make_mypaintr_pattern_grob(
        list(path),
        hand_spec = hatch_hand,
        fill_pattern = fill_pattern,
        gp = line_gp(fill_col, linewidth, linetype, params$linejoin, params$lineend),
        default.units = default.units
      )
      child_list[[length(child_list) + 1L]] <- wrap_mypaintr_style_grob(
        hatch_grob,
        make_stroke_style(fill_brush, hand = hatch_hand)
      )
    }

    if (is_visible_col(border_col)) {
      border_grob <- grid::polylineGrob(
        x = path$x,
        y = path$y,
        default.units = default.units,
        gp = line_gp(border_col, linewidth, linetype, params$linejoin, params$lineend)
      )
      child_list[[length(child_list) + 1L]] <- wrap_mypaintr_style_grob(
        border_grob,
        make_stroke_style(border_brush, hand = outline_hand)
      )
    }
  }

  if (!length(child_list)) {
    return(grid::nullGrob())
  }
  grid::gTree(children = do.call(grid::gList, child_list))
}
