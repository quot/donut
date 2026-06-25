const std = @import("std");
const math = @import("../utils/math.zig");
const mesh = @import("./mesh.zig");

pub fn newLine(overlay_data: *mesh.OverlayMeshData, edge: [2]mesh.Vertex, width: f32) void {
    // Direction
    // dx = x1 - x0
    // dy = y1 - y0
    // len = sqrt(dx*dx + dy*dy)
    // dir = (dx / len, dy / len)

    const dx = edge[1].position[0] - edge[0].position[0];
    const dy = edge[1].position[1] - edge[0].position[1];
    const len = std.math.sqrt((dx*dx)+(dy*dy));
    // const dir: [2]f32 = .{(dx/len), (dy/len)};

    // Perpendicular Direction
    // normal = (-dy / len, dx / len)
    const normal: [2]f32 = .{(-dy/len), (dx/len)};

    // Offset
    // h = width / 2
    // offset = normal * h
    const h = width / 2;
    // const offset = normal * h;

    // Rect Corners
    // A_left  = (x0 + normal.x*h, y0 + normal.y*h)
    // A_right = (x0 - normal.x*h, y0 - normal.y*h)
    // B_left  = (x1 + normal.x*h, y1 + normal.y*h)
    // B_right = (x1 - normal.x*h, y1 - normal.y*h)
    const a_left = mesh.Vertex.new(.{(edge[0].position[0]+(normal[0]*h)), (edge[0].position[1]+(normal[1]*h))}, edge[0].color);
    const a_right = mesh.Vertex.new(.{(edge[0].position[0]-(normal[0]*h)), (edge[0].position[1]-(normal[1]*h))}, edge[0].color);
    const b_left = mesh.Vertex.new(.{(edge[1].position[0]+(normal[0]*h)), (edge[1].position[1]+(normal[1]*h))}, edge[1].color);
    const b_right = mesh.Vertex.new(.{(edge[1].position[0]-(normal[0]*h)), (edge[1].position[1]-(normal[1]*h))}, edge[1].color);

    overlay_data.addTriangle(.{a_left, a_right, b_right});
    overlay_data.addTriangle(.{b_left, b_right, a_left});
}

pub fn triangle(cent: math.Vec2, side_len: f32) [3]math.Vec2 {
    const height: f32 = (std.math.sqrt(3.0) / 2.0) * side_len;
    return .{
        math.Vec2.new(cent.x, cent.y-(height/3*2)),
        math.Vec2.new(cent.x-(side_len/2), cent.y+(height/3)),
        math.Vec2.new(cent.x+(side_len/2), cent.y+(height/3)),
    };
}