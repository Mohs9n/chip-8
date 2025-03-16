package imgui_example_sdl2_sdlrenderer2

// This is an example of using the bindings with SDL2 and SDL_Renderer
// For a more complete example with comments, see:
// https://github.com/ocornut/imgui/blob/docking/examples/example_sdl2_sdlrenderer2/main.cpp
// Based on the above at tag `v1.91.1-docking` (24b077)

import im "../.."
import imsdl "../../sdl2"
import imsdlrenderer "../../sdl2renderer"

import sdl "vendor:sdl2"
// Required for SDL_RenderGeometryRaw()
#assert(sdl.MAJOR_VERSION >= 2)
#assert(sdl.MINOR_VERSION >= 0)
// #assert(sdl.PATCHLEVEL >= 18)

main :: proc() {
	assert(sdl.Init(sdl.INIT_EVERYTHING) == 0)
	defer sdl.Quit()

	window := sdl.CreateWindow(
		"Dear ImGui SDL2+SDL_Renderer example",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		1280,
		720,
		{.RESIZABLE, .ALLOW_HIGHDPI},
	)
	assert(window != nil)
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, -1, {.PRESENTVSYNC, .ACCELERATED})
	assert(renderer != nil)
	defer sdl.DestroyRenderer(renderer)

	im.CHECKVERSION()
	im.CreateContext()
	defer im.DestroyContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad, .DockingEnable}

	im.StyleColorsDark()

	imsdl.InitForSDLRenderer(window, renderer)
	defer imsdl.Shutdown()
	imsdlrenderer.Init(renderer)
	defer imsdlrenderer.Shutdown()

	running := true
	for running {
		e: sdl.Event
		for sdl.PollEvent(&e) {
			imsdl.ProcessEvent(&e)

			#partial switch e.type {
			case .QUIT:
				running = false
			}
		}

		imsdlrenderer.NewFrame()
		imsdl.NewFrame()
		im.NewFrame()

		im.ShowDemoWindow()

		if im.Begin("Window containing a quit button") {
			if im.Button("The quit button in question") {
				running = false
			}
		}
		im.End()

		im.Render()
		sdl.RenderSetScale(renderer, io.DisplayFramebufferScale.x, io.DisplayFramebufferScale.y)
		sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
		sdl.RenderClear(renderer)
		imsdlrenderer.RenderDrawData(im.GetDrawData(), renderer)
		sdl.RenderPresent(renderer)
	}
}
