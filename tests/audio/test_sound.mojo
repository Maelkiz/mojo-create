from std.testing import TestSuite, assert_equal, assert_true
from create.audio import Sound


def test_from_pcm_byte_length() raises -> None:
    var data: List[Int16] = [0, 100, -100, 32767]
    var s = Sound.from_pcm(data, channels=2, freq=48000)
    assert_equal(len(s.pcm), len(data) * 2)
    assert_equal(s.channels, 2)
    assert_equal(s.freq, 48000)


def test_from_pcm_little_endian_packing() raises -> None:
    var data: List[Int16] = [1, -1]
    var s = Sound.from_pcm(data)
    var ptr = s.pcm.unsafe_ptr()
    # 1 == 0x0001 LE
    assert_equal(Int(ptr[unsafe_offset=0]), 1)
    assert_equal(Int(ptr[unsafe_offset=1]), 0)
    # -1 == 0xFFFF LE
    assert_equal(Int(ptr[unsafe_offset=2]), 255)
    assert_equal(Int(ptr[unsafe_offset=3]), 255)


def test_from_pcm_defaults() raises -> None:
    var data: List[Int16] = [0, 0]
    var s = Sound.from_pcm(data)
    assert_equal(s.channels, 1)
    assert_equal(s.freq, 44100)


def test_load_wav() raises -> None:
    var s = Sound.load("tests/fixtures/tone.wav")
    assert_equal(s.channels, 1)
    assert_equal(s.freq, 8000)
    assert_equal(len(s.pcm), 160)
    var ptr = s.pcm.unsafe_ptr()
    assert_equal(Int(ptr[unsafe_offset=0]), 34)
    assert_equal(Int(ptr[unsafe_offset=1]), 1)


def test_load_flac() raises -> None:
    var s = Sound.load("tests/fixtures/tone.flac")
    assert_equal(s.channels, 1)
    assert_equal(s.freq, 8000)
    assert_equal(len(s.pcm), 160)
    var ptr = s.pcm.unsafe_ptr()
    # Lossless, so this can assert exact sample values, not a tolerance --
    # and they match tone.wav's, since both are the same source signal.
    assert_equal(Int(ptr[unsafe_offset=0]), 34)
    assert_equal(Int(ptr[unsafe_offset=1]), 1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
