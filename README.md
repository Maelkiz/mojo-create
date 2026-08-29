# Mojo Create

**Mojo Create** is a creative coding library for rapid prototyping and 
interactive graphics, inspired by Processing but built to scale — from sketch to 
game, prototype to full application. It provides a clean, modular API while 
taking full advantage of Mojo's performance and language features.

## The shape of a program

```mojo
from create.core import Program, Context, run


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def setup(mut self, mut ctx: Context) raises:
        # Executed once when the program starts
        pass

    def update(mut self, mut ctx: Context) raises:
        # Executed once per frame
        pass


def main() raises:
    # Set window title, width, and height, and run the program
    run[App]("Example Sketch", 400, 300)
```

Run the program using `run`:

```bash
pixi run run examples/sketch.mojo
```