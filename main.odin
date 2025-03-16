package main

import "core:bufio"
import "core:fmt"
import "core:io"
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

	ww, wh: i32
	sdl.GetWindowSize(app.window, &ww, &wh)
	buf: [4]byte

	game_loop: for {
		if input() do break game_loop

		prepareScene()

		for i in 0 ..< 20 {
			cycle()
			// if doInput() do break game_loop
			cycles += 1
		}
		// fmt.printf("\n\nDisplay:  %x\n\n\n", display)
		// render()
		//
		//

		imsdlrndr.NewFrame()
		imsdl.NewFrame()
		im.NewFrame()

		im.ShowDemoWindow()

		if im.Begin("Emulation Control") {
			label := strings.clone_to_cstring(
				fmt.aprintf("%s Emulation", "Continue" if PAUSE else "Pause"),
				context.temp_allocator,
			)
			if im.Button(label) {
				PAUSE = !PAUSE
			}
		}
		im.End()


		im.Render()

		render()
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
		// sdl.Delay(8)
	}
}

input :: proc() -> bool {
	for e: sdl.Event; sdl.PollEvent(&e); {
		imsdl.ProcessEvent(&e)
		#partial switch e.type {
		case .QUIT:
			return true
		case .KEYDOWN, .KEYUP:
			if e.type == .KEYUP && e.key.keysym.sym == .ESCAPE {
				sdl.PushEvent(&sdl.Event{type = .QUIT})
			}
		}
	}
	return false
}
