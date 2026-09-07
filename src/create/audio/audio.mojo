from ._sdl_audio import SDLAudio
from .sound import Sound

comptime _GEN_SHIFT = 32
comptime _INDEX_MASK: Int = 0xFFFFFFFF


struct Audio(Movable):
    """Program-owned playback device. Construct once, hold as a Program field,
    call `play` from `update` or event callbacks.

    Call `update` once per frame (e.g. from `Program.update`) -- it reaps
    finished one-shot voices and refills looping ones. SDL keeps playing
    whatever was last queued and never tells this struct a stream finished on
    its own, so skipping `update` silently stalls a loop after its first
    buffer drains, and leaks one-shot voice slots forever.
    """

    var _sdl: SDLAudio
    var _voices: List[Int]         # stream handle per slot, 0 = free
    var _generations: List[Int]    # bumped whenever a slot is freed
    var _paused: List[Bool]
    var _looping: List[Bool]
    var _loop_pcm: List[List[UInt8]]
    var volume: Float32

    def __init__(out self) raises:
        self._sdl = SDLAudio()
        self._sdl.init()
        self._voices = List[Int]()
        self._generations = List[Int]()
        self._paused = List[Bool]()
        self._looping = List[Bool]()
        self._loop_pcm = List[List[UInt8]]()
        self.volume = 1.0

    @staticmethod
    def _encode(index: Int, generation: Int) -> Int:
        return (generation << _GEN_SHIFT) | index

    @staticmethod
    def _decode(id: Int) -> Tuple[Int, Int]:
        return id & _INDEX_MASK, id >> _GEN_SHIFT

    def _valid(self, id: Int) -> Bool:
        var parts = Self._decode(id)
        var index = parts[0]
        var generation = parts[1]
        return (
            index >= 0
            and index < len(self._voices)
            and self._generations[index] == generation
            and self._voices[index] != 0
        )

    def play(mut self, sound: Sound, loop: Bool = False) raises -> Int:
        """Play a Sound. Returns a voice id usable with `stop`/`pause`/`resume`/
        `is_playing`. Looping voices are refilled by `update`."""
        var stream = self._sdl.open_device_stream(sound.format, sound.channels, sound.freq)
        self._sdl.set_gain(stream, self.volume)
        self._sdl.put_data(stream, sound.pcm.unsafe_ptr(), Int32(len(sound.pcm)))
        self._sdl.resume_stream(stream)
        var loop_pcm = sound.pcm.copy() if loop else List[UInt8]()

        var index = -1
        for i in range(len(self._voices)):
            if self._voices[i] == 0:
                index = i
                break

        if index == -1:
            self._voices.append(stream)
            self._generations.append(0)
            self._paused.append(False)
            self._looping.append(loop)
            self._loop_pcm.append(loop_pcm^)
            index = len(self._voices) - 1
        else:
            self._voices[index] = stream
            self._paused[index] = False
            self._looping[index] = loop
            self._loop_pcm[index] = loop_pcm^

        return Self._encode(index, self._generations[index])

    def _free_slot(mut self, index: Int) raises:
        self._sdl.destroy_stream(self._voices[index])
        self._voices[index] = 0
        self._generations[index] += 1
        self._paused[index] = False
        self._looping[index] = False
        self._loop_pcm[index] = List[UInt8]()

    def stop(mut self, id: Int) raises:
        """Stop and release the voice with the given id. No-op if already
        stopped or the id is stale (from a since-recycled slot)."""
        if not self._valid(id):
            return
        self._free_slot(Self._decode(id)[0])

    def stop_all(mut self) raises:
        for i in range(len(self._voices)):
            if self._voices[i] != 0:
                self._free_slot(i)

    def pause(mut self, id: Int) raises:
        if not self._valid(id):
            return
        var index = Self._decode(id)[0]
        self._sdl.pause_stream(self._voices[index])
        self._paused[index] = True

    def resume(mut self, id: Int) raises:
        if not self._valid(id):
            return
        var index = Self._decode(id)[0]
        self._sdl.resume_stream(self._voices[index])
        self._paused[index] = False

    def is_playing(self, id: Int) raises -> Bool:
        if not self._valid(id):
            return False
        return not self._paused[Self._decode(id)[0]]

    def update(mut self) raises:
        """Reap finished one-shot voices and top up looping ones.

        Looping voices are topped up *before* the queue drains (once queued
        audio drops below one loop's worth), not after `available()` hits 0
        -- by then the device has already gone silent and the refill lands
        late, audible as a click/pop at every loop boundary.
        """
        for i in range(len(self._voices)):
            if self._voices[i] == 0:
                continue
            if self._looping[i]:
                if self._sdl.available(self._voices[i]) < Int32(len(self._loop_pcm[i])):
                    self._sdl.put_data(
                        self._voices[i],
                        self._loop_pcm[i].unsafe_ptr(),
                        Int32(len(self._loop_pcm[i])),
                    )
            elif self._sdl.available(self._voices[i]) == 0:
                self._free_slot(i)

    def __deinit__(deinit self):
        try:
            self.stop_all()
            self._sdl.quit()
        except:
            pass
