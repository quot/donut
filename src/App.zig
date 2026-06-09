const std = @import("std");

// Sokol
const sokol = @import("sokol");
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;
const sg = sokol.gfx;

var pass_action: sg.PassAction = .{};

// Rendering
const scene = @import("./3d/Scene.zig");
const overlay = @import("./overlay/Overlay.zig");
const gui = @import("./ui/Gui.zig");

// ImGui
pub const simgui = sokol.imgui;
pub const sgimgui = sokol.gfximgui;
pub const sappimgui = sokol.appimgui;

// App States
const config = @import("./Config.zig");
var gpa: *const std.mem.Allocator = undefined;

// TESTING: Overlay frame update
const math = @import("./utils/math.zig");
const coords = @import("./utils/coords.zig");

pub fn setAlloc(alloc: *const std.mem.Allocator) void {
    gpa = alloc;
}

pub export fn initCb() void {
    // Init graphics
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // Setup State Managers
    scene.init(gpa);
    overlay.initOverlay();
    gui.initUi();

    // Setup screen clearing
    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = config.clear_color,
    };
    pass_action.depth = .{
        .load_action = .CLEAR,
        .clear_value = 1.0,
    };
}

pub export fn frameCb() void {
    sg.beginPass(.{ .action = pass_action, .swapchain = sglue.swapchain() });

    // Frame Updates
    scene.drawFrame(config.fov);
    overlay.drawFrame(coords.worldToScreen(scene.getApexPos(), scene.mvp, math.Vec2.new(sapp.widthf(), sapp.heightf())));
    gui.drawFrame();

    // Final Rendering
    sg.endPass();
    sg.commit();
}

pub export fn eventCb(ev: [*c]const sapp.Event) void {
    // Forward input events to sokol-imgui
    const imgui_handled_event = simgui.handleEvent(ev.*);

    // Track events in imgui example window
    sappimgui.trackEvent(ev.*);

    switch (ev.*.type) {
        .MOUSE_SCROLL => {
            if (!imgui_handled_event) {
                scene.model_rotation = @mod((ev.*.scroll_x * config.rotation_scale) + scene.model_rotation, 360.0);
            }
        },
        .KEY_DOWN, .KEY_UP => {
            switch (ev.*.key_code) {
                .ESCAPE => {
                    sapp.requestQuit();
                },
                .E => {
                    if (!imgui_handled_event) {
                        if (ev.*.type == .KEY_DOWN) {
                            scene.eye_movement.y = 0.5;
                        } else {
                            scene.eye_movement.y = 0.0;
                        }
                    }
                },
                else => {},
            }
        },
        // .QUIT_REQUESTED => {
        //     sapp.cancelQuit();
        // },
        else => {},
    }
}

pub export fn cleanupCb() void {
    gui.sappimgui.shutdown();
    gui.simgui.shutdown();
    gui.sgimgui.shutdown();
    sg.shutdown();
}
