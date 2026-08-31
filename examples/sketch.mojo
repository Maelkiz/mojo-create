from create.core import *


@fieldwise_init
struct Sketch(Windowed, Movable, Deinitable):

    @staticmethod
    def create(mut ctx: Context) raises -> Sketch:
        return Sketch()

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.WHITE)
        canvas.stroke(Color.GREEN)

        canvas.fill(Color.RED)
        canvas.rect((150, 150), 100, 100)

        canvas.fill(Color.BLUE)
        canvas.circle((300, 300), 50)
        
        canvas.fill(Color.BLACK)
        canvas.triangle((400, 400), (450, 550), (550, 450))

        canvas.stroke_width(3)
        canvas.line((200, 200), (400, 400))

        canvas.fill(Color.BLACK)
        canvas.fontSize(54)
        canvas.text("Create!", 450, 200)


def main() raises:
    run[Sketch]("Example Sketch", 800, 600)
