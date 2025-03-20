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
import hlp "../helpers"


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
		label := hlp.fmt_cstr("%s Emulation","Continue" if core.is_paused(chip8) else "Pause")

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
					label := hlp.fmt_cstr(file.name)

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

	
	render_debug_window(chip8)

	
	im.Render()

	
	update_fps(ui)
	ww, wh: i32
	sdl.GetWindowSize(r.window, &ww, &wh)

	buf: [4]byte
	res := strconv.itoa(buf[:], int(ui.fps_current))
	cres := hlp.fmt_cstr(res)
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


render_debug_window :: proc(chip8: ^core.Chip8) {
	if im.Begin("CHIP-8 Debug") {
		// Display general state
		im.Text("General State")
		im.Separator()
		im.Text(hlp.fmt_cstr("PC: 0x%04X", chip8.PC))
		im.Text(hlp.fmt_cstr("I: 0x%04X", chip8.I))
		im.Text(hlp.fmt_cstr("SP: %d", chip8.sp))
		im.Text(hlp.fmt_cstr("Delay Timer: %d", chip8.DTimer))
		im.Text(hlp.fmt_cstr("Sound Timer: %d", chip8.STimer))
		im.Text(hlp.fmt_cstr("Status: %s", "PAUSED" if chip8.paused else "RUNNING"))

		// Display current opcode
		if chip8.PC < len(chip8.ram) - 1 {
			opcode := u16(chip8.ram[chip8.PC]) << 8 | u16(chip8.ram[chip8.PC + 1])
			im.Text(hlp.fmt_cstr("Current Opcode: 0x%04X", opcode))
		}
		
		im.Spacing()
		
		// Display registers
		if im.CollapsingHeader("Registers") {
			for i in 0..<16 {
				// Display 4 registers per row
				if i % 4 != 0 {
					im.SameLine()
				}
				im.Text(hlp.fmt_cstr("V%X: 0x%02X", i, chip8.reg[i]))
			}
		}
		
		// Stack view
		if im.CollapsingHeader("Stack") {
			for i in 0..<int(chip8.sp) {
				im.Text(hlp.fmt_cstr("[%d]: 0x%04X", i, chip8.stack[i]))
			}
			if chip8.sp == 0 {
				im.TextColored({1, 0.5, 0.5, 1}, "Stack Empty")
			}
		}

		// Memory viewer
		if im.CollapsingHeader("Memory Viewer") {
			region :cstring= "Program"
			regions := []cstring{"Program", "Font", "Stack", "Around I"}
			
			if im.BeginCombo("Region", region) {
				for region_name in regions {
					is_selected := region == region_name
					if im.Selectable(region_name, is_selected) {
						region = region_name
					}
					if is_selected {
						im.SetItemDefaultFocus()
					}
				}
				im.EndCombo()
			}
			
			start_addr, end_addr: int
			
			// Select memory region to display
			switch region {
			case "Program":
				start_addr = 0x200
				end_addr = min(0x200 + 0x100, len(chip8.ram))
			case "Font":
				start_addr = 0x050
				end_addr = 0x050 + 80 // 16 characters * 5 bytes
			case "Stack":
				start_addr = 0
				end_addr = 16 * 2 // Just a placeholder, we're showing stack values
			case "Around I":
				start_addr = max(0, int(chip8.I) - 16)
				end_addr = min(int(chip8.I) + 16, len(chip8.ram))
			}
			
			// Display memory in hex format, 16 bytes per row
			if region != "Stack" {
				for addr := start_addr; addr < end_addr; addr += 16 {
					im.Text(hlp.fmt_cstr("%04X:", addr))
					im.SameLine()
					
					for offset in 0..<16 {
						if addr + offset < end_addr {
							// Highlight memory at PC or I
							if addr + offset == int(chip8.PC) || 
							   addr + offset == int(chip8.PC + 1) {
								im.TextColored({1, 0.5, 0, 1}, 
									hlp.fmt_cstr("%02X", chip8.ram[addr + offset]))
							} else if addr + offset == int(chip8.I) {
								im.TextColored({0.5, 1, 0.5, 1}, 
									hlp.fmt_cstr("%02X", chip8.ram[addr + offset]))
							} else {
								im.Text(hlp.fmt_cstr("%02X", chip8.ram[addr + offset]))
							}
							im.SameLine()
						}
					}
					im.NewLine()
				}
			}
		}
		
		// Input state
		if im.CollapsingHeader("Input State") {
			for i in 0..<16 {
				if i % 4 != 0 {
					im.SameLine()
				}
				
				key_color := [4]f32{1, 1, 1, 1} // Default white
				if chip8.keys[i] {
					key_color = {0, 1, 0, 1} // Green when pressed
				}
				
				im.TextColored(key_color, hlp.fmt_cstr("Key %X: %v", i, chip8.keys[i]))
			}
		}

		im.End()
	}
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
