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
        canvas.text_align(HAlign.CENTER)
        canvas.text_baseline(VAlign.MIDDLE)
        canvas.text("Hello World!", 0, 0)


def main() raises:
    run[MyApp]("Example Sketch", fullscreen=True)
