package input

import sdl "vendor:sdl2"
import imsdl "../lib/imgui/sdl2"
import "../core"



process_event :: proc(chip8: ^core.Chip8, e: ^sdl.Event) -> bool {
    imsdl.ProcessEvent(e)
    #partial switch e.type {
    case .KEYDOWN:
        #partial switch e.key.keysym.sym {
        case .NUM1:
            core.set_key_state(chip8, 0x1, true)
        case .NUM2:
            core.set_key_state(chip8, 0x2, true)
        case .NUM3:
            core.set_key_state(chip8, 0x3, true)
        case .NUM4:
            core.set_key_state(chip8, 0xC, true)
        case .q:
            core.set_key_state(chip8, 0x4, true)
        case .W:
            core.set_key_state(chip8, 0x5, true)
        case .E:
            core.set_key_state(chip8, 0x6, true)
        case .R:
            core.set_key_state(chip8, 0xD, true)
        case .A:
            core.set_key_state(chip8, 0x7, true)
        case .S:
            core.set_key_state(chip8, 0x8, true)
        case .D:
            core.set_key_state(chip8, 0x9, true)
        case .F:
            core.set_key_state(chip8, 0xE, true)
        case .Z:
            core.set_key_state(chip8, 0xA, true)
        case .X:
            core.set_key_state(chip8, 0x0, true)
        case .C:
            core.set_key_state(chip8, 0xB, true)
        case .V:
            core.set_key_state(chip8, 0xF, true)
        case .ESCAPE:
            return true
        case .SPACE:
            core.toggle_pause(chip8)
        }
        
    case .KEYUP:
        #partial switch e.key.keysym.sym {
        case .NUM1:
            core.set_key_state(chip8, 0x1, false)
        case .NUM2:
            core.set_key_state(chip8, 0x2, false)
        case .NUM3:
            core.set_key_state(chip8, 0x3, false)
        case .NUM4:
            core.set_key_state(chip8, 0xC, false)
        case .q:
            core.set_key_state(chip8, 0x4, false)
        case .W:
            core.set_key_state(chip8, 0x5, false)
        case .E:
            core.set_key_state(chip8, 0x6, false)
        case .R:
            core.set_key_state(chip8, 0xD, false)
        case .A:
            core.set_key_state(chip8, 0x7, false)
        case .S:
            core.set_key_state(chip8, 0x8, false)
        case .D:
            core.set_key_state(chip8, 0x9, false)
        case .F:
            core.set_key_state(chip8, 0xE, false)
        case .Z:
            core.set_key_state(chip8, 0xA, false)
        case .X:
            core.set_key_state(chip8, 0x0, false)
        case .C:
            core.set_key_state(chip8, 0xB, false)
        case .V:
            core.set_key_state(chip8, 0xF, false)
        }
    }
    
    return false
}


process_input :: proc(chip8: ^core.Chip8) -> bool {
    e: sdl.Event
    quit := false
    
    for sdl.PollEvent(&e) {
        if process_event(chip8, &e) {
            quit = true
        }
        
        if e.type == .QUIT {
            quit = true
        }
    }
    
    return quit
}
