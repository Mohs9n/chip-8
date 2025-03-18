package main

import sdl "vendor:sdl2"

App :: struct {
	window:           ^sdl.Window,
	renderer:         ^sdl.Renderer,
	viewport_texture: ^sdl.Texture,
}
app: App
