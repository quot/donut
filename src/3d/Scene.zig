const std = @import("std");

const scene_shaders = @import("../shaders/scene.glsl.zig");

const mesh = @import("../3d/mesh.zig");
const math = @import("../utils/math.zig");
const shapes = @import("../3d/shapes.zig");

const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;

// Mesh Data
pub var index_count: u32 = 0;
pub var model_rotation: f32 = 0.0;
pub var mesh_vertices: []mesh.MeshVertex = undefined;
pub var mesh_indices: []u16 = undefined;

// Camera State
pub var eye_pos: math.Vec3 = math.Vec3.new(0.0, 1.5, 5.0);
pub var eye_focus_pos: math.Vec3 = math.Vec3.zero();
pub var eye_movement: math.Vec3 = math.Vec3.zero();

pub var mvp: math.Mat4 = undefined;

pub var gpa: *const std.mem.Allocator = undefined;

pub var pip: sg.Pipeline = .{};
pub var bind: sg.Bindings = .{};

//////////////
// TESTING

// Pyramid
const apex_indices = [_]usize{ 0, 3, 6, 9 };
var apex_pos: f32 = 1.0;
var apex_direction: f32 = 1.0;
const apex_max: f32 = 1.5;
const apex_min: f32 = 0.5;

// Cube
var cube: mesh.NGonMesh = undefined;

///////////////

pub fn init(appGpa: *const std.mem.Allocator) void {
    gpa = appGpa;

    ////////////////////
    // Test Cube Build
    cube = mesh.NGonMesh.new(gpa);
    shapes.cube(&cube);

    ///////////////
    // Mesh Setup

    mesh_vertices = cube.mesh_verts.items;

    bind.vertex_buffers[0] = sg.makeBuffer(.{
        .size = mesh_vertices.len * @sizeOf(mesh.MeshVertex),
        .usage = .{
            .vertex_buffer = true,
            .stream_update = true,
        },
    });

    mesh_indices = cube.mesh_indices.items;

    bind.index_buffer = sg.makeBuffer(.{
        .usage = .{
            .index_buffer = true,
            .immutable = true,
        },
        .data = sg.asRange(mesh_indices),
    });

    index_count = @intCast(mesh_indices.len);

    ///////////////////
    // Pipeline Setup

    const shd = sg.makeShader(scene_shaders.sceneShaderDesc(sg.queryBackend()));

    var pip_desc: sg.PipelineDesc = .{
        .shader = shd,
        .primitive_type = .TRIANGLES,
        .index_type = .UINT16,
        .cull_mode = .NONE,
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
    };

    pip_desc.layout.buffers[0].stride = @sizeOf(mesh.MeshVertex);

    pip_desc.layout.attrs[scene_shaders.sceneAttrSlot("position").?] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(mesh.MeshVertex, "position"),
    };

    pip_desc.layout.attrs[scene_shaders.sceneAttrSlot("normal").?] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(mesh.MeshVertex, "normal"),
    };

    pip_desc.layout.attrs[scene_shaders.sceneAttrSlot("texcoord").?] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(mesh.MeshVertex, "texcoord"),
    };

    pip_desc.layout.attrs[scene_shaders.sceneAttrSlot("color").?] = .{
        .format = .FLOAT4,
        .offset = @offsetOf(mesh.MeshVertex, "color"),
    };

    pip = sg.makePipeline(pip_desc);
}

pub fn drawFrame(fov: f32) void {
    /////////////////
    // Mesh Updates

    // apex_pos += apex_direction * @as(f32, @floatCast(sapp.frameDuration()));
    // if (apex_pos >= apex_max) {
    //     apex_pos = apex_max;
    //     apex_direction = -@abs(apex_direction);
    // } else if (apex_pos <= apex_min) {
    //     apex_pos = apex_min;
    //     apex_direction = @abs(apex_direction);
    // }

    // for (apex_indices) |i| {
    //     mesh_vertices[i].position[1] = apex_pos;
    // }

    ///////////
    // Render

    eye_pos.y = eye_pos.y + @as(f32, @floatCast(sapp.frameDuration() * eye_movement.y));
    eye_focus_pos.y = eye_focus_pos.y + @as(f32, @floatCast(sapp.frameDuration() * eye_movement.y));

    sg.updateBuffer(bind.vertex_buffers[0], sg.asRange(mesh_vertices));

    const aspect = sapp.widthf() / sapp.heightf();
    const model = math.Mat4.rotate(model_rotation, math.Vec3.up());
    const view = math.Mat4.lookat(eye_pos, eye_focus_pos, math.Vec3.up());

    const view_model = math.Mat4.mul(view, model);
    const proj = math.Mat4.persp(fov, aspect, 0.01, 100.0);
    mvp = math.Mat4.mul(proj, view_model);

    const vs_params: scene_shaders.VsParams = .{
        .mvp = mvp,
        .model = model,
    };

    sg.applyPipeline(pip);
    sg.applyBindings(bind);
    sg.applyUniforms(@intCast(scene_shaders.sceneUniformBlockSlot("vs_params").?), sg.asRange(&vs_params));
    sg.draw(0, index_count, 1);
}

//////////////////////////////////
// TESTING: Overlay frame update
pub fn getApexPos() math.Vec3 {
    return math.Vec3.new(mesh_vertices[apex_indices[0]].position[0], mesh_vertices[apex_indices[0]].position[1], mesh_vertices[apex_indices[0]].position[2]);
}
//////////////////////////////////
