# Mojo Create

**Mojo Create** is a creative coding library for rapid prototyping and 
interactive graphics, inspired by Processing but built to scale — from sketch to 
game, prototype to full application. It provides a clean, modular API while 
taking full advantage of Mojo's performance and language features.

## The shape of a program

```mojo
from create.core import *


@fieldwise_init
struct MyApp(Program):

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        return App() # Set initial application state here

    def update(mut self, mut ctx: Context) raises:
        pass # Executes once per frame

    def render(self, mut canvas: Canvas) raises:
        pass # canvas.rect(), canvas.circle(), etc.


def main() raises:
    run[MyApp]("Example Sketch", 400, 300)
```

Run the example programs using the `create` pixi task:

```bash
pixi run create examples/sketch.mojo
```