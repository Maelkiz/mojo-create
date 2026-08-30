from create.core import *


@fieldwise_init
struct Sketch(Windowed, Movable, Deinitable):

    @staticmethod
    def create(mut ctx: Context) raises -> Sketch:
        return Sketch()

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.WHITE)

        canvas.fill(Color.RED)
        canvas.rect(150, 150, 100, 100)

        canvas.fill(Color.BLUE)
        canvas.circle(400, 400, 50)

        canvas.stroke(Color.GREEN)
        canvas.stroke_width(3)
        canvas.line(150, 150, 400, 400)


def main() raises:
    run[Sketch]("Example Sketch", 800, 600)
