from ._sdl_audio import SDLAudio, SDL_AUDIO_S16


struct Sound(Movable):
    var pcm: List[UInt8]
    var format: Int32
    var channels: Int32
    var freq: Int32

    def __init__(out self, var pcm: List[UInt8], format: Int32, channels: Int32, freq: Int32):
        self.pcm = pcm^
        self.format = format
        self.channels = channels
        self.freq = freq

    @staticmethod
    def load(path: String) raises -> Sound:
        """Load a WAV file."""
        var result = SDLAudio().load_wav(path)
        return Sound(result[0].copy(), result[1], result[2], result[3])

    @staticmethod
    def from_pcm(data: List[Int16], channels: Int32 = 1, freq: Int32 = 44100) -> Sound:
        """Build a Sound from raw S16LE samples, e.g. a synthesized waveform."""
        var pcm = List[UInt8](length=len(data) * 2, fill=0)
        var dst = pcm.unsafe_ptr()
        for i in range(len(data)):
            var sample = data[i]
            dst[unsafe_offset=i * 2] = UInt8(sample & 0xFF)
            dst[unsafe_offset=i * 2 + 1] = UInt8((sample >> 8) & 0xFF)
        return Sound(pcm^, SDL_AUDIO_S16, channels, freq)
