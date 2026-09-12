from create.render.canvas import Canvas, PersistentCanvasState
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
    var state: PersistentCanvasState,
) raises -> PersistentCanvasState:
    """Advance `program` by one frame onto `surf` and hand its state back.

    The windowed and headless loops differ in how they get a frame started —
    one pumps SDL events and reads a clock, the other counts — but from here
    on they must not differ at all, so this is the one copy of what a frame
    *is*. It lives in its own module rather than in `run.mojo` because the
    headless path must not pull in the window.

    `state` travels in and out because a `Canvas` is a per-frame view: it is
    built for this frame and dropped before the frame is presented, so anything
    longer-lived than a frame rides in `PersistentCanvasState`.

    `surf` reaches the backend, never the `Canvas` — a `Canvas` holds no
    framebuffer. It is still taken as an argument rather than built here
    because only the caller knows where the pixels are, and in the windowed
    loop it is only valid once events have been pumped.

    A frame is two halves: `render` records draw commands and touches no
    pixels, then the backend replays the whole recording onto `surf`. Both
    halves are here rather than split across the two loops, so neither loop can
    present a frame the other would not.
    """
    program.update(ctx, input)
    var canvas = Canvas(ctx.view, state^)
    program.render(canvas)
    # Recorded last, so it doubles as the clip for anything drawn out of
    # bounds — the replay honours the buffer's order.
    canvas._draw_letterbox()
    var out = canvas^._release()
    out.backend.present(surf, ctx.view.scale)
    return out^
