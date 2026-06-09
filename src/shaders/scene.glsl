@header const m = @import("../utils/math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding=0) uniform vs_params {
    mat4 mvp;
    mat4 model;
};

in vec3 position;
in vec3 normal;
in vec2 texcoord;
in vec4 color;

out vec3 frag_normal;
out vec4 frag_color;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
    frag_normal = mat3(model) * normal;
    frag_color = color;
}
@end

@fs fs
in vec3 frag_normal;
in vec4 frag_color;
out vec4 out_color;

void main() {
    vec3 light_dir = normalize(vec3(1.0, 2.0, 3.0));
    float diffuse = max(dot(normalize(frag_normal), light_dir), 0.0);
    float light = 0.15 + diffuse * 0.85;
    out_color = vec4(frag_color.rgb * light, 1.0);
}
@end

@program scene vs fs