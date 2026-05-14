const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;
const shaders = @import("shaders/donut.glsl.zig");

// Interleaved vertex: position (xy) + color (rgb)
const Vertex = extern struct {
    x: f32,
    y: f32,
    r: f32,
    g: f32,
    b: f32,
};

const VERTEX_HIT_RADIUS: f32 = 15.0; // pixels

var pip: sg.Pipeline = .{};
var bind: sg.Bindings = .{};
var pass_action: sg.PassAction = .{};
var vertices: [3]Vertex = undefined;
var dragging_vert: i32 = -1; // index of vertex being dragged, -1 = none

// NDC → window pixel coords
fn ndcToScreen(nx: f32, ny: f32) struct { x: f32, y: f32 } {
    return .{
        .x = (nx + 1.0) * 0.5 * sapp.widthf(),
        .y = (1.0 - ny) * 0.5 * sapp.heightf(),
    };
}

// Window pixel coords → NDC
fn screenToNdc(px: f32, py: f32) struct { x: f32, y: f32 } {
    return .{
        .x = (px / sapp.widthf()) * 2.0 - 1.0,
        .y = 1.0 - (py / sapp.heightf()) * 2.0,
    };
}

fn hitTest(mx: f32, my: f32) i32 {
    for (&vertices, 0..) |*v, i| {
        const s = ndcToScreen(v.x, v.y);
        const dx = mx - s.x;
        const dy = my - s.y;
        if (dx * dx + dy * dy <= VERTEX_HIT_RADIUS * VERTEX_HIT_RADIUS) {
            return @intCast(i);
        }
    }
    return -1;
}

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // Initial triangle in NDC space — top-center, bottom-right, bottom-left
    vertices = .{
        .{ .x = 0.0, .y = 0.6, .r = 1.0, .g = 0.2, .b = 0.2 },
        .{ .x = 0.6, .y = -0.6, .r = 0.2, .g = 1.0, .b = 0.2 },
        .{ .x = -0.6, .y = -0.6, .r = 0.2, .g = 0.2, .b = 1.0 },
    };

    // Stream vertex buffer — updated every frame
    bind.vertex_buffers[0] = sg.makeBuffer(.{
        .usage = .{ .vertex_buffer = true, .stream_update = true },
        .size = @sizeOf(@TypeOf(vertices)),
    });

    const shd = sg.makeShader(shaders.donutShaderDesc(sg.queryBackend()));

    var pip_desc: sg.PipelineDesc = .{
        .shader = shd,
        .primitive_type = .TRIANGLES,
    };
    pip_desc.layout.attrs[0] = .{ .format = .FLOAT2 }; // position
    pip_desc.layout.attrs[1] = .{ .format = .FLOAT3 }; // color
    pip = sg.makePipeline(pip_desc);

    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.08, .g = 0.08, .b = 0.12, .a = 1.0 },
    };
}

export fn frame() void {
    sg.updateBuffer(bind.vertex_buffers[0], sg.asRange(&vertices));

    sg.beginPass(.{ .action = pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(pip);
    sg.applyBindings(bind);
    sg.draw(0, 3, 1);
    sg.endPass();
    sg.commit();
}

export fn on_event(ev: [*c]const sapp.Event) void {
    switch (ev.*.type) {
        .MOUSE_DOWN => {
            if (ev.*.mouse_button == .LEFT) {
                dragging_vert = hitTest(ev.*.mouse_x, ev.*.mouse_y);
            }
        },
        .MOUSE_UP => {
            if (ev.*.mouse_button == .LEFT) {
                dragging_vert = -1;
            }
        },
        .MOUSE_MOVE => {
            if (dragging_vert >= 0) {
                const ndc = screenToNdc(ev.*.mouse_x, ev.*.mouse_y);
                const i: usize = @intCast(dragging_vert);
                vertices[i].x = ndc.x;
                vertices[i].y = ndc.y;
            }
        },
        else => {},
    }
}

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
        .window_title = "Dynamic Mesh — drag the vertices",
        .logger = .{ .func = slog.func },
    });
}
