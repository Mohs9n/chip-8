package renderer

import "../core"
import "core:fmt"
import "core:strings"
import sdl "vendor:sdl2"
import sdlF "vendor:sdl2/ttf"

SCALE :: 15


Renderer :: struct {
	window:           ^sdl.Window,
	renderer:         ^sdl.Renderer,
	viewport_texture: ^sdl.Texture,
	viewport_width:   i32,
	viewport_height:  i32,
}


initialize_renderer :: proc() -> ^Renderer {
	renderer := new(Renderer)

	window_width := i32(core.CH8_WIDTH * SCALE + 400)
	window_height := i32(core.CH8_HEIGHT * SCALE + 100)

	init_err := sdl.Init(sdl.INIT_VIDEO)
	assert(init_err == 0, sdl.GetErrorString())

	windowFlags := sdl.WINDOW_SHOWN | sdl.WINDOW_VULKAN

	rendererFlags := sdl.RENDERER_ACCELERATED | sdl.RENDERER_PRESENTVSYNC | sdl.RENDERER_TARGETTEXTURE

	renderer.window = sdl.CreateWindow(
		"Chip 8 Emulator",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		window_width,
		window_height,
		windowFlags,
	)
	assert(renderer.window != nil, sdl.GetErrorString())
	sdl.SetHint(sdl.HINT_RENDER_SCALE_QUALITY, "linear")
	renderer.renderer = sdl.CreateRenderer(renderer.window, -1, rendererFlags)
	assert(renderer.renderer != nil, sdl.GetErrorString())

	renderer.viewport_width = i32(core.CH8_WIDTH * SCALE)
	renderer.viewport_height = i32(core.CH8_HEIGHT * SCALE)

	update_viewport_texture(renderer)

	return renderer
}


destroy_renderer :: proc(renderer: ^Renderer) {
	if renderer.viewport_texture != nil {
		sdl.DestroyTexture(renderer.viewport_texture)
	}

	if renderer.renderer != nil {
		sdl.DestroyRenderer(renderer.renderer)
	}

	if renderer.window != nil {
		sdl.DestroyWindow(renderer.window)
	}

	free(renderer)
	sdl.Quit()
}


update_viewport_texture :: proc(renderer: ^Renderer) {
	if renderer.viewport_texture != nil {
		sdl.DestroyTexture(renderer.viewport_texture)
	}

	renderer.viewport_texture = sdl.CreateTexture(
		renderer.renderer,
		sdl.PixelFormatEnum.RGBA8888,
		sdl.TextureAccess.TARGET,
		renderer.viewport_width,
		renderer.viewport_height,
	)
}


render_chip8_display :: proc(renderer: ^Renderer, chip8: ^core.Chip8) {
	if renderer.viewport_texture == nil do return

	previous_target := sdl.GetRenderTarget(renderer.renderer)
	sdl.SetRenderTarget(renderer.renderer, renderer.viewport_texture)

	
	sdl.SetRenderDrawColor(renderer.renderer, 0, 0, 0, 255)
	sdl.RenderClear(renderer.renderer)

	
	sdl.SetRenderDrawColor(renderer.renderer, 255, 255, 255, 255)

	pixel_width := renderer.viewport_width / i32(core.CH8_WIDTH)
	pixel_height := renderer.viewport_height / i32(core.CH8_HEIGHT)

	
	for x in 0 ..< core.CH8_WIDTH {
		for y in 0 ..< core.CH8_HEIGHT {
			if chip8.display[x][y] != 0 {
				rect := sdl.Rect {
					x = i32(x) * pixel_width,
					y = i32(y) * pixel_height,
					w = pixel_width,
					h = pixel_height,
				}
				sdl.RenderFillRect(renderer.renderer, &rect)
			}
		}
	}

	
	sdl.SetRenderTarget(renderer.renderer, previous_target)
}


render_frame :: proc(renderer: ^Renderer) {
	sdl.SetRenderDrawColor(renderer.renderer, 40, 40, 40, 255)
	sdl.RenderClear(renderer.renderer)
}


present_renderer :: proc(renderer: ^Renderer) {
	sdl.RenderPresent(renderer.renderer)
}


draw_text :: proc(renderer: ^Renderer, x, y: i32, font: rawptr, text: cstring, color: sdl.Color) {
	when ODIN_DEBUG {
		fmt.println("Drawing text:", text)
	}


	surface := sdlF.RenderText_Solid(cast(^sdlF.Font)font, text, color)
	if surface == nil {
		fmt.eprintln("Failed to render text surface")
		return
	}
	defer sdl.FreeSurface(surface)

	texture := sdl.CreateTextureFromSurface(renderer.renderer, surface)
	if texture == nil {
		fmt.eprintln("Failed to create texture from text surface")
		return
	}
	defer sdl.DestroyTexture(texture)

	rect := sdl.Rect{x, y, surface.w, surface.h}
	sdl.RenderCopy(renderer.renderer, texture, nil, &rect)
}
