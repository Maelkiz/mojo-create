from create.core import *


@fieldwise_init
struct App(Program):
    var x: Float64
    var dir: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        # Everything below is authored against the 800x600 passed to run().
        # Resize the window and the whole scene scales with it, letterboxed.
        ctx.autoscale = True
        return App(100.0, 1.0)

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        self.x += self.dir * 200.0 * ctx.delta_time
        if self.x > Float64(ctx.width) - 40.0 or self.x < 40.0:
            self.dir = -self.dir

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(0x99))
        var center = canvas.center

        canvas.fill(Color.RED)
        canvas.circle((self.x, 150), 40)

        canvas.fill(Color.BLUE)
        canvas.rect(center, 200, 120)

        canvas.fill(Color.BLACK)
        canvas.fontSize(28)
        canvas.textAlign(Align.CENTER)
        canvas.text("scale " + String(canvas.scale), center.x, 480)


def main() raises:
    run[App]("Autoscale", 800, 600)
