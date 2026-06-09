const std = @import("std");
const math = @import("../utils/math.zig");

pub fn triangle(cent: math.Vec2, side_len: f32) [3]math.Vec2 {
    const height: f32 = (std.math.sqrt(3.0) / 2.0) * side_len;
    return .{
        math.Vec2.new(cent.x, cent.y-(height/3*2)),
        math.Vec2.new(cent.x-(side_len/2), cent.y+(height/3)),
        math.Vec2.new(cent.x+(side_len/2), cent.y+(height/3)),
    };
}