const std = @import("std");
const math = @import("../utils/math.zig");
const shapes = @import("./shapes.zig");
const overlay_shaders = @import("../shaders/overlay.glsl.zig");
const mesh = @import("./mesh.zig");

const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;

var pip: sg.Pipeline = .{};
var bind: sg.Bindings = .{};

var vs_params: overlay_shaders.VsParams = undefined;
var overlay_data: mesh.OverlayMeshData = undefined;

pub fn initOverlay(gpa: *const std.mem.Allocator) void {
    overlay_data = mesh.OverlayMeshData.new(gpa);
    shapes.newLine(&overlay_data, [2]mesh.Vertex{
        mesh.Vertex.new(.{ 100.0, 100.0 }, .{ 1.0, 0.2, 0.8}),
        mesh.Vertex.new(.{ 500.0, 300.0 }, .{ 1.0, 0.2, 0.8}),
    }, 5.0);

    // Stream vertex buffer — updated every frame
    bind.vertex_buffers[0] = sg.makeBuffer(.{
        .usage = .{ .vertex_buffer = true, .stream_update = true },
        .size = overlay_data.vertices.items.len * @sizeOf(mesh.Vertex),
    });

    const shd = sg.makeShader(overlay_shaders.overlayShaderDesc(sg.queryBackend()));

    var pip_desc: sg.PipelineDesc = .{
        .shader = shd,
        .primitive_type = .TRIANGLES,
    };
    pip_desc.layout.attrs[overlay_shaders.overlayAttrSlot("position").?] = .{
        .format = .FLOAT2,
        .offset = @offsetOf(mesh.Vertex, "position"),
    };
    pip_desc.layout.attrs[overlay_shaders.overlayAttrSlot("color").?] = .{
        .format = .FLOAT3,
        .offset = @offsetOf(mesh.Vertex, "color"),
    };
    pip = sg.makePipeline(pip_desc);
}

pub fn drawFrame() void {
    sg.updateBuffer(bind.vertex_buffers[0], sg.asRange(overlay_data.vertices.items));
    vs_params = .{ .screen_size = .{ sapp.widthf(), sapp.heightf() } };

    sg.applyPipeline(pip);
    sg.applyBindings(bind);
    sg.applyUniforms(@intCast(overlay_shaders.overlayUniformBlockSlot("vs_params").?), sg.asRange(&vs_params));
    sg.draw(0, @intCast(overlay_data.vertices.items.len), 1);
}
