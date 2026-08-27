from create import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def window(mut self) -> WindowConfig:
        return WindowConfig("Example Sketch", 300, 200)

    def update(mut self, mut canvas: Canvas) raises:
        canvas.background(255)
        canvas.fill(255, 0, 0)
        canvas.rect(10, 10, 100, 100)
        canvas.fill(0, 0, 255)
        canvas.circle(200, 100, 50)


def main() raises:
    run(App())
