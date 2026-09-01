from create.core import *


@fieldwise_init
struct App(Program):
    var center: Circle
    var mouse: Circle

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        return App(
            center=Circle(ctx.center, 100),
            mouse=Circle(0, 0, 100),
        )

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        self.center.move_to(ctx.center)
        self.mouse.move_to(input.mouse)

    def render(self, mut canvas: Canvas) raises:
        if overlaps(self.center, self.mouse):
            canvas.background(Color(40, 40, 60))
        else:
            canvas.background(Color(20, 20, 30))

        canvas.no_stroke()
        canvas.fill(Color(220, 60, 60))
        canvas.circle(self.center)
        canvas.fill(Color(60, 120, 220))
        canvas.circle(self.mouse)


def main() raises:
    run[App]("Circle Overlap", 1000, 1000)
