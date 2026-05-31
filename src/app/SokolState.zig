const std = @import("std");

// Sub States
pub const scene = @import("SceneState.zig");
pub const overlay = @import("OverlayState.zig");

// Sokol Imports
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;

// Donut Imports
const math = @import("../utils/math.zig");
const mesh = @import("../scene/mesh/mesh.zig");
const scene_shaders = @import("../shaders/donut.glsl.zig");
const overlay_shaders = @import("../shaders/overlay.glsl.zig");
// const Config = @import("Config.zig");

pub var gpa: *const std.mem.Allocator = undefined;

pub var pass_action: sg.PassAction = .{};

// 3D Layer
pub var pip: sg.Pipeline = .{};
pub var bind: sg.Bindings = .{};

pub fn initGraphics() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
}

pub fn initSokol() void {
    scene.initScene();
    init3d(&scene.mesh_vertices, &scene.mesh_indices);
    overlay.initOverlay();
}

pub fn init3d(mesh_vertices: *[18]mesh.MeshVertex, mesh_indices: *[18]u16) void {
    bind.vertex_buffers[0] = sg.makeBuffer(.{
        .size = @sizeOf(@TypeOf(mesh_vertices.*)),
        .usage = .{
            .vertex_buffer = true,
            .stream_update = true,
        },
    });

    bind.index_buffer = sg.makeBuffer(.{
        .usage = .{
            .index_buffer = true,
            .immutable = true,
        },
        .data = sg.asRange(mesh_indices),
    });

    scene.index_count = @intCast(mesh_indices.*.len);

    const shd = sg.makeShader(scene_shaders.donutShaderDesc(sg.queryBackend()));

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

    pip_desc.layout.attrs[scene_shaders.donutAttrSlot("position").?] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(mesh.MeshVertex, "position"),
    };

    pip_desc.layout.attrs[scene_shaders.donutAttrSlot("normal").?] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(mesh.MeshVertex, "normal"),
    };

    pip_desc.layout.attrs[scene_shaders.donutAttrSlot("texcoord").?] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(mesh.MeshVertex, "texcoord"),
    };

    pip_desc.layout.attrs[scene_shaders.donutAttrSlot("color").?] = .{
        .format = .FLOAT4,
        .offset = @offsetOf(mesh.MeshVertex, "color"),
    };

    pip = sg.makePipeline(pip_desc);
}

pub fn initPassActions(clear_color: *sokol.gfx.Color) void {
    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = clear_color.*,
    };

    pass_action.depth = .{
        .load_action = .CLEAR,
        .clear_value = 1.0,
    };
}

pub fn drawFrame(fov: f32) void {
    scene.updateFrame();
    drawScene(fov);
    drawOverlay();
}

fn drawScene(fov: f32) void {
    sg.updateBuffer(bind.vertex_buffers[0], sg.asRange(&scene.mesh_vertices));

    const aspect = sapp.widthf() / sapp.heightf();
    const model = math.Mat4.rotate(scene.model_rotation, math.Vec3.up());
    const view = math.Mat4.lookat(scene.eye_pos, scene.eye_focus_pos, math.Vec3.up());

    const view_model = math.Mat4.mul(view, model);
    const proj = math.Mat4.persp(fov, aspect, 0.01, 100.0);
    const mvp = math.Mat4.mul(proj, view_model);

    const vs_params: scene_shaders.VsParams = .{
        .mvp = mvp,
        .model = model,
    };

    sg.beginPass(.{ .action = pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(pip);
    sg.applyBindings(bind);
    sg.applyUniforms(@intCast(scene_shaders.donutUniformBlockSlot("vs_params").?), sg.asRange(&vs_params));
    sg.draw(0, scene.index_count, 1);
}

fn drawOverlay() void {
    sg.updateBuffer(overlay.bind.vertex_buffers[0], sg.asRange(&overlay.overlayVerts));
    const vs_params: overlay_shaders.VsParams = .{
        .screen_size = .{sapp.widthf(), sapp.heightf()}
    };

    sg.applyPipeline(overlay.pip);
    sg.applyBindings(overlay.bind);
    sg.applyUniforms(@intCast(overlay_shaders.overlayUniformBlockSlot("vs_params").?), sg.asRange(&vs_params));
    sg.draw(0, 3, 1);
}
