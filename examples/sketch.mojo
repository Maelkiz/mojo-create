from create.core import *


@fieldwise_init
struct Sketch(Windowed, Movable, Deinitable):

    @staticmethod
    def create(mut ctx: Context) raises -> Sketch:
        return Sketch()

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(255))
        canvas.fill(Color.red())
        canvas.draw(Rect(10, 10, 100, 100))
        canvas.fill(Color.blue())
        canvas.draw(Circle(200, 100, 50))
        canvas.stroke(Color.green())
        canvas.stroke_width(3)
        canvas.draw(Line(0, 0, 300, 200))


def main() raises:
    run[Sketch]("Example Sketch", 300, 200)
