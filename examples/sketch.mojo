from create import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def window(self) -> WindowConfig:
        return WindowConfig("Example Sketch", 300, 200)

    def update(mut self, mut canvas: Canvas) raises:
        canvas.background(Color(255))
        canvas.fill(Color.red())
        canvas.rect(10, 10, 100, 100)
        canvas.fill(Color.blue())
        canvas.circle(200, 100, 50)


def main() raises:
    run(App())
