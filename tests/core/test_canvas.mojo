# The rendering tests: draw through the real Canvas into an owned buffer and
# assert on the pixels that come out. Everything here runs headless, so the
# geometry conventions the library promises — centred origin, y up, centred
# shapes, source-over alpha — are checked rather than eyeballed.

from std.math import pi
from std.testing import TestSuite, assert_equal

from create.core import *
from create.core.headless import run_headless
from create.graphics.sprite import Sprite
from create.math.matrix import rotate


@fieldwise_init
struct Background(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> Background:
        return Background(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(10, 20, 30))


def test_background_fills_every_pixel() raises -> None:
    var m = run_headless[Background](16, 16)
    var want = Color(10, 20, 30)
    for y in range(16):
        for x in range(16):
            assert_equal(m.pixel(x, y), want)


@fieldwise_init
struct CentredRect(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> CentredRect:
        return CentredRect(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.no_stroke()
        canvas.fill(Color.RED)
        canvas.rect(0.0, 0.0, 20.0, 20.0)


def test_rect_is_centre_positioned() raises -> None:
    # A 20x20 rect at the origin covers pixels [40, 60) on both axes. If shapes
    # were top-left anchored like Processing's, it would sit in the corner.
    var m = run_headless[CentredRect](100, 100)
    assert_equal(m.pixel(50, 50), Color.RED)
    assert_equal(m.pixel(41, 41), Color.RED)
    assert_equal(m.pixel(58, 58), Color.RED)
    assert_equal(m.pixel(38, 38), Color.BLACK)
    assert_equal(m.pixel(61, 61), Color.BLACK)
    # The top-left corner, where a Processing-style rect would have landed.
    assert_equal(m.pixel(5, 5), Color.BLACK)


@fieldwise_init
struct HighRect(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> HighRect:
        return HighRect(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.no_stroke()
        canvas.fill(Color.GREEN)
        canvas.rect(0.0, 30.0, 10.0, 10.0)


def test_positive_y_draws_above_centre() raises -> None:
    # The load-bearing orientation test: world y grows upward, so +30 must land
    # in *lower*-numbered rows. Row 20 is 30 pixels above centre, row 80 is 30
    # below it — a y-down mapping would swap the two assertions.
    var m = run_headless[HighRect](100, 100)
    assert_equal(m.pixel(50, 20), Color.GREEN)
    assert_equal(m.pixel(50, 80), Color.BLACK)


@fieldwise_init
struct CentredCircle(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> CentredCircle:
        return CentredCircle(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.no_stroke()
        canvas.fill(Color.CYAN)
        canvas.circle(0.0, 0.0, 20.0)


def test_circle_is_centred_and_radial() raises -> None:
    var m = run_headless[CentredCircle](100, 100)
    assert_equal(m.pixel(50, 50), Color.CYAN)
    # Well inside the radius on each axis — y up means both rows are in.
    assert_equal(m.pixel(68, 50), Color.CYAN)
    assert_equal(m.pixel(50, 32), Color.CYAN)
    # Outside the radius, but inside the square that bounds it: the corner
    # catches a circle rasterised as a box.
    assert_equal(m.pixel(66, 66), Color.BLACK)
    assert_equal(m.pixel(75, 50), Color.BLACK)
    # And not anchored top-left.
    assert_equal(m.pixel(5, 5), Color.BLACK)


@fieldwise_init
struct UprightTriangle(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> UprightTriangle:
        return UprightTriangle(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.no_stroke()
        canvas.fill(Color.MAGENTA)
        # Apex up, base below — in world terms, since y grows upward.
        canvas.triangle(0.0, 30.0, -30.0, -30.0, 30.0, -30.0)


def test_triangle_fills_its_interior_only() raises -> None:
    var m = run_headless[UprightTriangle](100, 100)
    # Centroid, and a point low in the wide part of the triangle.
    assert_equal(m.pixel(50, 50), Color.MAGENTA)
    assert_equal(m.pixel(35, 70), Color.MAGENTA)
    # The apex is at the top of the buffer, so the upper corners are outside.
    assert_equal(m.pixel(25, 25), Color.BLACK)
    assert_equal(m.pixel(75, 25), Color.BLACK)
    # Below the base.
    assert_equal(m.pixel(50, 85), Color.BLACK)


@fieldwise_init
struct AlphaOverRed(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> AlphaOverRed:
        return AlphaOverRed(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.RED)
        canvas.no_stroke()
        canvas.fill(Color(0, 0, 255, 128))
        canvas.rect(0.0, 0.0, 40.0, 40.0)


def test_alpha_composites_source_over() raises -> None:
    var m = run_headless[AlphaOverRed](64, 64)
    assert_equal(m.pixel(32, 32), Color(0, 0, 255, 128).over(Color.RED))
    assert_equal(m.pixel(2, 2), Color.RED)


@fieldwise_init
struct ThickLine(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> ThickLine:
        return ThickLine(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.stroke(Color.WHITE)
        canvas.stroke_width(3)
        canvas.line(-10.0, 0.0, 10.0, 0.0)


def test_stroke_width_scales_to_pixels() raises -> None:
    # 50x50 design in a 100x100 buffer is a 2x scale, so a 3-unit stroke is 6
    # pixels thick: rows 47..52 around the centre row.
    var m = run_headless[ThickLine](50, 50, 1, 100, 100)
    for row in range(47, 53):
        assert_equal(m.pixel(50, row), Color.WHITE)
    assert_equal(m.pixel(50, 46), Color.BLACK)
    assert_equal(m.pixel(50, 53), Color.BLACK)


@fieldwise_init
struct FitBars(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> FitBars:
        return FitBars(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLUE)


@fieldwise_init
struct ExtendNoBars(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> ExtendNoBars:
        ctx.autoscale = AutoScale.EXTEND
        return ExtendNoBars(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLUE)


def test_fit_paints_letterbox_bars() raises -> None:
    # A 100x50 design in a 100x100 buffer scales by 1 and leaves 25 rows of bar
    # top and bottom, painted after render so they also clip the design area.
    var m = run_headless[FitBars](100, 50, 1, 100, 100)
    assert_equal(m.pixel(50, 5), Color(0x22))
    assert_equal(m.pixel(50, 95), Color(0x22))
    assert_equal(m.pixel(50, 50), Color.BLUE)


def test_extend_has_no_letterbox_bars() raises -> None:
    # Same shape under EXTEND: the world grows into the leftover instead.
    var m = run_headless[ExtendNoBars](100, 50, 1, 100, 100)
    assert_equal(m.pixel(50, 5), Color.BLUE)
    assert_equal(m.pixel(50, 95), Color.BLUE)


@fieldwise_init
struct RotatedRect(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> RotatedRect:
        return RotatedRect(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.no_stroke()
        canvas.fill(Color.YELLOW)
        with canvas.transform(rotate(pi / 4.0)):
            canvas.rect(0.0, 0.0, 20.0, 20.0)


def test_rotation_takes_the_inverse_mapped_path() raises -> None:
    # Rotating a square 45 degrees swaps which points are inside: the corners of
    # the axis-aligned box fall out, and the diagonal tips fall in.
    var m = run_headless[RotatedRect](100, 100)
    assert_equal(m.pixel(50, 50), Color.YELLOW)
    # World (0, 13) — outside the unrotated square, inside the rotated one.
    assert_equal(m.pixel(50, 37), Color.YELLOW)
    # World (-9, 9) — inside the unrotated square, outside the rotated one.
    assert_equal(m.pixel(41, 41), Color.BLACK)


struct SpriteBlit(Program):
    var sprite: Sprite

    def __init__(out self, var sprite: Sprite):
        self.sprite = sprite^

    @staticmethod
    def create(mut ctx: Context) raises -> SpriteBlit:
        return SpriteBlit(Sprite.load("tests/fixtures/test_2x2.bmp"))

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.sprite(self.sprite, 0.0, 0.0)


def test_sprite_blits_unflipped() raises -> None:
    # test_2x2.bmp: top-left red, top-right white, bottom-left blue, bottom-
    # right white. Sprites are not y-flipped — only their anchor is mapped — so
    # the image's top row stays on top.
    var m = run_headless[SpriteBlit](100, 100)
    assert_equal(m.pixel(49, 49), Color.RED)
    assert_equal(m.pixel(50, 49), Color.WHITE)
    assert_equal(m.pixel(49, 50), Color.BLUE)
    assert_equal(m.pixel(50, 50), Color.WHITE)


@fieldwise_init
struct StyleAcrossFrames(Program):
    # Frame 1 sets a style and draws nothing; frame 2 draws without setting
    # one. Style is per-frame, so frame 2 must get the defaults back.
    var frame: Int

    @staticmethod
    def create(mut ctx: Context) raises -> StyleAcrossFrames:
        return StyleAcrossFrames(0)

    def update(mut self, mut ctx: Context, input: Input) raises:
        self.frame = ctx.time.frame_count

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        if self.frame == 1:
            canvas.fill(Color.RED)
            canvas.no_stroke()
        else:
            canvas.rect((0, 0), 20, 20)


def test_style_does_not_survive_the_frame_boundary() raises -> None:
    # Only the last frame's buffer comes back, so red here would mean frame
    # 1's fill leaked forward.
    var m = run_headless[StyleAcrossFrames](100, 100, 2)
    assert_equal(m.pixel(50, 50), Color.WHITE)


@fieldwise_init
struct GuardedStyle(Program):
    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> GuardedStyle:
        return GuardedStyle(0)

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.no_stroke()
        canvas.fill(Color.RED)
        with canvas.style():
            canvas.fill(Color.BLUE)
            canvas.rect((-25, 0), 20, 20)
        canvas.rect((25, 0), 20, 20)


def test_style_guard_restores_on_scope_exit() raises -> None:
    var m = run_headless[GuardedStyle](100, 100)
    assert_equal(m.pixel(25, 50), Color.BLUE)
    assert_equal(m.pixel(75, 50), Color.RED)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
