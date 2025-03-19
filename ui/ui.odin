package ui

import im "../lib/imgui"
import imsdl "../lib/imgui/sdl2"
import imsdlrndr "../lib/imgui/sdl2renderer"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import sdl "vendor:sdl2"
import sdlF "vendor:sdl2/ttf"

import "../core"
import "../renderer"


UI :: struct {
	font:         ^sdlF.Font,
	fps_current:  u32,
	fps_frames:   u32,
	fps_lasttime: u32,
	white_color:  sdl.Color,
}

FPS_INTERVAL :: 1.0


initialize_ui :: proc(sdl_window: ^sdl.Window, sdl_renderer: ^sdl.Renderer) -> ^UI {
	ui := new(UI)

	
	sdlF.Init()

	
	ui.font = sdlF.OpenFont("./assets/fonts/JetBrainsMonoNerdFontMono-Regular.ttf", 24)
	if ui.font == nil {
		fmt.eprintln("Failed to load font")
	}

	ui.white_color = {255, 255, 255, 255}
	ui.fps_lasttime = sdl.GetTicks()

	
	im.CHECKVERSION()
	im.CreateContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad, .DockingEnable}

	im.StyleColorsDark()

	imsdl.InitForSDLRenderer(sdl_window, sdl_renderer)
	imsdlrndr.Init(sdl_renderer)

	return ui
}


destroy_ui :: proc(ui: ^UI) {
	imsdlrndr.Shutdown()
	imsdl.Shutdown()
	im.DestroyContext()

	if ui.font != nil {
		sdlF.CloseFont(ui.font)
	}

	sdlF.Quit()
	free(ui)
}


begin_frame :: proc() {
	imsdlrndr.NewFrame()
	imsdl.NewFrame()
	im.NewFrame()
}


render_ui :: proc(ui: ^UI, r: ^renderer.Renderer, chip8: ^core.Chip8) {
	

	
	render_dockspace()

	
	render_viewport_window(r)

	
	

	
	if im.Begin("Emulation Control") {
		label := strings.clone_to_cstring(
			fmt.aprintf(
				"%s Emulation",
				"Continue" if core.is_paused(chip8) else "Pause",
				allocator = context.temp_allocator,
			),
			context.temp_allocator,
		)

		if im.Button(label) {
			core.toggle_pause(chip8)
		}

		im.End()
	}

	
	if im.Begin("Rom Selection") {
		dir_path :: "./roms"

		if dir, err := os.open(dir_path); err == nil {
			defer os.close(dir)

			if files, err := os.read_dir(dir, -1, context.temp_allocator); err == nil {
				for file in files {
					label := strings.clone_to_cstring(file.name, context.temp_allocator)

					if im.Button(label) {
						core.reset_state(chip8)
						if ok := core.load_rom(chip8, file.fullpath); !ok {
							fmt.printf("Error reading ROM: %s\n", file.fullpath)
						}
					}
				}
			} else {
				fmt.printf("Error reading directory: %v\n", err)
			}
		} else {
			fmt.println("Error opening directory:", err)
		}

		im.End()
	}

	
	im.Render()

	
	update_fps(ui)
	ww, wh: i32
	sdl.GetWindowSize(r.window, &ww, &wh)

	buf: [4]byte
	res := strconv.itoa(buf[:], int(ui.fps_current))
	cres, _ := strings.clone_to_cstring(res, context.temp_allocator)
	renderer.draw_text(r, ww - 70, 10, ui.font, cres, ui.white_color)

	
	imsdlrndr.RenderDrawData(im.GetDrawData(), r.renderer)
}


render_dockspace :: proc() {
	dockspace_open := true
	opt_fullscreen_persistent := true
	opt_fullscreen := opt_fullscreen_persistent

	window_flags := im.WindowFlags {
		.NoDocking,
		.NoTitleBar,
		.NoCollapse,
		.NoMove,
		.NoBringToFrontOnFocus,
		.NoNavFocus,
		.NoBackground,
	}

	if opt_fullscreen {
		viewport := im.GetMainViewport()
		im.SetNextWindowPos(viewport.WorkPos)
		im.SetNextWindowSize(viewport.WorkSize)
		im.SetNextWindowViewport(viewport.ID_)
		im.PushStyleVarImVec2(im.StyleVar.WindowPadding, {0.0, 0.0})
		im.PushStyleVar(im.StyleVar.WindowRounding, 0.0)
		im.PushStyleVar(im.StyleVar.WindowBorderSize, 0.0)
	}

	im.Begin("DockSpace Demo", &dockspace_open, window_flags)

	if opt_fullscreen {
		im.PopStyleVar(3)
	}

	dockspace_id := im.GetIDStr("MyDockSpace", nil)
	im.DockSpace(dockspace_id, {0.0, 0.0}, {.PassthruCentralNode, .NoDockingOverCentralNode})
	im.End()
}


render_viewport_window :: proc(r: ^renderer.Renderer) {
	flags := im.WindowFlags{.NoCollapse, .NoResize}

	im.SetNextWindowSize({f32(r.viewport_width + 35), f32(r.viewport_height + 35)}, im.Cond.Always)
	im.Begin("SDL Viewport", nil, flags)

	im.Image(
		im.TextureID(r.viewport_texture),
		{f32(r.viewport_width), f32(r.viewport_height)},
		{0, 0},
		{1, 1},
		{1, 1, 1, 1},
		{0, 0, 0, 0},
	)

	im.End()
}


update_fps :: proc(ui: ^UI) {
	ui.fps_frames += 1

	if ui.fps_lasttime < sdl.GetTicks() - u32(FPS_INTERVAL * 1000) {
		ui.fps_lasttime = sdl.GetTicks()
		ui.fps_current = ui.fps_frames
		ui.fps_frames = 0
	}
}


process_imgui_events :: proc(event: ^sdl.Event) -> bool {
	return imsdl.ProcessEvent(event)
}
