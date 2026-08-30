from create.core import *


@fieldwise_init
struct App(Windowed, Movable, Deinitable):
    var center: Circle
    var mouse: Circle

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        return App(
            center = Circle(ctx.width // 2, ctx.height // 2, 100), 
            mouse = Circle(0, 0, 100), 
        )

    def update(mut self, mut ctx: Context) raises:
        self.center = Circle(ctx.width // 2, ctx.height // 2, 100)
        self.mouse = Circle(ctx.input.mouse_x, ctx.input.mouse_y, 100)

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
    run[App]("Circle Overlap")
