const math = @import("./math.zig");
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat4 = math.Mat4;

//////////////////////////////
//     Conversions for:
// Screen <-> NDC <-> World

pub fn worldToScreen(w_coords: Vec3, mvp: Mat4, screen_size: Vec2) ?Vec2 {
    const ndc = worldToNdc(w_coords, mvp);

    if (ndc == null) {
        return null;
    } else {
        return ndcToScreen(ndc.?, screen_size);
    }
}

pub fn worldToNdc(w_coords: Vec3, mvp: Mat4) ?Vec3 {
    const clip_x = mvp.m[0][0] * w_coords.x + mvp.m[1][0] * w_coords.y + mvp.m[2][0] * w_coords.z + mvp.m[3][0];
    const clip_y = mvp.m[0][1] * w_coords.x + mvp.m[1][1] * w_coords.y + mvp.m[2][1] * w_coords.z + mvp.m[3][1];
    const clip_z = mvp.m[0][2] * w_coords.x + mvp.m[1][2] * w_coords.y + mvp.m[2][2] * w_coords.z + mvp.m[3][2];
    const clip_w = mvp.m[0][3] * w_coords.x + mvp.m[1][3] * w_coords.y + mvp.m[2][3] * w_coords.z + mvp.m[3][3];

    if (clip_w == 0.0) {
        return null;
    } else {
        return Vec3.new(
            clip_x / clip_w,
            clip_y / clip_w,
            clip_z / clip_w,
        );
    }
}

pub fn ndcToScreen(ndc: Vec3, screen_size: Vec2) Vec2 {
    return .{
        .x = (ndc.x + 1.0) * 0.5 * screen_size.x,
        .y = (1.0 - ndc.y) * 0.5 * screen_size.y,
    };
}

pub fn screenToNdc(screen_pos: Vec2, screen_size: Vec2) Vec2 {
    return Vec2.new(
        (screen_pos.x / screen_size.x) * 2.0 - 1.0,
        1.0 - (screen_pos.y / screen_size.y) * 2.0,
    );
}

//////////
// TODO:
// Should output to a ray with the camera as the source?
// pub fn ndcToWorld() Ray?
// pub fn screenToWorld() Ray?