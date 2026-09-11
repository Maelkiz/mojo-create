from window.window import Window
from window.event import (
    Event,
    Quit,
    Resized,
    KeyDown,
    KeyUp,
    MouseMoved,
    MouseButtonDown,
    MouseButtonUp,
    MouseWheel,
)
from create.render.canvas import PersistentCanvasState
from .frame import step
from create.render.surface import Surface
from .input import Input
from .context import Context
from create.render.autoscale import AutoScale
from .program import Program
from create.math.vector2 import Vector2


def _update_dimensions(mut win: Window, mut ctx: Context) raises:
    ctx._set_viewport(win.width(), win.height())


def _wait_for_dimensions(mut win: Window, mut ctx: Context) raises:
    # For fullscreen, SDL fires a bogus (1, 1) Resized before reporting real
    # dimensions — pump events until the window reports a usable size.
    _update_dimensions(win, ctx)
    while ctx.width <= 1 or ctx.height <= 1:
        _ = win.events()
        _update_dimensions(win, ctx)


def _process_events(mut win: Window, mut ctx: Context, mut input: Input) raises:
    input._new_frame()
    var events = win.events()
    for event in events:
        if event.isa[Quit]():
            win.close()
        elif event.isa[KeyDown]():
            var keycode = event[KeyDown].keycode
            if keycode == 27 and ctx.exit_on_escape:
                win.close()
            if not input.is_key_down(keycode):
                input._held_keys.set(keycode)
                input._just_pressed.set(keycode)
        elif event.isa[KeyUp]():
            var keycode = event[KeyUp].keycode
            input._held_keys.clear(keycode)
            input._just_released.set(keycode)
        elif event.isa[MouseMoved]():
            var e = event[MouseMoved]
            # Pointer positions reach the program in the same space it draws in.
            var p = ctx.to_world(Float64(e.x), Float64(e.y))
            input._set_mouse(p[0], p[1])
        elif event.isa[MouseButtonDown]():
            var e = event[MouseButtonDown]
            var p = ctx.to_world(Float64(e.x), Float64(e.y))
            input.mouse_pressed = True
            input.mouse_button = e.button
            input._set_mouse(p[0], p[1])
            input.mouse_press_pos = Vector2(p[0], p[1])
            input._held_buttons |= 1 << e.button
            input._pressed_buttons |= 1 << e.button
        elif event.isa[MouseButtonUp]():
            var e = event[MouseButtonUp]
            var p = ctx.to_world(Float64(e.x), Float64(e.y))
            input.mouse_pressed = False
            input._set_mouse(p[0], p[1])
            input._held_buttons &= ~(1 << e.button)
            input._released_buttons |= 1 << e.button
        elif event.isa[MouseWheel]():
            var e = event[MouseWheel]
            input.wheel = Vector2(Float64(e.x), Float64(e.y))
        elif event.isa[Resized]():
            pass  # ctx.width/height are refreshed every frame regardless.


def _run_loop[
    P: Program
](mut program: P, mut win: Window, mut ctx: Context, mut input: Input) raises:
    # Style and loaded fonts live here rather than in the Canvas, which is
    # rebuilt every frame; the transform stack deliberately does not, so each
    # frame starts unrotated and untranslated.
    var state = PersistentCanvasState()
    # Seeded here rather than in run() so the program's create() — which may
    # load fonts or decode audio — does not land in the first frame's delta.
    ctx.time._start(win.ticks())
    while win.is_open() and not ctx._quit:
        # Dimensions are refreshed before events so pointer positions are
        # mapped with this frame's scale, not the previous one's.
        _update_dimensions(win, ctx)
        _process_events(win, ctx, input)
        ctx.time._tick(win.ticks())
        # The Surface is taken here, after events, because Window._resize
        # reallocates the pixel buffer: one taken before them could point at
        # freed memory. Its extent comes from the window rather than the
        # viewport for the same reason — the viewport was measured before the
        # resize, and a stale width would run the raster loops off the new
        # buffer.
        var pixel_w = win.width()
        var pixel_h = win.height()
        state = step(
            program,
            ctx,
            input,
            Surface(win.pixels(), pixel_w, pixel_h),
            state^,
        )
        win.present()


def run[
    P: Program
](
    title: String,
    width: Int = 1280,
    height: Int = 720,
    fullscreen: Bool = False,
) raises:
    """Open a window and run `P` in it until it quits.

    `width`/`height` are both the window size and the design resolution — the
    coordinate space the program is authored in. A fullscreen window covers the
    display, so the size only shapes the design space there.

    The design is scaled to the window (`AutoScale.FIT`) unless `create` sets
    `ctx.autoscale` otherwise, so a program keeps its layout on any display.
    The two jobs of the size stay independent once the window is open:

    | call                              | FIT / EXTEND             | OFF            |
    |-----------------------------------|--------------------------|----------------|
    | `run("T", 1000, 1000)`            | design 1000x1000, scaled | world = window |
    | `run("T", 1000, 1000, True)`      | design 1000x1000, scaled | world = monitor|
    | `run("T", fullscreen=True)`       | design 1280x720, scaled  | world = monitor|

    So `fullscreen=True` with a size means *author at that size, present
    fullscreen*. Under `OFF` the design resolution goes unused entirely, which
    is the other half of why `FIT` is the default: it keeps the numbers passed
    here meaningful in every launch mode.
    """
    var win = Window(title, width, height, fullscreen)
    var ctx = Context()
    # The size the program is authored against is always what the caller asked
    # for, never what the display handed back. In fullscreen SDL ignores the
    # requested size, so seeding this from the window would make the design
    # space a property of the user's monitor rather than of the program.
    ctx.view.set_design(width, height)
    # Scaling the design to the window is the default because the alternative
    # punishes the obvious way to write a program: laid-out coordinates that
    # break on a display the author never had. `create` can opt back out with
    # `ctx.autoscale = AutoScale.OFF`.
    ctx.autoscale = AutoScale.FIT
    _wait_for_dimensions(win, ctx)
    var program = P.create(ctx)
    # create() may have changed the mode or pinned its own design size, so the
    # mapping derived above is stale by the time it returns — re-derive it
    # before the first frame.
    _update_dimensions(win, ctx)
    var input = Input()
    _run_loop(program, win, ctx, input)
