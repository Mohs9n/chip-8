package main

import sdl "vendor:sdl2"
import sdlF "vendor:sdl2/ttf"

render :: proc() {
	sdl.SetRenderDrawColor(app.renderer, 255, 255, 255, 255)
	for i in 0 ..< len(display) {
		for j in 0 ..< len(display[i]) {
			if display[i][j] == 1 {
				rect: sdl.Rect = {i32(i) * SCALE, i32(j) * SCALE, SCALE, SCALE}
				sdl.RenderFillRect(app.renderer, &rect)
			}
		}
	}
}

drawText :: proc(x, y: i32, font: ^sdlF.Font, text: cstring, color: sdl.Color) {
	surfaceMessege: ^sdl.Surface = sdlF.RenderText_Solid(font, text, color)
	defer sdl.FreeSurface(surfaceMessege)
	texture: ^sdl.Texture = sdl.CreateTextureFromSurface(app.renderer, surfaceMessege)
	defer sdl.DestroyTexture(texture)

	textRect: sdl.Rect = {x, y, surfaceMessege.w, surfaceMessege.h}
	sdl.RenderCopy(app.renderer, texture, nil, &textRect)
}

drawGrid :: proc() {
	sdl.SetRenderDrawColor(app.renderer, 255, 20, 30, 255)
	for i in 0 ..< 64 {
		for j in 0 ..< 32 {
			rect: sdl.Rect = {i32(i) * SCALE, i32(j) * SCALE, SCALE, SCALE}
			sdl.RenderDrawRect(app.renderer, &rect)
		}
	}
	// rect: sdl.Rect = {1 * SCALE,1*SCALE,SCALE,SCALE}
	// sdl.RenderDrawRect(app.renderer, &rect)

}

prepareScene :: proc() {
	sdl.SetRenderDrawColor(app.renderer, 0x50, 0x99, 0xA0, 0xFF)
	sdl.RenderClear(app.renderer)
}

presentScene :: proc() {
	sdl.RenderPresent(app.renderer)
}
