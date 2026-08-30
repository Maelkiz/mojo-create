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
from .time import Time
from .context import Context
from .program import Headless, Windowed


def _wait_for_dimensions(mut ctx: Context) raises:
    # For fullscreen (requested 0x0), SDL fires a bogus (1, 1) Resized before
    # reporting real dimensions — pump until we get the actual size.
    if ctx.width == 0 and ctx.height == 0:
        while ctx.width <= 1 or ctx.height <= 1:
            var events = ctx._canvas.events()
            for event in events:
                if event.isa[Resized]():
                    var e = event[Resized]
                    ctx.width = e.width
                    ctx.height = e.height


def _process_events[P: Headless](mut program: P, mut ctx: Context) raises:
    var events = ctx._canvas.events()
    for event in events:
        if event.isa[Quit]():
            ctx._canvas.close()
        elif event.isa[KeyDown]():
            var keycode = event[KeyDown].keycode
            if keycode == 27 and ctx.exit_on_escape:
                ctx._canvas.close()
            if not ctx.input.is_key_down(keycode):
                ctx.input._held_keys.append(keycode)
                program.on_key_down(keycode)
        elif event.isa[KeyUp]():
            var keycode = event[KeyUp].keycode
            for i in range(len(ctx.input._held_keys)):
                if ctx.input._held_keys[i] == keycode:
                    _ = ctx.input._held_keys.pop(i)
                    break
            program.on_key_up(keycode)
        elif event.isa[MouseMoved]():
            var e = event[MouseMoved]
            ctx.input.mouse_x = e.x
            ctx.input.mouse_y = e.y
            program.on_mouse_moved(e.x, e.y)
        elif event.isa[MouseButtonDown]():
            var e = event[MouseButtonDown]
            ctx.input.mouse_pressed = True
            ctx.input.mouse_button = e.button
            ctx.input.mouse_x = e.x
            ctx.input.mouse_y = e.y
            program.on_mouse_down(e.button, e.x, e.y)
        elif event.isa[MouseButtonUp]():
            var e = event[MouseButtonUp]
            ctx.input.mouse_pressed = False
            program.on_mouse_up(e.button, e.x, e.y)
        elif event.isa[MouseWheel]():
            var e = event[MouseWheel]
            program.on_mouse_wheel(e.x, e.y)
        elif event.isa[Resized]():
            var e = event[Resized]
            program.on_resize(e.width, e.height)


def _tick_time(mut ctx: Context, mut last_ticks: Int) raises:
    var now = ctx._canvas.ticks()
    ctx.time.delta_millis = now - last_ticks
    ctx.time.delta_time = Float64(ctx.time.delta_millis) / 1000.0
    ctx.time.frame_count += 1
    last_ticks = now


def _run_headless_loop[P: Headless](mut program: P, mut ctx: Context) raises:
    var last_ticks = ctx._canvas.ticks()
    while ctx._canvas.is_open():
        _process_events(program, ctx)
        ctx.width = ctx._canvas._win.width()
        ctx.height = ctx._canvas._win.height()
        _tick_time(ctx, last_ticks)
        program.update(ctx)


def _run_windowed_loop[P: Windowed](mut program: P, mut ctx: Context) raises:
    var last_ticks = ctx._canvas.ticks()
    while ctx._canvas.is_open():
        _process_events(program, ctx)
        ctx.width = ctx._canvas._win.width()
        ctx.height = ctx._canvas._win.height()
        _tick_time(ctx, last_ticks)
        program.update(ctx)
        program.render(ctx._canvas)
        ctx._canvas.present()


def _make_ctx(title: String, width: Int, height: Int) raises -> Context:
    var canvas = Canvas(title, width, height)
    return Context(canvas^, Input(), Time(0, 0.0, 0), width, height)


def run_headless[P: Headless](title: String) raises:
    var ctx = _make_ctx(title, 0, 0)
    _wait_for_dimensions(ctx)
    var program = P.create(ctx)
    _run_headless_loop(program, ctx)


def run_headless[P: Headless](title: String, width: Int, height: Int) raises:
    var ctx = _make_ctx(title, width, height)
    _wait_for_dimensions(ctx)
    var program = P.create(ctx)
    _run_headless_loop(program, ctx)


def run[P: Windowed](title: String) raises:
    var ctx = _make_ctx(title, 0, 0)
    _wait_for_dimensions(ctx)
    var program = P.create(ctx)
    _run_windowed_loop(program, ctx)


def run[P: Windowed](title: String, width: Int, height: Int) raises:
    var ctx = _make_ctx(title, width, height)
    _wait_for_dimensions(ctx)
    var program = P.create(ctx)
    _run_windowed_loop(program, ctx)
