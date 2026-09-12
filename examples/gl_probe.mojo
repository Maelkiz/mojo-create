"""Proves the GL entry-point table binds and calls against a live context.

Not a sketch — it uses no `Program`, no `Canvas` and no run loop, because
there is no GL backend yet to run one on. What it checks is exactly the layer
below that: that `create.render._gl` can resolve every GL 3.3 symbol the
backend will need through SDL's loader, without importing `window` itself,
and that calling through the bitcast pointers works under both `mojo run` and
`mojo build`.

The window is a `GLWindow` from `mojo-window` rather than the `Window` the
rest of the examples use: `GL()` requires a current GL context, which is what
a `GLWindow` provides and a pixel-buffer `Window` does not.

    pixi run create examples/gl_probe.mojo
    mojo build -I src examples/gl_probe.mojo -o build/gl_probe && ./build/gl_probe
"""

from create.render._gl import (
    GL,
    GL_COLOR_BUFFER_BIT,
    GL_MAJOR_VERSION,
    GL_MINOR_VERSION,
)
from window import GLWindow, Quit

comptime _FRAMES = 90
"""Long enough to see the window, short enough that the binary the pre-push
example build produces is never left sitting on screen for minutes."""


def main() raises:
    var window = GLWindow("GL Probe", 640, 360)
    window.set_swap_interval(1)

    var gl = GL()
    print("GL_VERSION:", gl.version())
    print(
        "GL_MAJOR_VERSION/GL_MINOR_VERSION:",
        gl.read_int(GL_MAJOR_VERSION),
        gl.read_int(GL_MINOR_VERSION),
    )
    print("drawable_size:", window.drawable_size())
    gl.check("after probing the version")

    var frame = 0
    while window.is_open() and frame < _FRAMES:
        for event in window.events():
            if event.isa[Quit]():
                window.close()
        var t = Float32(frame) / Float32(_FRAMES)
        gl.clear_color(0.10, 0.10 + 0.5 * t, 0.30, 1.0)
        gl.clear(GL_COLOR_BUFFER_BIT)
        window.swap_buffers()
        frame += 1

    gl.check("after the last frame")
    # Rule 3: the context owner must outlive the last GL call. It does here
    # only because of this line — `window`'s last other use is above the loop.
    _ = window^
