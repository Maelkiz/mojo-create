def lerp(a: Float64, b: Float64, t: Float64) -> Float64:
    return a + (b - a) * t

def map(value: Float64, in_low: Float64, in_high: Float64, out_low: Float64, out_high: Float64) -> Float64:
    return out_low + (value - in_low) / (in_high - in_low) * (out_high - out_low)
