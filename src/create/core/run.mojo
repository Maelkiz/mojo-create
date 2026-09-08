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
from .canvas import Canvas
from .input import Input
from .context import Context
from .autoscale import AutoScale
from .program import Program
from std.math import floor
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


def _process_events[
    P: Program
](mut program: P, mut win: Window, mut ctx: Context, mut input: Input) raises:
    input._just_pressed.clear_all()
    input._just_released.clear_all()
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
                program.on_key_down(keycode)
        elif event.isa[KeyUp]():
            var keycode = event[KeyUp].keycode
            input._held_keys.clear(keycode)
            input._just_released.set(keycode)
            program.on_key_up(keycode)
        elif event.isa[MouseMoved]():
            var e = event[MouseMoved]
            # Pointer positions reach the program in the same space it draws in.
            var p = ctx.to_world(Float64(e.x), Float64(e.y))
            input.mouse = Vector2(p[0], p[1])
            input.mouse_x = Int(floor(p[0]))
            input.mouse_y = Int(floor(p[1]))
            program.on_mouse_moved(input.mouse_x, input.mouse_y)
        elif event.isa[MouseButtonDown]():
            var e = event[MouseButtonDown]
            var p = ctx.to_world(Float64(e.x), Float64(e.y))
            input.mouse_pressed = True
            input.mouse_button = e.button
            input.mouse = Vector2(p[0], p[1])
            input.mouse_x = Int(floor(p[0]))
            input.mouse_y = Int(floor(p[1]))
            program.on_mouse_down(e.button, input.mouse_x, input.mouse_y)
        elif event.isa[MouseButtonUp]():
            var e = event[MouseButtonUp]
            var p = ctx.to_world(Float64(e.x), Float64(e.y))
            input.mouse_pressed = False
            program.on_mouse_up(e.button, Int(floor(p[0])), Int(floor(p[1])))
        elif event.isa[MouseWheel]():
            var e = event[MouseWheel]
            program.on_mouse_wheel(e.x, e.y)
        elif event.isa[Resized]():
            var e = event[Resized]
            program.on_resize(e.width, e.height)


def _run_loop[
    P: Program
](mut program: P, mut win: Window, mut ctx: Context, mut input: Input) raises:
    # Canvas borrows the window for the whole loop, so it is built here rather
    # than passed in: no single call may take both `win` and `canvas` mutably.
    # Building it once also keeps font loading out of the frame path.
    var canvas = Canvas(win)
    # Seeded here rather than in run() so the program's create() — which may
    # load fonts or decode audio — does not land in the first frame's delta.
    ctx.time._start(win.ticks())
    while win.is_open() and not ctx._quit:
        # Dimensions are refreshed before events so pointer positions are
        # mapped with this frame's scale, not the previous one's.
        _update_dimensions(win, ctx)
        _process_events(program, win, ctx, input)
        # Canvas mirrors the frame dimensions and the design-space mapping; it
        # cannot be updated inside _update_dimensions because that call already
        # borrows the window.
        canvas._sync(ctx)
        ctx.time._tick(win.ticks())
        program.update(ctx, input)
        program.render(canvas)
        canvas._draw_letterbox()
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
