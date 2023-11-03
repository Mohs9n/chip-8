package main

import "core:mem"
import "core:fmt"
import "core:container/queue"
import "core:math/rand"

cycle :: proc() {
    op := fetch()
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
                    clearDisplay()
                case 0xEE:
                    PC = queue.pop_back(&stack)
            }
        case 0x1:
            PC = NNN
        case 0x2:
            queue.append_elem(&stack, PC)
            PC = NNN
        case 0x3:
            if u16(reg[X]) == NN do PC+=2
        case 0x4:
            if u16(reg[X]) != NN do PC+=2
        case 0x5:
            if reg[X] == reg[Y] do PC+=2
        case 0x6:
            reg[X] = u8(NN)
        case 0x7:
            reg[X] += u8(NN)
        case 0x8:
            switch N {
                case 0x0:
                    reg[X] = reg[Y]
                case 0x1:
                    reg[X] |= reg[Y]
                case 0x2:
                    reg[X] &= reg[Y]
                case 0x3:
                    reg[X] ~= reg[Y]
                case 0x4:
                    sum := u16(reg[X]) + u16(reg[Y])
                    reg[X] = u8(sum)
                    if sum > 255 do reg[0xF] = 1
                    else do reg[0xF] = 0
                case 0x5:
                    diff := reg[X] - reg[Y]
                    reg[0xF] = 1 if reg[X] > reg[Y] else 0
                    reg[X] = diff
                case 0x6:
                    reg[X] = reg[Y]
                    reg[0xF] = reg[X] & 1
                    reg[X] = reg[X] >> 1
                case 0x7:
                    diff := reg[Y] - reg[X]
                    reg[0xF] = 1 if reg[Y] > reg[X] else 0
                    reg[X] = diff
                case 0xE:
                    reg[X] = reg[Y]
                    reg[0xF] = (reg[X] & 0x80) >> 7
                    reg[X] = reg[X] << 1
            }
        case 0x9:
            if reg[X] != reg[Y] do PC+=2
        case 0xA:
            I = NNN
        case 0xB:
            PC = NNN + u16(reg[0])
        case 0xC:
            reg[X] = u8(rand._system_random() & u32(NN))
        case 0xD:
                x := reg[X] % 64
                y := reg[Y] % 32
                reg[0xF] = 0
                for i in 0..<N {
                    b := ram[I+i]
                    for j in 0..<8 {
                        bit := (b >> u8(7 - j)) & 1
                        if bit == 1 {
                            if display[x+u8(j)][y+u8(i)] == 1 {
                                reg[0xF] = 1
                                display[x+u8(j)][y+u8(i)] = 0
                            }
                            display[x+u8(j)][y+u8(i)] = 1
                        }
                    }
                }    
                render()
        case 0xE:
            switch NN {
                case 0x9E:
                    
            }
        case 0xF:
            switch NN {
                case 0x07:
                    reg[X] = DTimer
                case 0x15:
                    DTimer = reg[X]
                case 0x18:
                    STimer = reg[X]
                case 0x1E:
                    I = I +u16(reg[X])
                case 0x29:
                    I = u16(0x050 + (reg[X] * 5))
                case 0x33:
                    ram[I] =     u8(reg[X] / 100)
                    ram[I + 1] = u8((reg[X] / 10) % 10)
                    ram[I + 2] = u8(reg[X] % 10)
                case 0x55:
                    for i in 0..=X {
                        ram[I+i] =reg[i]
                    }
                case 0x65:
                    for i in 0..=X {
                        reg[i] = ram[I+i]
                    }
            }
    }
}

fetch :: proc() -> u16 {
    o := ram[PC]
    t := ram[PC+1]
    PC+=2
    return u16(o) << 8 | u16(t)
}

clearDisplay :: proc() {
    mem.zero(&display, len(display))
}