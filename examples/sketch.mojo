from create import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def settings(mut self) -> WindowConfig:
        return WindowConfig("Example Sketch", 300, 200)

    def update(mut self, mut canvas: Canvas) raises:
        canvas.background(255)


def main() raises:
    run(App())
