package app

import "core:fmt"
import "core:os"
import "core:time"
import sdl "vendor:sdl2"
import "../audio"
import "../core"
import "../input"
import "../renderer"
import "../ui"

App :: struct {
	chip8:    ^core.Chip8,
	renderer: ^renderer.Renderer,
	ui:       ^ui.UI,
	audio:    ^audio.Audio_Context,
	running:  bool,
}

create_app :: proc() -> ^App {
	app := new(App)

	app.chip8 = core.create_chip8()
	app.renderer = renderer.initialize_renderer()
	app.ui = ui.initialize_ui(app.renderer.window, app.renderer.renderer)
	app.audio = audio.initialize_audio()
	app.running = true

	load_default_rom(app)

	return app
}

destroy_app :: proc(app: ^App) {
	ui.destroy_ui(app.ui)
	renderer.destroy_renderer(app.renderer)
	audio.destroy_audio(app.audio)
	core.destroy_chip8(app.chip8)
	free(app)
}

load_default_rom :: proc(app: ^App) {
	if len(os.args) > 1 {
		if ok := core.load_rom(app.chip8, os.args[1]); !ok {
			fmt.eprintln("Error loading ROM from command line arguments")
		}
	} else {
		if ok := core.load_rom(app.chip8, "roms/ibm.ch8"); !ok {
			fmt.eprintln("Error loading default ROM")
		}
	}
}

run :: proc(app: ^App) {
	dt: f64 = 1.0 / 500.0
	timer_dt: f64 = 1.0 / 60.0
	accumulator: f64 = 0.0
	timer_accumulator: f64 = 0.0
	last_counter := sdl.GetPerformanceCounter()
	perf_freq := f64(sdl.GetPerformanceFrequency())

	for app.running {
		e: sdl.Event
		for sdl.PollEvent(&e) {
			imgui_handled := ui.process_imgui_events(&e)

            if input.process_event(app.chip8, &e) {
                app.running = false
                break
            }

			
			if e.type == .QUIT {
				app.running = false
				break
			}
		}

		
		current_counter := sdl.GetPerformanceCounter()
		delta_time := f64(current_counter - last_counter) / perf_freq
		last_counter = current_counter

		accumulator += delta_time
		timer_accumulator += delta_time

		
		for accumulator >= dt {
			core.cycle(app.chip8)
			accumulator -= dt
		}

		if timer_accumulator >= timer_dt {
			core.update_timers(app.chip8)
			
			// Update audio based on sound timer
			if app.chip8.STimer > 0 {
				audio.play_audio(app.audio)
			} else {
				audio.stop_audio(app.audio)
			}
			
			timer_accumulator -= timer_dt
		}

		
		renderer.render_chip8_display(app.renderer, app.chip8)

		
		renderer.render_frame(app.renderer)

		
		ui.begin_frame()

		
		ui.render_ui(app.ui, app.renderer, app.chip8)

		
		renderer.present_renderer(app.renderer)

		
		free_all(context.temp_allocator)
	}
}
