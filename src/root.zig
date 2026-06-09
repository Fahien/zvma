// © 2026 Antonio Caggiano
// SPDX-License-Identifier: MIT

pub const c = @cImport({
    @cInclude("vk_mem_alloc.h");
});

test "links" {
    const f = &c.vmaCreateAllocator;
    if (@intFromPtr(f) == 0) unreachable;
}
