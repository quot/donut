const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;

const math = @import("utils/math.zig");
const mesh = @import("mesh.zig");
const mesh_testing = @import("tests/test_mesh.zig");

const shaders = @import("shaders/donut.glsl.zig");
const VsParams = shaders.VsParams;

var pip: sg.Pipeline = .{};
var bind: sg.Bindings = .{};
var pass_action: sg.PassAction = .{};

var index_count: u32 = 0;
// var model_rotation: @Vector(2, f32) = .{ 0.0, 0.0 };
var model_rotation: f32 = 0.0;

// TODO: These should be user configurable.
const rotation_scale: f32 = 1.5;
const clear_color: sg.Color = .{ .r = 0.94, .g = 0.94, .b = 0.94, .a = 1.0 };
const fov: f32 = 60.0;

// Camera State
var eye_pos: math.Vec3 = math.Vec3.new(0.0, 1.5, 5.0);
var eye_focus_pos: math.Vec3 = math.Vec3.zero();
var eye_movement: math.Vec3 = math.Vec3.zero();
////////////////////////////////////////////////////////////////////////

// const VERTEX_HIT_RADIUS: f32 = 15.0; // in pixels

// var dragging_vert: i32 = -1; // index of vertex being dragged, -1 = none

// // NDC → window pixel coords
// fn ndcToScreen(nx: f32, ny: f32) struct { x: f32, y: f32 } {
//     return .{
//         .x = (nx + 1.0) * 0.5 * sapp.widthf(),
//         .y = (1.0 - ny) * 0.5 * sapp.heightf(),
//     };
// }

// // Window pixel coords → NDC
// fn screenToNdc(px: f32, py: f32) struct { x: f32, y: f32 } {
//     return .{
//         .x = (px / sapp.widthf()) * 2.0 - 1.0,
//         .y = 1.0 - (py / sapp.heightf()) * 2.0,
//     };
// }

// fn hitTest(mx: f32, my: f32) i32 {
//     for (&vertices, 0..) |*v, i| {
//         const s = ndcToScreen(v.x, v.y);
//         const dx = mx - s.x;
//         const dy = my - s.y;
//         if (dx * dx + dy * dy <= VERTEX_HIT_RADIUS * VERTEX_HIT_RADIUS) {
//             return @intCast(i);
//         }
//     }
//     return -1;
// }

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    const pyramid = mesh_testing.pyramidFlat();

    bind.vertex_buffers[0] = sg.makeBuffer(.{
        .usage = .{
            .vertex_buffer = true,
            .immutable = true,
        },
        .data = sg.asRange(pyramid.vertices),
    });

    bind.index_buffer = sg.makeBuffer(.{
        .usage = .{
            .index_buffer = true,
            .immutable = true,
        },
        .data = sg.asRange(pyramid.indices),
    });

    index_count = @intCast(pyramid.indices.len);

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

    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = clear_color,
    };

    pass_action.depth = .{
        .load_action = .CLEAR,
        .clear_value = 1.0,
    };
}

export fn frame() void {
    eye_pos.y = eye_pos.y + @as(f32, @floatCast(sapp.frameDuration() * eye_movement.y));
    eye_focus_pos.y = eye_focus_pos.y + @as(f32, @floatCast(sapp.frameDuration() * eye_movement.y));

    const aspect = sapp.widthf() / sapp.heightf();
    const model = math.Mat4.rotate(model_rotation, math.Vec3.up());
    const view = math.Mat4.lookat(eye_pos, eye_focus_pos, math.Vec3.up());

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
    sg.draw(0, index_count, 1);
    sg.endPass();
    sg.commit();
}

export fn on_event(ev: [*c]const sapp.Event) void {
    switch (ev.*.type) {
        .MOUSE_SCROLL => {
            model_rotation = @mod((ev.*.scroll_x * rotation_scale) + model_rotation, 360.0);
        },
        .KEY_DOWN, .KEY_UP => {
            switch (ev.*.key_code) {
                .E => {
                    if (ev.*.type == .KEY_DOWN) {
                        eye_movement.y = 0.5;
                    } else {
                        eye_movement.y = 0.0;
                    }
                },
                else => {},
            }
        },
        else => {},
    }
}

// export fn on_event(ev: [*c]const sapp.Event) void {
//     switch (ev.*.type) {
//         .MOUSE_DOWN => {
//             if (ev.*.mouse_button == .LEFT) {
//                 dragging_vert = hitTest(ev.*.mouse_x, ev.*.mouse_y);
//             }
//         },
//         .MOUSE_UP => {
//             if (ev.*.mouse_button == .LEFT) {
//                 dragging_vert = -1;
//             }
//         },
//         .MOUSE_MOVE => {
//             if (dragging_vert >= 0) {
//                 const ndc = screenToNdc(ev.*.mouse_x, ev.*.mouse_y);
//                 const i: usize = @intCast(dragging_vert);
//                 vertices[i].x = ndc.x;
//                 vertices[i].y = ndc.y;
//             }
//         },
//         else => {},
//     }
// }

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = on_event,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .window_title = "🍩",
        .logger = .{ .func = slog.func },
    });
}
