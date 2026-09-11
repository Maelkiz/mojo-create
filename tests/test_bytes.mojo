from std.testing import TestSuite, assert_equal
from create.bytes import le_uint, sign_extend_32


def test_le_uint_two_bytes() raises -> None:
    var data: List[UInt8] = [0x34, 0x12]
    assert_equal(le_uint(data.unsafe_ptr(), 0, 2), 0x1234)


def test_le_uint_four_bytes() raises -> None:
    var data: List[UInt8] = [0x78, 0x56, 0x34, 0x12]
    assert_equal(le_uint(data.unsafe_ptr(), 0, 4), 0x12345678)


def test_le_uint_eight_bytes() raises -> None:
    # Eight bytes is the pointer-sized read the freetype struct walk needs.
    var data: List[UInt8] = [0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01]
    assert_equal(le_uint(data.unsafe_ptr(), 0, 8), 0x0123456789ABCDEF)


def test_le_uint_honours_the_offset() raises -> None:
    var data: List[UInt8] = [0xFF, 0xFF, 0x78, 0x56, 0x34, 0x12]
    assert_equal(le_uint(data.unsafe_ptr(), 2, 4), 0x12345678)


def test_le_uint_is_unsigned_at_the_top_bit() raises -> None:
    # The whole point of keeping sign extension separate: a 4-byte read with
    # the high bit set stays positive until someone asks for it to be signed.
    var data: List[UInt8] = [0x00, 0x00, 0x00, 0x80]
    assert_equal(le_uint(data.unsafe_ptr(), 0, 4), 0x80000000)


def test_le_uint_zero_count_is_zero() raises -> None:
    var data: List[UInt8] = [0xFF, 0xFF]
    assert_equal(le_uint(data.unsafe_ptr(), 0, 0), 0)


def test_sign_extend_32_leaves_positive_values_alone() raises -> None:
    assert_equal(sign_extend_32(0), 0)
    assert_equal(sign_extend_32(1), 1)
    assert_equal(sign_extend_32(0x7FFFFFFF), 0x7FFFFFFF)


def test_sign_extend_32_flips_at_the_boundary() raises -> None:
    # 0x7FFFFFFF is the largest positive; the very next value is the most
    # negative. A BMP's negative height (top-down rows) lands in this range.
    assert_equal(sign_extend_32(0x80000000), -2147483648)
    assert_equal(sign_extend_32(0xFFFFFFFF), -1)
    assert_equal(sign_extend_32(0xFFFFFFF6), -10)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
