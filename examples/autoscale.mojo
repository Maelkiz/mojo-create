from create.core import *


@fieldwise_init
struct App(Program):
    var x: Float64
    var dir: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        # Everything below is authored against the 800x600 passed to run().
        # Resize the window and the whole scene scales with it, letterboxed;
        # press space for EXTEND, where the leftover becomes extra world
        # instead of bars and the circle turns at the new window edge.
        # The origin is the middle of the design area and y grows upward,
        # so the labels below centre sit at negative y.
        ctx.autoscale = AutoScale.FIT
        return App(100.0, 1.0)

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        if input.just_pressed("space"):
            if ctx.autoscale == AutoScale.FIT:
                ctx.autoscale = AutoScale.EXTEND
            else:
                ctx.autoscale = AutoScale.FIT
        self.x += self.dir * 200.0 * ctx.delta_time
        if self.x > ctx.right() - 40.0 or self.x < ctx.left() + 40.0:
            self.dir = -self.dir

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(0x99))

        canvas.fill(Color.RED)
        canvas.circle((self.x, 150), 40)

        canvas.fill(Color.BLUE)
        canvas.rect((0, 0), 200, 120)

        var mode = "FIT" if canvas.autoscale == AutoScale.FIT else "EXTEND"
        canvas.fill(Color.BLACK)
        canvas.fontSize(28)
        canvas.textAlign(Align.CENTER)
        canvas.text("Autoscale Mode: " + mode, 0, -140)
        canvas.fontSize(20)
        canvas.text("(space to toggle)", 0, -180)
        canvas.fontSize(28)
        canvas.text("Current scale: " + String(canvas.scale), 0, -220)


def main() raises:
    run[App]("Autoscale", 800, 600)
