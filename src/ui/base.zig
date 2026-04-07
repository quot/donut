const rl = @import("raylib");
const rg = @import("raygui");

pub const State = struct {
    show_message_box: bool = false,
};

const status_bar_height: f32 = 20;

pub fn draw_ui(state: *State) void {
    const win_height: f32 = @floatFromInt(rl.getScreenHeight());
    const win_width: f32 = @floatFromInt(rl.getScreenWidth());

    const btn_rect = rl.Rectangle{ .x = 0, .y = 0, .width = 50, .height = 50 };

    if (rg.button(btn_rect, "Click me!")) {
        state.show_message_box = true;
    }

    if (state.show_message_box) {
        const result = rg.messageBox(
            rl.Rectangle{ .x = 200, .y = 150, .width = 400, .height = 150 },
            "Hello!",
            "This is a placeholder message.",
            "OK",
        );
        if (result >= 0) {
            state.show_message_box = false;
        }
    }

    _ = rg.statusBar(.{ .x = 0.0, .y = (win_height - status_bar_height), .height = status_bar_height, .width = win_width }, "TEST");
}
