from std.math import sin, cos
from create.core import *


@fieldwise_init
struct App(Program):
    var t: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        return App(0.0)

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        self.t += ctx.delta_time

    def render(self, mut canvas: Canvas) raises:
        # A translucent background fades the previous frame instead of
        # clearing it, leaving motion trails.
        canvas.background(Color(0x11, 0x11, 0x11, 24))

        var center = canvas.center
        canvas.no_stroke()

        # Overlapping translucent fills mix where they cross.
        canvas.fill(Color(255, 0, 0, 128))
        canvas.circle((center.x - 60.0, center.y), 90.0)
        canvas.fill(Color(0, 255, 0, 128))
        canvas.circle((center.x + 60.0, center.y), 90.0)
        canvas.fill(Color(0, 0, 255, 128))
        canvas.circle((center.x, center.y - 90.0), 90.0)

        # An orbiting dot draws the trail the faded background preserves.
        var r = 220.0
        canvas.fill(Color.ORANGE)
        canvas.circle(
            (center.x + r * cos(self.t), center.y + r * sin(self.t) * 0.5), 14.0
        )

        canvas.fill(Color(255, 255, 255, 160))
        canvas.fontSize(28)
        canvas.textAlign(Align.CENTER)
        canvas.text("alpha", center.x, center.y + 150.0)


def main() raises:
    run[App]("Alpha", 800, 600)
