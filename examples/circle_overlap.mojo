from create.core import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    @staticmethod
    def create(mut ctx: Context) raises -> App:
        return App()

    def update(mut self, mut ctx: Context) raises:
        var radius = 100
        var cx = ctx.width // 2
        var cy = ctx.height // 2
        var dx = ctx.input.mouse_x - cx
        var dy = ctx.input.mouse_y - cy

        var overlaps = dx * dx + dy * dy < (radius * 2) * (radius * 2)

        var bg_col = Color(40, 40, 60) if overlaps else Color(20, 20, 30)

        ctx.render(Background(bg_col))
        ctx.no_stroke()
        ctx.fill(Color(220, 60, 60))
        ctx.render(Circle(cx, cy, radius))
        ctx.fill(Color(60, 120, 220))
        ctx.render(Circle(ctx.input.mouse_x, ctx.input.mouse_y, radius))


def main() raises:
    run[App]("Circle Overlap")
