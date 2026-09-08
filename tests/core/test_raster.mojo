from std.testing import TestSuite, assert_equal, assert_true
from create.core.color import Color
from create.core.raster import (
    blend,
    blit_glyph,
    blit_sprite,
    fill_all,
    fill_pixels,
    fill_triangle,
    line_pixels,
)
from create.core.font import GlyphInfo
from create.core.surface import MemorySurface
from create.graphics.sprite import Sprite


def _filled(width: Int, height: Int, c: Color) raises -> MemorySurface:
    var mem = MemorySurface(width, height)
    fill_all(mem.surface(), c)
    return mem^


def test_an_opaque_blend_stores_the_color_outright() raises -> None:
    var mem = _filled(2, 2, Color(10, 20, 30, 40))
    blend(mem.surface(), mem.surface().offset(1, 1), Color(1, 2, 3, 255))
    assert_equal(mem.pixel(1, 1), Color(1, 2, 3, 255))


def test_a_fully_transparent_blend_is_a_no_op() raises -> None:
    var mem = _filled(2, 2, Color(10, 20, 30, 255))
    blend(mem.surface(), 0, Color(200, 200, 200, 0))
    assert_equal(mem.pixel(0, 0), Color(10, 20, 30, 255))


def test_a_partial_blend_composites_source_over() raises -> None:
    var dst = Color(0, 0, 0, 255)
    var src = Color(255, 100, 0, 128)
    var mem = _filled(1, 1, dst)
    blend(mem.surface(), 0, src)
    # Same arithmetic the raster path must not diverge from.
    assert_equal(mem.pixel(0, 0), src.over(dst))


def test_fill_all_covers_every_pixel() raises -> None:
    var mem = _filled(3, 2, Color.WHITE)
    for y in range(2):
        for x in range(3):
            assert_equal(mem.pixel(x, y), Color.WHITE)


def test_fill_pixels_is_half_open() raises -> None:
    var mem = MemorySurface(4, 4)
    fill_pixels(mem.surface(), 1, 1, 3, 3, Color.WHITE)
    assert_equal(mem.pixel(1, 1), Color.WHITE)
    assert_equal(mem.pixel(2, 2), Color.WHITE)
    # x1/y1 are exclusive.
    assert_equal(mem.pixel(3, 3).a, 0)
    assert_equal(mem.pixel(0, 0).a, 0)


def test_fill_pixels_clips_at_every_edge() raises -> None:
    var mem = MemorySurface(4, 4)
    # Straddles all four edges at once; must neither crash nor wrap a row.
    fill_pixels(mem.surface(), -10, -10, 20, 20, Color.WHITE)
    for y in range(4):
        for x in range(4):
            assert_equal(mem.pixel(x, y), Color.WHITE)

    var edge = MemorySurface(4, 4)
    fill_pixels(edge.surface(), -3, 0, 1, 4, Color.WHITE)
    for y in range(4):
        assert_equal(edge.pixel(0, y), Color.WHITE)
        # A wrapped row would light up the right-hand column.
        assert_equal(edge.pixel(3, y).a, 0)


def test_fill_pixels_wholly_outside_writes_nothing() raises -> None:
    var mem = MemorySurface(4, 4)
    fill_pixels(mem.surface(), 10, 10, 20, 20, Color.WHITE)
    fill_pixels(mem.surface(), -20, -20, -10, -10, Color.WHITE)
    for y in range(4):
        for x in range(4):
            assert_equal(mem.pixel(x, y).a, 0)


def test_line_pixels_covers_both_endpoints() raises -> None:
    var mem = MemorySurface(8, 8)
    line_pixels(mem.surface(), 1.0, 1.0, 6.0, 1.0, Color.WHITE, 1)
    assert_equal(mem.pixel(1, 1), Color.WHITE)
    assert_equal(mem.pixel(6, 1), Color.WHITE)
    assert_equal(mem.pixel(0, 1).a, 0)
    assert_equal(mem.pixel(7, 1).a, 0)


def test_line_pixels_thickens_with_stroke_width() raises -> None:
    var mem = MemorySurface(8, 8)
    line_pixels(mem.surface(), 1.0, 4.0, 6.0, 4.0, Color.WHITE, 3)
    # half = 3 // 2 = 1, so rows 3..5 around the line.
    assert_equal(mem.pixel(3, 3), Color.WHITE)
    assert_equal(mem.pixel(3, 4), Color.WHITE)
    assert_equal(mem.pixel(3, 5), Color.WHITE)
    assert_equal(mem.pixel(3, 6).a, 0)


def test_line_pixels_clips_outside_the_surface() raises -> None:
    var mem = MemorySurface(4, 4)
    line_pixels(mem.surface(), -5.0, 2.0, 9.0, 2.0, Color.WHITE, 1)
    for x in range(4):
        assert_equal(mem.pixel(x, 2), Color.WHITE)
    assert_equal(mem.pixel(0, 0).a, 0)


def test_fill_triangle_covers_its_interior_not_its_outside() raises -> None:
    var mem = MemorySurface(8, 8)
    fill_triangle(mem.surface(), 0.0, 0.0, 6.0, 0.0, 0.0, 6.0, Color.WHITE)
    assert_equal(mem.pixel(1, 1), Color.WHITE)
    assert_equal(mem.pixel(0, 0), Color.WHITE)
    # Beyond the hypotenuse.
    assert_equal(mem.pixel(5, 5).a, 0)
    assert_equal(mem.pixel(7, 7).a, 0)


def test_blit_sprite_one_to_one() raises -> None:
    var sp = Sprite.solid(2, 2, 255, 0, 0)
    var mem = MemorySurface(4, 4)
    blit_sprite(mem.surface(), sp, 1, 1, 2, 2)
    assert_equal(mem.pixel(1, 1), Color(255, 0, 0, 255))
    assert_equal(mem.pixel(2, 2), Color(255, 0, 0, 255))
    assert_equal(mem.pixel(0, 0).a, 0)
    assert_equal(mem.pixel(3, 3).a, 0)


def test_blit_sprite_downscales_by_nearest_neighbour() raises -> None:
    var sp = Sprite(4, 4)
    var ptr = sp.pixels.unsafe_ptr()
    # Left half red, right half blue — a downscale must keep both halves.
    for row in range(4):
        for col in range(4):
            var off = (row * 4 + col) * 4
            ptr[unsafe_offset=off] = 255 if col < 2 else 0
            ptr[unsafe_offset=off + 1] = 0
            ptr[unsafe_offset=off + 2] = 0 if col < 2 else 255
            ptr[unsafe_offset=off + 3] = 255
    var mem = MemorySurface(4, 4)
    blit_sprite(mem.surface(), sp, 0, 0, 2, 2)
    assert_equal(mem.pixel(0, 0), Color(255, 0, 0, 255))
    assert_equal(mem.pixel(1, 0), Color(0, 0, 255, 255))
    assert_equal(mem.pixel(0, 2).a, 0)


def test_blit_sprite_skips_transparent_source_pixels() raises -> None:
    var sp = Sprite(2, 1)
    var ptr = sp.pixels.unsafe_ptr()
    ptr[unsafe_offset=0] = 255
    ptr[unsafe_offset=3] = 255  # opaque red
    ptr[unsafe_offset=7] = 0  # fully transparent
    var mem = _filled(2, 1, Color(9, 9, 9, 255))
    blit_sprite(mem.surface(), sp, 0, 0, 2, 1)
    assert_equal(mem.pixel(0, 0), Color(255, 0, 0, 255))
    assert_equal(mem.pixel(1, 0), Color(9, 9, 9, 255))


def test_blit_sprite_clips_against_every_edge() raises -> None:
    var sp = Sprite.solid(4, 4, 255, 255, 255)
    var mem = MemorySurface(4, 4)
    # Anchored off the top-left: only the bottom-right quarter lands.
    blit_sprite(mem.surface(), sp, -2, -2, 4, 4)
    assert_equal(mem.pixel(0, 0), Color.WHITE)
    assert_equal(mem.pixel(1, 1), Color.WHITE)
    assert_equal(mem.pixel(2, 2).a, 0)

    var far = MemorySurface(4, 4)
    blit_sprite(far.surface(), sp, 3, 3, 4, 4)
    assert_equal(far.pixel(3, 3), Color.WHITE)
    # A wrapped row would light up column 0.
    assert_equal(far.pixel(0, 3).a, 0)


def _glyph(width: Int, height: Int, coverage: UInt8) raises -> GlyphInfo:
    var g = GlyphInfo(width, height, 0, 0, width)
    var p = g.pixels.unsafe_ptr()
    for i in range(width * height):
        p[unsafe_offset=i] = coverage
    return g^


def test_blit_glyph_scales_the_fill_alpha_by_coverage() raises -> None:
    var g = _glyph(2, 2, 128)
    var mem = _filled(4, 4, Color(0, 0, 0, 255))
    blit_glyph(mem.surface(), g, 1, 1, Color(255, 255, 255, 255))
    # cov 128 of an opaque white fill: half-strength, composited over black.
    var expected = Color(255, 255, 255, UInt8(128 * 255 // 255)).over(
        Color(0, 0, 0, 255)
    )
    assert_equal(mem.pixel(1, 1), expected)
    assert_equal(mem.pixel(0, 0), Color(0, 0, 0, 255))


def test_blit_glyph_skips_zero_coverage() raises -> None:
    var g = _glyph(2, 2, 0)
    var mem = _filled(2, 2, Color(7, 7, 7, 255))
    blit_glyph(mem.surface(), g, 0, 0, Color.WHITE)
    assert_equal(mem.pixel(0, 0), Color(7, 7, 7, 255))


def test_blit_glyph_clips_against_the_surface() raises -> None:
    var g = _glyph(4, 4, 255)
    var mem = MemorySurface(4, 4)
    blit_glyph(mem.surface(), g, -2, -2, Color.WHITE)
    assert_equal(mem.pixel(0, 0), Color.WHITE)
    assert_equal(mem.pixel(1, 1), Color.WHITE)
    assert_equal(mem.pixel(2, 2).a, 0)

    var far = MemorySurface(4, 4)
    blit_glyph(far.surface(), g, 3, 3, Color.WHITE)
    assert_equal(far.pixel(3, 3), Color.WHITE)
    assert_equal(far.pixel(0, 3).a, 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
