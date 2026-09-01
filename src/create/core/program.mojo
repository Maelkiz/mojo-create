from .canvas import Canvas
from .context import Context
from .input import Input


trait Program(Deinitable, Movable):
    @staticmethod
    def create(mut ctx: Context) raises -> Self:
        ...

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        pass

    def render(self, mut canvas: Canvas) raises:
        pass

    def on_key_down(mut self, keycode: Int) raises:
        pass

    def on_key_up(mut self, keycode: Int) raises:
        pass

    def on_mouse_moved(mut self, x: Int, y: Int) raises:
        pass

    def on_mouse_down(mut self, button: Int, x: Int, y: Int) raises:
        pass

    def on_mouse_up(mut self, button: Int, x: Int, y: Int) raises:
        pass

    def on_mouse_wheel(mut self, x: Int, y: Int) raises:
        pass

    def on_resize(mut self, width: Int, height: Int) raises:
        pass
