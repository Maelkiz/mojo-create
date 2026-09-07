from ._sdl_audio import SDLAudio
from .sound import Sound


struct Audio(Movable):
    """Program-owned playback device. Construct once, hold as a Program field,
    call `play` from `update` or event callbacks."""

    var _sdl: SDLAudio
    var _voices: List[Int]
    var volume: Float32

    def __init__(out self) raises:
        self._sdl = SDLAudio()
        self._sdl.init()
        self._voices = List[Int]()
        self.volume = 1.0

    def play(mut self, sound: Sound) raises -> Int:
        """Play a Sound once. Returns a voice id usable with `stop`."""
        var stream = self._sdl.open_device_stream(sound.format, sound.channels, sound.freq)
        self._sdl.set_gain(stream, self.volume)
        self._sdl.put_data(stream, sound.pcm.unsafe_ptr(), Int32(len(sound.pcm)))
        self._sdl.resume_stream(stream)
        self._voices.append(stream)
        return len(self._voices) - 1

    def stop(mut self, id: Int) raises:
        """Stop and release the voice with the given id. No-op if already stopped."""
        if id < 0 or id >= len(self._voices) or self._voices[id] == 0:
            return
        self._sdl.destroy_stream(self._voices[id])
        self._voices[id] = 0

    def stop_all(mut self) raises:
        for i in range(len(self._voices)):
            if self._voices[i] != 0:
                self._sdl.destroy_stream(self._voices[i])
                self._voices[i] = 0

    def __deinit__(deinit self):
        try:
            self.stop_all()
            self._sdl.quit()
        except:
            pass
