// Adapted from shaders/paper/rings/scribbling-pencils.glsl

// Theme colours affect artwork only; palette = false restores the original RGB.
// Keep the original shade and soften highlights without changing effect opacity.
vec3 theme_color(vec3 original, float position) {
    if (umbriel_palette_count <= 0) return original;
    float value = max(original.r, max(original.g, original.b));
    float white = min(original.r, min(original.g, original.b)) / max(value, 0.0001);
    return value * mix(umbriel_palette_at(position).rgb, vec3(1.0), white * 0.75);
}

#define ring_padding 28.0
#define ring_size (umbriel_border_hole.zw * umbriel_size)
#define ring_width max((1.0 - umbriel_border_hole.w) * umbriel_size.y * 0.5 - ring_padding, 1.0)
#define ring_radius umbriel_border_radius
float ring_distance(vec2 coords) { return umbriel_border_distance(coords / umbriel_size + umbriel_border_hole.xy); }
const float PENCIL_SPEED = 46.0;
const float PENCIL_INSET = 22.0;
const float PENCIL_OUTSET = 30.0;
const float PENCIL_PI = 3.14159265359;

float pencil_radius() { return min(18.0, min(ring_size.x, ring_size.y) * 0.25); }
float pencil_perimeter() {
    return 2.0 * (ring_size.x + ring_size.y) - (8.0 - 2.0 * PENCIL_PI) * pencil_radius();
}

// Fixed authoring contour shared by both contracts, independent of native
// corner radii. The compositor still clips each pass to the real client hole.
vec2 pencil_coordinates(vec2 p) {
    float r = pencil_radius();
    vec2 span = ring_size - 2.0 * r;
    float arc = PENCIL_PI * r * 0.5;
    vec2 q = abs(p - ring_size * 0.5) - ring_size * 0.5 + r;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
    float along;
    if (p.x > ring_size.x - r && p.y < r)
        along = span.x + r * atan(max(p.x - ring_size.x + r, 0.00001), max(r - p.y, 0.00001));
    else if (p.x > ring_size.x - r && p.y > ring_size.y - r)
        along = span.x + arc + span.y + r * atan(max(p.y - ring_size.y + r, 0.00001), max(p.x - ring_size.x + r, 0.00001));
    else if (p.x < r && p.y > ring_size.y - r)
        along = 2.0 * span.x + 2.0 * arc + span.y + r * atan(max(r - p.x, 0.00001), max(p.y - ring_size.y + r, 0.00001));
    else if (p.x < r && p.y < r)
        along = 2.0 * span.x + 3.0 * arc + 2.0 * span.y + r * atan(max(r - p.y, 0.00001), max(r - p.x, 0.00001));
    else {
        vec4 distances = abs(vec4(p.y, p.x - ring_size.x, p.y - ring_size.y, p.x));
        float nearest = min(min(distances.x, distances.y), min(distances.z, distances.w));
        if (nearest == distances.x) along = clamp(p.x - r, 0.0, span.x);
        else if (nearest == distances.y) along = span.x + arc + clamp(p.y - r, 0.0, span.y);
        else if (nearest == distances.z) along = span.x + arc * 2.0 + span.y + clamp(ring_size.x - r - p.x, 0.0, span.x);
        else along = span.x * 2.0 + arc * 3.0 + span.y + clamp(ring_size.y - r - p.y, 0.0, span.y);
    }
    return vec2(along, d);
}

// Position and unit tangent; rigid pencil sprites turn smoothly at corners.
vec4 pencil_frame(float along) {
    float r = pencil_radius();
    float s = mod(along, pencil_perimeter());
    for (int side = 0; side < 4; side++) {
        float line;
        vec2 start, tangent, center;
        if (side == 0) {
            line = ring_size.x - 2.0 * r;
            start = vec2(r, 0.0); tangent = vec2(1.0, 0.0); center = vec2(ring_size.x - r, r);
        } else if (side == 1) {
            line = ring_size.y - 2.0 * r;
            start = vec2(ring_size.x, r); tangent = vec2(0.0, 1.0); center = ring_size - r;
        } else if (side == 2) {
            line = ring_size.x - 2.0 * r;
            start = vec2(ring_size.x - r, ring_size.y); tangent = vec2(-1.0, 0.0); center = vec2(r, ring_size.y - r);
        } else {
            line = ring_size.y - 2.0 * r;
            start = vec2(0.0, ring_size.y - r); tangent = vec2(0.0, -1.0); center = vec2(r);
        }
        if (s <= line) return vec4(start + tangent * s, tangent);
        s -= line;
        float arc = PENCIL_PI * r * 0.5;
        if (s <= arc || side == 3) {
            float angle = (float(side) - 1.0) * PENCIL_PI * 0.5 + s / max(r, 0.001);
            return vec4(center + r * vec2(cos(angle), sin(angle)), -sin(angle), cos(angle));
        }
        s -= arc;
    }
    return vec4(r, 0.0, 1.0, 0.0);
}

float pencil_wiggle(float along) {
    float phase = along / pencil_perimeter() * 2.0 * PENCIL_PI;
    float loops = max(2.0, floor(pencil_perimeter() / 125.0));
    return 1.0 + 6.5 * sin(phase * loops) + 1.8 * sin(phase * (loops * 3.0 + 1.0));
}

vec4 pencil_over(vec4 under, vec3 color, float alpha) {
    alpha = clamp(alpha, 0.0, 1.0);
    return vec4(color * alpha + under.rgb * (1.0 - alpha), alpha + under.a * (1.0 - alpha));
}

vec4 ring_color(vec2 coords) {
    if (min(ring_size.x, ring_size.y) <= 0.0) return vec4(0.0);
    vec2 path = pencil_coordinates(coords);
    if (path.y < -PENCIL_INSET || path.y > PENCIL_OUTSET) return vec4(0.0);
    float aa = 0.65 / max(umbriel_scale, 0.01);
    float perimeter = pencil_perimeter();
    vec4 paint = vec4(0.0);
    float grain = fract(sin(dot(floor(coords * 2.0), vec2(12.9898, 78.233))) * 43758.5453);

    // A lightly sketched double outline remains behind the moving strokes.
    float wobble = 0.55 * sin(path.x * 0.17) + 0.3 * sin(path.x * 0.43);
    float outline = min(abs(path.y - 2.4 - wobble), abs(path.y + 1.1 - wobble * 0.7));
    paint = pencil_over(paint, theme_color(vec3(0.22, 0.20, 0.17), 0.5),
        (1.0 - smoothstep(0.3, 0.3 + aa, outline)) * (0.30 + grain * 0.20));

    for (int i = 0; i < 4; i++) {
        float head = mod(umbriel_time * PENCIL_SPEED + (float(i) + 0.12) * perimeter * 0.25, perimeter);
        float behind = mod(head - path.x + perimeter, perimeter);
        float trail_length = min(260.0, perimeter * 0.235);
        float trail = 1.0 - smoothstep(trail_length * 0.30, trail_length, behind);
        float stroke = abs(path.y - pencil_wiggle(path.x));

        // A narrow paper wash follows each stroke and shares its fade.
        float signed_behind = mod(head - path.x + perimeter * 0.5, perimeter) - perimeter * 0.5;
        float paper_fade = signed_behind >= 0.0 ? trail : smoothstep(-7.0, 0.0, signed_behind);
        float paper_width = 1.0 - smoothstep(1.5, 7.0, stroke);
        vec3 paper = theme_color(vec3(0.98, 0.96, 0.90), 0.5) * (0.97 + 0.03 * grain);
        paint = pencil_over(paint, paper, paper_width * paper_fade * 0.68);
        paint = pencil_over(paint, theme_color(vec3(0.18, 0.16, 0.14), 0.5),
            (1.0 - smoothstep(0.48, 0.48 + aa, stroke)) * trail * (0.62 + grain * 0.30));

        vec4 frame = pencil_frame(head);
        vec2 normal = vec2(frame.w, -frame.z);
        vec2 tip = frame.xy + normal * pencil_wiggle(head);
        float tilt = 0.48 + 0.12 * sin(umbriel_time * 5.0 + float(i) * 1.7);
        vec2 axis = frame.zw * cos(tilt) + normal * sin(tilt);
        vec2 relative = coords - tip;
        vec2 p = vec2(dot(relative, axis), dot(relative, vec2(-axis.y, axis.x)));
        if (p.x < -2.0 || p.x > 35.0 || abs(p.y) > 6.0) continue;
        float width = 2.7 * clamp(p.x / 7.0, 0.0, 1.0);
        float body = smoothstep(-aa, aa, p.x) * (1.0 - smoothstep(32.0 - aa, 32.0 + aa, p.x))
            * (1.0 - smoothstep(width - aa, width + aa, abs(p.y)));
        vec3 color = theme_color(vec3(0.91, 0.65, 0.15), 0.5); // lacquered yellow cedar pencil
        color *= 0.78 + 0.22 * smoothstep(-2.0, 1.3, p.y);
        color += theme_color(vec3(0.16, 0.15, 0.08), 0.5) * exp(-pow((p.y + 0.7) * 2.0, 2.0));
        if (p.x < 7.0) color = theme_color(vec3(0.80, 0.61, 0.39), 0.5) * (0.90 + p.y * 0.05);
        if (p.x < 2.6) color = theme_color(vec3(0.16, 0.15, 0.14), 0.5);
        if (p.x > 24.0) color = theme_color(vec3(0.63, 0.66, 0.64), 0.25) * (0.85 + 0.15 * sin(p.x * 5.0));
        if (p.x > 27.5) color = theme_color(vec3(0.86, 0.43, 0.40), 0.75) * (0.9 + p.y * 0.035);
        float rim = smoothstep(max(width - 0.7, 0.0), max(width, 0.001), abs(p.y));
        color *= 1.0 - 0.28 * rim;
        paint = pencil_over(paint, color, body);
    }
    // Return straight RGBA; each host applies its own premultiplication.
    return vec4(paint.rgb / max(paint.a, 0.0001), paint.a);
}

vec4 border(vec2 uv) {
    vec4 c = ring_color((uv - umbriel_border_hole.xy) * umbriel_size);
    return vec4(c.rgb * c.a, c.a);
}
