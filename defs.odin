package main

CH8_WIDTH :: 64
CH8_HEIGHT :: 32

// extra space for ui
SCREEN_WIDTH :: CH8_WIDTH + 30
SCREEN_HEIGHT :: CH8_HEIGHT + 25
SCALE :: 15

viewport_width: i32 = CH8_WIDTH * SCALE
viewport_height: i32 = CH8_HEIGHT * SCALE

PAUSE := true

FPS_INTERVAL :: 1.0

