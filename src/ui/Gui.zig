const use_docking = @import("build_options").docking;
const ig = if (use_docking) @import("cimgui_docking") else @import("cimgui");

// Sokol
const sokol = @import("sokol");
const sapp = sokol.app;
const slog = sokol.log;

// ImGui
pub const simgui = sokol.imgui;
pub const sgimgui = sokol.gfximgui;
pub const sappimgui = sokol.appimgui;

// App
const base_ui = @import("./base.zig");

pub fn initUi() void {
    sappimgui.setup();
    sgimgui.setup(.{});
    simgui.setup(.{ .logger = .{ .func = slog.func } });

    if (use_docking) {
        ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }
}

pub fn drawFrame() void {
    // call simgui.newFrame() before any ImGui calls
    simgui.newFrame(.{
        .width = sapp.width(),
        .height = sapp.height(),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });

    // For debugging hud
    sappimgui.trackFrame();

    base_ui.buildUi();

    sgimgui.draw();
    sappimgui.draw();

    simgui.render();
}