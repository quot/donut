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
const shaders = @import("3d/shaders/donut.glsl.zig");
const VsParams = shaders.VsParams;
const app = @import("app/State.zig");
const ui = @import("ui/base.zig");
const math = @import("utils/math.zig");

// const mesh = @import("3d/mesh/mesh.zig");
// const shapes = @import("3d/mesh/shapes.zig");

////////////////////////////////////////////////////////////////////////

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

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

export fn frame() void {
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

export fn on_event(ev: [*c]const sapp.Event) void {
    // forward input events to sokol-imgui
    const imgui_handled_event = simgui.handleEvent(ev.*);

    // Track events in imgui example window
    // Main menu -> S-App -> Events
    sappimgui.trackEvent(ev.*);

    switch (ev.*.type) {
        .QUIT_REQUESTED => {
            // sapp.cancelQuit();
        },
        .MOUSE_SCROLL => {
            if (!imgui_handled_event) {
                app.sokol_state.scene_state.model_rotation = @mod((ev.*.scroll_x * app.config.rotation_scale) + app.sokol_state.scene_state.model_rotation, 360.0);
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
                            app.sokol_state.scene_state.eye_movement.y = 0.5;
                        } else {
                            app.sokol_state.scene_state.eye_movement.y = 0.0;
                        }
                    }
                },
                else => {},
            }
        },
        else => {},
    }
}

export fn cleanup() void {
    sappimgui.shutdown();
    simgui.shutdown();
    sgimgui.shutdown();
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = on_event,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .window_title = "🍩",
        .logger = .{ .func = slog.func },
    });
}
