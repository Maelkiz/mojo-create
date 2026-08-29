from create.core import *


@fieldwise_init
struct Sketch(Program, Movable, Deinitable):
    def update(mut self, mut ctx: Context) raises:
        ctx.render(Background(Color(255)))
        ctx.fill(Color.red())
        ctx.render(Rect(10, 10, 100, 100))
        ctx.fill(Color.blue())
        ctx.render(Circle(200, 100, 50))
        ctx.stroke(Color.green())
        ctx.stroke_width(3)
        ctx.render(Line(0, 0, 300, 200))


def main() raises:
    run(Sketch(), "Example Sketch", 300, 200)
