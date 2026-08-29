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
from .program import Program


def _run_loop[P: Program & Movable & Deinitable](mut program: P, mut ctx: Context) raises:
    program.setup(ctx)

    var last_ticks = ctx._canvas.ticks()

    while ctx._canvas.is_open():
        var events = ctx._canvas.events()
        for event in events:
            if event.isa[Quit]():
                ctx._canvas.close()
            elif event.isa[KeyDown]():
                var keycode = event[KeyDown].keycode
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
                ctx._canvas.width = e.width
                ctx._canvas.height = e.height
                ctx.width = e.width
                ctx.height = e.height
                program.on_resize(e.width, e.height)

        var now = ctx._canvas.ticks()
        ctx.time.delta_millis = now - last_ticks
        ctx.time.delta_time = Float64(ctx.time.delta_millis) / 1000.0
        ctx.time.frame_count += 1
        last_ticks = now

        program.update(ctx)
        ctx._canvas.present()


def _make_ctx(title: String, width: Int, height: Int) raises -> Context:
    var canvas = Canvas(title, width, height)
    var w = canvas.width
    var h = canvas.height
    return Context(canvas^, Input(), Time(0, 0.0, 0), w, h)


def run[P: Program & Movable & Deinitable](var program: P, title: String) raises:
    var ctx = _make_ctx(title, 0, 0)
    _run_loop(program, ctx)


def run[P: Program & Movable & Deinitable](
    var program: P, title: String, width: Int, height: Int
) raises:
    var ctx = _make_ctx(title, width, height)
    _run_loop(program, ctx)
