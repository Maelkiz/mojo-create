from .color import Color
from .align import HorizontalAlignment, VerticalAlignment
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
from create.sprite.sprite import Sprite
from create.sprite.animator import SpriteAnimator
from ._backend import Backend
from ._command import (
    circle_command,
    clear_command,
    letterbox_command,
    line_command,
    rect_command,
    sprite_command,
    text_command,
    triangle_command,
)
from ._style import Style
from .surface import Surface


struct PersistentCanvasState(Movable):
    """The part of a `Canvas` that outlives the frame it was drawn in.

    A `Canvas` is built fresh over each frame's framebuffer, so anything it
    must remember between frames — the backend, and through it the loaded
    fonts, the glyph cache and the interned sprite images — is moved out at the
    end of one frame and into the next. The transform stack and the style are
    deliberately absent: both start fresh every frame by construction, so a
    missing pop or a forgotten `no_stroke` cannot leak into the next frame.
    """

    var backend: Backend
    var letterbox: Color

    def __init__(out self):
        self.backend = Backend()
        self.letterbox = Color(0x22)


struct TransformGuard[surf_origin: Origin[mut=True], origin: Origin[mut=True]](
    Movable
):
    """Pops the matrix `canvas.transform` pushed, on scope exit."""

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
    frame goes in and out through `PersistentCanvasState`.

    Rebuilding is also the only way to point at a new framebuffer. Handing an
    existing `Canvas` a fresh `Surface` does not compile -- the type embeds the
    window's pixel origin, so a `canvas._sync(Surface(win.pixels(), ...))` call
    is a second mutable path to the same window:

        error: aliasing values passed mutably to 'self' argument and passed
        mutably to 's' argument in '_sync' call

    Origin erasure would sidestep it, but `MutableAnyOrigin` is not a known
    declaration in this Mojo version. `__init__` takes `out self`, so there is
    no existing borrow to alias against. Don't reach for the `_sync` shape.

    A draw call touches no pixels: it appends a `DrawCommand` to the backend's
    recording, and the backend replays the whole frame afterwards. So a
    `Canvas` is a recorder, and the geometry it records is *local* — the shape
    as the program asked for it, paired with the current transform — never
    device pixels. A style is resolved at record time, so a later `fill()`
    cannot reach back and change what an earlier command paints.

    Every pixel write blends source-over, so a fill, stroke, sprite, glyph or
    `background` with `a < 255` composites with what is already there.
    """

    var width: Int
    var height: Int
    var autoscale: Int
    var scale: Float64
    var letterbox: Color
    var view: Viewport
    var _surf: Surface[Self.origin]
    var _state: PersistentCanvasState
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
        var state: PersistentCanvasState,
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

    def _release(deinit self) -> PersistentCanvasState:
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

    def _draw_letterbox(mut self):
        """Record the window area outside the design bounds.

        Runs after render, so it doubles as the clip for anything drawn past
        the edges of the design area. Nothing to do under `AutoScale.EXTEND`:
        the design covers the whole frame, so there is neither a bar to paint
        nor an out-of-bounds region to clip — and rounding the extended size
        could otherwise leave a one-pixel seam along an edge.

        The one command whose geometry is already in device pixels: it is the
        frame's clip rather than something the program drew, so no transform
        applies to it.
        """
        if not self.view.scaled() or self.autoscale == AutoScale.EXTEND:
            return
        var cx0 = Float64(Int(self.view.offset_x))
        var cy0 = Float64(Int(self.view.offset_y))
        var cx1 = Float64(
            Int(self.view.offset_x + Float64(self.width) * self.scale + 0.5)
        )
        var cy1 = Float64(
            Int(self.view.offset_y + Float64(self.height) * self.scale + 0.5)
        )
        self._state.backend.record(
            letterbox_command(self.letterbox, cx0, cy0, cx1, cy1)
        )

    # `_uniform`, `_pixel_scale`, `_device_bounds` and `_stroke_width_px` used
    # to live here. They are properties of a matrix, not of a canvas, and only
    # the replay needs them now — see `_backend.mojo`.

    def transform(
        mut self, m: Matrix[3, 3]
    ) -> TransformGuard[Self.origin, origin_of(self)]:
        """Apply `m` to everything drawn inside a `with` block.

        ```mojo
        with canvas.transform(translate(50.0, 50.0)):
            canvas.rectangle((0, 0), 100, 100)
        ```

        The matrix pops on exit, including on an early return or a raise.
        `_push_transform` is the same push without that guarantee -- a missed
        pop shifts every later draw in the frame, so go through here.
        """
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

    def fill(mut self, color: Color):
        """Paint the inside of shapes in `color`, and re-enable filling.

        Holds until changed or until the frame ends — every frame starts from
        the `Style` defaults, so nothing set here leaks into the next one.
        """
        self._style.fill = color
        self._style.fill_enabled = True

    def no_fill(mut self):
        """Draw only the outline of shapes from here on."""
        self._style.fill_enabled = False

    def stroke(mut self, color: Color):
        """Outline shapes in `color`, and re-enable stroking."""
        self._style.stroke = color
        self._style.stroke_enabled = True

    def no_stroke(mut self):
        """Drop the outline. Worth knowing that stroke is *on* by default, in
        black — a `rectangle` drawn without this gets an outline nobody asked for."""
        self._style.stroke_enabled = False

    def stroke_width(mut self, w: Int):
        """Outline thickness in world units, scaled by autoscale like every
        other coordinate, and never rendered thinner than one pixel."""
        self._style.stroke_width = w

    def background(mut self, color: Color):
        """Paint the whole framebuffer — the usual first call in `render`.

        A translucent color blends instead of clearing, which is how motion
        trails are drawn: `canvas.background(Color(0x11, 0x11, 0x11, 24))`
        fades the previous frame a little further each time.
        """
        self._state.backend.record(clear_command(color))

    def rectangle(mut self, x: Float64, y: Float64, w: Float64, h: Float64):
        self._state.backend.record(
            rect_command(self._transform, self._style, x, y, w, h)
        )

    def circle(mut self, cx: Float64, cy: Float64, r: Float64):
        self._state.backend.record(
            circle_command(self._transform, self._style, cx, cy, r)
        )

    def line(mut self, x0: Float64, y0: Float64, x1: Float64, y1: Float64):
        # Recorded only when it would draw: a stroke-less line is the one shape
        # with nothing left to paint, so the command would be pure overhead.
        if not self._style.stroke_enabled:
            return
        self._state.backend.record(
            line_command(self._transform, self._style, x0, y0, x1, y1)
        )

    def triangle(
        mut self,
        x1: Float64,
        y1: Float64,
        x2: Float64,
        y2: Float64,
        x3: Float64,
        y3: Float64,
    ):
        self._state.backend.record(
            triangle_command(
                self._transform, self._style, x1, y1, x2, y2, x3, y3
            )
        )

    def rectangle(mut self, x: Int, y: Int, w: Int, h: Int):
        self.rectangle(Float64(x), Float64(y), Float64(w), Float64(h))

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

    def rectangle(mut self, r: Rectangle):
        self.rectangle(r.x, r.y, r.w, r.h)

    def rectangle(mut self, pos: Vector2, w: Float64, h: Float64):
        self.rectangle(pos.x, pos.y, w, h)

    def rectangle(mut self, pos: Vector2, size: Vector2):
        self.rectangle(pos.x, pos.y, size.x, size.y)

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
        """Draw `s` at its own pixel size.

        The same command as the sized overload: at a pixel scale of 1 the two
        agree exactly, and the one-sprite-pixel-per-framebuffer-pixel shortcut
        they used to differ by now lives inside `blit_sprite`, where the replay
        can take it without the record site having to know.
        """
        self.sprite(s, cx, cy, s.width, s.height)

    def sprite(mut self, s: Sprite, pos: Vector2):
        self.sprite(s, pos.x, pos.y)

    def sprite(mut self, s: Sprite, cx: Float64, cy: Float64, w: Int, h: Int):
        # Rotation and shear are not resampled — only position and scale apply.
        #
        # The image is interned *now*, not at replay: the command then carries
        # an id rather than a borrow of the program's pixels, which is what
        # keeps caller-owned memory out of a buffer that outlives the call.
        var image = self._state.backend.intern_image(
            s._id, s.pixels.unsafe_ptr(), s.width, s.height
        )
        self._state.backend.record(
            sprite_command(
                self._transform,
                self._style,
                cx,
                cy,
                Float64(w),
                Float64(h),
                image,
                s.width,
                s.height,
            )
        )

    def sprite(mut self, s: Sprite, cx: Int, cy: Int, w: Int, h: Int):
        self.sprite(s, Float64(cx), Float64(cy), w, h)

    def sprite(mut self, s: Sprite, pos: Vector2, w: Int, h: Int):
        self.sprite(s, pos.x, pos.y, w, h)

    def sprite(mut self, a: SpriteAnimator, cx: Float64, cy: Float64):
        """Draw the animator's current frame, centred at (cx, cy).

        The frame is indexed here rather than handed back by an accessor on
        `SpriteAnimator`: a `List` element's origin is not spellable from user
        code, so a reference to it cannot cross a function boundary. That is
        also why only this overload and the sized one below index it — the
        rest delegate here, so the inline indexing lives in two places rather
        than six.
        """
        self.sprite(a.animation[].frames[a.frame_index], cx, cy)

    def sprite(mut self, a: SpriteAnimator, cx: Int, cy: Int):
        self.sprite(a, Float64(cx), Float64(cy))

    def sprite(mut self, a: SpriteAnimator, pos: Vector2):
        self.sprite(a, pos.x, pos.y)

    def sprite(mut self, a: SpriteAnimator, cx: Float64, cy: Float64, w: Int, h: Int):
        self.sprite(a.animation[].frames[a.frame_index], cx, cy, w, h)

    def sprite(mut self, a: SpriteAnimator, cx: Int, cy: Int, w: Int, h: Int):
        self.sprite(a, Float64(cx), Float64(cy), w, h)

    def sprite(mut self, a: SpriteAnimator, pos: Vector2, w: Int, h: Int):
        self.sprite(a, pos.x, pos.y, w, h)

    def font_size(mut self, size: Int):
        """Text height in world units, scaled by autoscale like a coordinate."""
        self._style.font_size = size

    def font_weight(mut self, weight: Int):
        """Stroke weight of the face, named by `FontWeight`. The packaged Noto
        faces are variable, so this interpolates rather than swapping files."""
        self._style.font_weight = weight

    def text_align(mut self, horizontal: HorizontalAlignment):
        """Anchor the next text horizontally.

        The argument's type picks the axis, so both are set through one verb:
        `text_align(HorizontalAlignment.CENTER)`,
        `text_align(VerticalAlignment.MIDDLE)`, or both at once.
        `VerticalAlignment.TOP`/`MIDDLE`/`BOTTOM` are edges of the text box,
        not typographic baselines.
        """
        self._style.text_horizontal_alignment = horizontal

    def text_align(mut self, vertical: VerticalAlignment):
        self._style.text_vertical_alignment = vertical

    def text_align(
        mut self, horizontal: HorizontalAlignment, vertical: VerticalAlignment
    ):
        self._style.text_horizontal_alignment = horizontal
        self._style.text_vertical_alignment = vertical

    def text(mut self, s: String, x: Int, y: Int) raises:
        self.text(s, Float64(x), Float64(y))

    def text(mut self, s: String, pos: Vector2) raises:
        self.text(s, pos.x, pos.y)

    def font(mut self, var f: Font):
        """Swap the face. Lives in `PersistentCanvasState`, so unlike the style
        settings a font outlives the frame that set it."""
        self._state.backend.text.set_font(f^)

    def text(mut self, s: String, x: Float64, y: Float64) raises:
        if not self._style.fill_enabled:
            return
        # Deferred whole. Nothing about the layout is decided here: the
        # advances, the alignment and the baseline all come out of the font,
        # which the backend owns, so they are resolved at replay.
        self._state.backend.record(
            text_command(self._transform, self._style, x, y, s.copy())
        )
