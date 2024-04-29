package main

import "core:container/queue"
import "core:fmt"
import "core:os"

ram: [4096]u8

reg: [0x10]u8

display: [64][32]u8

stack: queue.Queue(u16)
@(init)
initMem :: proc() {
	queue.init(&stack)

	font := [?]u8 {
		0xF0,
		0x90,
		0x90,
		0x90,
		0xF0, // 0
		0x20,
		0x60,
		0x20,
		0x20,
		0x70, // 1
		0xF0,
		0x10,
		0xF0,
		0x80,
		0xF0, // 2
		0xF0,
		0x10,
		0xF0,
		0x10,
		0xF0, // 3
		0x90,
		0x90,
		0xF0,
		0x10,
		0x10, // 4
		0xF0,
		0x80,
		0xF0,
		0x10,
		0xF0, // 5
		0xF0,
		0x80,
		0xF0,
		0x90,
		0xF0, // 6
		0xF0,
		0x10,
		0x20,
		0x40,
		0x40, // 7
		0xF0,
		0x90,
		0xF0,
		0x90,
		0xF0, // 8
		0xF0,
		0x90,
		0xF0,
		0x10,
		0xF0, // 9
		0xF0,
		0x90,
		0xF0,
		0x90,
		0x90, // A
		0xE0,
		0x90,
		0xE0,
		0x90,
		0xE0, // B
		0xF0,
		0x80,
		0x80,
		0x80,
		0xF0, // C
		0xE0,
		0x90,
		0x90,
		0x90,
		0xE0, // D
		0xF0,
		0x80,
		0xF0,
		0x80,
		0xF0, // E
		0xF0,
		0x80,
		0xF0,
		0x80,
		0x80, // F
	}

	// add font data to memory
	for i in 0 ..< len(font) {
		ram[0x050 + i] = font[i]
	}
	// fmt.println(j)
	// fmt.printf("%x",ram)

	// load rom
	rom: []byte
	ok: bool
	if len(os.args) > 1 do rom, ok = os.read_entire_file(os.args[1])
	else do rom, ok = os.read_entire_file("roms/ibm.ch8")
	assert(ok, "Error loading rom")

	for i in 0 ..< len(rom) {
		ram[0x200 + i] = rom[i]
	}
	// fmt.printf("%x",ram)

	// display[0][0] = 0x01
	// fmt.printf("%x\n\n\n", display)
	// clearDisplay()
	// fmt.printf("%x", display)

}
cycles: u64
I: u16

PC: u16 = 0x200

DTimer, STimer: u8

block := 0

