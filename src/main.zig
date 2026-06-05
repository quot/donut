const std = @import("std");

// Sokol
const sokol = @import("sokol");
const sapp = sokol.app;
const slog = sokol.log;

// Donut Imports
const app = @import("./App.zig");


pub fn main(init: std.process.Init) void {
    const gpa = init.gpa;
    app.setAlloc(&gpa);

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