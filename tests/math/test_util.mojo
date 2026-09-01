from std.testing import TestSuite, assert_equal, assert_almost_equal, assert_true
from create.math.util import lerp, map, norm, smoothstep, sign, fract, fmod, degrees, radians
from std.math import pi


def test_lerp_start() raises -> None:
    assert_equal(lerp(0.0, 10.0, 0.0), 0.0)


def test_lerp_end() raises -> None:
    assert_equal(lerp(0.0, 10.0, 1.0), 10.0)


def test_lerp_midpoint() raises -> None:
    assert_equal(lerp(0.0, 10.0, 0.5), 5.0)


def test_lerp_negative_range() raises -> None:
    assert_equal(lerp(-10.0, 10.0, 0.5), 0.0)


def test_lerp_extrapolates() raises -> None:
    assert_equal(lerp(0.0, 10.0, 2.0), 20.0)


def test_map_low() raises -> None:
    assert_equal(map(0.0, 0.0, 10.0, 0.0, 100.0), 0.0)


def test_map_high() raises -> None:
    assert_equal(map(10.0, 0.0, 10.0, 0.0, 100.0), 100.0)


def test_map_midpoint() raises -> None:
    assert_equal(map(5.0, 0.0, 10.0, 0.0, 100.0), 50.0)


def test_map_different_ranges() raises -> None:
    assert_equal(map(1.0, 0.0, 4.0, 0.0, 1.0), 0.25)


def test_map_inverted_output() raises -> None:
    assert_equal(map(0.0, 0.0, 1.0, 1.0, 0.0), 1.0)
    assert_equal(map(1.0, 0.0, 1.0, 1.0, 0.0), 0.0)


def test_norm_low() raises -> None:
    assert_equal(norm(0.0, 0.0, 10.0), 0.0)


def test_norm_high() raises -> None:
    assert_equal(norm(10.0, 0.0, 10.0), 1.0)


def test_norm_mid() raises -> None:
    assert_equal(norm(5.0, 0.0, 10.0), 0.5)


def test_smoothstep_below_edge0() raises -> None:
    assert_equal(smoothstep(0.0, 1.0, -1.0), 0.0)


def test_smoothstep_above_edge1() raises -> None:
    assert_equal(smoothstep(0.0, 1.0, 2.0), 1.0)


def test_smoothstep_at_edges() raises -> None:
    assert_equal(smoothstep(0.0, 1.0, 0.0), 0.0)
    assert_equal(smoothstep(0.0, 1.0, 1.0), 1.0)


def test_smoothstep_midpoint() raises -> None:
    assert_equal(smoothstep(0.0, 1.0, 0.5), 0.5)


def test_smoothstep_is_smooth() raises -> None:
    # smoothstep should be monotonically increasing
    var prev = smoothstep(0.0, 1.0, 0.0)
    for i in range(1, 11):
        var cur = smoothstep(0.0, 1.0, Float64(i) / 10.0)
        assert_true(cur >= prev)
        prev = cur


def test_sign_positive() raises -> None:
    assert_equal(sign(5.0), 1.0)
    assert_equal(sign(0.001), 1.0)


def test_sign_negative() raises -> None:
    assert_equal(sign(-3.0), -1.0)


def test_sign_zero() raises -> None:
    assert_equal(sign(0.0), 0.0)


def test_fract_positive() raises -> None:
    assert_almost_equal(fract(3.75), 0.75, atol=1e-12)
    assert_almost_equal(fract(1.0), 0.0, atol=1e-12)


def test_fract_negative() raises -> None:
    # fract(-0.25) = -0.25 - floor(-0.25) = -0.25 - (-1) = 0.75
    assert_almost_equal(fract(-0.25), 0.75, atol=1e-12)


def test_fmod_basic() raises -> None:
    assert_almost_equal(fmod(7.0, 3.0), 1.0, atol=1e-12)
    assert_almost_equal(fmod(6.0, 3.0), 0.0, atol=1e-12)


def test_degrees_from_radians() raises -> None:
    assert_almost_equal(degrees(pi), 180.0, atol=1e-9)
    assert_almost_equal(degrees(0.0), 0.0, atol=1e-12)


def test_radians_from_degrees() raises -> None:
    assert_almost_equal(radians(180.0), pi, atol=1e-12)
    assert_almost_equal(radians(0.0), 0.0, atol=1e-12)


def test_degrees_radians_roundtrip() raises -> None:
    assert_almost_equal(degrees(radians(90.0)), 90.0, atol=1e-9)
    assert_almost_equal(radians(degrees(1.0)), 1.0, atol=1e-9)


def test_fmod_negative_numerator() raises -> None:
    # floor(-1/3) = -1, so -1 - (-1)*3 = 2
    assert_almost_equal(fmod(-1.0, 3.0), 2.0, atol=1e-12)


def test_fmod_negative_large() raises -> None:
    # floor(-7/3) = -3, so -7 - (-3)*3 = 2
    assert_almost_equal(fmod(-7.0, 3.0), 2.0, atol=1e-12)


def test_lerp_out_of_range_extrapolates_below() raises -> None:
    assert_equal(lerp(0.0, 10.0, -1.0), -10.0)


def test_map_extrapolates_outside_input() raises -> None:
    # value outside [in_low, in_high] extrapolates linearly
    assert_almost_equal(map(15.0, 0.0, 10.0, 0.0, 100.0), 150.0, atol=1e-9)


def test_norm_outside_range() raises -> None:
    assert_almost_equal(norm(-5.0, 0.0, 10.0), -0.5, atol=1e-12)
    assert_almost_equal(norm(15.0, 0.0, 10.0), 1.5, atol=1e-12)


def test_fract_at_integer() raises -> None:
    assert_almost_equal(fract(5.0), 0.0, atol=1e-12)
    assert_almost_equal(fract(0.0), 0.0, atol=1e-12)


def test_degrees_quarter_turn() raises -> None:
    assert_almost_equal(degrees(pi / 2.0), 90.0, atol=1e-9)


def test_radians_quarter_turn() raises -> None:
    from std.math import pi as PI
    assert_almost_equal(radians(90.0), PI / 2.0, atol=1e-12)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
