package main

import "core:bufio"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
import mu "vendor:microui"
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

	textRect: sdl.Rect = {0, 0, surfaceMessege.w, surfaceMessege.h}

	state.atlas_texture = sdl.CreateTexture(
		app.renderer,
		u32(sdl.PixelFormatEnum.RGBA32),
		.TARGET,
		mu.DEFAULT_ATLAS_WIDTH,
		mu.DEFAULT_ATLAS_HEIGHT,
	)
	assert(state.atlas_texture != nil)
	if err := sdl.SetTextureBlendMode(state.atlas_texture, .BLEND); err != 0 {
		fmt.eprintln("SDL>SetTextureBlendMode:", err)
		return
	}

	pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i].rgb = 0xff
		pixels[i].a = alpha
	}
	if err := sdl.UpdateTexture(
		state.atlas_texture,
		nil,
		raw_data(pixels),
		4 * mu.DEFAULT_ATLAS_WIDTH,
	); err != 0 {
		fmt.eprintln("SDL.UpdateTexture:", err)
		return
	}
	ctx := &state.mu_ctx
	mu.init(ctx)
	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

	fps_lasttime := sdl.GetTicks()
	fps_current: u32
	fps_frames: u32

	ww, wh: i32
	sdl.GetWindowSize(app.window, &ww, &wh)
	buf: [4]byte

	game_loop: for {
		if input(ctx) do break game_loop

		prepareScene()

		for i in 0 ..< 20 {
			cycle()
			// if doInput() do break game_loop
			cycles += 1
		}
		// fmt.printf("\n\nDisplay:  %x\n\n\n", display)
		// render()
		mu.begin(ctx)
		all_windows(ctx)
		mu.end(ctx)
		render()
		res := strconv.itoa(buf[:], int(fps_current))
		cres, err := strings.clone_to_cstring(res, context.temp_allocator)
		drawText(ww - 70, 10, font, cres, White)
		uirender(ctx, app.renderer)
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

input :: proc(ctx: ^mu.Context) -> bool {
	for e: sdl.Event; sdl.PollEvent(&e); {
		#partial switch e.type {
		case .QUIT:
			return true
		case .MOUSEMOTION:
			mu.input_mouse_move(ctx, e.motion.x, e.motion.y)
		case .MOUSEWHEEL:
			mu.input_scroll(ctx, e.wheel.x * 30, e.wheel.y * -30)
		case .TEXTINPUT:
			mu.input_text(ctx, string(cstring(&e.text.text[0])))
		case .MOUSEBUTTONDOWN, .MOUSEBUTTONUP:
			fn := mu.input_mouse_down if e.type == .MOUSEBUTTONDOWN else mu.input_mouse_up
			switch e.button.button {
			case sdl.BUTTON_LEFT:
				fn(ctx, e.button.x, e.button.y, .LEFT)
			case sdl.BUTTON_MIDDLE:
				fn(ctx, e.button.x, e.button.y, .MIDDLE)
			case sdl.BUTTON_RIGHT:
				fn(ctx, e.button.x, e.button.y, .RIGHT)
			}
		case .KEYDOWN, .KEYUP:
			if e.type == .KEYUP && e.key.keysym.sym == .ESCAPE {
				sdl.PushEvent(&sdl.Event{type = .QUIT})
			}
			fn := mu.input_key_down if e.type == .KEYDOWN else mu.input_key_up
			#partial switch e.key.keysym.sym {
			case .LSHIFT:
				fn(ctx, .SHIFT)
			case .RSHIFT:
				fn(ctx, .SHIFT)
			case .LCTRL:
				fn(ctx, .CTRL)
			case .RCTRL:
				fn(ctx, .CTRL)
			case .LALT:
				fn(ctx, .ALT)
			case .RALT:
				fn(ctx, .ALT)
			case .RETURN:
				fn(ctx, .RETURN)
			case .KP_ENTER:
				fn(ctx, .RETURN)
			case .BACKSPACE:
				fn(ctx, .BACKSPACE)
			}
		}
	}
	return false
}

