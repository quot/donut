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
out vec3 frag_pos;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
    frag_normal = mat3(model) * normal;
    frag_pos = position;
}
@end

@fs fs
in vec3 frag_normal;
in vec4 frag_color;
in vec3 frag_pos;

out vec4 out_color;

void main() {
    vec3 light_dir = normalize(vec3(1.0, 2.0, 3.0));
    float diffuse = max(dot(normalize(frag_normal), light_dir), 0.0);
    float light = 0.15 + diffuse * 0.85;
    vec3 color = frag_color.rgb;

    if (!gl_FrontFacing) {
        vec3 dpdx = dFdx(frag_pos);
        vec3 dpdy = dFdy(frag_pos);
        vec3 n = abs(normalize(cross(dpdx, dpdy)));

        vec2 uv;
        if (n.z > n.x && n.z > n.y) {
            uv = frag_pos.xy;
        } else if (n.x > n.y) {
            uv = frag_pos.yz;
        } else {
            uv = frag_pos.xz;
        }

        vec2 p = floor(uv * 8.0);
        float checker = mod(p.x + p.y, 2.0);

        color = mix(vec3(0.08), vec3(1.0, 0.2, 0.8), checker);
    }

    out_color = vec4(color * light, 1.0);
}
@end

@program scene vs fs