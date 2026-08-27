# Mojo Create

**Mojo Create** is a creative coding library for rapid prototyping, interactive
graphics, and graphical sketches. It provides a simple, intuitive API while
taking advantage of Mojo's performance and language features.

## A basic program

```mojo
from create import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def window(self) -> WindowConfig:
        return WindowConfig("My Sketch", 800, 600)

    def update(mut self, mut canvas: Canvas) raises:
        canvas.background(Color(255))
        canvas.fill(Color.red())
        canvas.circle(400, 300, 100)


def main() raises:
    run(App())
```

Define a struct conforming to `Program`, implement `window` (window config)
and `update` (called every frame), then hand it to `run`.

## The `Program` trait

```mojo
trait Program:
    def window(self) -> WindowConfig: ...        # required — title and size
    def update(mut self, mut canvas: Canvas) raises: ...         # required
    def update(mut self, mut canvas: Canvas, time: Time) raises: ...  # or with time

    # optional — default no-ops:
    def setup(mut self) raises: ...
    def on_key_down(mut self, keycode: Int) raises: ...
    def on_key_up(mut self, keycode: Int) raises: ...
    def on_mouse_moved(mut self, x: Int, y: Int) raises: ...
    def on_mouse_down(mut self, button: Int, x: Int, y: Int) raises: ...
    def on_mouse_up(mut self, button: Int, x: Int, y: Int) raises: ...
    def on_mouse_wheel(mut self, x: Int, y: Int) raises: ...
    def on_resize(mut self, width: Int, height: Int) raises: ...
```

Override `update(canvas, time)` instead of `update(canvas)` to receive frame
timing. User state lives in struct fields.

## Window config

```mojo
WindowConfig("My Sketch", 800, 600)  # windowed
WindowConfig("My Sketch")            # fullscreen
```

## Color

```mojo
Color(255)               # gray
Color(255, 0, 0)         # RGB
Color(255, 0, 0, 128)    # RGBA
Color.red()              # named constant (also black, white, green, blue)
```

## Drawing

```mojo
canvas.background(Color(40))

canvas.fill(Color.red())
canvas.stroke(Color.black())
canvas.stroke_width(2)
canvas.rect(x, y, w, h)
canvas.circle(cx, cy, r)

canvas.no_fill()         # outline only
canvas.no_stroke()       # filled only
canvas.line(x0, y0, x1, y1)
```

## Time

```mojo
def update(mut self, mut canvas: Canvas, time: Time) raises:
    # time.frame_count   — frames elapsed since start
    # time.delta_time    — seconds since last frame (Float64)
    # time.delta_millis  — milliseconds since last frame (Int)
```

## Running

```
pixi run run examples/sketch.mojo
```
