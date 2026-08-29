from .canvas import Canvas


trait Renderable:
    def render_to(self, mut canvas: Canvas) raises:
        pass
