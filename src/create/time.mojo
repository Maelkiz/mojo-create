@fieldwise_init
struct Time(ImplicitlyCopyable, Movable):
    var frame_count: Int
    var delta_time: Float64
    var delta_millis: Int
