from .canvas import Canvas
from .context import Context
from .input import Input


trait Program(Deinitable, Movable):
    @staticmethod
    def create(mut ctx: Context) raises -> Self:
        ...

    def update(mut self, mut ctx: Context, input: Input) raises:
        """Advance the program by one frame.

        `ctx` is mutable because the program writes back to it — `quit()`,
        `autoscale`, `exit_on_escape`. `input` is not: the run loop is its only
        writer, so borrowing it read-only makes that one-way flow a compile
        error to violate rather than a convention to remember.
        """
        pass

    def render(self, mut canvas: Canvas) raises:
        pass
