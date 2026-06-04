const std = @import("std");

const sapp = @import("sokol").app;

pub const config = @import("./Config.zig");
const event_man = @import("./EventManager.zig");

const scene = @import("./render/Scene.zig");
const overlay = @import("./render/Overlay.zig");
const gui = @import("./render/Gui.zig");

pub fn setAlloc(alloc: *const std.mem.Allocator) void {
    scene.gpa = alloc;
}

pub fn appInit() void {
    scene.init();
    overlay.initOverlay();
    gui.initUi();
}

pub fn drawFrame() void {
    scene.drawFrame(config.fov);
    overlay.drawFrame();
    gui.drawFrame();
}

pub fn eventHandler(ev: [*c]const sapp.Event) void {
    // forward input events to sokol-imgui
    const imgui_handled_event = event_man.simgui.handleEvent(ev.*);

    // Track events in imgui example window
    event_man.sappimgui.trackEvent(ev.*);

    switch (ev.*.type) {
        .QUIT_REQUESTED => {
            // sapp.cancelQuit();
        },
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
        else => {},
    }
}

pub fn cleanup() void {
    gui.sappimgui.shutdown();
    gui.simgui.shutdown();
    gui.sgimgui.shutdown();
}
