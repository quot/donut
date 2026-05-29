const mesh = @import("../scene/mesh/mesh.zig");
const math = @import("../utils/math.zig");
const shapes = @import("../scene/mesh/shapes.zig");
const overlay_shaders = @import("../shaders/overlay.glsl.zig");

const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;

pub var pip: sg.Pipeline = .{};
pub var bind: sg.Bindings = .{};

// Interleaved vertex: position (xy) + color (rgb)
const OverlayVertex = extern struct {
    x: f32,
    y: f32,
    r: f32,
    g: f32,
    b: f32,
};

pub const overlayVerts: [3]OverlayVertex = .{
    .{ .x = 0.0, .y = 0.6, .r = 1.0, .g = 0.2, .b = 0.2 },
    .{ .x = 0.6, .y = -0.6, .r = 0.2, .g = 1.0, .b = 0.2 },
    .{ .x = -0.6, .y = -0.6, .r = 0.2, .g = 0.2, .b = 1.0 },
};

pub fn initOverlay() void {
    // Stream vertex buffer — updated every frame
    bind.vertex_buffers[0] = sg.makeBuffer(.{
        .usage = .{ .vertex_buffer = true, .stream_update = true },
        .size = @sizeOf(@TypeOf(overlayVerts)),
    });

    const shd = sg.makeShader(overlay_shaders.overlayShaderDesc(sg.queryBackend()));

    var pip_desc: sg.PipelineDesc = .{
        .shader = shd,
        .primitive_type = .TRIANGLES,
    };
    pip_desc.layout.attrs[0] = .{ .format = .FLOAT2 }; // position
    pip_desc.layout.attrs[1] = .{ .format = .FLOAT3 }; // color
    pip = sg.makePipeline(pip_desc);
}
