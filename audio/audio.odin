package audio

import "core:fmt"
import sdl "vendor:sdl2"

AUDIO_SAMPLE_RATE :: 44100
AUDIO_BUFFER_SIZE :: 1024
TONE_FREQUENCY :: 440.0 // 440Hz - standard A note

Audio_Context :: struct {
	device_id:        sdl.AudioDeviceID,
	is_playing:       bool,
	sample_position:  f32,
	sample_increment: f32,
	volume:           f32,
}

initialize_audio :: proc() -> ^Audio_Context {
	// Initialize SDL Audio subsystem if not done already
	if sdl.WasInit(sdl.INIT_AUDIO) & {.AUDIO} == {} {
		if sdl.InitSubSystem(sdl.INIT_AUDIO) < 0 {
			fmt.eprintln("Failed to initialize SDL audio:", sdl.GetError())
			return nil
		}
	}

	audio_ctx := new(Audio_Context)
	audio_ctx.is_playing = false
	audio_ctx.sample_position = 0.0
	audio_ctx.sample_increment = TONE_FREQUENCY / f32(AUDIO_SAMPLE_RATE)
	audio_ctx.volume = 0.3 // 30% volume to avoid being too loud

	// Configure audio spec
	want: sdl.AudioSpec
	have: sdl.AudioSpec

	want.freq = AUDIO_SAMPLE_RATE
	want.format = sdl.AUDIO_S16SYS
	want.channels = 1
	want.samples = AUDIO_BUFFER_SIZE
	want.callback = sdl.AudioCallback(audio_callback)
	want.userdata = rawptr(audio_ctx)

	// Open audio device
	device_id := sdl.OpenAudioDevice(nil, false, &want, &have, false)
	if device_id == 0 {
		fmt.eprintln("Failed to open audio device:", sdl.GetError())
		free(audio_ctx)
		return nil
	}

	audio_ctx.device_id = device_id
	return audio_ctx
}

destroy_audio :: proc(audio_ctx: ^Audio_Context) {
	if audio_ctx != nil {
		if audio_ctx.device_id != 0 {
			stop_audio(audio_ctx)
			sdl.CloseAudioDevice(audio_ctx.device_id)
		}
		free(audio_ctx)
	}
}

audio_callback :: proc "c" (userdata: rawptr, stream: [^]u8, len: i32) {
	context = {} // Required for Odin's runtime

	audio_ctx := (^Audio_Context)(userdata)
	if audio_ctx == nil || !audio_ctx.is_playing {
		// Fill with silence if not playing
		for i in 0 ..< len {
			stream[i] = 0
		}
		return
	}

	buffer := ([^]i16)(rawptr(stream))
	buffer_length := int(len) / 2 // 16-bit samples (2 bytes per sample)

	// Generate square wave
	for i in 0 ..< buffer_length {
		if audio_ctx.sample_position >= 1.0 {
			audio_ctx.sample_position -= 1.0
		}

		// Square wave: high when sample_position < 0.5, low otherwise
		signal: i16 =
			i16(32767 * audio_ctx.volume) if audio_ctx.sample_position < 0.5 else i16(-32767 * audio_ctx.volume)
		buffer[i] = signal

		audio_ctx.sample_position += audio_ctx.sample_increment
	}
}

play_audio :: proc(audio_ctx: ^Audio_Context) {
	if audio_ctx != nil && !audio_ctx.is_playing {
		audio_ctx.is_playing = true
		sdl.PauseAudioDevice(audio_ctx.device_id, false) // 0 = unpause
	}
}

stop_audio :: proc(audio_ctx: ^Audio_Context) {
	if audio_ctx != nil && audio_ctx.is_playing {
		audio_ctx.is_playing = false
		sdl.PauseAudioDevice(audio_ctx.device_id, true) // 1 = pause
	}
}

is_audio_playing :: proc(audio_ctx: ^Audio_Context) -> bool {
	return audio_ctx != nil && audio_ctx.is_playing
}
