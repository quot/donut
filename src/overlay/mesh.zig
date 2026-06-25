const std = @import("std");

pub const Vertex = struct {
    position: [2]f32,
    color: [3]f32,

    pub fn new(position: [2]f32, color: [3]f32) Vertex {
        return Vertex{ .position = position, .color = color };
    }
};

pub const Triangle = struct {
    // FIX: Rework list of pointers. This could cause dangling pointers
    //      if reference is reallocated.
    //      Posible alternative: Store the item's index value instead.
    vertices: [3]*Vertex,
};

pub const OverlayMeshData = struct {
    alloc: *const std.mem.Allocator,
    vertices: std.ArrayList(Vertex) = undefined,
    vertex_indices: std.ArrayList(usize) = undefined,
    triangles: std.ArrayList(Triangle) = undefined,

    pub fn new(gpa: *const std.mem.Allocator) OverlayMeshData {
        return OverlayMeshData{
            .alloc = gpa,
            .vertices = .empty,
            .vertex_indices = .empty,
            .triangles = .empty,
        };
    }

    pub fn addVertex(self: *OverlayMeshData, vertex: Vertex) void {
        self.vertices.append(self.alloc.*, vertex) catch undefined;
        self.vertex_indices.append(self.alloc.*, self.vertices.items.len-1) catch undefined;
    }

    pub fn addTriangle(self: *OverlayMeshData, vertices: [3]Vertex) void {
        for (vertices) |vert| {
            self.addVertex(vert);
        }

        self.triangles.append(self.alloc.*, Triangle{
            .vertices = .{
                &self.vertices.items[self.vertices.items.len-3],
                &self.vertices.items[self.vertices.items.len-2],
                &self.vertices.items[self.vertices.items.len-1],
            },
        }) catch undefined;
    }
};
