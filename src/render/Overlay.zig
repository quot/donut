const std = @import("std");
const mesh = @import("../scene/mesh/mesh.zig");
const math = @import("../utils/math.zig");
const shapes = @import("../scene/mesh/shapes.zig");
const overlay_shaders = @import("./shaders/overlay.glsl.zig");

const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;

var pip: sg.Pipeline = .{};
var bind: sg.Bindings = .{};

var vs_params: overlay_shaders.VsParams = undefined;

// Interleaved vertex: position (xy) + color (rgb)
const OverlayVertex = extern struct {
    x: f32,
    y: f32,
    r: f32,
    g: f32,
    b: f32,
};

const tri_side_len: f32 = 20.0;
const tri_r: f32 = 1.0;
const tri_g: f32 = 0.0;
const tri_b: f32 = 0.86;
var triangle: [3]math.Vec2 = shapes.triangleFromCenter(math.Vec2.new(400.0, 300.0), tri_side_len);

pub var overlayVerts: [3]OverlayVertex = undefined;

pub fn initOverlay() void {
    overlayVerts = .{
        .{ .x = triangle[0].x, .y = triangle[0].y, .r = tri_r, .g = tri_g, .b = tri_b },
        .{ .x = triangle[1].x, .y = triangle[1].y, .r = tri_r, .g = tri_g, .b = tri_b },
        .{ .x = triangle[2].x, .y = triangle[2].y, .r = tri_r, .g = tri_g, .b = tri_b },
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

pub fn drawFrame(tri_screen_pos: ?math.Vec2) void {
    if (tri_screen_pos != null) {
        triangle = shapes.triangleFromCenter(tri_screen_pos.?, tri_side_len);

        overlayVerts[0].x = triangle[0].x;
        overlayVerts[0].y = triangle[0].y;

        overlayVerts[1].x = triangle[1].x;
        overlayVerts[1].y = triangle[1].y;

        overlayVerts[2].x = triangle[2].x;
        overlayVerts[2].y = triangle[2].y;
    }

    sg.updateBuffer(bind.vertex_buffers[0], sg.asRange(&overlayVerts));
    vs_params = .{ .screen_size = .{ sapp.widthf(), sapp.heightf() } };

    sg.applyPipeline(pip);
    sg.applyBindings(bind);
    sg.applyUniforms(@intCast(overlay_shaders.overlayUniformBlockSlot("vs_params").?), sg.asRange(&vs_params));
    sg.draw(0, 3, 1);
}
