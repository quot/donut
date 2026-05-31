const std = @import("std");

pub const sokol_state = @import("SokolState.zig");
pub const config = @import("Config.zig");

pub fn setAlloc(alloc: *const std.mem.Allocator) void {
    sokol_state.gpa = alloc;
}
