from std.math import max, min, abs
from .color import Color
from .align import HAlign, VAlign
from .autoscale import AutoScale
from .font import Font
from .viewport import Viewport
from create.math.geometry import Rectangle, Circle, Line, Triangle
from create.math.vector2 import Vector2
from create.math.matrix import (
    Matrix,
    identity,
    inverse,
    apply as mat_apply,
)
from create.graphics.sprite import Sprite
from .style import Style
from .text import TextRenderer
from .surface import Surface
from .raster import (
    blend,
    blit_glyph,
    blit_sprite,
    fill_all,
    fill_pixels,
    fill_triangle,
    line_pixels,
)


struct CanvasState(Movable):
    """The part of a `Canvas` that outlives the frame it was drawn in.

    A `Canvas` is built fresh over each frame's framebuffer, so anything it
    must remember between frames — the loaded fonts — is moved out at the end
    of one frame and into the next. The transform stack and the style are
    deliberately absent: both start fresh every frame by construction, so a
    missing pop or a forgotten `no_stroke` cannot leak into the next frame.
    """

    var text: TextRenderer
    var letterbox: Color

    def __init__(out self):
        self.text = TextRenderer()
        self.letterbox = Color(0x22)


struct TransformGuard[surf_origin: Origin[mut=True], origin: Origin[mut=True]](
    Movable
):
    var _canvas: Pointer[Canvas[Self.surf_origin], Self.origin]

    def __init__(out self, ref[Self.origin] canvas: Canvas[Self.surf_origin]):
        self._canvas = Pointer(to=canvas)

    def __enter__(mut self):
        pass

    def __exit__(mut self):
        self._canvas[]._pop_transform()


struct StyleGuard[surf_origin: Origin[mut=True], origin: Origin[mut=True]](
    Movable
):
    """Restores the style the canvas had when the scope was entered.

    `Style` is a plain value, so the guard carries its own snapshot and no
    stack is needed — nesting works because each guard restores what it saw.
    """

    var _canvas: Pointer[Canvas[Self.surf_origin], Self.origin]
    var _saved: Style

    def __init__(out self, ref[Self.origin] canvas: Canvas[Self.surf_origin]):
        self._saved = canvas._style.copy()
        self._canvas = Pointer(to=canvas)

    def __enter__(mut self):
        pass

    def __exit__(mut self):
        self._canvas[]._style = self._saved.copy()


struct Canvas[origin: Origin[mut=True]]:
    """A drawing surface for one frame.

    Built fresh each frame over that frame's `Surface`, which is why it has
    exactly one parameter: `Program.render(self, mut canvas: Canvas)` infers
    it, so user code never spells the backend. State that must survive the
    frame goes in and out through `CanvasState`.
    """

    var width: Int
    var height: Int
    var autoscale: Int
    var scale: Float64
    var letterbox: Color
    var view: Viewport
    var _surf: Surface[Self.origin]
    var _state: CanvasState
    # Style is per-frame, not carried in `_state`: `Canvas` is only reachable
    # from `render`, so nothing can seed a style outside a frame and carrying
    # one across would only preserve a forgotten setting.
    var _style: Style
    var _base: Matrix[3, 3]
    var _base_inv: Matrix[3, 3]
    # `_user` is the composition of the matrices the program pushed, mapping
    # local coordinates to world. `_base` maps world to pixels. Drawing uses
    # the product; `to_world`/`to_local` use `_user` alone, so a program never
    # sees the pixel mapping it did not ask for.
    var _user: Matrix[3, 3]
    var _user_inv: Matrix[3, 3]
    var _transform: Matrix[3, 3]
    var _transform_inv: Matrix[3, 3]
    var _transform_stack: List[Matrix[3, 3]]

    def __init__(
        out self,
        surf: Surface[Self.origin],
        view: Viewport,
        var state: CanvasState,
    ):
        """Adopt this frame's framebuffer, mapping and carried-over state."""
        self._surf = surf
        self.view = view.copy()
        self.width = view.width
        self.height = view.height
        self.autoscale = view.autoscale
        self.scale = view.scale
        self.letterbox = state.letterbox
        self._state = state^
        self._style = Style()
        self._base = view.base_matrix()
        self._base_inv = inverse(self._base)
        # The stack starts empty, so the base mapping is the current transform;
        # user transforms compose on top of it.
        self._user = identity[3]()
        self._user_inv = identity[3]()
        self._transform = self._base
        self._transform_inv = self._base_inv
        self._transform_stack = List[Matrix[3, 3]]()

    def _release(deinit self) -> CanvasState:
        """Hand back the state the next frame's `Canvas` should start from.

        Consumes the canvas, so the borrow on the framebuffer ends here — the
        run loop cannot present while a `Canvas` is still alive.
        """
        var state = self._state^
        state.letterbox = self.letterbox
        return state^

    def left(self) -> Float64:
        """World x of the left edge — negative, since the origin is centred."""
        return self.view.left()

    def right(self) -> Float64:
        return self.view.right()

    def bottom(self) -> Float64:
        """World y of the bottom edge — negative, since y grows upward."""
        return self.view.bottom()

    def top(self) -> Float64:
        return self.view.top()

    def _fill_pixels(mut self, x0: Int, y0: Int, x1: Int, y1: Int, c: Color):
        fill_pixels(self._surf, x0, y0, x1, y1, c)

    def _draw_letterbox(mut self):
        """Paint the window area outside the design bounds.

        Runs after render, so it doubles as the clip for anything drawn past
        the edges of the design area. Nothing to do under `AutoScale.EXTEND`:
        the design covers the whole frame, so there is neither a bar to paint
        nor an out-of-bounds region to clip — and rounding the extended size
        could otherwise leave a one-pixel seam along an edge.
        """
        if not self.view.scaled() or self.autoscale == AutoScale.EXTEND:
            return
        var W = self._surf.width
        var H = self._surf.height
        var cx0 = Int(self.view.offset_x)
        var cy0 = Int(self.view.offset_y)
        var cx1 = Int(
            self.view.offset_x + Float64(self.width) * self.scale + 0.5
        )
        var cy1 = Int(
            self.view.offset_y + Float64(self.height) * self.scale + 0.5
        )
        var c = self.letterbox
        if cy0 > 0:
            self._fill_pixels(0, 0, W, cy0, c)
        if cy1 < H:
            self._fill_pixels(0, cy1, W, H, c)
        if cx0 > 0:
            self._fill_pixels(0, cy0, cx0, cy1, c)
        if cx1 < W:
            self._fill_pixels(cx1, cy0, W, cy1, c)

    def _uniform(self) -> Bool:
        """True when the transform is an axis-aligned uniform scale plus a
        translation — a rect stays a rect, a circle stays a circle.

        The base mapping alone qualifies (it scales by `s` and `-s`), so plain
        drawing keeps the integer raster paths even under autoscale. Only
        rotation, shear, and non-uniform scales fall through to the per-pixel
        inverse mapping.
        """
        var m = self._transform
        return (
            m[0, 1] == 0.0
            and m[1, 0] == 0.0
            and m[2, 0] == 0.0
            and m[2, 1] == 0.0
            and m[2, 2] == 1.0
            and abs(m[0, 0]) == abs(m[1, 1])
        )

    def _pixel_scale(self) -> Float64:
        """World units per pixel along the current transform.

        Stroke width, font size, and sprite extents are authored in world units
        but rasterised in pixels, so they all scale by this. Falls back to the
        autoscale factor when the transform is not uniform and no single factor
        exists.
        """
        if self._uniform():
            return abs(self._transform[0, 0])
        return self.scale

    def transform(
        mut self, m: Matrix[3, 3]
    ) -> TransformGuard[Self.origin, origin_of(self)]:
        self._push_transform(m)
        return TransformGuard[Self.origin, origin_of(self)](self)

    def style(mut self) -> StyleGuard[Self.origin, origin_of(self)]:
        """Scope the fill, stroke and font settings to a `with` block.

        For helpers that set style before drawing: without this, a callee's
        `no_stroke()` silently applies to whatever the caller draws next.
        """
        return StyleGuard[Self.origin, origin_of(self)](self)

    def _push_transform(mut self, m: Matrix[3, 3]):
        # Parent first, then child: a point is mapped by the innermost matrix
        # before the ones it nests inside. Composing the other way round would
        # apply the outer transform last, so a nested translate would move in
        # the frame of its own children rather than its parent's.
        self._transform_stack.append(self._user)
        self._user = self._user @ m
        self._sync_transform()

    def _pop_transform(mut self):
        if len(self._transform_stack) > 0:
            self._user = self._transform_stack.pop()
            self._sync_transform()

    def _sync_transform(mut self):
        self._user_inv = inverse(self._user)
        self._transform = self._base @ self._user
        self._transform_inv = self._user_inv @ self._base_inv

    def to_world(self, x: Float64, y: Float64) -> Tuple[Float64, Float64]:
        """Map a point from the current transform's frame into world space."""
        return mat_apply(self._user, x, y)

    def to_local(self, x: Float64, y: Float64) -> Tuple[Float64, Float64]:
        """Map a world-space point — a mouse position, say — into the current
        transform's frame."""
        return mat_apply(self._user_inv, x, y)

    def _stroke_width_px(self) -> Int:
        """Stroke width in framebuffer pixels, never thinner than one."""
        return max(
            Int(Float64(self._style.stroke_width) * self._pixel_scale() + 0.5),
            1,
        )

    def _line_pixels(
        mut self, x0: Float64, y0: Float64, x1: Float64, y1: Float64
    ):
        line_pixels(
            self._surf,
            x0,
            y0,
            x1,
            y1,
            self._style.stroke,
            self._stroke_width_px(),
        )

    def fill(mut self, color: Color):
        self._style.fill = color
        self._style.fill_enabled = True

    def no_fill(mut self):
        self._style.fill_enabled = False

    def stroke(mut self, color: Color):
        self._style.stroke = color
        self._style.stroke_enabled = True

    def no_stroke(mut self):
        self._style.stroke_enabled = False

    def stroke_width(mut self, w: Int):
        self._style.stroke_width = w

    def background(mut self, color: Color):
        fill_all(self._surf, color)

    def rect(mut self, x: Float64, y: Float64, w: Float64, h: Float64):
        var surf = self._surf
        var W = surf.width
        var H = surf.height
        var lx0 = x - w / 2.0
        var ly0 = y - h / 2.0
        var lx1 = x + w / 2.0
        var ly1 = y + h / 2.0

        if self._uniform():
            # Axis-aligned: map the two opposite corners and order them, since
            # the y flip in the base mapping sends the smaller world y to the
            # larger pixel row.
            var p0 = mat_apply(self._transform, lx0, ly0)
            var p1 = mat_apply(self._transform, lx1, ly1)
            var x0 = Int(min(p0[0], p1[0]))
            var y0 = Int(min(p0[1], p1[1]))
            var iw = Int(abs(p1[0] - p0[0]))
            var ih = Int(abs(p1[1] - p0[1]))
            if self._style.fill_enabled:
                fill_pixels(surf, x0, y0, x0 + iw, y0 + ih, self._style.fill)
            if self._style.stroke_enabled:
                var sw = self._stroke_width_px()
                var c = self._style.stroke
                fill_pixels(surf, x0, y0, x0 + iw, y0 + sw, c)
                fill_pixels(surf, x0, y0 + ih - sw, x0 + iw, y0 + ih, c)
                fill_pixels(surf, x0, y0 + sw, x0 + sw, y0 + ih - sw, c)
                fill_pixels(
                    surf, x0 + iw - sw, y0 + sw, x0 + iw, y0 + ih - sw, c
                )
        else:
            var c0 = mat_apply(self._transform, lx0, ly0)
            var c1 = mat_apply(self._transform, lx1, ly0)
            var c2 = mat_apply(self._transform, lx1, ly1)
            var c3 = mat_apply(self._transform, lx0, ly1)
            var sx_min = max(Int(min(min(c0[0], c1[0]), min(c2[0], c3[0]))), 0)
            var sx_max = min(
                Int(max(max(c0[0], c1[0]), max(c2[0], c3[0]))) + 1, W
            )
            var sy_min = max(Int(min(min(c0[1], c1[1]), min(c2[1], c3[1]))), 0)
            var sy_max = min(
                Int(max(max(c0[1], c1[1]), max(c2[1], c3[1]))) + 1, H
            )
            var sw_f = Float64(self._style.stroke_width)
            for row in range(sy_min, sy_max):
                for col in range(sx_min, sx_max):
                    var local = mat_apply(
                        self._transform_inv, Float64(col), Float64(row)
                    )
                    var lx = local[0]
                    var ly = local[1]
                    if lx < lx0 or lx > lx1 or ly < ly0 or ly > ly1:
                        continue
                    var off = (row * W + col) * 4
                    var in_inner = (
                        lx >= lx0 + sw_f
                        and lx <= lx1 - sw_f
                        and ly >= ly0 + sw_f
                        and ly <= ly1 - sw_f
                    )
                    if self._style.fill_enabled and (
                        not self._style.stroke_enabled or in_inner
                    ):
                        blend(surf, off, self._style.fill)
                    elif self._style.stroke_enabled and not in_inner:
                        blend(surf, off, self._style.stroke)

    def circle(mut self, cx: Float64, cy: Float64, r: Float64):
        var surf = self._surf
        var W = surf.width
        var H = surf.height
        var r2 = r * r
        var r_inner = r - Float64(self._style.stroke_width)
        var r_inner2 = r_inner * r_inner

        if self._uniform():
            # A uniform scale keeps a circle a circle, so it stays a distance
            # test — just in pixels rather than world units.
            var p = mat_apply(self._transform, cx, cy)
            var pcx = p[0]
            var pcy = p[1]
            var pr = r * self._pixel_scale()
            var pr2 = pr * pr
            var pr_inner = pr - Float64(self._stroke_width_px())
            var pr_inner2 = pr_inner * pr_inner
            var x0 = max(Int(pcx - pr), 0)
            var y0 = max(Int(pcy - pr), 0)
            var x1 = min(Int(pcx + pr) + 1, W)
            var y1 = min(Int(pcy + pr) + 1, H)
            for row in range(y0, y1):
                var dy = Float64(row) - pcy
                for col in range(x0, x1):
                    var dx = Float64(col) - pcx
                    var d2 = dx * dx + dy * dy
                    if d2 <= pr2:
                        var off = (row * W + col) * 4
                        if self._style.fill_enabled and (
                            not self._style.stroke_enabled
                            or pr_inner <= 0.0
                            or d2 <= pr_inner2
                        ):
                            blend(surf, off, self._style.fill)
                        elif self._style.stroke_enabled and d2 > pr_inner2:
                            blend(surf, off, self._style.stroke)
        else:
            # The scan bounds must come from the bounding square's corners,
            # not its edge midpoints: under a rotation the midpoints are no
            # longer the extremes, and using them clips the circle.
            var p0 = mat_apply(self._transform, cx - r, cy - r)
            var p1 = mat_apply(self._transform, cx + r, cy - r)
            var p2 = mat_apply(self._transform, cx + r, cy + r)
            var p3 = mat_apply(self._transform, cx - r, cy + r)
            var sx_min = max(Int(min(min(p0[0], p1[0]), min(p2[0], p3[0]))), 0)
            var sx_max = min(
                Int(max(max(p0[0], p1[0]), max(p2[0], p3[0]))) + 1, W
            )
            var sy_min = max(Int(min(min(p0[1], p1[1]), min(p2[1], p3[1]))), 0)
            var sy_max = min(
                Int(max(max(p0[1], p1[1]), max(p2[1], p3[1]))) + 1, H
            )
            for row in range(sy_min, sy_max):
                for col in range(sx_min, sx_max):
                    var local = mat_apply(
                        self._transform_inv, Float64(col), Float64(row)
                    )
                    var dx = local[0] - cx
                    var dy = local[1] - cy
                    var d2 = dx * dx + dy * dy
                    if d2 <= r2:
                        var off = (row * W + col) * 4
                        if self._style.fill_enabled and (
                            not self._style.stroke_enabled
                            or r_inner <= 0.0
                            or d2 <= r_inner2
                        ):
                            blend(surf, off, self._style.fill)
                        elif self._style.stroke_enabled and d2 > r_inner2:
                            blend(surf, off, self._style.stroke)

    def line(mut self, x0: Float64, y0: Float64, x1: Float64, y1: Float64):
        if not self._style.stroke_enabled:
            return
        var p0 = mat_apply(self._transform, x0, y0)
        var p1 = mat_apply(self._transform, x1, y1)
        self._line_pixels(p0[0], p0[1], p1[0], p1[1])

    def triangle(
        mut self,
        x1: Float64,
        y1: Float64,
        x2: Float64,
        y2: Float64,
        x3: Float64,
        y3: Float64,
    ):
        var p1 = mat_apply(self._transform, x1, y1)
        var p2 = mat_apply(self._transform, x2, y2)
        var p3 = mat_apply(self._transform, x3, y3)
        var sx1 = p1[0]
        var sy1 = p1[1]
        var sx2 = p2[0]
        var sy2 = p2[1]
        var sx3 = p3[0]
        var sy3 = p3[1]
        if self._style.fill_enabled:
            fill_triangle(
                self._surf, sx1, sy1, sx2, sy2, sx3, sy3, self._style.fill
            )
        if self._style.stroke_enabled:
            self._line_pixels(sx1, sy1, sx2, sy2)
            self._line_pixels(sx2, sy2, sx3, sy3)
            self._line_pixels(sx3, sy3, sx1, sy1)

    def rect(mut self, x: Int, y: Int, w: Int, h: Int):
        self.rect(Float64(x), Float64(y), Float64(w), Float64(h))

    def circle(mut self, cx: Int, cy: Int, r: Int):
        self.circle(Float64(cx), Float64(cy), Float64(r))

    def line(mut self, x0: Int, y0: Int, x1: Int, y1: Int):
        self.line(Float64(x0), Float64(y0), Float64(x1), Float64(y1))

    def triangle(
        mut self, x1: Int, y1: Int, x2: Int, y2: Int, x3: Int, y3: Int
    ):
        self.triangle(
            Float64(x1),
            Float64(y1),
            Float64(x2),
            Float64(y2),
            Float64(x3),
            Float64(y3),
        )

    def rect(mut self, r: Rectangle):
        self.rect(r.x, r.y, r.w, r.h)

    def rect(mut self, pos: Vector2, w: Float64, h: Float64):
        self.rect(pos.x, pos.y, w, h)

    def rect(mut self, pos: Vector2, size: Vector2):
        self.rect(pos.x, pos.y, size.x, size.y)

    def circle(mut self, c: Circle):
        self.circle(c.x, c.y, c.r)

    def circle(mut self, pos: Vector2, r: Float64):
        self.circle(pos.x, pos.y, r)

    def circle(mut self, pos: Vector2, r: Int):
        self.circle(pos.x, pos.y, Float64(r))

    def line(mut self, l: Line):
        self.line(l.x0, l.y0, l.x1, l.y1)

    def line(mut self, start: Vector2, end: Vector2):
        self.line(start.x, start.y, end.x, end.y)

    def triangle(mut self, t: Triangle):
        self.triangle(t.x1, t.y1, t.x2, t.y2, t.x3, t.y3)

    def triangle(mut self, a: Vector2, b: Vector2, c: Vector2):
        self.triangle(a.x, a.y, b.x, b.y, c.x, c.y)

    def sprite(mut self, s: Sprite, cx: Int, cy: Int):
        self.sprite(s, Float64(cx), Float64(cy))

    def sprite(mut self, s: Sprite, cx: Float64, cy: Float64):
        # One sprite pixel per framebuffer pixel — worth a dedicated blit, but
        # only while nothing resizes it. Anything else goes through the sized
        # overload, which resamples.
        if not self._uniform() or self._pixel_scale() != 1.0:
            self.sprite(s, cx, cy, s.width, s.height)
            return
        var p = mat_apply(self._transform, cx, cy)
        blit_sprite(
            self._surf,
            s,
            Int(p[0]) - s.width // 2,
            Int(p[1]) - s.height // 2,
            s.width,
            s.height,
        )

    def sprite(mut self, s: Sprite, pos: Vector2):
        self.sprite(s, pos.x, pos.y)

    def sprite(mut self, s: Sprite, cx: Float64, cy: Float64, w: Int, h: Int):
        # Rotation and shear are not resampled — only position and scale apply.
        var p = mat_apply(self._transform, cx, cy)
        var sf = self._pixel_scale()
        var dw = max(Int(Float64(w) * sf + 0.5), 1)
        var dh = max(Int(Float64(h) * sf + 0.5), 1)
        blit_sprite(
            self._surf,
            s,
            Int(p[0]) - dw // 2,
            Int(p[1]) - dh // 2,
            dw,
            dh,
        )

    def sprite(mut self, s: Sprite, cx: Int, cy: Int, w: Int, h: Int):
        self.sprite(s, Float64(cx), Float64(cy), w, h)

    def sprite(mut self, s: Sprite, pos: Vector2, w: Int, h: Int):
        self.sprite(s, pos.x, pos.y, w, h)

    def font_size(mut self, size: Int):
        self._style.font_size = size

    def font_weight(mut self, weight: Int):
        self._style.font_weight = weight

    def text_align(mut self, halign: HAlign):
        """Anchor the next text horizontally.

        The argument's type picks the axis, so both are set through one verb:
        `text_align(HAlign.CENTER)`, `text_align(VAlign.MIDDLE)`, or both at
        once. `VAlign.TOP`/`MIDDLE`/`BOTTOM` are edges of the text box, not
        typographic baselines.
        """
        self._style.text_halign = halign

    def text_align(mut self, valign: VAlign):
        self._style.text_valign = valign

    def text_align(mut self, halign: HAlign, valign: VAlign):
        self._style.text_halign = halign
        self._style.text_valign = valign

    def text(mut self, s: String, x: Int, y: Int) raises:
        self.text(s, Float64(x), Float64(y))

    def text(mut self, s: String, pos: Vector2) raises:
        self.text(s, pos.x, pos.y)

    def font(mut self, var f: Font):
        self._state.text.set_font(f^)

    def text(mut self, s: String, x: Float64, y: Float64) raises:
        if not self._style.fill_enabled:
            return
        # Only the anchor is mapped — the layout itself happens in pixel space.
        var p = mat_apply(self._transform, x, y)
        var surf = self._surf
        var scale = self._pixel_scale()
        self._state.text.draw(surf, s, p[0], p[1], self._style, scale)
