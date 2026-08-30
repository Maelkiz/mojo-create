from create.core import *


@fieldwise_init
struct App(Windowed, Movable, Deinitable):
    var overlaps: Bool
    var cx: Int
    var cy: Int
    var mouse_x: Int
    var mouse_y: Int

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        return App(False, ctx.width // 2, ctx.height // 2, 0, 0)

    def update(mut self, mut ctx: Context) raises:
        var radius = 100
        self.cx = ctx.width // 2
        self.cy = ctx.height // 2
        var dx = ctx.input.mouse_x - self.cx
        var dy = ctx.input.mouse_y - self.cy
        self.overlaps = dx * dx + dy * dy < (radius * 2) * (radius * 2)
        self.mouse_x = ctx.input.mouse_x
        self.mouse_y = ctx.input.mouse_y

    def render(self, mut canvas: Canvas) raises:
        var radius = 100
        canvas.background(Color(40, 40, 60) if self.overlaps else Color(20, 20, 30))
        canvas.no_stroke()
        canvas.fill(Color(220, 60, 60))
        canvas.draw(Circle(self.cx, self.cy, radius))
        canvas.fill(Color(60, 120, 220))
        canvas.draw(Circle(self.mouse_x, self.mouse_y, radius))


def main() raises:
    run[App]("Circle Overlap")
