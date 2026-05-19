// Sokol imports
const use_docking = @import("build_options").docking;
const ig = if (use_docking) @import("cimgui_docking") else @import("cimgui");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;
const simgui = sokol.imgui;
const sgimgui = sokol.gfximgui;
const sappimgui = sokol.appimgui;

// Donut imports
const ui = @import("ui/base.zig");
const math = @import("utils/math.zig");
const mesh = @import("mesh/mesh.zig");
const mesh_testing = @import("mesh/pyramid.zig");
const shaders = @import("shaders/donut.glsl.zig");
const VsParams = shaders.VsParams;

////////////////////////////////////////////////////////////////////////

var pip: sg.Pipeline = .{};
var bind: sg.Bindings = .{};
var pass_action: sg.PassAction = .{};

// Mesh Data
var index_count: u32 = 0;
var model_rotation: f32 = 0.0;
var mesh_vertices: [18]mesh.MeshVertex = undefined;

// Camera State
// TODO: Move to camera struct with projection/view math
var eye_pos: math.Vec3 = math.Vec3.new(0.0, 1.5, 5.0);
var eye_focus_pos: math.Vec3 = math.Vec3.zero();
var eye_movement: math.Vec3 = math.Vec3.zero();

// TODO: These should be user configurable.
const rotation_scale: f32 = 1.5;
var clear_color: sg.Color = .{ .r = 0.94, .g = 0.94, .b = 0.94, .a = 1.0 };
const fov: f32 = 60.0;

// TEST
const apex_indices = [_]usize{ 0, 3, 6, 9 };
var apex_pos: f32 = 1.0;
var apex_direction: f32 = 1.0;
const apex_max: f32 = 1.5;
const apex_min: f32 = 0.5;
var show_first_window: bool = true;
var show_second_window: bool = true;

////////////////////////////////////////////////////////////////////////

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // the debug/tracing ui
    sappimgui.setup();
    sgimgui.setup(.{});
    // initialize sokol-imgui
    simgui.setup(.{
        .logger = .{ .func = slog.func },
    });
    if (use_docking) {
        ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }

    const pyramid = mesh_testing.pyramidFlat();
    @memcpy(mesh_vertices[0..], pyramid.vertices);

    bind.vertex_buffers[0] = sg.makeBuffer(.{
        .size = @sizeOf(@TypeOf(mesh_vertices)),
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
    // call simgui.newFrame() before any ImGui calls
    simgui.newFrame(.{
        .width = sapp.width(),
        .height = sapp.height(),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });

    // For debugging hud
    sappimgui.trackFrame();

    ui.buildBaseUi();

    //////////////////////
    // 3D Scene Building

    apex_pos += apex_direction * @as(f32, @floatCast(sapp.frameDuration()));
    if (apex_pos >= apex_max) {
        apex_pos = apex_max;
        apex_direction = -@abs(apex_direction);
    } else if (apex_pos <= apex_min) {
        apex_pos = apex_min;
        apex_direction = @abs(apex_direction);
    }

    for (apex_indices) |i| {
        mesh_vertices[i].position[1] = apex_pos;
    }

    sg.updateBuffer(bind.vertex_buffers[0], sg.asRange(&mesh_vertices));

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
    simgui.render();
    sg.endPass();
    sg.commit();
}

export fn on_event(ev: [*c]const sapp.Event) void {
    // forward input events to sokol-imgui
    const imgui_handled_event = simgui.handleEvent(ev.*);

    // Track events in imgui example window
    // Main menu -> S-App -> Events
    sappimgui.trackEvent(ev.*);

    switch (ev.*.type) {
        .QUIT_REQUESTED => {
            // sapp.cancelQuit();
        },
        .MOUSE_SCROLL => {
            if (!imgui_handled_event) {
                model_rotation = @mod((ev.*.scroll_x * rotation_scale) + model_rotation, 360.0);
            }
        },
        .KEY_DOWN, .KEY_UP => {
            switch (ev.*.key_code) {
                .ESCAPE => {
                    sapp.requestQuit();
                },
                .E => {
                    if (!imgui_handled_event) {
                        if (ev.*.type == .KEY_DOWN) {
                            eye_movement.y = 0.5;
                        } else {
                            eye_movement.y = 0.0;
                        }
                    }
                },
                else => {},
            }
        },
        else => {},
    }
}

export fn cleanup() void {
    sappimgui.shutdown();
    simgui.shutdown();
    sgimgui.shutdown();
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
