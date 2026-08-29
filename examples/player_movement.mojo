from create.core import *


struct Game(Program, Movable, Deinitable):
    var x: Int
    var y: Int

    def __init__(out self):
        self.x = 0
        self.y = 0

    def setup(mut self, mut ctx: Context) raises:
        self.x = ctx.width // 2 - 30
        self.y = ctx.height // 2 - 50

    def update(mut self, mut ctx: Context) raises:
        var speed = 5
        if ctx.input.is_key_down(119):  # w
            self.y -= speed
        if ctx.input.is_key_down(115):  # s
            self.y += speed
        if ctx.input.is_key_down(97):   # a
            self.x -= speed
        if ctx.input.is_key_down(100):  # d
            self.x += speed

        ctx.render(Background(Color(30, 30, 30)))
        ctx.fill(Color(220, 80, 80))
        ctx.no_stroke()
        ctx.render(Rect(self.x, self.y, 60, 100))


def main() raises:
    run[Game]("Player Movement")
