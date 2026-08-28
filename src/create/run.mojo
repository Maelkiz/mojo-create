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
from .time import Time
from .program import Program


def run[P: Program & Movable & Deinitable](var program: P) raises:
    var canvas = Canvas(program.window())
    program.setup()

    var frame_count = 0
    var last_ticks = canvas._win.ticks()

    while canvas.is_open():
        var events = canvas.events()
        for event in events:
            if event.isa[Quit]():
                canvas.close()
            elif event.isa[KeyDown]():
                var keycode = event[KeyDown].keycode
                canvas._held_keys.append(keycode)
                program.on_key_down(keycode)
            elif event.isa[KeyUp]():
                var keycode = event[KeyUp].keycode
                for i in range(len(canvas._held_keys)):
                    if canvas._held_keys[i] == keycode:
                        _ = canvas._held_keys.pop(i)
                        break
                program.on_key_up(keycode)
            elif event.isa[MouseMoved]():
                var e = event[MouseMoved]
                canvas.mouse_x = e.x
                canvas.mouse_y = e.y
                program.on_mouse_moved(e.x, e.y)
            elif event.isa[MouseButtonDown]():
                var e = event[MouseButtonDown]
                canvas.mouse_pressed = True
                canvas.mouse_button = e.button
                canvas.mouse_x = e.x
                canvas.mouse_y = e.y
                program.on_mouse_down(e.button, e.x, e.y)
            elif event.isa[MouseButtonUp]():
                var e = event[MouseButtonUp]
                canvas.mouse_pressed = False
                program.on_mouse_up(e.button, e.x, e.y)
            elif event.isa[MouseWheel]():
                var e = event[MouseWheel]
                program.on_mouse_wheel(e.x, e.y)
            elif event.isa[Resized]():
                var e = event[Resized]
                canvas.width = e.width
                canvas.height = e.height
                program.on_resize(e.width, e.height)

        var now = canvas._win.ticks()
        var delta_millis = now - last_ticks
        last_ticks = now
        frame_count += 1
        var time = Time(frame_count, Float64(delta_millis) / 1000.0, delta_millis)
        program.update(canvas, time)
        canvas.present()
