from create.core import *


def _mode_name(mode: Int) -> String:
    if mode == AutoScale.FIT:
        return "FIT"
    if mode == AutoScale.EXTEND:
        return "EXTEND"
    return "OFF"


@fieldwise_init
struct App(Program):
    var x: Float64
    var dir: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        # Everything below is authored against the 1280x720 passed to run().
        # Space cycles the three modes:
        #   FIT     resize and the whole scene scales, letterboxed
        #   EXTEND  same scale, no bars — the leftover becomes extra world, so
        #           the circle turns at the new window edge
        #   OFF     no scaling at all — the world is the window in pixels, so
        #           the scene stays put while the space around it grows
        # The origin is the middle of the design area and y grows upward, so
        # the labels below centre sit at negative y.
        ctx.autoscale = AutoScale.FIT
        return App(100.0, 1.0)

    def update(mut self, mut ctx: Context, input: Input) raises:
        if input.just_pressed("space"):
            if ctx.autoscale == AutoScale.FIT:
                ctx.autoscale = AutoScale.EXTEND
            elif ctx.autoscale == AutoScale.EXTEND:
                ctx.autoscale = AutoScale.OFF
            else:
                ctx.autoscale = AutoScale.FIT
        self.x += self.dir * 200.0 * ctx.time.delta
        if self.x > ctx.right() - 40.0 or self.x < ctx.left() + 40.0:
            self.dir = -self.dir

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(0x99))

        canvas.fill(Color.RED)
        canvas.circle((self.x, 150), 40)

        canvas.fill(Color.BLUE)
        canvas.rect((0, 0), 200, 120)

        canvas.fill(Color.BLACK)
        canvas.font_size(28)
        canvas.text_align(HAlign.CENTER)
        canvas.text("Autoscale Mode: " + _mode_name(canvas.autoscale), 0, -140)
        canvas.font_size(20)
        canvas.text("(space to cycle)", 0, -180)
        canvas.font_size(28)
        canvas.text("Current scale: " + String(canvas.scale), 0, -220)


def main() raises:
    run[App]("Autoscale", 800, 600, fullscreen=True)
