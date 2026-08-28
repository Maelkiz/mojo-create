from create import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def update(mut self, mut ctx: Context) raises:
        ctx.draw.background(Color(255))
        ctx.draw.fill(Color.red())
        ctx.draw.rect(10, 10, 100, 100)
        ctx.draw.fill(Color.blue())
        ctx.draw.circle(200, 100, 50)
        ctx.draw.stroke(Color.green())
        ctx.draw.stroke_width(3)
        ctx.draw.line(0, 0, 300, 200)


def main() raises:
    run(App(), "Example Sketch", 300, 200)
