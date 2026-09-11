from create.render.autoscale import AutoScale
from create.render.canvas import CanvasState
from .frame import step
from .context import Context
from .input import Input
from .program import Program
from create.render.surface import MemorySurface

comptime _FRAME_MILLIS = 16
"""Synthetic frame duration, so a program that integrates delta is
reproducible run to run rather than dependent on how fast the test machine
got through the loop."""


def run_headless[
    P: Program
](
    width: Int,
    height: Int,
    frames: Int = 1,
    pixel_width: Int = 0,
    pixel_height: Int = 0,
) raises -> MemorySurface:
    """Run `P` for `frames` frames over an owned buffer and return it.

    The same sequence as `run`, minus the window: `create`, then `update` and
    `render` per frame, with the letterbox painted after each render. `width`
    and `height` are the design resolution; `pixel_width`/`pixel_height` are
    the framebuffer, defaulting to the same size — pass a different shape to
    exercise autoscale, since a design that matches the framebuffer maps 1:1
    and leaves no bars.

    Time is synthetic and the input is empty, so the result depends only on
    the program.
    """
    var pw = pixel_width if pixel_width > 0 else width
    var ph = pixel_height if pixel_height > 0 else height
    var mem = MemorySurface(pw, ph)
    var ctx = Context()
    ctx.view.set_design(width, height)
    ctx.autoscale = AutoScale.FIT
    ctx._set_viewport(pw, ph)
    var program = P.create(ctx)
    # create() may have pinned its own design size or changed the mode.
    ctx._set_viewport(pw, ph)
    var input = Input()
    var state = CanvasState()
    var now = 0
    ctx.time._start(now)
    for _ in range(frames):
        if ctx._quit:
            break
        now += _FRAME_MILLIS
        ctx.time._tick(now)
        state = step(program, ctx, input, mem.surface(), state^)
    return mem^
