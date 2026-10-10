// Adapted from shaders/cursor/mini-solar-system.glsl

// Theme colours affect artwork only; palette = false restores the original RGB.
// Keep the original shade and soften highlights without changing effect opacity.
vec3 theme_color(vec3 original, float position) {
    if (umbriel_palette_count <= 0) return original;
    float value = max(original.r, max(original.g, original.b));
    float white = min(original.r, min(original.g, original.b)) / max(value, 0.0001);
    return value * mix(umbriel_palette_at(position).rgb, vec3(1.0), white * 0.75);
}

vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
vec2 migration_pointer() { return umbriel_pointer * umbriel_size * umbriel_scale; }
#define umbriel_output_size migration_buffer_size()
#define umbriel_cursor migration_pointer()
#define umbriel_size migration_buffer_size()
vec4 solar_over(vec4 under, vec4 paint) {
    return paint + under * (1.0 - paint.a);
}

vec4 solar_disc(vec2 p, float radius, vec3 tint, vec2 light, float bands) {
    float aa = 0.7 / max(umbriel_scale, 0.01);
    float d = length(p);
    float alpha = 1.0 - smoothstep(radius - aa, radius + aa, d);
    if (alpha <= 0.0) return vec4(0.0);
    vec2 xy = p / radius;
    vec3 normal = vec3(xy, sqrt(max(1.0 - dot(xy, xy), 0.0)));
    float diffuse = max(dot(normal, normalize(vec3(light, 0.85))), 0.0);
    float stripe = sin(xy.y * 13.0 + 0.7 * sin(xy.x * 4.0));
    vec3 color = tint * (0.28 + 0.78 * diffuse) * (1.0 + bands * stripe);
    float gleam = pow(max(dot(normal, normalize(vec3(light * 0.5, 1.0))), 0.0), 18.0);
    color += theme_color(vec3(0.22, 0.24, 0.25), 0.25) * gleam;
    return vec4(clamp(color, 0.0, 1.0) * alpha, alpha);
}

vec4 solar_rings(vec2 p, float radius, float tilt, vec3 tint, bool front) {
    float c = cos(tilt), s = sin(tilt);
    vec2 q = vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
    if ((q.y >= 0.0) != front) return vec4(0.0);
    float r = length(vec2(q.x, q.y / 0.40));
    float aa = 1.0 / max(umbriel_scale, 0.01);
    float outer = 1.0 - smoothstep(radius * 1.91 - aa, radius * 1.91 + aa, r);
    float inner = smoothstep(radius * 1.30 - aa, radius * 1.30 + aa, r);
    float gap = 1.0 - 0.68 * exp(-pow((r - radius * 1.67) / 0.32, 2.0));
    float alpha = outer * inner * gap * (front ? 0.90 : 0.65);
    vec3 color = tint * (0.86 + 0.14 * cos(r * 4.0));
    return vec4(color * alpha, alpha);
}

vec4 solar_moon(vec2 p, vec2 offset, float radius, vec2 light) {
    return solar_disc(p - offset, radius, theme_color(vec3(0.82, 0.85, 0.91), 0.25), light, 0.07);
}

vec4 postprocess(vec3 coords) {
    vec4 under = tex2D_screen(coords.xy);
    vec2 p = (coords.xy * umbriel_output_size - umbriel_cursor) / max(umbriel_scale, 0.01);
    vec4 paint = vec4(0.0);

    // A bright central sun anchors the pointer inside an evenly spaced orbit.
    float glow = exp(-dot(p, p) / 70.0) * 0.24;
    paint = vec4(theme_color(vec3(1.0, 0.66, 0.18), 0.5) * glow, glow);
    paint = solar_over(paint, solar_disc(p, 5.2, theme_color(vec3(1.0, 0.80, 0.32), 0.5), vec2(-0.6, -0.8), 0.04));

    for (int i = 0; i < 5; i++) {
        float orbit = 56.0, radius = 3.2, speed = 0.75;
        float phase = -0.5 + float(i) * 6.2831853 / 5.0;
        vec3 tint = theme_color(vec3(0.95, 0.39, 0.19), 0.75);
        float bands = 0.04, ring_tilt = 0.0;
        bool rings = false;
        int moons = 0;
        if (i == 1) {
            radius = 5.0;
            tint = theme_color(vec3(0.16, 0.77, 0.65), 0.25); bands = 0.17; moons = 1;
        } else if (i == 2) {
            radius = 6.3;
            tint = theme_color(vec3(0.95, 0.67, 0.32), 0.5); bands = 0.16;
            rings = true; ring_tilt = -0.38;
        } else if (i == 3) {
            radius = 5.1;
            tint = theme_color(vec3(0.32, 0.63, 1.0), 0.25); bands = 0.09;
            rings = true; ring_tilt = 0.66; moons = 1;
        } else if (i == 4) {
            radius = 4.5;
            tint = theme_color(vec3(0.76, 0.40, 0.91), 0.0); bands = 0.10; moons = 2;
        }
        float angle = umbriel_time * speed + phase;
        vec2 center = orbit * vec2(cos(angle), sin(angle));
        vec2 local = p - center;
        if (length(local) > 18.0) continue;
        vec2 light = -center / orbit;
        float moon_angle = umbriel_time * (2.2 + float(i) * 0.29) + phase;
        float moon_orbit = rings ? 14.0 : 10.0;
        vec2 moon = moon_orbit * vec2(cos(moon_angle), sin(moon_angle) * 0.67);
        float second_angle = -umbriel_time * 3.7 + 1.8;
        vec2 second_moon = 15.0 * vec2(cos(second_angle), sin(second_angle) * 0.8);
        if (moons > 0 && moon.y < 0.0)
            paint = solar_over(paint, solar_moon(local, moon, 1.7, light));
        if (moons > 1 && second_moon.y < 0.0)
            paint = solar_over(paint, solar_moon(local, second_moon, 1.25, light));
        vec3 ring_color = i == 2 ? theme_color(vec3(1.0, 0.83, 0.55), 0.5) : theme_color(vec3(0.67, 0.83, 1.0), 0.25);
        if (rings) paint = solar_over(paint, solar_rings(local, radius, ring_tilt, ring_color, false));
        paint = solar_over(paint, solar_disc(local, radius, tint, light, bands));
        if (rings) paint = solar_over(paint, solar_rings(local, radius, ring_tilt, ring_color, true));
        if (moons > 0 && moon.y >= 0.0)
            paint = solar_over(paint, solar_moon(local, moon, 1.7, light));
        if (moons > 1 && second_moon.y >= 0.0)
            paint = solar_over(paint, solar_moon(local, second_moon, 1.25, light));
    }
    return solar_over(under, paint);
}

vec4 cursor(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
