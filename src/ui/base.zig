const use_docking = @import("build_options").docking;
const ig = if (use_docking) @import("cimgui_docking") else @import("cimgui");

const sokol = @import("sokol");
const sg = sokol.gfx;
const sgimgui = sokol.gfximgui;
const sappimgui = sokol.appimgui;

pub fn buildUi() void {
    // const backendName: [*c]const u8 = switch (sg.queryBackend()) {
    //     .D3D11 => "Direct3D11",
    //     .GLCORE => "OpenGL",
    //     .GLES3 => "OpenGLES3",
    //     .METAL_IOS => "Metal iOS",
    //     .METAL_MACOS => "Metal macOS",
    //     .METAL_SIMULATOR => "Metal Simulator",
    //     .WGPU => "WebGPU",
    //     .VULKAN => "Vulkan",
    //     .DUMMY => "Dummy",
    // };

    ig.igSetNextWindowPos(.{ .x = 10, .y = 30 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);

    // if (ig.igBegin("Hello Dear ImGui!", &show_first_window, ig.ImGuiWindowFlags_None)) {
    //     _ = ig.igColorEdit3("Background", &clear_color.r, ig.ImGuiColorEditFlags_None);
    //     _ = ig.igText("Dear ImGui Version: %s", ig.IMGUI_VERSION);
    // }
    // ig.igEnd();

    ig.igSetNextWindowPos(.{ .x = 50, .y = 150 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);

    // if (ig.igBegin("Another Window", &show_second_window, ig.ImGuiWindowFlags_None)) {
    //     _ = ig.igText("Sokol Backend: %s", backendName);
    // }
    // ig.igEnd();

    // the sokol-gfx-imgui debugging ui
    if (ig.igBeginMainMenuBar()) {
        sgimgui.drawMenu("sokol-gfx");
        sappimgui.drawMenu("sokol-app");
        ig.igEndMainMenuBar();
    }
}