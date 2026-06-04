const std = @import("std");

const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;

// Donut Imports
const app = @import("./App.zig");

pub var pass_action: sg.PassAction = .{};

pub fn main(init: std.process.Init) void {
    const gpa = init.gpa;
    app.setAlloc(&gpa);

    sapp.run(.{
        .init_cb = initCb,
        .frame_cb = frameCb,
        .event_cb = onEventCb,
        .cleanup_cb = cleanupCb,
        .width = 800,
        .height = 600,
        // .sample_count = 4,
        .window_title = "🍩",
        .logger = .{ .func = slog.func },
    });
}

export fn initCb() void {
    // Init graphics
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // Setup all app states
    app.appInit();

    // Setup screen clearing
    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = app.config.clear_color,
    };
    pass_action.depth = .{
        .load_action = .CLEAR,
        .clear_value = 1.0,
    };
}

export fn frameCb() void {
    sg.beginPass(.{ .action = pass_action, .swapchain = sglue.swapchain() });

    app.drawFrame();

    // Final Rendering
    sg.endPass();
    sg.commit();
}

export fn onEventCb(ev: [*c]const sapp.Event) void {
    app.eventHandler(ev);
}

export fn cleanupCb() void {
    app.cleanup();
    sg.shutdown();
}
