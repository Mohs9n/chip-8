package main

import "core:bufio"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
import im "lib/imgui"
import imsdl "lib/imgui/sdl2"
import imsdlrndr "lib/imgui/sdl2renderer"
import sdl "vendor:sdl2"
import sdlF "vendor:sdl2/ttf"

main :: proc() {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	initSDL()
	defer cleanup()

	sdlF.Init()
	font: ^sdlF.Font = sdlF.OpenFont("./assets/fonts/JetBrainsMonoNerdFontMono-Regular.ttf", 24)
	White: sdl.Color : {255, 255, 255, 255}
	surfaceMessege: ^sdl.Surface = sdlF.RenderText_Solid(font, "hello", White)
	defer sdl.FreeSurface(surfaceMessege)
	Messege: ^sdl.Texture = sdl.CreateTextureFromSurface(app.renderer, surfaceMessege)
	defer sdl.DestroyTexture(Messege)


	// imgui
	im.CHECKVERSION()
	im.CreateContext()
	defer im.DestroyContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad, .DockingEnable}

	im.StyleColorsDark()

	imsdl.InitForSDLRenderer(app.window, app.renderer)
	defer imsdl.Shutdown()
	imsdlrndr.Init(app.renderer)
	defer imsdlrndr.Shutdown()
	// imgui

	textRect: sdl.Rect = {0, 0, surfaceMessege.w, surfaceMessege.h}


	fps_lasttime := sdl.GetTicks()
	fps_current: u32
	fps_frames: u32


	dt: f64 = 1.0 / 500.0
	accumulator: f64 = 0.0
	lastCounter := sdl.GetPerformanceCounter()
	freq := f64(sdl.GetPerformanceFrequency())

	ww, wh: i32
	sdl.GetWindowSize(app.window, &ww, &wh)

	game_loop: for {
		if input() do break game_loop

		currentCounter := sdl.GetPerformanceCounter()
		deltaTime := f64(currentCounter - lastCounter) / freq
		lastCounter = currentCounter

		accumulator += deltaTime

		for accumulator >= dt {
			cycle()
			accumulator -= dt
		}

		prepareScene()

		// cycle()

		imsdlrndr.NewFrame()
		imsdl.NewFrame()
		im.NewFrame()

		im.ShowDemoWindow()

		if im.Begin("Emulation Control") {
			label := strings.clone_to_cstring(
				fmt.aprintf(
					"%s Emulation",
					"Continue" if PAUSE else "Pause",
					allocator = context.temp_allocator,
				),
				context.temp_allocator,
			)
			if im.Button(label) {
				PAUSE = !PAUSE
			}
			im.End()
			if im.Begin("Rom Selection") {
				dir_path :: "./roms"

				if dir, err := os.open(dir_path); err == nil {
					defer os.close(dir)

					if files, err := os.read_dir(dir, -1, context.temp_allocator); err == nil {
						for file in files {
							label = strings.clone_to_cstring(file.name, context.temp_allocator)
							if im.Button(label) {
								reset_state()
								if ok := load_rom(file.fullpath); !ok {
									fmt.printf("Error reading directory\n")
								}
							}
						}
					} else {
						fmt.printf("Error reading directory:", err)
					}
				} else {
					fmt.println("Error opening directory:", err)
				}
			}
		}
		im.End()


		im.Render()

		render()

		buf: [4]byte
		res := strconv.itoa(buf[:], int(fps_current))
		cres, err := strings.clone_to_cstring(res, context.temp_allocator)
		drawText(ww - 70, 10, font, cres, White)

		imsdlrndr.RenderDrawData(im.GetDrawData(), app.renderer)
		// uirender(ctx, app.renderer)


		sdl.RenderPresent(app.renderer)
		// drawGrid()
		// presentScene()
		fps_frames += 1
		if fps_lasttime < sdl.GetTicks() - FPS_INTERVAL * 1000 {
			fps_lasttime = sdl.GetTicks()
			fps_current = fps_frames
			fps_frames = 0
		}

		free_all(context.temp_allocator)
		// sdl.Delay(8)
	}
}

input :: proc() -> bool {
	for e: sdl.Event; sdl.PollEvent(&e); {
		imsdl.ProcessEvent(&e)
		#partial switch e.type {
		case .QUIT:
			return true
		case .KEYDOWN:
			#partial switch e.key.keysym.sym {
			case .NUM1:
				keys[0x1] = true
			case .NUM2:
				keys[0x2] = true
			case .NUM3:
				keys[0x3] = true
			case .NUM4:
				keys[0xC] = true
			case .q:
				keys[0x4] = true
			case .W:
				keys[0x5] = true
			case .E:
				keys[0x6] = true
			case .R:
				keys[0xD] = true
			case .A:
				keys[0x7] = true
			case .S:
				keys[0x8] = true
			case .D:
				keys[0x9] = true
			case .F:
				keys[0xE] = true
			case .Z:
				keys[0xA] = true
			case .X:
				keys[0x0] = true
			case .C:
				keys[0xB] = true
			case .V:
				keys[0xF] = true
			}
		case .KEYUP:
			#partial switch e.key.keysym.sym {
			case .NUM1:
				keys[0x1] = false
			case .NUM2:
				keys[0x2] = false
			case .NUM3:
				keys[0x3] = false
			case .NUM4:
				keys[0xC] = false
			case .q:
				keys[0x4] = false
			case .W:
				keys[0x5] = false
			case .E:
				keys[0x6] = false
			case .R:
				keys[0xD] = false
			case .A:
				keys[0x7] = false
			case .S:
				keys[0x8] = false
			case .D:
				keys[0x9] = false
			case .F:
				keys[0xE] = false
			case .Z:
				keys[0xA] = false
			case .X:
				keys[0x0] = false
			case .C:
				keys[0xB] = false
			case .V:
				keys[0xF] = false
			case .ESCAPE:
				sdl.PushEvent(&sdl.Event{type = .QUIT})
			}
		}
	}
	return false
}
