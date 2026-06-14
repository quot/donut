const std = @import("std");
const math = @import("../utils/math.zig");

const mesh = @import("mesh.zig");
const MeshVertex = mesh.MeshVertex;
const Vertex = mesh.Vertex;
const Edge = mesh.Edge;

const NGonMesh = mesh.NGonMesh;

pub fn cube(cube_mesh: *NGonMesh) void {
    cube_mesh.*.addVert(.{ .position = @Vector(3, f32){ -1.0, 1.0, 1.0 } });
    cube_mesh.*.addVert(.{ .position = @Vector(3, f32){ 1.0, 1.0, 1.0 } });
    cube_mesh.*.addVert(.{ .position = @Vector(3, f32){ -1.0, 1.0, -1.0 } });
    cube_mesh.*.addVert(.{ .position = @Vector(3, f32){ 1.0, 1.0, -1.0 } });
    cube_mesh.*.addVert(.{ .position = @Vector(3, f32){ -1.0, -1.0, 1.0 } });
    cube_mesh.*.addVert(.{ .position = @Vector(3, f32){ 1.0, -1.0, 1.0 } });
    cube_mesh.*.addVert(.{ .position = @Vector(3, f32){ -1.0, -1.0, -1.0 } });
    cube_mesh.*.addVert(.{ .position = @Vector(3, f32){ 1.0, -1.0, -1.0 } });

    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[0], &cube_mesh.*.vertices.items[1] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[0], &cube_mesh.*.vertices.items[2] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[0], &cube_mesh.*.vertices.items[4] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[1], &cube_mesh.*.vertices.items[3] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[1], &cube_mesh.*.vertices.items[5] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[3], &cube_mesh.*.vertices.items[2] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[3], &cube_mesh.*.vertices.items[7] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[2], &cube_mesh.*.vertices.items[6] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[6], &cube_mesh.*.vertices.items[4] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[6], &cube_mesh.*.vertices.items[7] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[4], &cube_mesh.*.vertices.items[5] } });
    cube_mesh.*.addEdge(mesh.Edge{ .vertices = .{ &cube_mesh.*.vertices.items[5], &cube_mesh.*.vertices.items[7] } });

    var face_ind = cube_mesh.*.newFace(mesh.colors[0]);
    // std.log.debug("FACE APPENDED! - Index: {d}", .{faceInd});

    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[0]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[3]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[5]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[1]);

    face_ind = cube_mesh.*.newFace(mesh.colors[0+face_ind]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[2]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[0]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[4]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[10]);

    face_ind = cube_mesh.*.newFace(mesh.colors[0+face_ind]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[7]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[1]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[2]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[8]);

    face_ind = cube_mesh.*.newFace(mesh.colors[0+face_ind]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[6]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[3]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[4]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[11]);

    face_ind = cube_mesh.*.newFace(mesh.colors[0+face_ind]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[8]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[10]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[6]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[9]);

    face_ind = cube_mesh.*.newFace(mesh.colors[0+face_ind]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[9]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[7]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[5]);
    cube_mesh.*.addFaceEdge(face_ind, &cube_mesh.*.edges.items[6]);

    cube_mesh.*.buildMesh();
}

pub fn pyramidVertices() [18]MeshVertex {
    const apex: [3]f32 = .{ 0.0, 1.0, 0.0 };
    const front_left: [3]f32 = .{ -1.0, -1.0, 1.0 };
    const front_right: [3]f32 = .{ 1.0, -1.0, 1.0 };
    const back_right: [3]f32 = .{ 1.0, -1.0, -1.0 };
    const back_left: [3]f32 = .{ -1.0, -1.0, -1.0 };

    const n_front: [3]f32 = .{ 0.0, 0.4472136, 0.8944272 };
    const n_right: [3]f32 = .{ 0.8944272, 0.4472136, 0.0 };
    const n_back: [3]f32 = .{ 0.0, 0.4472136, -0.8944272 };
    const n_left: [3]f32 = .{ -0.8944272, 0.4472136, 0.0 };
    const n_bottom: [3]f32 = .{ 0.0, -1.0, 0.0 };

    const red: [4]f32 = .{ 1.0, 0.2, 0.2, 1.0 };
    const green: [4]f32 = .{ 0.2, 1.0, 0.2, 1.0 };
    const blue: [4]f32 = .{ 0.2, 0.3, 1.0, 1.0 };
    const yellow: [4]f32 = .{ 1.0, 0.85, 0.2, 1.0 };
    const gray: [4]f32 = .{ 0.65, 0.65, 0.7, 1.0 };

    const uv0: [2]f32 = .{ 0.5, 1.0 };
    const uv1: [2]f32 = .{ 0.0, 0.0 };
    const uv2: [2]f32 = .{ 1.0, 0.0 };

    return [18]MeshVertex{
        // front face
        MeshVertex.new(apex, n_front, uv0, red),
        MeshVertex.new(front_left, n_front, uv1, red),
        MeshVertex.new(front_right, n_front, uv2, red),

        // right face
        MeshVertex.new(apex, n_right, uv0, green),
        MeshVertex.new(front_right, n_right, uv1, green),
        MeshVertex.new(back_right, n_right, uv2, green),

        // back face
        MeshVertex.new(apex, n_back, uv0, blue),
        MeshVertex.new(back_right, n_back, uv1, blue),
        MeshVertex.new(back_left, n_back, uv2, blue),

        // left face
        MeshVertex.new(apex, n_left, uv0, yellow),
        MeshVertex.new(back_left, n_left, uv1, yellow),
        MeshVertex.new(front_left, n_left, uv2, yellow),

        // base triangle 1
        MeshVertex.new(front_left, n_bottom, uv0, gray),
        MeshVertex.new(back_right, n_bottom, uv1, gray),
        MeshVertex.new(front_right, n_bottom, uv2, gray),

        // base triangle 2
        MeshVertex.new(front_left, n_bottom, uv0, gray),
        MeshVertex.new(back_left, n_bottom, uv1, gray),
        MeshVertex.new(back_right, n_bottom, uv2, gray),
    };
}

pub fn pyramidIndices() [18]u16 {
    return [18]u16{
        0,  1,  2,
        3,  4,  5,
        6,  7,  8,
        9,  10, 11,
        12, 13, 14,
        15, 16, 17,
    };
}
