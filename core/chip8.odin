package core

import "core:container/queue"
import "core:fmt"
import "core:math/rand"
import "core:os"

CH8_WIDTH :: 64
CH8_HEIGHT :: 32


Chip8 :: struct {
	ram:            [4096]u8,
	reg:            [0x10]u8,
	keys:           [16]bool,
	display:        [CH8_WIDTH][CH8_HEIGHT]u8,
	I:              u16,
	PC:             u16,
	DTimer, STimer: u8,
	stack:          queue.Queue(u16),
	paused:         bool,
}


create_chip8 :: proc() -> ^Chip8 {
	chip8 := new(Chip8)
	reset_state(chip8)
	load_font(chip8)
	return chip8
}


destroy_chip8 :: proc(chip8: ^Chip8) {
    queue.destroy(&chip8.stack)
	free(chip8)
}


reset_state :: proc(chip8: ^Chip8) {
	chip8^ = {} 
	chip8.PC = 0x200
	chip8.paused = false
	queue.init(&chip8.stack)
}


load_rom :: proc(chip8: ^Chip8, path: string) -> bool {
	rom: []byte
	ok: bool
	if rom, ok = os.read_entire_file(path); !ok {
		return false
	}
	defer delete(rom)

	for i in 0 ..< len(rom) {
		if 0x200 + i < len(chip8.ram) {
			chip8.ram[0x200 + i] = rom[i]
		}
	}
	return true
}


load_font :: proc(chip8: ^Chip8) {
    font := [?]u8 {
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80, // F
    }

    
    for i in 0 ..< len(font) {
        chip8.ram[0x050 + i] = font[i]
    }
}


fetch :: proc(chip8: ^Chip8) -> u16 {
	o := chip8.ram[chip8.PC]
	t := chip8.ram[chip8.PC + 1]
	chip8.PC += 2
	return u16(o) << 8 | u16(t)
}


clear_display :: proc(chip8: ^Chip8) {
	chip8.display = {}
}


set_key_state :: proc(chip8: ^Chip8, key: int, pressed: bool) {
	if 0 <= key && key < len(chip8.keys) {
		chip8.keys[key] = pressed
	}
}


toggle_pause :: proc(chip8: ^Chip8) {
	chip8.paused = !chip8.paused
}


is_paused :: proc(chip8: ^Chip8) -> bool {
	return chip8.paused
}


cycle :: proc(chip8: ^Chip8) {
	if chip8.paused do return

	op := fetch(chip8)
	F := (op & 0xF000) >> 12
	X := (op & 0x0F00) >> 8
	Y := (op & 0x00F0) >> 4
	N := op & 0x000F
	NN := op & 0x00FF
	NNN := op & 0x0FFF

	switch F {
	case 0x0:
		switch NN {
		case 0xE0:
			clear_display(chip8)
		case 0xEE:
			chip8.PC = queue.pop_back(&chip8.stack)
		}
	case 0x1:
		chip8.PC = NNN
	case 0x2:
		queue.append_elem(&chip8.stack, chip8.PC)
		chip8.PC = NNN
	case 0x3:
		if u16(chip8.reg[X]) == NN do chip8.PC += 2
	case 0x4:
		if u16(chip8.reg[X]) != NN do chip8.PC += 2
	case 0x5:
		if chip8.reg[X] == chip8.reg[Y] do chip8.PC += 2
	case 0x6:
		chip8.reg[X] = u8(NN)
	case 0x7:
		chip8.reg[X] += u8(NN)
	case 0x8:
		switch N {
		case 0x0:
			chip8.reg[X] = chip8.reg[Y]
		case 0x1:
			chip8.reg[X] |= chip8.reg[Y]
		case 0x2:
			chip8.reg[X] &= chip8.reg[Y]
		case 0x3:
			chip8.reg[X] ~= chip8.reg[Y]
		case 0x4:
			sum := u16(chip8.reg[X]) + u16(chip8.reg[Y])
			chip8.reg[X] = u8(sum)
			if sum > 255 do chip8.reg[0xF] = 1
			else do chip8.reg[0xF] = 0
		case 0x5:
			diff := chip8.reg[X] - chip8.reg[Y]
			chip8.reg[0xF] = 1 if chip8.reg[X] >= chip8.reg[Y] else 0
			chip8.reg[X] = diff
		case 0x6:
			chip8.reg[0xF] = chip8.reg[X] & 1
			chip8.reg[X] = chip8.reg[X] >> 1
		case 0x7:
			diff := chip8.reg[Y] - chip8.reg[X]
			chip8.reg[0xF] = 1 if chip8.reg[Y] >= chip8.reg[X] else 0
			chip8.reg[X] = diff
		case 0xE:
			chip8.reg[0xF] = (chip8.reg[X] & 0x80) >> 7
			chip8.reg[X] = chip8.reg[X] << 1
		}
	case 0x9:
		if chip8.reg[X] != chip8.reg[Y] do chip8.PC += 2
	case 0xA:
		chip8.I = NNN
	case 0xB:
		chip8.PC = NNN + u16(chip8.reg[0])
	case 0xC:
		chip8.reg[X] = u8(rand.uint64() & u64(NN))
	case 0xD:
		x := chip8.reg[X] % CH8_WIDTH
		y := chip8.reg[Y] % CH8_HEIGHT
		chip8.reg[0xF] = 0

		for i in 0 ..< N {
			b := chip8.ram[chip8.I + i]
			for j in 0 ..< 8 {
				bit := (b >> u8(7 - j)) & 1
				if bit == 1 {
					px := x + u8(j)
					py := y + u8(i)

					if int(px) < CH8_WIDTH && int(py) < CH8_HEIGHT {
						if chip8.display[px][py] == 1 {
							chip8.reg[0xF] = 1
						}
						chip8.display[px][py] ~= 1
					}
				}
			}
		}
	case 0xE:
		switch NN {
		case 0x9E:
			if chip8.keys[chip8.reg[X]] {
				chip8.PC += 2
			}
		case 0xA1:
			if !chip8.keys[chip8.reg[X]] {
				chip8.PC += 2
			}
		}
	case 0xF:
		switch NN {
		case 0x07:
			chip8.reg[X] = chip8.DTimer
		case 0x0A:
			keyPressed := false
			for i in 0 ..< 16 {
				if chip8.keys[i] {
					chip8.reg[X] = u8(i)
					keyPressed = true
					break
				}
			}
			if !keyPressed do return
		case 0x15:
			chip8.DTimer = chip8.reg[X]
		case 0x18:
			chip8.STimer = chip8.reg[X]
		case 0x1E:
			chip8.I = chip8.I + u16(chip8.reg[X])
		case 0x29:
			chip8.I = u16(0x050 + (chip8.reg[X] * 5))
		case 0x33:
			chip8.ram[chip8.I] = u8(chip8.reg[X] / 100)
			chip8.ram[chip8.I + 1] = u8((chip8.reg[X] / 10) % 10)
			chip8.ram[chip8.I + 2] = u8(chip8.reg[X] % 10)
		case 0x55:
			for i in 0 ..= X {
				chip8.ram[chip8.I + i] = chip8.reg[i]
			}
		case 0x65:
			for i in 0 ..= X {
				chip8.reg[i] = chip8.ram[chip8.I + i]
			}
		}
	}
}


update_timers :: proc(chip8: ^Chip8) {
	if chip8.DTimer > 0 do chip8.DTimer -= 1
	if chip8.STimer > 0 do chip8.STimer -= 1
}
