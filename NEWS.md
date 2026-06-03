# mypaintr 0.1.0

* `hand()` and `human_hand()` now accept `speed`, `pressure`, `xtilt`, `ytilt`, 
  and `barrel_rotation` for libmypaint brush rendering.
* Pressure and speed profiles (`pressure_*()`, 
  `speed_*()`) let you vary speed and pressure over the whole stroke. 
* Dashed lines are implemented using `pressure_dashed()`.
* Hand `wobble` and `bow` are now smoother.
* `human_hand()` defaults are less wobbly and bowed.
* mypaintr now use the libmypaint backend for blending, rather than its own 
  hand-rolled solution.
* Updated libmypaint to vendor the whole source and fix build problems.
* We now have tests including many snapshot tests. I guess that means this is a
  real package...
* Added a new vignette, reimplementing some ggplot2 examples.

# mypaintr 0.0.1

* Initial commits.
