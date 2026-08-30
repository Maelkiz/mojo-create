from create.core import *
from create.math import clamp

@fieldwise_init
struct Player:
    var x: Int
    var y: Int
    var width: Int
    var height: Int

    def move(mut self, mut ctx: Context):
        var speed = 10
        if ctx.input.is_key_down(119):  # w
            self.y -= speed
        if ctx.input.is_key_down(115):  # s
            self.y += speed
        if ctx.input.is_key_down(97):   # a
            self.x -= speed
        if ctx.input.is_key_down(100):  # d
            self.x += speed

        self.x = clamp(self.x, self.width // 2, ctx.width - self.width // 2)
        self.y = clamp(self.y, self.height // 2, ctx.height - self.height // 2)

    def draw(self, mut canvas: Canvas) raises:
        canvas.fill(Color(220, 80, 80))
        canvas.no_stroke()
        canvas.draw(Rect(self.x, self.y, self.width, self.height))


@fieldwise_init
struct Game(Windowed, Movable, Deinitable):
    var player: Player

    @staticmethod
    def create(mut ctx: Context) raises -> Game:
        return Game(Player(ctx.width // 2, ctx.height // 2, 60, 100))

    def update(mut self, mut ctx: Context) raises:
        self.player.move(ctx)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(30, 30, 30))
        self.player.draw(canvas)


def main() raises:
    run[Game]("Player Movement")
