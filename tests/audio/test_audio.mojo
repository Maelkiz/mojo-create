# Requires SDL_AUDIO_DRIVER=dummy (set globally by the `test` pixi task) so
# this runs without real audio hardware.

from std.memory import ArcPointer
from std.testing import TestSuite, assert_equal, assert_true, assert_false
from create.audio import Audio, Sound


def _tone() -> ArcPointer[Sound]:
    var data = List[Int16](length=256, fill=0)
    return ArcPointer(Sound.from_pcm(data))


def test_play_returns_valid_id() raises -> None:
    var audio = Audio()
    var id = audio.play(_tone())
    assert_true(audio.is_playing(id))


def test_stop_invalidates_id() raises -> None:
    var audio = Audio()
    var id = audio.play(_tone())
    audio.stop(id)
    assert_false(audio.is_playing(id))


def test_stop_all() raises -> None:
    var audio = Audio()
    var a = audio.play(_tone())
    var b = audio.play(_tone())
    audio.stop_all()
    assert_false(audio.is_playing(a))
    assert_false(audio.is_playing(b))


def test_pause_resume() raises -> None:
    var audio = Audio()
    var id = audio.play(_tone())
    audio.pause(id)
    assert_false(audio.is_playing(id))
    audio.resume(id)
    assert_true(audio.is_playing(id))


def test_stale_id_after_slot_recycle() raises -> None:
    var audio = Audio()
    var first = audio.play(_tone())
    audio.stop(first)
    var second = audio.play(_tone())
    # first's slot was recycled into second; the stale id must not alias it.
    assert_false(audio.is_playing(first))
    assert_true(audio.is_playing(second))


def test_play_loop_returns_valid_id() raises -> None:
    var audio = Audio()
    var id = audio.play(_tone(), loop=True)
    assert_true(audio.is_playing(id))


def test_looping_voice_stays_live_across_updates() raises -> None:
    var audio = Audio()
    var id = audio.play(_tone(), loop=True)
    for _ in range(5):
        audio.update()
    assert_true(audio.is_playing(id))


def test_stop_releases_looping_voice() raises -> None:
    var audio = Audio()
    var id = audio.play(_tone(), loop=True)
    audio.stop(id)
    assert_false(audio.is_playing(id))


def test_stop_all_releases_looping_and_one_shot_together() raises -> None:
    var audio = Audio()
    var one_shot = audio.play(_tone())
    var looping = audio.play(_tone(), loop=True)
    audio.stop_all()
    assert_false(audio.is_playing(one_shot))
    assert_false(audio.is_playing(looping))


def test_looping_voice_shares_sound_via_refcount() raises -> None:
    var audio = Audio()
    var sound = _tone()
    assert_equal(sound.count(), 1)
    var id = audio.play(sound, loop=True)
    # `play` copies the ArcPointer into Voice.loop_sound, a refcount bump.
    assert_equal(sound.count(), 2)
    audio.stop(id)
    assert_equal(sound.count(), 1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
