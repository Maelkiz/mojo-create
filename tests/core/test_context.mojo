from std.testing import TestSuite, assert_equal, assert_almost_equal
from create.core.context import Context


def _design(w: Int, h: Int) raises -> Context:
    var ctx = Context()
    ctx.autoscale = True
    ctx._design_w = w
    ctx._design_h = h
    return ctx^


def test_viewport_passthrough_without_autoscale() raises -> None:
    var ctx = Context()
    ctx._set_viewport(1024, 768)
    assert_equal(ctx.width, 1024)
    assert_equal(ctx.height, 768)
    assert_equal(ctx.scale, 1.0)
    assert_equal(ctx._offset_x, 0.0)
    assert_equal(ctx._offset_y, 0.0)


def test_autoscale_keeps_design_dimensions() raises -> None:
    var ctx = _design(800, 600)
    ctx._set_viewport(1600, 1200)
    assert_equal(ctx.width, 800)
    assert_equal(ctx.height, 600)
    assert_equal(ctx.center.x, 400.0)
    assert_equal(ctx.center.y, 300.0)


def test_autoscale_uniform_scale_no_letterbox() raises -> None:
    var ctx = _design(800, 600)
    ctx._set_viewport(1600, 1200)
    assert_equal(ctx.scale, 2.0)
    assert_equal(ctx._offset_x, 0.0)
    assert_equal(ctx._offset_y, 0.0)


def test_autoscale_letterboxes_wider_window() raises -> None:
    var ctx = _design(800, 600)
    ctx._set_viewport(1600, 600)
    assert_equal(ctx.scale, 1.0)
    assert_equal(ctx._offset_x, 400.0)
    assert_equal(ctx._offset_y, 0.0)


def test_autoscale_letterboxes_taller_window() raises -> None:
    var ctx = _design(800, 600)
    ctx._set_viewport(800, 1200)
    assert_equal(ctx.scale, 1.0)
    assert_equal(ctx._offset_x, 0.0)
    assert_equal(ctx._offset_y, 300.0)


def test_autoscale_shrinks_below_design_size() raises -> None:
    var ctx = _design(800, 600)
    ctx._set_viewport(400, 300)
    assert_equal(ctx.scale, 0.5)


def test_to_design_is_identity_without_autoscale() raises -> None:
    var ctx = Context()
    ctx._set_viewport(1024, 768)
    var p = ctx.to_design(120.0, 40.0)
    assert_equal(p[0], 120.0)
    assert_equal(p[1], 40.0)


def test_to_design_maps_window_centre_to_design_centre() raises -> None:
    var ctx = _design(800, 600)
    ctx._set_viewport(1600, 900)
    var p = ctx.to_design(800.0, 450.0)
    assert_almost_equal(p[0], 400.0)
    assert_almost_equal(p[1], 300.0)


def test_to_design_maps_letterboxed_corner_to_origin() raises -> None:
    var ctx = _design(800, 600)
    ctx._set_viewport(1600, 600)
    var p = ctx.to_design(400.0, 0.0)
    assert_almost_equal(p[0], 0.0)
    assert_almost_equal(p[1], 0.0)


def test_autoscale_ignored_before_design_size_known() raises -> None:
    var ctx = Context()
    ctx.autoscale = True
    ctx._set_viewport(1024, 768)
    assert_equal(ctx.width, 1024)
    assert_equal(ctx.scale, 1.0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
