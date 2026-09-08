from std.testing import TestSuite, assert_equal, assert_true, assert_raises
from create.graphics.sprite import Sprite


def test_solid_dimensions() raises -> None:
    var s = Sprite.solid(4, 3, 255, 0, 0)
    assert_equal(s.width, 4)
    assert_equal(s.height, 3)
    assert_equal(len(s.pixels), 4 * 3 * 4)


def test_solid_pixels_correct() raises -> None:
    var s = Sprite.solid(2, 2, 255, 0, 0)
    var ptr = s.pixels.unsafe_ptr()
    for i in range(4):
        var off = i * 4
        assert_equal(Int(ptr[unsafe_offset=off]), 255)      # R
        assert_equal(Int(ptr[unsafe_offset=off + 1]), 0)    # G
        assert_equal(Int(ptr[unsafe_offset=off + 2]), 0)    # B
        assert_equal(Int(ptr[unsafe_offset=off + 3]), 255)  # A


def test_solid_blue() raises -> None:
    var s = Sprite.solid(1, 1, 0, 0, 255)
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


def test_load_bmp_32bit_pixels_and_alpha() raises -> None:
    # test_2x2_32bit.bmp: same colour layout as test_2x2.bmp (TL=red,
    # TR=white, BL=blue, BR=white) but 32-bit BI_RGB with four distinct,
    # file-supplied alpha values -- the only decode path that reads alpha
    # from disk rather than synthesising it.
    var s = Sprite.load("tests/fixtures/test_2x2_32bit.bmp")
    assert_equal(s.width, 2)
    assert_equal(s.height, 2)
    var ptr = s.pixels.unsafe_ptr()
    assert_equal(Int(ptr[unsafe_offset=0]), 255)  # (0,0) R -- red
    assert_equal(Int(ptr[unsafe_offset=1]), 0)
    assert_equal(Int(ptr[unsafe_offset=2]), 0)
    assert_equal(Int(ptr[unsafe_offset=3]), 0)    # (0,0) A
    assert_equal(Int(ptr[unsafe_offset=4]), 255)  # (1,0) -- white
    assert_equal(Int(ptr[unsafe_offset=5]), 255)
    assert_equal(Int(ptr[unsafe_offset=6]), 255)
    assert_equal(Int(ptr[unsafe_offset=7]), 85)   # (1,0) A
    assert_equal(Int(ptr[unsafe_offset=8]), 0)    # (0,1) -- blue
    assert_equal(Int(ptr[unsafe_offset=9]), 0)
    assert_equal(Int(ptr[unsafe_offset=10]), 255)
    assert_equal(Int(ptr[unsafe_offset=11]), 170) # (0,1) A
    assert_equal(Int(ptr[unsafe_offset=12]), 255) # (1,1) -- white
    assert_equal(Int(ptr[unsafe_offset=13]), 255)
    assert_equal(Int(ptr[unsafe_offset=14]), 255)
    assert_equal(Int(ptr[unsafe_offset=15]), 255) # (1,1) A


def test_load_topdown_bmp_matches_bottom_up() raises -> None:
    # test_2x2_topdown.bmp carries a negative height and top-down row order,
    # but the same final image as test_2x2.bmp. Identical output here is the
    # only proof the row flip fires for one file and not the other.
    var top_down = Sprite.load("tests/fixtures/test_2x2_topdown.bmp")
    var bottom_up = Sprite.load("tests/fixtures/test_2x2.bmp")
    assert_equal(top_down.width, bottom_up.width)
    assert_equal(top_down.height, bottom_up.height)
    var a = top_down.pixels.unsafe_ptr()
    var b = bottom_up.pixels.unsafe_ptr()
    for i in range(2 * 2 * 4):
        assert_equal(Int(a[unsafe_offset=i]), Int(b[unsafe_offset=i]))


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


def test_load_png_pixels() raises -> None:
    # test_2x2.png: top-left=red, top-right=green, bottom-left=blue,
    # bottom-right=white. Source has no alpha channel -- decoder must
    # synthesise 255.
    var s = Sprite.load("tests/fixtures/test_2x2.png")
    var ptr = s.pixels.unsafe_ptr()
    assert_equal(Int(ptr[unsafe_offset=0]), 255)   # (0,0) R -- red
    assert_equal(Int(ptr[unsafe_offset=1]), 0)
    assert_equal(Int(ptr[unsafe_offset=2]), 0)
    assert_equal(Int(ptr[unsafe_offset=3]), 255)   # synthesised alpha
    assert_equal(Int(ptr[unsafe_offset=4]), 0)     # (1,0) -- green
    assert_equal(Int(ptr[unsafe_offset=5]), 255)
    assert_equal(Int(ptr[unsafe_offset=6]), 0)
    assert_equal(Int(ptr[unsafe_offset=8]), 0)     # (0,1) -- blue
    assert_equal(Int(ptr[unsafe_offset=9]), 0)
    assert_equal(Int(ptr[unsafe_offset=10]), 255)
    assert_equal(Int(ptr[unsafe_offset=12]), 255)  # (1,1) -- white
    assert_equal(Int(ptr[unsafe_offset=13]), 255)
    assert_equal(Int(ptr[unsafe_offset=14]), 255)


def _assert_close(got: Int, want: Int, tolerance: Int) raises:
    var diff = got - want if got > want else want - got
    assert_true(diff <= tolerance)


def test_load_jpeg_pixels() raises -> None:
    # test_2x2.jpeg: same layout as test_2x2.png, encoded at quality 100 with
    # no chroma subsampling. Lossy, so compare within a band far tighter than
    # the gap between any two of these colours -- a red/blue channel swap
    # would blow well past this tolerance.
    var s = Sprite.load("tests/fixtures/test_2x2.jpeg")
    var ptr = s.pixels.unsafe_ptr()
    var tol = 16
    _assert_close(Int(ptr[unsafe_offset=0]), 255, tol)  # (0,0) -- red
    _assert_close(Int(ptr[unsafe_offset=1]), 0, tol)
    _assert_close(Int(ptr[unsafe_offset=2]), 0, tol)
    _assert_close(Int(ptr[unsafe_offset=4]), 0, tol)    # (1,0) -- green
    _assert_close(Int(ptr[unsafe_offset=5]), 255, tol)
    _assert_close(Int(ptr[unsafe_offset=6]), 0, tol)
    _assert_close(Int(ptr[unsafe_offset=8]), 0, tol)    # (0,1) -- blue
    _assert_close(Int(ptr[unsafe_offset=9]), 0, tol)
    _assert_close(Int(ptr[unsafe_offset=10]), 255, tol)
    _assert_close(Int(ptr[unsafe_offset=12]), 255, tol) # (1,1) -- white
    _assert_close(Int(ptr[unsafe_offset=13]), 255, tol)
    _assert_close(Int(ptr[unsafe_offset=14]), 255, tol)


def test_load_with_dimensions() raises -> None:
    var s = Sprite.load("tests/fixtures/test_2x2.bmp", 4, 4)
    assert_equal(s.width, 4)
    assert_equal(s.height, 4)


def test_load_nonexistent_path_raises() raises -> None:
    with assert_raises():
        _ = Sprite.load("tests/fixtures/does_not_exist.bmp")


def test_load_bmp_too_small_raises() raises -> None:
    with assert_raises(contains="too small"):
        _ = Sprite.load("tests/fixtures/bmp_too_small.bmp")


def test_load_bmp_bad_magic_raises() raises -> None:
    with assert_raises(contains="Not a BMP"):
        _ = Sprite.load("tests/fixtures/bmp_bad_magic.bmp")


def test_load_bmp_bad_dib_header_raises() raises -> None:
    with assert_raises(contains="DIB header"):
        _ = Sprite.load("tests/fixtures/bmp_bad_dib.bmp")


def test_load_bmp_bad_bpp_raises() raises -> None:
    with assert_raises(contains="24-bit or 32-bit"):
        _ = Sprite.load("tests/fixtures/bmp_bad_bpp.bmp")


def test_load_bmp_rle_compression_raises() raises -> None:
    with assert_raises(contains="Compressed BMP"):
        _ = Sprite.load("tests/fixtures/bmp_rle_compressed.bmp")


def test_load_bmp_bitfields_compression_raises() raises -> None:
    with assert_raises(contains="Compressed BMP"):
        _ = Sprite.load("tests/fixtures/bmp_bitfields_compressed.bmp")


def test_resize_dimensions() raises -> None:
    var s = Sprite.solid(4, 4, 255, 0, 0)
    s.resize(2, 2)
    assert_equal(s.width, 2)
    assert_equal(s.height, 2)
    assert_equal(len(s.pixels), 2 * 2 * 4)


def test_resize_preserves_color() raises -> None:
    var s = Sprite.solid(4, 4, 255, 0, 0)
    s.resize(2, 2)
    var ptr = s.pixels.unsafe_ptr()
    for i in range(4):  # 2×2 = 4 pixels
        var off = i * 4
        assert_equal(Int(ptr[unsafe_offset=off]),     255)  # R
        assert_equal(Int(ptr[unsafe_offset=off + 1]), 0)    # G
        assert_equal(Int(ptr[unsafe_offset=off + 2]), 0)    # B
        assert_equal(Int(ptr[unsafe_offset=off + 3]), 255)  # A


def test_resize_upscale() raises -> None:
    var s = Sprite.solid(2, 2, 0, 255, 0)
    s.resize(4, 4)
    assert_equal(s.width, 4)
    assert_equal(s.height, 4)
    assert_equal(len(s.pixels), 4 * 4 * 4)


def test_resize_to_1x1() raises -> None:
    var s = Sprite.solid(100, 100, 255, 255, 255)
    s.resize(1, 1)
    assert_equal(s.width, 1)
    assert_equal(s.height, 1)
    assert_equal(len(s.pixels), 4)


def test_solid_1x1() raises -> None:
    var s = Sprite.solid(1, 1, 0, 255, 0)
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
