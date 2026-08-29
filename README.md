# Mojo Create

**Mojo Create** is a creative coding library for rapid prototyping and 
interactive graphics, inspired by Processing but built to scale — from sketch to 
game, prototype to full application. It provides a clean, modular API while 
taking full advantage of Mojo's performance and language features.

## The shape of a program

```mojo
from create.core import *


@fieldwise_init
struct App(Program, Movable, Deinitable):

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        return App() # Set initial application state here

    def update(mut self, mut ctx: Context) raises:
        pass # Executes once per frame


def main() raises:
    run[App]("Example Sketch", 400, 300)
```

Run the program using `run`:

```bash
pixi run run examples/sketch.mojo
```