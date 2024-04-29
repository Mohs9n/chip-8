package main

import sdl "vendor:sdl2"

doInput :: proc() -> bool {
	quit := false
	event: sdl.Event
	if sdl.PollEvent(&event) {
		#partial switch event.type {
		case sdl.EventType.QUIT:
			return true
		}
	}
	return false
}

