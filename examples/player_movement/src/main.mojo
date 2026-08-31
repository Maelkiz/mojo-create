from create.core import *
from player import Player


@fieldwise_init
struct Game(Windowed, Movable, Deinitable):
    var player: Player

    @staticmethod
    def create(mut ctx: Context) raises -> Game:
        var w: Float64 = 60
        var h: Float64 = 80
        return Game(Player(Float64(ctx.width) / 2, Float64(ctx.height) / 2, w, h, 0.0, False, 2))

    def update(mut self, mut ctx: Context) raises:
        self.player.update(ctx)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(30, 30, 30))
        self.player.draw(canvas)


def main() raises:
    run[Game]("Player Movement")
