package main

import sdl "vendor:sdl2"
import "core:fmt"
import "core:io"
import "vendor:microui"
import "core:bufio"
import "core:os"
import "core:time"

main :: proc() {
    initSDL()
    defer cleanup()
    game_loop: for {
        prepareScene()

        for i in 0..<20 {
            cycle()
            if doInput() do break game_loop
            cycles+=1
        }
        // fmt.printf("\n\nDisplay:  %x\n\n\n", display)
        render()
        // drawGrid()
        presentScene()
        sdl.Delay(16)
    }
}