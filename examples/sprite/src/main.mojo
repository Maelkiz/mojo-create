from create.core import *
from create.graphics import Sprite
from create.math import clamp


@fieldwise_init
struct Game(Windowed, Movable, Deinitable):
    var sprite: Sprite
    var x: Int
    var y: Int

    @staticmethod
    def create(mut ctx: Context) raises -> Game:
        var sprite = Sprite.load(script_dir() + "/../assets/sprite.jpeg", 120, 120)
        return Game(sprite^, ctx.width // 2, ctx.height // 2)

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        var speed = 15
        if input.is_key_down("w"):
            self.y -= speed
        if input.is_key_down("s"):
            self.y += speed
        if input.is_key_down("a"):
            self.x -= speed
        if input.is_key_down("d"):
            self.x += speed

        var hw = (self.sprite.width) // 2
        var hh = (self.sprite.height) // 2
        self.x = clamp(self.x, hw, (ctx.width) - hw)
        self.y = clamp(self.y, hh, (ctx.height) - hh)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(30, 30, 30))
        canvas.sprite(self.sprite, self.x, self.y)


def main() raises:
    run[Game]("Sprite Example")
