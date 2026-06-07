const std = @import("std");
const builtin = @import("builtin");

// Sokol
const sokol = @import("sokol");
const sapp = sokol.app;
const slog = sokol.log;

// Donut Imports
const app = @import("./App.zig");

pub fn main(init: std.process.Init) void {
    var debug_alloc = std.heap.DebugAllocator(.{
            // .never_unmap = true,
            // .safety = true,
        }){};
    defer std.debug.assert(debug_alloc.deinit() == .ok);

    const alloc = switch (builtin.mode) {
        .Debug => debug_alloc.allocator(),
        else => init.gpa,
    };

    app.setAlloc(&alloc);

    sapp.run(.{
        .init_cb = app.initCb,
        .frame_cb = app.frameCb,
        .event_cb = app.eventCb,
        .cleanup_cb = app.cleanupCb,
        .width = 800,
        .height = 600,
        // .sample_count = 4,
        .window_title = "🍩",
        .logger = .{ .func = slog.func },
    });
}