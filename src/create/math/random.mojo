struct Random(Movable):
    var _state: UInt64

    def __init__(out self, seed: UInt64):
        self._state = seed | 1

    def _xorshift(mut self) -> UInt64:
        self._state ^= self._state << 13
        self._state ^= self._state >> 7
        self._state ^= self._state << 17
        return self._state

    def float(mut self) -> Float64:
        return Float64(self._xorshift()) / Float64(UInt64.MAX)

    def float(mut self, low: Float64, high: Float64) -> Float64:
        return low + self.float() * (high - low)

    def int(mut self, low: Int, high: Int) -> Int:
        debug_assert(high > low, "Random.int: high must be greater than low")
        return low + Int(self._xorshift() % UInt64(high - low))

    def bool(mut self) -> Bool:
        return self._xorshift() & 1 == 1
