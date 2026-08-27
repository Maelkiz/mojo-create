from create import *


struct App(Program, Movable):
    def setup(mut self):
        init_window("Example Sketch", 300, 200)

    def update(mut self):
        draw_background(0)


def main() raises:
    run(App())
