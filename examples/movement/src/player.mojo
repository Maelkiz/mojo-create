from create.core import *


@fieldwise_init
struct Player:
    # y grows upward, so gravity is negative and a jump is positive.
    comptime GRAVITY: Float64 = -1.5
    comptime JUMP_FORCE: Float64 = 30.0
    comptime JUMP_HOLD_FORCE: Float64 = 0.3
    comptime SPEED: Float64 = 14.0

    var x: Float64
    var y: Float64
    var width: Float64
    var height: Float64
    var vel_y: Float64
    var on_ground: Bool
    var jumps_left: Int

    def update(mut self, mut ctx: Context, mut input: Input):
        if input.is_key_down("a"):
            self.x -= self.SPEED
        if input.is_key_down("d"):
            self.x += self.SPEED

        if input.just_pressed("w") and self.jumps_left > 0:
            self.vel_y = self.JUMP_FORCE
            self.jumps_left -= 1

        if input.is_key_down("w") and self.vel_y > 0:
            self.vel_y += self.JUMP_HOLD_FORCE

        self.vel_y += self.GRAVITY
        self.y += self.vel_y

        var half_w = self.width / 2
        var half_h = self.height / 2

        if self.x - half_w < ctx.left():
            self.x = ctx.left() + half_w
        if self.x + half_w > ctx.right():
            self.x = ctx.right() - half_w

        # Ceiling: moving up and past the top edge.
        if self.y + half_h > ctx.top():
            self.y = ctx.top() - half_h
            if self.vel_y > 0:
                self.vel_y = 0.0

        if self.y - half_h <= ctx.bottom():
            self.y = ctx.bottom() + half_h
            self.vel_y = 0.0
            self.on_ground = True
            self.jumps_left = 2
        else:
            self.on_ground = False

    def draw(self, mut canvas: Canvas) raises:
        canvas.fill(Color(220, 80, 80))
        canvas.no_stroke()
        canvas.rect(self.x, self.y, self.width, self.height)