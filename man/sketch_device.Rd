\name{sketch_device}
\alias{sketch_device}
\title{Open a libmypaint-backed graphics device}
\usage{
sketch_device(
  file,
  width = 7,
  height = 7,
  res = 144,
  pointsize = 12,
  bg = "white",
  brush = "ink",
  brush_settings = NULL,
  fill_style = c("solid", "brush"),
  fill_brush = brush,
  fill_settings = NULL
)
}
\arguments{
  \item{file}{Output PNG filename. If it contains \code{\%d}, page numbers are substituted.}
  \item{width, height}{Device size in inches.}
  \item{res}{Resolution in pixels per inch.}
  \item{pointsize}{Base point size.}
  \item{bg}{Background colour.}
  \item{brush}{Stroke brush preset name, libmypaint JSON string, or named brush settings.}
  \item{brush_settings}{Named settings overriding \code{brush}.}
  \item{fill_style}{Either \code{"solid"} or \code{"brush"}.}
  \item{fill_brush}{Optional fill brush specification.}
  \item{fill_settings}{Named settings overriding \code{fill_brush}.}
}
\description{
Opens a raster graphics device that renders strokes with \code{libmypaint}
and writes PNG files on \code{dev.off()} or page changes.
}
\details{
This first version uses Cairo for text rendering and solid fills.
Brush fills are implemented as repeated hatched brush strokes.
}
\value{
Returns \code{NULL} invisibly after opening the device.
}
\examples{
\dontrun{
sketch_device("sketch-%d.png", brush = "chalk", fill_style = "brush")
plot(1:10, col = "grey30", pch = 16, cex = 1.4)
lines(1:10, col = "firebrick", lwd = 4)
dev.off()
}
}
