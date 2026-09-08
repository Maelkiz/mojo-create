# TextRenderer, driven straight onto an owned buffer.
#
# Hermetic: both faces ship in defaults/fonts/, so this asserts on real glyph
# pixels rather than mocking the rasteriser.

from std.testing import TestSuite, assert_equal, assert_true, assert_false

from create.core.align import HAlign, VAlign
from create.core.color import Color
from create.core.font import FontWeight
from create.core.style import Style
from create.core.surface import MemorySurface
from create.core.text import TextRenderer


def _ink_box(m: MemorySurface) -> Tuple[Int, Int, Int, Int]:
    """Bounding box of everything drawn — `(x0, y0, x1, y1)`, inclusive.

    The buffer starts fully transparent, so any pixel with alpha is ink.
    Returns `(-1, -1, -1, -1)` when nothing was drawn.
    """
    var x0 = m.width
    var y0 = m.height
    var x1 = -1
    var y1 = -1
    for y in range(m.height):
        for x in range(m.width):
            if m.pixel(x, y).a > 0:
                x0 = min(x0, x)
                y0 = min(y0, y)
                x1 = max(x1, x)
                y1 = max(y1, y)
    if x1 < 0:
        return (-1, -1, -1, -1)
    return (x0, y0, x1, y1)


def _style(halign: HAlign, valign: VAlign) -> Style:
    var s = Style()
    s.fill = Color.WHITE
    s.font_size = 24
    s.text_halign = halign
    s.text_valign = valign
    return s^


def _draw(
    halign: HAlign, valign: VAlign, x: Float64, y: Float64
) raises -> MemorySurface:
    var m = MemorySurface(200, 120)
    var t = TextRenderer()
    t.draw(m.surface(), "Hi", x, y, _style(halign, valign), 1.0)
    return m^


def test_construction_touches_no_disk() raises -> None:
    # A program that draws no text must not pay the font load, and must not
    # fail on a missing file it never needed.
    var t = TextRenderer()
    assert_equal(len(t._font), 0)
    assert_equal(len(t._fallback_font), 0)
    assert_false(t._fallback_attempted)


def test_font_loads_lazily_on_first_draw() raises -> None:
    var t = TextRenderer()
    t._ensure_font(16)
    assert_equal(len(t._font), 1)
    assert_true(t._fallback_attempted)


def test_fallback_is_attempted_at_most_once() raises -> None:
    # A missing fallback must not be retried on every glyph of every frame.
    var t = TextRenderer()
    t._ensure_font(16)
    var loaded = len(t._fallback_font)
    t._ensure_font(16)
    t._ensure_font(32)
    assert_equal(len(t._fallback_font), loaded)


def test_draw_puts_ink_below_and_right_of_a_top_left_anchor() raises -> None:
    var m = _draw(HAlign.LEFT, VAlign.TOP, 40.0, 30.0)
    var box = _ink_box(m)
    assert_true(box[2] >= 0, "nothing was drawn")
    assert_true(box[0] >= 40, "ink started left of the anchor")
    assert_true(box[1] >= 30, "ink started above the anchor")
    assert_true(box[2] < 200 and box[3] < 120, "ink ran off the buffer")


def test_centre_align_shifts_ink_left_of_left_align() raises -> None:
    var left = _ink_box(_draw(HAlign.LEFT, VAlign.TOP, 100.0, 30.0))
    var centre = _ink_box(_draw(HAlign.CENTER, VAlign.TOP, 100.0, 30.0))
    var right = _ink_box(_draw(HAlign.RIGHT, VAlign.TOP, 100.0, 30.0))
    assert_true(centre[0] < left[0], "CENTER did not shift left of LEFT")
    assert_true(right[0] < centre[0], "RIGHT did not shift left of CENTER")


def test_baseline_shifts_ink_up_the_buffer() raises -> None:
    # Glyphs rasterise upright regardless of the world y axis, so TOP must put
    # the box below the anchor and BOTTOM above it — in pixel rows, upward
    # means smaller.
    var top = _ink_box(_draw(HAlign.LEFT, VAlign.TOP, 40.0, 60.0))
    var middle = _ink_box(_draw(HAlign.LEFT, VAlign.MIDDLE, 40.0, 60.0))
    var bottom = _ink_box(_draw(HAlign.LEFT, VAlign.BOTTOM, 40.0, 60.0))
    assert_true(middle[1] < top[1], "MIDDLE did not sit above TOP")
    assert_true(bottom[1] < middle[1], "BOTTOM did not sit above MIDDLE")


def test_pixel_scale_grows_the_glyphs() raises -> None:
    # Font size is authored in world units, so autoscale must reach the raster.
    var m1 = MemorySurface(200, 120)
    var t1 = TextRenderer()
    t1.draw(m1.surface(), "Hi", 20.0, 20.0, _style(HAlign.LEFT, VAlign.TOP), 1.0)
    var m2 = MemorySurface(200, 120)
    var t2 = TextRenderer()
    t2.draw(m2.surface(), "Hi", 20.0, 20.0, _style(HAlign.LEFT, VAlign.TOP), 2.0)
    var small = _ink_box(m1)
    var big = _ink_box(m2)
    assert_true(
        (big[2] - big[0]) > (small[2] - small[0]), "2x scale was not wider"
    )


def test_style_defaults() raises -> None:
    # What every frame starts with, since style does not survive the frame
    # boundary — a wrong default here silently changes the first draw call of
    # every render that doesn't set that field.
    var s = Style()
    assert_equal(s.fill, Color.WHITE)
    assert_true(s.fill_enabled)
    assert_equal(s.stroke, Color.BLACK)
    assert_equal(s.stroke_width, 1)
    assert_true(s.stroke_enabled)
    assert_equal(s.font_size, 16)
    assert_equal(s.font_weight, FontWeight.REGULAR)
    assert_true(s.text_halign == HAlign.LEFT)
    assert_true(s.text_valign == VAlign.TOP)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
