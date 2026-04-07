const rl = @import("raylib");
const rg = @import("raygui");

const ui_base = @import("ui/base.zig");
const ui_theme = @import("ui/themes.zig");

pub fn main() anyerror!void {
    const screenWidth = 1200;
    const screenHeight = 700;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "🍩 Donut");
    defer rl.closeWindow();

    rl.setTargetFPS(120);

    var ui_state = ui_base.State{};
    var ui_theme_state = ui_theme.State{}; // have this under ui_state instead of being its own type

    ui_theme.applyTheme(&ui_theme_state, ui_theme.Theme.Dark);

    // ui_theme.applyDarkTheme();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(ui_theme_state.background_color);
        ui_base.draw_ui(&ui_state);
    }
}
