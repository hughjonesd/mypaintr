
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
    "fill_pattern", "brush", "brush_settings",
    "fill_brush", "fill_settings", "hand", "stroke_hand",
    "fill_hand", "auto_solid_bg"
  ),
  draw_panel = function(self, data, panel_params, coord, lineend = "butt",
                        linejoin = "mitre", just = 0.5, na.rm = FALSE,
                        fill_pattern = NULL,
                        brush = NULL, brush_settings = NULL,
                        fill_brush = NULL, fill_settings = NULL,
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
        brush_settings = brush_settings,
        fill_brush = fill_brush,
        fill_settings = fill_settings,
        stroke_hand = as_optional_hand(stroke_hand),
        fill_hand = as_optional_hand(fill_hand),
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
#'   [crosshatch()], [zigzag()], or [jumble()]. When omitted, bars use a simple
#'   hatch fill by default.
#' @param brush,brush_settings Stroke brush spec and overrides.
#' @param fill_brush,fill_settings Fill-hatch brush spec and overrides.
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
                             brush = NULL, brush_settings = NULL,
                             fill_brush = NULL, fill_settings = NULL,
                             hand = NULL, stroke_hand = hand, fill_hand = hand,
                             auto_solid_bg = NULL) {
  require_ggplot2()
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
      brush_settings = brush_settings,
      fill_brush = fill_brush,
      fill_settings = fill_settings,
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
                             brush = NULL, brush_settings = NULL,
                             fill_brush = NULL, fill_settings = NULL,
                             hand = NULL, stroke_hand = hand, fill_hand = hand,
                             auto_solid_bg = NULL) {
  require_ggplot2()
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
      brush_settings = brush_settings,
      fill_brush = fill_brush,
      fill_settings = fill_settings,
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
#' @param brush Stroke brush preset, installed brush name, JSON brush string,
#'   named settings, or `NULL` for solid strokes.
#' @param brush_settings Named settings overriding `brush`.
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
                                 brush_settings = NULL,
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
  if (is.null(brush) && !is.null(brush_settings)) {
    stop("brush_settings requires brush", call. = FALSE)
  }

  stroke_spec <- if (is.null(brush) && is.null(brush_settings)) NULL else normalize_brush_spec(brush, brush_settings)
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
#' @param brush Stroke brush preset, installed brush name, JSON brush string,
#'   named settings, or `NULL` for solid borders.
#' @param brush_settings Named settings overriding `brush`.
#' @param fill_brush Fill brush preset, installed brush name, JSON brush string,
#'   named settings, or `NULL` for solid fills.
#' @param fill_settings Named settings overriding `fill_brush`.
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
                                 brush_settings = NULL,
                                 fill_brush = NULL,
                                 fill_settings = NULL,
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
  if (missing(fill_brush)) {
    fill_brush <- brush
  }
  if (is.null(brush) && !is.null(brush_settings)) {
    stop("brush_settings requires brush", call. = FALSE)
  }
  if (is.null(fill_brush) && !is.null(fill_settings)) {
    stop("fill_settings requires fill_brush", call. = FALSE)
  }

  stroke_spec <- if (is.null(brush) && is.null(brush_settings)) NULL else normalize_brush_spec(brush, brush_settings)
  fill_spec <- if (is.null(fill_brush) && is.null(fill_settings)) NULL else normalize_brush_spec(fill_brush, fill_settings)
  style <- make_style_override(
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

make_stroke_style <- function(brush = NULL, settings = NULL, hand = NULL) {
  spec <- if (is.null(brush) && is.null(settings)) NULL else normalize_brush_spec(brush, settings)
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

build_mypaint_rect_grob <- function(data, params, default.units = "native") {
  child_list <- list()
  border_brush <- params$brush
  border_settings <- params$brush_settings
  fill_brush <- if (is.null(params$fill_brush) && is.null(params$fill_settings)) params$brush else params$fill_brush
  fill_settings <- params$fill_settings
  outline_hand <- params$stroke_hand
  hatch_hand <- params$fill_hand %||% outline_hand
  fill_pattern <- as_fill_pattern(
    params$fill_pattern,
    hand_spec = hatch_hand,
    default_when_missing = TRUE
  )

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
      hatch <- if (is.null(hatch_hand)) {
        rough_fill_pattern_data(list(path), hand_spec = NULL, fill_pattern = fill_pattern)
      } else {
        with_hand_seed(hatch_hand$seed, {
          rough_fill_pattern_data(list(path), hand_spec = hatch_hand, fill_pattern = fill_pattern)
        })
      }
      if (length(hatch$x)) {
        hatch_grob <- grid::polylineGrob(
          x = hatch$x,
          y = hatch$y,
          id = hatch$id,
          default.units = default.units,
          gp = line_gp(fill_col, linewidth, linetype, params$linejoin, params$lineend)
        )
        child_list[[length(child_list) + 1L]] <- wrap_mypaintr_style_grob(
          hatch_grob,
          make_stroke_style(fill_brush, fill_settings, hand = hatch_hand)
        )
      }
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
        make_stroke_style(border_brush, border_settings, hand = outline_hand)
      )
    }
  }

  if (!length(child_list)) {
    return(grid::nullGrob())
  }
  grid::gTree(children = do.call(grid::gList, child_list))
}
