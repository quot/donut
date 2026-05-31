const std = @import("std");
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

const triangle: [3]math.Vec2 = shapes.triangleFromCenter(math.Vec2.new(400.0, 300.0), 10.0);
// var ndc_triangle: [3]math.Vec2 = undefined;

pub var overlayVerts: [3]OverlayVertex = undefined;

pub fn initOverlay() void {
    overlayVerts = .{
        .{ .x = triangle[0].x, .y = triangle[0].y, .r = 0.0, .g = 0.0, .b = 0.0 },
        .{ .x = triangle[1].x, .y = triangle[1].y, .r = 0.0, .g = 0.0, .b = 0.0 },
        .{ .x = triangle[2].x, .y = triangle[2].y, .r = 0.0, .g = 0.0, .b = 0.0 },
    };

    std.log.debug("TRI: [{d}, {d}], [{d}, {d}], [{d}, {d}]", .{
        overlayVerts[0].x, overlayVerts[0].y,
        overlayVerts[1].x, overlayVerts[1].y,
        overlayVerts[2].x, overlayVerts[2].y,
        });

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
