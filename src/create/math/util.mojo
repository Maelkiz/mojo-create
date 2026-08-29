from std.math import floor, pi, clamp


def lerp(a: Float64, b: Float64, t: Float64) -> Float64:
    return a + (b - a) * t

def map(value: Float64, in_low: Float64, in_high: Float64, out_low: Float64, out_high: Float64) -> Float64:
    return out_low + (value - in_low) / (in_high - in_low) * (out_high - out_low)

def norm(value: Float64, low: Float64, high: Float64) -> Float64:
    return (value - low) / (high - low)

def smoothstep(edge0: Float64, edge1: Float64, x: Float64) -> Float64:
    var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

def sign(x: Float64) -> Float64:
    if x > 0.0:
        return 1.0
    if x < 0.0:
        return -1.0
    return 0.0

def fract(x: Float64) -> Float64:
    return x - floor(x)

def fmod(x: Float64, y: Float64) -> Float64:
    return x - floor(x / y) * y

def degrees(r: Float64) -> Float64:
    return r * (180.0 / pi)

def radians(d: Float64) -> Float64:
    return d * (pi / 180.0)
