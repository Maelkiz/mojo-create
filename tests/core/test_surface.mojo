from std.testing import TestSuite, assert_equal
from create.render.color import Color
from create.render.surface import MemorySurface, Surface


def _write(mut s: Surface, x: Int, y: Int, c: Color):
    var off = s.offset(x, y)
    s.px[unsafe_offset=off] = c.r
    s.px[unsafe_offset=off + 1] = c.g
    s.px[unsafe_offset=off + 2] = c.b
    s.px[unsafe_offset=off + 3] = c.a


def test_a_new_surface_is_transparent_black() raises -> None:
    var mem = MemorySurface(4, 3)
    assert_equal(mem.pixel(0, 0), Color(0, 0, 0, 0))
    assert_equal(mem.pixel(3, 2), Color(0, 0, 0, 0))


def test_offset_is_row_major_rgba() raises -> None:
    var mem = MemorySurface(4, 3)
    var s = mem.surface()
    assert_equal(s.offset(0, 0), 0)
    assert_equal(s.offset(1, 0), 4)
    assert_equal(s.offset(0, 1), 16)
    assert_equal(s.offset(3, 2), 44)


def test_a_write_through_a_surface_reads_back_from_the_owner() raises -> None:
    var mem = MemorySurface(4, 3)
    var s = mem.surface()
    _write(s, 2, 1, Color(10, 20, 30, 40))
    assert_equal(mem.pixel(2, 1), Color(10, 20, 30, 40))


def test_a_write_leaves_every_other_pixel_untouched() raises -> None:
    var mem = MemorySurface(4, 3)
    var s = mem.surface()
    _write(s, 2, 1, Color.WHITE)
    for y in range(3):
        for x in range(4):
            if x == 2 and y == 1:
                continue
            assert_equal(mem.pixel(x, y), Color(0, 0, 0, 0))


def test_the_surface_reports_the_owners_dimensions() raises -> None:
    var mem = MemorySurface(7, 5)
    var s = mem.surface()
    assert_equal(s.width, 7)
    assert_equal(s.height, 5)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
