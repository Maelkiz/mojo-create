from create.core import *


@fieldwise_init
struct Draw:
    """The drawing scene. Left-drag paints, right-click returns to the menu.

    Deliberately never calls `canvas.background()` per frame — a `Canvas`
    doesn't clear itself, so skipping the clear is what lets ink accumulate
    frame to frame. `enter()` is the one exception: it's a plain method, not
    part of `Program`, that `App` calls the frame it switches in, so this
    scene gets a one-shot clear instead of showing the menu bleeding through
    the first stroke.
    """

    var back_pressed: Bool
    var _entering: Bool
    var drawing: Bool
    var pen: Vector2

    def enter(mut self):
        self._entering = True

    def update(mut self, mut ctx: Context, input: Input) raises:
        self._entering = False
        # SDL button indices: 1 = left, 2 = middle, 3 = right.
        self.back_pressed = input.mouse_just_pressed(3)
        self.drawing = input.is_mouse_down(1)
        self.pen = input.mouse

    def render(self, mut canvas: Canvas) raises:
        if self._entering:
            canvas.background(Color(24, 24, 28))

        if self.drawing:
            with canvas.style():
                canvas.no_stroke()
                canvas.fill(Color(240, 200, 90))
                canvas.circle(self.pen, 14.0)

        with canvas.style():
            canvas.fill(Color(180, 180, 190))
            canvas.font_size(18)
            canvas.text_align(HAlign.CENTER)
            # BOTTOM baseline anchors the text box's bottom edge at y, so it
            # grows upward from the margin instead of downward past it — the
            # default TOP baseline would run this line's descenders straight
            # through canvas.bottom() and into the letterbox clip.
            canvas.text_baseline(VAlign.BOTTOM)
            canvas.text(
                "left-drag to paint    right-click for menu",
                0,
                canvas.bottom() + 14.0,
            )
