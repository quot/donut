const mesh = @import("../3d/mesh/mesh.zig");
const math = @import("../utils/math.zig");

const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;

// Mesh Data
pub var index_count: u32 = 0;
pub var model_rotation: f32 = 0.0;
pub var mesh_vertices: [18]mesh.MeshVertex = undefined;
pub var mesh_indices: [18]u16 = undefined;

// Camera State
pub var eye_pos: math.Vec3 = math.Vec3.new(0.0, 1.5, 5.0);
pub var eye_focus_pos: math.Vec3 = math.Vec3.zero();
pub var eye_movement: math.Vec3 = math.Vec3.zero();

// TEST
const apex_indices = [_]usize{ 0, 3, 6, 9 };
var apex_pos: f32 = 1.0;
var apex_direction: f32 = 1.0;
const apex_max: f32 = 1.5;
const apex_min: f32 = 0.5;

pub fn drawFrame() void {
    apex_pos += apex_direction * @as(f32, @floatCast(sapp.frameDuration()));
    if (apex_pos >= apex_max) {
        apex_pos = apex_max;
        apex_direction = -@abs(apex_direction);
    } else if (apex_pos <= apex_min) {
        apex_pos = apex_min;
        apex_direction = @abs(apex_direction);
    }

    for (apex_indices) |i| {
        mesh_vertices[i].position[1] = apex_pos;
    }


    eye_pos.y = eye_pos.y + @as(f32, @floatCast(sapp.frameDuration() * eye_movement.y));
    eye_focus_pos.y = eye_focus_pos.y + @as(f32, @floatCast(sapp.frameDuration() * eye_movement.y));
}