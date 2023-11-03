package main

import sdl "vendor:sdl2"

render :: proc() {
    sdl.SetRenderDrawColor(app.renderer, 255,255,255,255)
    for i in 0..<len(display) {
        for j in 0..<len(display[i]){
            if display[i][j]==1{
                rect: sdl.Rect = {i32(i) * SCALE,i32(j) * SCALE,SCALE,SCALE}
                sdl.RenderFillRect(app.renderer, &rect)
            }
        }
    }
//  0x70 0x70 0x20 0x70 0xA8 0x20 0x50 0x50

}

drawGrid :: proc() {
    sdl.SetRenderDrawColor(app.renderer, 255,20,30,255)
    for i in 0..<64 {
        for j in 0..<32 { 
            rect: sdl.Rect = {i32(i) * SCALE,i32(j) * SCALE,SCALE,SCALE}
            sdl.RenderDrawRect(app.renderer, &rect)
        }
    }
    // rect: sdl.Rect = {1 * SCALE,1*SCALE,SCALE,SCALE}
    // sdl.RenderDrawRect(app.renderer, &rect)

}

prepareScene :: proc() {
    sdl.SetRenderDrawColor(app.renderer, 10, 20, 30, 255)
    sdl.RenderClear(app.renderer)
}

presentScene :: proc() {
    sdl.RenderPresent(app.renderer)
}