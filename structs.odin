package main

import sdl "vendor:sdl2"

App :: struct {
	renderer: ^sdl.Renderer,
	window:   ^sdl.Window,
}
app: App

