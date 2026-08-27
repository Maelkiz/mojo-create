# Mojo Create

**Mojo Create** is a creative coding library for rapid prototyping, interactive
graphics, and graphical sketches. It provides a simple, intuitive API while
taking advantage of Mojo's performance and language features.

## A basic program

```mojo
from create import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def settings(mut self) -> WindowConfig:
        return WindowConfig("My Program", 800, 600)

    def update(mut self, mut canvas: Canvas) raises:
        draw_background(canvas, 255)  # White background


def main() raises:
    run(App())
```

Define a struct conforming to `Program`, implement `settings` (window config)
and `update` (called every frame), then hand it to `run`.

## The `Program` trait

```mojo
trait Program:
    def settings(mut self) -> WindowConfig: ...   # required — title, width, height
    def update(mut self, mut canvas: Canvas) raises: ...  # required — per frame

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

Only `settings` and `update` must be implemented. All other methods are
optional — override only what you need. User state lives in struct fields.

## Drawing functions

| Function | Description |
|---|---|
| `draw_background(canvas, gray)` | Fill canvas with a grayscale value (0–255) |

## Running

```
pixi run run examples/sketch.mojo
```
