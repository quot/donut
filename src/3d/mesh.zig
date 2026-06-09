const std = @import("std");

pub const Vertex = struct {
    position: @Vector(3, f32),

    pub fn new(position: @Vector(3, f32)) Vertex {
        return Vertex{ .position = position };
    }
};

pub const Edge = struct {
    vertices: [2]*Vertex,
};

const NGonFace = struct {
    edges: std.ArrayList(*Edge) = undefined,
    color: @Vector(4, f32) = .{ 0, 0, 0, 1},
};

pub const NGon = struct {
    alloc: *const std.mem.Allocator,
    vertices: std.ArrayList(Vertex) = undefined,
    edges: std.ArrayList(Edge) = undefined,
    faces: std.ArrayList(NGonFace) = undefined,
    mesh_verts: std.ArrayList(MeshVertex) = undefined,
    mesh_indices: std.ArrayList(u16) = undefined,

    pub fn new(alloc: *const std.mem.Allocator) NGon {
        return .{
            .alloc = alloc,
            .vertices = std.ArrayList(Vertex).empty,
            .edges = std.ArrayList(Edge).empty,
            .faces = std.ArrayList(NGonFace).empty,
            .mesh_verts = std.ArrayList(MeshVertex).empty,
            .mesh_indices = std.ArrayList(u16).empty,
        };
    }

    pub fn addVert(self: *NGon, vert: Vertex) void {
        // FIX: Properly handle errors
        self.vertices.append(self.alloc.*, vert) catch unreachable;
        // std.log.debug("APPENDED VERTEX! - Array Length: {d}", .{self.vertices.items.len});
    }

    pub fn addEdge(self: *NGon, edge: Edge) void {
        // FIX: Properly handle errors
        self.edges.append(self.alloc.*, edge) catch unreachable;
        // std.log.debug("APPENDED EDGE! - Array Length: {d}", .{self.edges.items.len});
    }

    pub fn newFace(self: *NGon, color: @Vector(4, f32)) usize {
        self.faces.append(self.alloc.*, NGonFace{ .edges = std.ArrayList(*Edge).empty, .color = color }) catch unreachable;
        return self.faces.items.len - 1;
    }

    pub fn addFaceEdge(self: *NGon, face_ind: usize, edge: *Edge) void {
        self.faces.items[face_ind].edges.append(self.alloc.*, edge) catch unreachable;
        // std.log.debug("APPENDED FACE EDGE! - Array Length: {d}", .{self.faces.items[face_ind].edges.items.len});
    }

    pub fn buildMesh(self: *NGon) void {
        var cur_face_vert: usize = 0;

        for (self.faces.items) |cur_face| {
            cur_face_vert = 0;
            for (cur_face.edges.items) |cur_edge| {
                for (cur_edge.*.vertices) |cur_vert| {
                    if (@mod(cur_face_vert, 3)  == 0 and cur_face_vert != 0) {
                        self.mesh_verts.append(self.alloc.*, self.mesh_verts.items[self.mesh_verts.items.len-1]) catch unreachable;
                        self.mesh_indices.append(self.alloc.*, @as(u16, @intCast(self.mesh_verts.items.len-1))) catch unreachable;
                        cur_face_vert += 1;
                    }
                    self.mesh_verts.append(self.alloc.*, MeshVertex.new(cur_vert.*.position, .{0,0,0},  .{0,0}, cur_face.color)) catch unreachable;
                    self.mesh_indices.append(self.alloc.*, @as(u16, @intCast(self.mesh_verts.items.len-1))) catch unreachable;

                    cur_face_vert += 1;
                }
            }
        }

        const overflow_verts = @mod(self.mesh_verts.items.len, 3);
        for (0..overflow_verts) |over_ind| {
            std.log.debug("TOO MANY VERTS! Total Count: {d}, Overflow Count: {d}", .{self.mesh_verts.items.len, over_ind});
            _ = self.mesh_verts.orderedRemove(self.mesh_verts.items.len-1);
            _ = self.mesh_indices.orderedRemove(self.mesh_indices.items.len-1);
        }
    }
};

pub const MeshVertex = extern struct {
    position: @Vector(3, f32),
    normal: @Vector(3, f32),
    texcoord: @Vector(2, f32),
    color: @Vector(4, f32),

    pub fn new(position: [3]f32, normal: [3]f32, texcoord: [2]f32, color: [4]f32) MeshVertex {
        return MeshVertex{ .position = position, .normal = normal, .texcoord = texcoord, .color = color };
    }
};

// pub const MeshData = struct {
//     vertices: []const MeshVertex,
//     indices: []const u16,
// };
