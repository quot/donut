const std = @import("std");

const math = @import("../utils/math.zig");

pub const colors: [6][4]f32 = .{
    .{ 0.1, 0.1, 0.1, 1.0 },
    .{ 1.0, 0.2, 0.2, 1.0 },
    .{ 0.2, 1.0, 0.2, 1.0 },
    .{ 0.2, 0.3, 1.0, 1.0 },
    .{ 1.0, 0.85, 0.2, 1.0 },
    .{ 0.65, 0.65, 0.7, 1.0 },
};

fn computeNormal(tri: [3]*Vertex) [3]f32 {
    // https://wikis.khronos.org/opengl/Calculating_a_Surface_Normal

    const p1 = math.Vec3.fromVector(tri[0].position);
    const p2 = math.Vec3.fromVector(tri[1].position);
    const p3 = math.Vec3.fromVector(tri[2].position);

    const vec_u = math.Vec3.sub(p2, p1);
    const vec_v = math.Vec3.sub(p3, p1);

    // return math.Vec3.mul(math.Vec3.cross(vec_u, vec_v), -1.0).toArray();
    return math.Vec3.cross(vec_u, vec_v).toArray();
}

pub const Vertex = struct {
    position: @Vector(3, f32),

    pub fn new(position: @Vector(3, f32)) Vertex {
        return Vertex{ .position = position };
    }

    pub fn equals(self: *const Vertex, v: Vertex) bool {
        return @reduce(.And, self.*.position == v.position);
    }

    pub fn print(self: *const Vertex) void {
        std.log.debug("VERTEX: [{d}, {d}, {d}]", .{self.*.position[0], self.*.position[1], self.*.position[2]});
    }
};

pub const Edge = struct {
    vertices: [2]*Vertex,
};

const NGonFace = struct {
    alloc: *const std.mem.Allocator,
    edges: std.ArrayList(*Edge) = undefined,
    triangles: std.ArrayList([3]*Vertex) = undefined,
    normal: ?@Vector(3, f32) = null,
    color: @Vector(4, f32) = .{ 0, 0, 0, 1 },

    pub fn new(gpa: *const std.mem.Allocator, color: @Vector(4, f32)) NGonFace {
        return .{
            .alloc = gpa,
            .edges =  .empty,
            .triangles = .empty,
            .color = color,
        };
    }

    fn printEdges(self: *const NGonFace) void {
        var log_str = std.ArrayList(u8).empty;
        defer log_str.deinit(self.alloc.*);

        log_str.print(self.alloc.*, "[{*}] Edges:", .{self}) catch unreachable;

        for (0..self.*.edges.items.len) |index| {
            log_str.print(self.alloc.*, "\nEdge [{d}]: [{d},{d},{d}]<->[{d},{d},{d}]", .{
                index,
                self.edges.items[index].*.vertices[0].*.position[0],
                self.edges.items[index].*.vertices[0].*.position[1],
                self.edges.items[index].*.vertices[0].*.position[2],
                self.edges.items[index].*.vertices[1].*.position[0],
                self.edges.items[index].*.vertices[1].*.position[1],
                self.edges.items[index].*.vertices[1].*.position[2],
            }) catch unreachable;
        }

        std.log.debug("{s}", .{log_str.items});
    }

    fn printTriangleVerts(self: *const NGonFace) void {
        var log_str = std.ArrayList(u8).empty;
        defer log_str.deinit(self.alloc.*);

        log_str.print(self.alloc.*, "[{*}] Trianles:", .{self}) catch unreachable;

        for (0..self.*.triangles.items.len) |tri_ind| {
            log_str.print(self.alloc.*, "\nTRI [{d}]:", .{tri_ind}) catch unreachable;
            for (0..self.*.triangles.items[tri_ind].len) |vert_ind| {
                log_str.print(self.alloc.*, "\n -> VERTEX [{d}]: [{d}, {d}, {d}]", .{vert_ind, self.*.triangles.items[tri_ind][vert_ind].*.position[0], self.*.triangles.items[tri_ind][vert_ind].*.position[1], self.*.triangles.items[tri_ind][vert_ind].*.position[2]}) catch unreachable;
            }
        }
        std.log.debug("{s}", .{log_str.items});
    }

    pub fn sortEdges(self: *NGonFace) void {
        for (0..self.edges.items.len - 1) |index| {
            const next_vert = self.edges.items[index].*.vertices[1].*;

            if (!next_vert.equals(self.edges.items[index + 1].*.vertices[0].*)) {
                var swap_index = index + 1;

                search_loop: for ((index + 1)..self.edges.items.len) |search_index| {
                    if (next_vert.equals(self.edges.items[search_index].*.vertices[1].*)) {
                        std.mem.swap(*Vertex, &self.edges.items[search_index].*.vertices[0], &self.edges.items[search_index].*.vertices[1]);
                        swap_index = search_index;
                        break :search_loop;
                    }

                    if (next_vert.equals(self.edges.items[search_index].*.vertices[0].*)) {
                        swap_index = search_index;
                        break :search_loop;
                    }
                }
                if (swap_index != index + 1) {
                    std.mem.swap(*Edge, &self.edges.items[index + 1], &self.edges.items[swap_index]);
                }
            }
        }
    }

    pub fn buildMesh(self: *NGonFace) void {
        std.log.debug("--- [{*}] buildMesh ------------", .{self});
        self.triangles = .empty;
        self.sortEdges();
        var cur_triangle: [3]?*Vertex = .{null, null, null}; // Build array of triangles instead of flat vertex list.

        for (0..self.edges.items.len) |edge_ind| {
            if (edge_ind == 0) {
                cur_triangle[0] = self.edges.items[edge_ind].*.vertices[0];
            }

            const next_vert = self.edges.items[edge_ind].*.vertices[1];

            if (cur_triangle[1] == null) {
                cur_triangle[1] = next_vert;
            } else {
                if (cur_triangle[2] == null) { cur_triangle[2] = next_vert; }
                const last_vert = cur_triangle[2];
                self.*.triangles.append(self.alloc.*, [3]*Vertex{cur_triangle[0].?, cur_triangle[1].?, cur_triangle[2].?}) catch unreachable;
                cur_triangle = .{last_vert, null, null};
            }
        }

        // Add first tri vert to last last triangle
        if (cur_triangle[1] != null and cur_triangle[2] == null and self.triangles.items.len >= 1) {
            cur_triangle[2] = self.triangles.items[0][0];
            self.*.triangles.append(self.alloc.*, [3]*Vertex{cur_triangle[0].?, cur_triangle[1].?, cur_triangle[2].?}) catch unreachable;
        }

        self.printEdges();
        self.printTriangleVerts();

        if (!self.*.triangles.getLast()[2].*.equals(self.*.triangles.items[0][0].*)) {
            std.log.err("[{*}] FIRST/LAST DONT MATCH! - CLEARING!", .{self});
            self.*.triangles = .empty;
        }
        std.log.debug("--- buildMesh Done ------------", .{});
    }
};

pub const NGonMesh = struct {
    alloc: *const std.mem.Allocator,
    vertices: std.ArrayList(Vertex) = undefined,
    edges: std.ArrayList(Edge) = undefined,
    faces: std.ArrayList(NGonFace) = undefined,

    // TODO: Move to NGon struct.
    mesh_verts: std.ArrayList(MeshVertex) = undefined,
    mesh_indices: std.ArrayList(u16) = undefined,

    pub fn new(alloc: *const std.mem.Allocator) NGonMesh {
        return .{
            .alloc = alloc,
            .vertices = std.ArrayList(Vertex).empty,
            .edges = std.ArrayList(Edge).empty,
            .faces = std.ArrayList(NGonFace).empty,
            .mesh_verts = std.ArrayList(MeshVertex).empty,
            .mesh_indices = std.ArrayList(u16).empty,
        };
    }

    pub fn addVert(self: *NGonMesh, vert: Vertex) void {
        // FIX: Properly handle errors
        self.vertices.append(self.alloc.*, vert) catch unreachable;
        // std.log.debug("APPENDED VERTEX! - Array Length: {d}", .{self.vertices.items.len});
    }

    pub fn addEdge(self: *NGonMesh, edge: Edge) void {
        // FIX: Properly handle errors
        self.edges.append(self.alloc.*, edge) catch unreachable;
        // std.log.debug("APPENDED EDGE! - Array Length: {d}", .{self.edges.items.len});
    }

    pub fn newFace(self: *NGonMesh, color: @Vector(4, f32)) usize {
        self.faces.append(self.alloc.*, NGonFace.new(self.alloc, color)) catch unreachable;
        return self.faces.items.len - 1;
    }

    pub fn addFaceEdge(self: *NGonMesh, face_ind: usize, edge: *Edge) void {
        self.faces.items[face_ind].edges.append(self.alloc.*, edge) catch unreachable;
        // std.log.debug("APPENDED FACE EDGE! - Array Length: {d}", .{self.faces.items[face_ind].edges.items.len});
    }

    fn addMeshVert(self: *NGonMesh, vert: MeshVertex) void {
        // std.log.debug("Appending: [{d},{d},{d}]", .{ vert.position[0], vert.position[1], vert.position[2] });
        self.mesh_verts.append(self.alloc.*, vert) catch unreachable;
        self.mesh_indices.append(self.alloc.*, @as(u16, @intCast(self.mesh_verts.items.len - 1))) catch unreachable;
    }

    pub fn buildMesh(self: *NGonMesh) void {
        for (self.faces.items) |*cur_face| {
            cur_face.buildMesh();

            for (cur_face.*.triangles.items) |cur_tri| {
                const normal = computeNormal(cur_tri);
                for (0..cur_tri.len) |tri_ind| {
                    self.addMeshVert(MeshVertex.new(cur_tri[tri_ind].*.position, normal, .{ 0, 0 }, cur_face.color));
                }
                if (self.mesh_verts.items.len % 3 != 0) { std.log.err("Mesh verts not divisible by 3!", .{}); }
            }
            // for (cur_face.edges.items) |cur_edge| {
            //     for (cur_edge.*.vertices) |cur_vert| {
            //         if (self.mesh_verts.items.len == 0 or !self.mesh_verts.items[self.mesh_verts.items.len - 1].equalsPosition(cur_vert.*.position)) {
            //             self.addMeshVert(MeshVertex.new(cur_vert.*.position, .{ 0.7, 0.7, 0.7 }, .{ 0, 0 }, cur_face.color));
            //         }

            //         if (@mod(self.mesh_verts.items.len, 3) == 0) {
            //             self.addMeshVert(MeshVertex.new(cur_vert.*.position, .{ 0.7, 0.7, 0.7 }, .{ 0, 0 }, cur_face.color));
            //         }
            //     }
            // }
            // const overflow_verts = @mod(self.mesh_verts.items.len, 3);
            // for (0..overflow_verts) |over_ind| {
            //     std.log.debug("TOO MANY VERTS! Total Count: {d}, Overflow Count: {d}", .{ self.mesh_verts.items.len, (overflow_verts - over_ind) });
            //     _ = self.mesh_verts.orderedRemove(self.mesh_verts.items.len - 1);
            //     _ = self.mesh_indices.orderedRemove(self.mesh_indices.items.len - 1);
            // }
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

    pub fn equalsPosition(self: *const MeshVertex, pos: @Vector(3, f32)) bool {
        return (self.*.position[0] == pos[0] and self.*.position[1] == pos[1] and self.*.position[2] == pos[2]);
    }
};

// pub const MeshData = struct {
//     vertices: []const MeshVertex,
//     indices: []const u16,
// };
