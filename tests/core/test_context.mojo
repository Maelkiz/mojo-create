from std.testing import TestSuite, assert_equal, assert_almost_equal
from create.core.autoscale import AutoScale
from create.core.context import Context


def _design(w: Int, h: Int, mode: Int) raises -> Context:
    var ctx = Context()
    ctx.autoscale = mode
    ctx._design_w = w
    ctx._design_h = h
    return ctx^


def _fit(w: Int, h: Int) raises -> Context:
    return _design(w, h, AutoScale.FIT)


def _extend(w: Int, h: Int) raises -> Context:
    return _design(w, h, AutoScale.EXTEND)


def test_viewport_passthrough_without_autoscale() raises -> None:
    var ctx = Context()
    ctx._set_viewport(1024, 768)
    assert_equal(ctx.width, 1024)
    assert_equal(ctx.height, 768)
    assert_equal(ctx.scale, 1.0)
    assert_equal(ctx._offset_x, 0.0)
    assert_equal(ctx._offset_y, 0.0)


def test_fit_keeps_design_dimensions() raises -> None:
    var ctx = _fit(800, 600)
    ctx._set_viewport(1600, 1200)
    assert_equal(ctx.width, 800)
    assert_equal(ctx.height, 600)
    assert_equal(ctx.center.x, 400.0)
    assert_equal(ctx.center.y, 300.0)


def test_fit_uniform_scale_no_letterbox() raises -> None:
    var ctx = _fit(800, 600)
    ctx._set_viewport(1600, 1200)
    assert_equal(ctx.scale, 2.0)
    assert_equal(ctx._offset_x, 0.0)
    assert_equal(ctx._offset_y, 0.0)


def test_fit_letterboxes_wider_window() raises -> None:
    var ctx = _fit(800, 600)
    ctx._set_viewport(1600, 600)
    assert_equal(ctx.scale, 1.0)
    assert_equal(ctx._offset_x, 400.0)
    assert_equal(ctx._offset_y, 0.0)


def test_fit_letterboxes_taller_window() raises -> None:
    var ctx = _fit(800, 600)
    ctx._set_viewport(800, 1200)
    assert_equal(ctx.scale, 1.0)
    assert_equal(ctx._offset_x, 0.0)
    assert_equal(ctx._offset_y, 300.0)


def test_fit_shrinks_below_design_size() raises -> None:
    var ctx = _fit(800, 600)
    ctx._set_viewport(400, 300)
    assert_equal(ctx.scale, 0.5)


def test_extend_widens_world_instead_of_letterboxing() raises -> None:
    var ctx = _extend(800, 600)
    ctx._set_viewport(1600, 600)
    assert_equal(ctx.scale, 1.0)
    assert_equal(ctx.width, 1600)
    assert_equal(ctx.height, 600)
    assert_equal(ctx._offset_x, 0.0)
    assert_equal(ctx._offset_y, 0.0)
    assert_equal(ctx.center.x, 800.0)
    assert_equal(ctx.center.y, 300.0)


def test_extend_heightens_world_instead_of_letterboxing() raises -> None:
    var ctx = _extend(800, 600)
    ctx._set_viewport(800, 1200)
    assert_equal(ctx.scale, 1.0)
    assert_equal(ctx.width, 800)
    assert_equal(ctx.height, 1200)
    assert_equal(ctx._offset_x, 0.0)
    assert_equal(ctx._offset_y, 0.0)


def test_extend_matches_fit_when_aspect_matches() raises -> None:
    var ctx = _extend(800, 600)
    ctx._set_viewport(1600, 1200)
    assert_equal(ctx.scale, 2.0)
    assert_equal(ctx.width, 800)
    assert_equal(ctx.height, 600)


def test_extend_scale_is_still_the_fit_factor() raises -> None:
    # Height constrains: 700/600 < 1000/800. The design height survives the
    # round-trip through the scale, and the width picks up the slack.
    var ctx = _extend(800, 600)
    ctx._set_viewport(1000, 700)
    assert_almost_equal(ctx.scale, 700.0 / 600.0)
    assert_equal(ctx.height, 600)
    assert_equal(ctx.width, 857)


def test_to_design_is_identity_without_autoscale() raises -> None:
    var ctx = Context()
    ctx._set_viewport(1024, 768)
    var p = ctx.to_design(120.0, 40.0)
    assert_equal(p[0], 120.0)
    assert_equal(p[1], 40.0)


def test_to_design_maps_window_centre_to_design_centre() raises -> None:
    var ctx = _fit(800, 600)
    ctx._set_viewport(1600, 900)
    var p = ctx.to_design(800.0, 450.0)
    assert_almost_equal(p[0], 400.0)
    assert_almost_equal(p[1], 300.0)


def test_to_design_maps_letterboxed_corner_to_origin() raises -> None:
    var ctx = _fit(800, 600)
    ctx._set_viewport(1600, 600)
    var p = ctx.to_design(400.0, 0.0)
    assert_almost_equal(p[0], 0.0)
    assert_almost_equal(p[1], 0.0)


def test_to_design_under_extend_has_no_offset() raises -> None:
    var ctx = _extend(800, 600)
    ctx._set_viewport(1600, 1200)
    var origin = ctx.to_design(0.0, 0.0)
    assert_almost_equal(origin[0], 0.0)
    assert_almost_equal(origin[1], 0.0)
    var p = ctx.to_design(1200.0, 800.0)
    assert_almost_equal(p[0], 600.0)
    assert_almost_equal(p[1], 400.0)


def test_autoscale_ignored_before_design_size_known() raises -> None:
    var ctx = Context()
    ctx.autoscale = AutoScale.FIT
    ctx._set_viewport(1024, 768)
    assert_equal(ctx.width, 1024)
    assert_equal(ctx.scale, 1.0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
