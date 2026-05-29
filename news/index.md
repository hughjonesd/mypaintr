# Changelog

## mypaintr (development version)

- [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md)
  and
  [`human_hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md)
  now accept `speed`, `xtilt`, `ytilt`, and `barrel_rotation` for
  libmypaint brush rendering.
- `hand(pressure = 0.5)` is now shorthand for
  `hand(pressure = pressure_flat(0.5))`.
- Hand `wobble` and `bow` are now smoother.
- [`human_hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md)
  defaults are less wobbly and bowed.
- Speeded up blending by using the libmypaint backend.

## mypaintr 0.0.1

- Initial commits.
