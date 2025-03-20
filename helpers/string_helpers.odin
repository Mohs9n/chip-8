package helpers

import "core:fmt"
import "core:strings"

fmt_cstr :: proc(format: string, args: ..any) -> cstring {
    return strings.clone_to_cstring(fmt.tprintf(format, ..args), allocator = context.temp_allocator)
}