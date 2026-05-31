# Changelog

## mypaintr (development version)

- [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md)
  and
  [`human_hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md)
  now accept `speed`, `pressure`, `xtilt`, `ytilt`, and
  `barrel_rotation` for libmypaint brush rendering.
- Pressure and speed profiles (`pressure_flat/human/smooth()`,
  `speed_flat/human()`) let you vary speed and pressure over the whole
  stroke.
- Hand `wobble` and `bow` are now smoother.
- [`human_hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md)
  defaults are less wobbly and bowed.
- mypaintr now use the libmypaint backend for blending, rather than its
  own hand-rolled solution.
- Updated libmypaint to vendor the whole source and fix build problems.

## mypaintr 0.0.1

- Initial commits.
