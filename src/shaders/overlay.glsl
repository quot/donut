@vs vs
layout(location=0) in vec2 position;
layout(location=1) in vec3 color;
out vec3 frag_color;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
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