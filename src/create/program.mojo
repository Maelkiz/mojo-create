from .context import Context
from .window_config import WindowConfig


trait Program:
    def window(self) -> WindowConfig: ...

    def setup(mut self, mut ctx: Context) raises:
        pass

    def update(mut self, mut ctx: Context) raises:
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
