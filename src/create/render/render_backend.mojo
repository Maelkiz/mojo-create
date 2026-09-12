"""Which renderer replays a frame's `DrawCommand`s.

A mode selector, not a typed value passed around structurally — `Backend.kind`
and `run`'s `backend` parameter both stay plain `Int`, compared with `==`,
the same shape as `AutoScale`. A struct instead of free constants because this
file is public surface and the library doesn't scatter top-level constants.
"""


struct RenderBackend:
    comptime CPU = 0  # replays onto a Surface through _raster.mojo
    comptime GPU = 1  # replays through GLRenderer — see _gl_backend.mojo
