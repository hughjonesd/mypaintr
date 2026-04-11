#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

SEXP mypaintr_device_open(SEXP filename, SEXP width, SEXP height, SEXP res, SEXP pointsize, SEXP bg_rgba, SEXP stroke_spec, SEXP fill_spec, SEXP fill_style);
SEXP mypaintr_brush_settings_info(void);
SEXP mypaintr_brush_inputs_info(void);

static const R_CallMethodDef call_methods[] = {
  {"mypaintr_device_open", (DL_FUNC) &mypaintr_device_open, 9},
  {"mypaintr_brush_settings_info", (DL_FUNC) &mypaintr_brush_settings_info, 0},
  {"mypaintr_brush_inputs_info", (DL_FUNC) &mypaintr_brush_inputs_info, 0},
  {NULL, NULL, 0}
};

void R_init_mypaintr(DllInfo *dll) {
  R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
