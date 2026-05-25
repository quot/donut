const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = @import("../utils/math.zig");
const mesh = @import("../3d/mesh/mesh.zig");
const shapes = @import("../3d/mesh/shapes.zig");
const shaders = @import("../3d/shaders/donut.glsl.zig");
const Config = @import("Config.zig");
pub const scene_state = @import("SceneState.zig");

pub var pass_action: sg.PassAction = .{};

// 3D Layer
pub var pip: sg.Pipeline = .{};
pub var bind: sg.Bindings = .{};

// TODO
// // 2D Overlay
// pub var overlay_pip: sg.Pipeline = .{};
// pub var overlay_bind: sg.Bindings = .{};

pub fn initScene() void {
    const pyramid = shapes.pyramid();
    @memcpy(scene_state.mesh_vertices[0..], pyramid.vertices);
    @memcpy(scene_state.mesh_indices[0..], pyramid.indices);
    init3d(&scene_state.mesh_vertices, &scene_state.mesh_indices);
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

    scene_state. index_count = @intCast(mesh_indices.*.len);

    const shd = sg.makeShader(shaders.donutShaderDesc(sg.queryBackend()));

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

    pip_desc.layout.attrs[shaders.donutAttrSlot("position").?] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(mesh.MeshVertex, "position"),
    };

    pip_desc.layout.attrs[shaders.donutAttrSlot("normal").?] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(mesh.MeshVertex, "normal"),
    };

    pip_desc.layout.attrs[shaders.donutAttrSlot("texcoord").?] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(mesh.MeshVertex, "texcoord"),
    };

    pip_desc.layout.attrs[shaders.donutAttrSlot("color").?] = .{
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
    scene_state.drawFrame();
    sg.updateBuffer(bind.vertex_buffers[0], sg.asRange(&scene_state.mesh_vertices));

    const aspect = sapp.widthf() / sapp.heightf();
    const model = math.Mat4.rotate(scene_state.model_rotation, math.Vec3.up());
    const view = math.Mat4.lookat(scene_state.eye_pos, scene_state.eye_focus_pos, math.Vec3.up());

    const view_model = math.Mat4.mul(view, model);
    const proj = math.Mat4.persp(fov, aspect, 0.01, 100.0);
    const mvp = math.Mat4.mul(proj, view_model);

    const vs_params: shaders.VsParams = .{
        .mvp = mvp,
        .model = model,
    };

    sg.beginPass(.{ .action = pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(pip);
    sg.applyBindings(bind);
    sg.applyUniforms(@intCast(shaders.donutUniformBlockSlot("vs_params").?), sg.asRange(&vs_params));
    sg.draw(0, scene_state.index_count, 1);
}
