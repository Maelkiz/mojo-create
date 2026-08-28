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


def main() raises:
    run(App())
```

Define a struct conforming to `Program`, implement `window` (window config)
and `update` (called every frame), then hand it to `run`:

```
pixi run run examples/sketch.mojo
```