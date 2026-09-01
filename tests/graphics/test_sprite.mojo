from std.testing import TestSuite, assert_equal, assert_true
from create.core.color import Color
from create.graphics.sprite import Sprite


def test_solid_dimensions() raises -> None:
    var s = Sprite.solid(4, 3, Color.RED)
    assert_equal(s.width, 4)
    assert_equal(s.height, 3)
    assert_equal(len(s.pixels), 4 * 3 * 4)


def test_solid_pixels_correct() raises -> None:
    var s = Sprite.solid(2, 2, Color.RED)
    var ptr = s.pixels.unsafe_ptr()
    for i in range(4):
        var off = i * 4
        assert_equal(Int(ptr[unsafe_offset=off]), 255)      # R
        assert_equal(Int(ptr[unsafe_offset=off + 1]), 0)    # G
        assert_equal(Int(ptr[unsafe_offset=off + 2]), 0)    # B
        assert_equal(Int(ptr[unsafe_offset=off + 3]), 255)  # A


def test_solid_blue() raises -> None:
    var s = Sprite.solid(1, 1, Color.BLUE)
    var ptr = s.pixels.unsafe_ptr()
    assert_equal(Int(ptr[unsafe_offset=0]), 0)    # R
    assert_equal(Int(ptr[unsafe_offset=1]), 0)    # G
    assert_equal(Int(ptr[unsafe_offset=2]), 255)  # B
    assert_equal(Int(ptr[unsafe_offset=3]), 255)  # A


def test_from_rgba_roundtrip() raises -> None:
    var data: List[UInt8] = [10, 20, 30, 128, 40, 50, 60, 200]
    var s = Sprite.from_rgba(2, 1, data)
    assert_equal(s.width, 2)
    assert_equal(s.height, 1)
    assert_equal(Int(s.pixels[0]), 10)
    assert_equal(Int(s.pixels[1]), 20)
    assert_equal(Int(s.pixels[2]), 30)
    assert_equal(Int(s.pixels[3]), 128)
    assert_equal(Int(s.pixels[4]), 40)
    assert_equal(Int(s.pixels[7]), 200)


def test_load_bmp_dimensions() raises -> None:
    var s = Sprite.load("tests/fixtures/test_2x2.bmp")
    assert_equal(s.width, 2)
    assert_equal(s.height, 2)
    assert_equal(len(s.pixels), 2 * 2 * 4)


def test_load_bmp_pixels() raises -> None:
    # test_2x2.bmp: top-left=red, top-right=white, bottom-left=blue, bottom-right=white
    var s = Sprite.load("tests/fixtures/test_2x2.bmp")
    var ptr = s.pixels.unsafe_ptr()
    assert_equal(Int(ptr[unsafe_offset=0]), 255)   # (0,0) R
    assert_equal(Int(ptr[unsafe_offset=1]), 0)     # (0,0) G
    assert_equal(Int(ptr[unsafe_offset=2]), 0)     # (0,0) B
    assert_equal(Int(ptr[unsafe_offset=3]), 255)   # (0,0) A
    assert_equal(Int(ptr[unsafe_offset=4]), 255)   # (1,0) R — white
    assert_equal(Int(ptr[unsafe_offset=5]), 255)
    assert_equal(Int(ptr[unsafe_offset=6]), 255)
    assert_equal(Int(ptr[unsafe_offset=8]), 0)     # (0,1) R — blue
    assert_equal(Int(ptr[unsafe_offset=9]), 0)
    assert_equal(Int(ptr[unsafe_offset=10]), 255)


def test_load_png() raises -> None:
    var s = Sprite.load("tests/assets/sprite.png")
    assert_equal(s.width, 500)
    assert_equal(s.height, 500)
    assert_equal(len(s.pixels), 500 * 500 * 4)


def test_load_jpeg() raises -> None:
    var s = Sprite.load("tests/assets/sprite.jpeg")
    assert_equal(s.width, 500)
    assert_equal(s.height, 500)
    assert_equal(len(s.pixels), 500 * 500 * 4)


def test_load_with_dimensions() raises -> None:
    var s = Sprite.load("tests/fixtures/test_2x2.bmp", 4, 4)
    assert_equal(s.width, 4)
    assert_equal(s.height, 4)


def test_resize_dimensions() raises -> None:
    var s = Sprite.solid(4, 4, Color.RED)
    s.resize(2, 2)
    assert_equal(s.width, 2)
    assert_equal(s.height, 2)
    assert_equal(len(s.pixels), 2 * 2 * 4)


def test_resize_preserves_color() raises -> None:
    var s = Sprite.solid(4, 4, Color.RED)
    s.resize(2, 2)
    var ptr = s.pixels.unsafe_ptr()
    for i in range(4):  # 2×2 = 4 pixels
        var off = i * 4
        assert_equal(Int(ptr[unsafe_offset=off]),     255)  # R
        assert_equal(Int(ptr[unsafe_offset=off + 1]), 0)    # G
        assert_equal(Int(ptr[unsafe_offset=off + 2]), 0)    # B
        assert_equal(Int(ptr[unsafe_offset=off + 3]), 255)  # A


def test_resize_upscale() raises -> None:
    var s = Sprite.solid(2, 2, Color.GREEN)
    s.resize(4, 4)
    assert_equal(s.width, 4)
    assert_equal(s.height, 4)
    assert_equal(len(s.pixels), 4 * 4 * 4)


def test_resize_to_1x1() raises -> None:
    var s = Sprite.solid(100, 100, Color.WHITE)
    s.resize(1, 1)
    assert_equal(s.width, 1)
    assert_equal(s.height, 1)
    assert_equal(len(s.pixels), 4)


def test_solid_1x1() raises -> None:
    var s = Sprite.solid(1, 1, Color.GREEN)
    assert_equal(s.width, 1)
    assert_equal(s.height, 1)
    assert_equal(len(s.pixels), 4)
    var ptr = s.pixels.unsafe_ptr()
    assert_equal(Int(ptr[unsafe_offset=0]), 0)    # R
    assert_equal(Int(ptr[unsafe_offset=1]), 255)  # G
    assert_equal(Int(ptr[unsafe_offset=2]), 0)    # B
    assert_equal(Int(ptr[unsafe_offset=3]), 255)  # A


def test_from_rgba_size_mismatch_uses_data() raises -> None:
    # from_rgba trusts the caller's dimensions; just verify pixel count matches w*h
    var data: List[UInt8] = [1, 2, 3, 4]
    var s = Sprite.from_rgba(1, 1, data)
    assert_equal(len(s.pixels), 4)


def test_load_bmp_alpha_channel() raises -> None:
    var s = Sprite.load("tests/fixtures/test_2x2.bmp")
    var ptr = s.pixels.unsafe_ptr()
    # BMP has no alpha — loader should set alpha=255 for all pixels
    assert_equal(Int(ptr[unsafe_offset=3]),  255)  # (0,0) A
    assert_equal(Int(ptr[unsafe_offset=7]),  255)  # (1,0) A
    assert_equal(Int(ptr[unsafe_offset=11]), 255)  # (0,1) A
    assert_equal(Int(ptr[unsafe_offset=15]), 255)  # (1,1) A


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
