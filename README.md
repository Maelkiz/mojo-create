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
    def create(mut ctx: Context) raises -> MyApp:
        return MyApp()  # Set initial application state here

    def update(mut self, mut ctx: Context, input: Input) raises:
        pass  # Executes once per frame, handle input, update state, etc.

    def render(self, mut canvas: Canvas) raises:
        # Also executes once per frame, canvas.rect(), canvas.circle(), etc.
        canvas.background(Color.BLACK)
        canvas.text_align(HAlign.CENTER, VAlign.MIDDLE)
        canvas.text("Hello World!", 0, 0)


def main() raises:
    run[MyApp]("Example Sketch", fullscreen=True)
```

Run the example programs using the `create` pixi task:

```bash
pixi run create examples/sketch.mojo
```