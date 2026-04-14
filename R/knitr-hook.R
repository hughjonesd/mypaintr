
require_knitr <- function() {
  if (!requireNamespace("knitr", quietly = TRUE)) {
    stop("knitr must be installed to use knitr_mypaint_hook()", call. = FALSE)
  }
}

chunk_sets_dev_explicitly <- function(options) {
  src <- options$params.src %||% ""
  is.character(src) && length(src) == 1L && grepl("(^|,)\\s*dev\\s*=", src, perl = TRUE)
}

#' Create a knitr chunk hook for live mypaint rendering
#'
#' The returned hook opens [mypaint_device()] before chunk evaluation and
#' injects the generated PNG files afterward. This avoids knitr's normal plot
#' replay path, which does not preserve device-local style changes such as
#' [set_hand()] and [set_brush()].
#'
#' Register it with `knitr::knit_hooks$set(mypaint = knitr_mypaint_hook(...))`
#' and then enable it for chunks with `mypaint = TRUE`. Chunks should also set
#' `fig.keep = "none"` and `fig.ext = "png"`. If a chunk explicitly sets
#' `dev=`, the hook is skipped and knitr's normal device handling is used.
#'
#' @param ... Default arguments passed through to [mypaint_device()] when the
#'   hook opens a device. Chunk-specific overrides can be supplied in the chunk
#'   option `mypaint.args` as a named list.
#' @return A function suitable for `knitr::knit_hooks$set()`.
#' @examples
#' if (requireNamespace("knitr", quietly = TRUE)) {
#'   hook <- knitr_mypaint_hook(brush = "deevad/2B_pencil")
#'   print(is.function(hook))
#' }
#' @export
knitr_mypaint_hook <- function(...) {
  require_knitr()
  device_defaults <- list(...)

  function(before, options, envir) {
    if (!isTRUE(options$mypaint)) {
      return()
    }
    if (chunk_sets_dev_explicitly(options)) {
      return()
    }

    stem <- knitr::fig_path("", options = options, number = NULL)
    pattern <- paste0(stem, "-%d.png")
    files_glob <- paste0(stem, "-*.png")

    if (before) {
      dir.create(dirname(stem), recursive = TRUE, showWarnings = FALSE)
      unlink(Sys.glob(files_glob))

      dev_args <- c(
        list(
          file = pattern,
          width = options$fig.width[1],
          height = options$fig.height[1]
        ),
        device_defaults
      )
      if (is.list(options$mypaint.args)) {
        dev_args[names(options$mypaint.args)] <- options$mypaint.args
      }
      do.call(mypaint_device, dev_args)
      return()
    }

    if (identical(names(grDevices::dev.cur()), "mypaintr")) {
      grDevices::dev.off()
    }

    files <- sort(Sys.glob(files_glob))
    if (!length(files)) {
      return("")
    }

    options$fig.num <- length(files)
    pieces <- character(length(files))
    for (i in seq_along(files)) {
      options$fig.cur <- i
      pieces[[i]] <- knitr::hook_plot_md(files[[i]], options)
    }
    paste0(pieces, collapse = "")
  }
}
