shader_type canvas_item;

void fragment() {
    vec2 center = vec2(0.5, 0.5); // center of UV space
    float radius = 0.5;           // max distance to cover

    float dist = distance(UV, center);
    float alpha = smoothstep(radius, radius * 0.8, dist); // fade out near edge

    // Make it white, fading out
    COLOR = vec4(1.0, 1.0, 1.0, 1.0 - alpha);
}