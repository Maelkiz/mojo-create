from create.core import *
from create.graphics import Sprite
from create.math import clamp

@fieldwise_init
struct Game(Windowed, Movable, Deinitable):
    var sprite: Sprite
    var x: Float64
    var y: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> Game:
        var sprite = Sprite.load("examples/sprite_example/assets/sprite.bmp")
        return Game(sprite^, Float64(ctx.width // 2), Float64(ctx.height // 2))

    def update(mut self, mut ctx: Context) raises:
        var speed = 4.0
        if ctx.input.is_key_down(119):  # w
            self.y -= speed
        if ctx.input.is_key_down(115):  # s
            self.y += speed
        if ctx.input.is_key_down(97):   # a
            self.x -= speed
        if ctx.input.is_key_down(100):  # d
            self.x += speed

        var hw = Float64(self.sprite.width) / 2.0
        var hh = Float64(self.sprite.height) / 2.0
        self.x = clamp(self.x, hw, Float64(ctx.width) - hw)
        self.y = clamp(self.y, hh, Float64(ctx.height) - hh)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(30, 30, 30))
        canvas.sprite(self.sprite, self.x, self.y)


def main() raises:
    run[Game]("Sprite Example", 800, 600)
