from create import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def settings(mut self) -> WindowConfig:
        return WindowConfig("Example Sketch", 300, 200)

    def update(mut self, mut canvas: Canvas) raises:
        canvas.background(255)
        canvas.fill(255, 0, 0)
        canvas.rect(10, 10, 100, 100)


def main() raises:
    run(App())
