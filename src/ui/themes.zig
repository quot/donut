const rl = @import("raylib");
const rg = @import("raygui");

pub const State = struct {
    background_color: rl.Color = rl.Color.white,
};

pub const Theme = enum { Dark };

inline fn col(v: u32) i32 {
    return @bitCast(v);
}

pub inline fn uncol(v: i32) u32 {
    return @bitCast(v);
}

pub fn applyTheme(app_theme: *State, new_theme: Theme) void {
    switch (new_theme) {
        Theme.Dark => applyDarkTheme(app_theme),
    }
}

fn applyDarkTheme(app_theme: *State) void {
    rg.setStyle(.default, .{ .control = .border_color_normal }, col(0x2f7486ff));
    rg.setStyle(.default, .{ .control = .base_color_normal }, col(0x024658ff));
    rg.setStyle(.default, .{ .control = .text_color_normal }, col(0x51bfd3ff));
    rg.setStyle(.default, .{ .control = .border_color_focused }, col(0x82cde0ff));
    rg.setStyle(.default, .{ .control = .base_color_focused }, col(0x3299b4ff));
    rg.setStyle(.default, .{ .control = .text_color_focused }, col(0xb6e1eaff));
    rg.setStyle(.default, .{ .control = .border_color_pressed }, col(0xeb7630ff));
    rg.setStyle(.default, .{ .control = .base_color_pressed }, col(0xffbc51ff));
    rg.setStyle(.default, .{ .control = .text_color_pressed }, col(0x462e00ff));
    rg.setStyle(.default, .{ .control = .border_color_disabled }, col(0x134b5aff));
    rg.setStyle(.default, .{ .control = .base_color_disabled }, col(0x02313dff));
    rg.setStyle(.default, .{ .control = .text_color_disabled }, col(0x17505fff));
    rg.setStyle(.default, .{ .default = .background_color }, col(0x14141bff));
    rg.setStyle(.default, .{ .default = .line_color }, col(0x59b5cbff));

    app_theme.background_color = rl.Color.fromInt(uncol(rg.getStyle(.default, .{ .default = .background_color })));
}
