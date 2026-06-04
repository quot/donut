const sokol = @import("sokol");
const sg = sokol.gfx;

// TODO: Load these from a user config file
pub var clear_color: sg.Color = .{ .r = 0.94, .g = 0.94, .b = 0.94, .a = 1.0 };
pub const rotation_scale: f32 = 1.5;
pub const fov: f32 = 60.0;
