from create.render.canvas import Canvas, CanvasState
from .context import Context
from .input import Input
from .program import Program
from create.render.surface import Surface


def step[
    P: Program, o: Origin[mut=True]
](
    mut program: P,
    mut ctx: Context,
    input: Input,
    surf: Surface[o],
    var state: CanvasState,
) raises -> CanvasState:
    """Advance `program` by one frame onto `surf` and hand its state back.

    The windowed and headless loops differ in how they get a frame started —
    one pumps SDL events and reads a clock, the other counts — but from here
    on they must not differ at all, so this is the one copy of what a frame
    *is*. It lives in its own module rather than in `run.mojo` because the
    headless path must not pull in the window.

    `state` travels in and out because a `Canvas` is a per-frame view: it is
    built over this frame's surface and dropped before the frame is presented,
    so anything longer-lived than a frame rides in `CanvasState`.
    """
    program.update(ctx, input)
    var canvas = Canvas(surf, ctx.view, state^)
    program.render(canvas)
    # The letterbox doubles as the clip for anything drawn out of bounds, so it
    # must land while the Canvas still holds the surface.
    canvas._draw_letterbox()
    # Releasing the Canvas ends its borrow of the surface, which is what lets
    # the frame be presented.
    return canvas^._release()
