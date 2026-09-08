# The one shared frame step, and the split it depends on.
#
# `Canvas` takes its geometry from the `Viewport` and its extent from the
# `Surface`. The windowed loop relies on exactly that: the viewport is measured
# before events, but `Window._resize` reallocates the pixel buffer during them,
# so the two can disagree for a frame. Only the surface knows how big the
# memory actually is — hence the extent must never be read off the viewport.

from std.testing import TestSuite, assert_equal

from create.core import *
from create.core.frame import step


@fieldwise_init
struct Painter(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> Painter:
        return Painter(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLUE)
        canvas.no_stroke()
        canvas.fill(Color.RED)
        canvas.rect(0.0, 0.0, 10.0, 10.0)


def _mismatched() raises -> MemorySurface:
    """One frame where the surface is larger than the viewport was measured for.

    64x64 viewport, 200x200 buffer — the shape a grown window produces between
    the measurement and the resize.
    """
    var ctx = Context()
    ctx.view.set_design(64, 64)
    ctx.autoscale = AutoScale.FIT
    ctx._set_viewport(64, 64)
    var program = Painter(0)
    var input = Input()
    var mem = MemorySurface(200, 200)
    var state = step(program, ctx, input, mem.surface(), CanvasState())
    _ = state^
    return mem^


def test_extent_comes_from_the_surface() raises -> None:
    # The far corner is outside what the viewport describes but inside the
    # buffer, so it must still be painted. Reading the extent off the viewport
    # would leave it at the zero fill.
    var m = _mismatched()
    assert_equal(m.pixel(199, 199), Color.BLUE)
    assert_equal(m.pixel(0, 0), Color.BLUE)


def test_geometry_comes_from_the_viewport() raises -> None:
    # Geometry does not follow the surface: the origin stays at the centre of
    # the 64x64 viewport, pixel (32, 32), not at the centre of the buffer. This
    # is the one-frame lag between mapping and framebuffer, and it is why the
    # windowed loop must still pass an honest extent — a wrong extent is
    # memory corruption, a lagging mapping is one crooked frame.
    var m = _mismatched()
    assert_equal(m.pixel(32, 32), Color.RED)
    assert_equal(m.pixel(100, 100), Color.BLUE)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
