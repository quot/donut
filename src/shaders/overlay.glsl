@vs vs
layout(binding=0) uniform vs_params {
    vec2 screen_size;
};
layout(location=0) in vec2 position;
layout(location=1) in vec3 color;
out vec3 frag_color;

void main() {
    vec2 ndc = vec2(
        (position.x / screen_size.x) * 2.0 - 1.0,
        1.0 - (position.y / screen_size.y) * 2.0
    );
    gl_Position = vec4(ndc, 0.0, 1.0);
    // gl_Position = vec4(position, 0.0, 1.0);
    frag_color = color;
}
@end

@fs fs
in vec3 frag_color;
out vec4 out_color;

void main() {
    out_color = vec4(frag_color, 1.0);
}
@end

@program overlay vs fs