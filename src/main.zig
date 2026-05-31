const std = @import("std");

// Sokol Imports
const use_docking = @import("build_options").docking;
const ig = if (use_docking) @import("cimgui_docking") else @import("cimgui");

const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;
const simgui = sokol.imgui;
const sgimgui = sokol.gfximgui;
const sappimgui = sokol.appimgui;

// Donut Imports
const shaders = @import("shaders/donut.glsl.zig");
const VsParams = shaders.VsParams;
const app = @import("app/State.zig");
const ui = @import("ui/base.zig");
const math = @import("utils/math.zig");

////////////////////////////////////////////////////////////////////////

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
    app.sokol_state.initGraphics();

    /////////////
    // UI Setup

    sappimgui.setup();
    sgimgui.setup(.{});
    simgui.setup(.{
        .logger = .{ .func = slog.func },
    });
    if (use_docking) {
        ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }

    ////////////////////
    // Rendering Setup
    app.sokol_state.initSokol();
    app.sokol_state.initPassActions(&app.config.clear_color);
}

export fn frameCb() void {
    // call simgui.newFrame() before any ImGui calls
    simgui.newFrame(.{
        .width = sapp.width(),
        .height = sapp.height(),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });

    // For debugging hud
    sappimgui.trackFrame();

    ui.drawBaseUi();

    //////////////////////
    // 3D Scene Building
    app.sokol_state.drawFrame(app.config.fov);

    // Final Rendering
    simgui.render();
    sg.endPass();
    sg.commit();
}

export fn onEventCb(ev: [*c]const sapp.Event) void {
    // forward input events to sokol-imgui
    const imgui_handled_event = simgui.handleEvent(ev.*);

    // Track events in imgui example window
    sappimgui.trackEvent(ev.*);

    switch (ev.*.type) {
        .QUIT_REQUESTED => {
            // sapp.cancelQuit();
        },
        .MOUSE_SCROLL => {
            if (!imgui_handled_event) {
                app.sokol_state.scene.model_rotation = @mod((ev.*.scroll_x * app.config.rotation_scale) + app.sokol_state.scene.model_rotation, 360.0);
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
                            app.sokol_state.scene.eye_movement.y = 0.5;
                        } else {
                            app.sokol_state.scene.eye_movement.y = 0.0;
                        }
                    }
                },
                else => {},
            }
        },
        else => {},
    }
}

export fn cleanupCb() void {
    sappimgui.shutdown();
    simgui.shutdown();
    sgimgui.shutdown();
    sg.shutdown();
}
