# Vendored libmypaint

This directory contains the full libmypaint source tree vendored for
explicit vendored builds, including the GitHub Actions platform check.

Source: https://github.com/mypaint/libmypaint
Version: v1.6.1
Commit: 2768251dacce3939136c839aeca413f4aa4241d0

`config.h` is maintained locally so the R package can compile the library
sources without running libmypaint's autotools build. The generated
`brushsettings-gen.h` and `mypaint-brush-settings-gen.h` files are also kept
locally for the same reason.

## Compilation flags

libmypaint's upstream README notes that standalone builds can benefit from
aggressive GCC optimization flags such as `-Ofast`, `-march=native`, and
unsafe math optimizations. Those flags are intentionally not hard-coded in
mypaintr's `configure` output: they are compiler-specific, machine-specific,
and not appropriate defaults for a distributed R package. When explicitly
enabled, the vendored build uses R's configured compiler flags, plus the
package-local `PKG_CPPFLAGS`, `PKG_LIBS`, and `OBJECTS` needed to compile and
link the vendored sources.

Users who want local experimental optimization can still provide their own
compiler flags through standard R mechanisms such as user or site Makevars.
