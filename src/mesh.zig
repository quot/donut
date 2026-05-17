pub const MeshVertex = extern struct {
    position: @Vector(3, f32),
    normal: @Vector(3, f32),
    texcoord: @Vector(2, f32),
    color: @Vector(4, f32),

    pub fn new(position: [3]f32, normal: [3]f32, texcoord: [2]f32, color: [4]f32) MeshVertex {
        return MeshVertex{ .position = position, .normal = normal, .texcoord = texcoord, .color = color };
    }
};

pub const MeshData = struct {
    vertices: []const MeshVertex,
    indices: []const u16,
};