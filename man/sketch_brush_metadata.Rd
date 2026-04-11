\name{sketch_brush_presets}
\alias{sketch_brush_presets}
\alias{sketch_brush_settings}
\alias{sketch_brush_inputs}
\title{Brush presets and libmypaint metadata}
\usage{
sketch_brush_presets()

sketch_brush_settings()

sketch_brush_inputs()
}
\description{
Helper functions for inspecting the bundled brush presets and the
available libmypaint settings and inputs.
}
\value{
\code{sketch_brush_presets()} returns a named list of preset setting vectors.

\code{sketch_brush_settings()} returns a data frame of brush setting metadata.

\code{sketch_brush_inputs()} returns a data frame of brush input metadata.
}
\examples{
sketch_brush_presets()
head(sketch_brush_settings())
head(sketch_brush_inputs())
}
