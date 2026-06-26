// ═══════════════════════════════════════════════════════════════════════════
// LIQUID FIRE — GPU-Accelerated Fragment Shader for DFC Adrenaline Gate
// ═══════════════════════════════════════════════════════════════════════════
//
// Generative viscous fire effect driven by AI win-probability data.
// Every viewer sees a unique, living fire at the exact millisecond they watch.
//
// Uniforms:
//   uTime      — elapsed seconds (drives liquid motion)
//   uSize      — viewport dimensions in pixels
//   uIntensity — AI win probability [0.0 → 1.0]
//                 0.0 = no fire, 0.6 = deep orange, 0.8+ = white-hot
//
// ═══════════════════════════════════════════════════════════════════════════

#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uSize;
uniform float uIntensity;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // ── Liquid motion: layered sinusoidal displacement ──
    vec2 p = uv * 3.0;
    for (int i = 1; i < 5; i++) {
        float fi = float(i);
        p.x += 0.3 / fi * sin(fi * 3.0 * p.y + uTime * 1.5);
        p.y += 0.3 / fi * cos(fi * 3.0 * p.x + uTime * 1.2);
    }

    // ── Fire body: combined sinusoidal noise ──
    float fire = 0.5 + 0.5 * sin(p.x + p.y);

    // Vertical falloff: fire drips from top, fades at bottom
    float verticalMask = smoothstep(1.0, 0.2, uv.y);
    fire *= verticalMask;

    // Scale by AI intensity
    fire *= uIntensity;

    // ── Adrenaline Palette: Deep Crimson → Electric Orange → White-Hot ──
    vec3 color;
    if (uIntensity < 0.6) {
        // Low heat: deep crimson embers
        color = mix(vec3(0.15, 0.02, 0.0), vec3(0.8, 0.15, 0.0), fire);
    } else if (uIntensity < 0.8) {
        // Medium: full orange fire
        color = mix(vec3(0.8, 0.15, 0.0), vec3(1.0, 0.5, 0.0), fire);
    } else {
        // White-hot KO zone: approaching 1.0
        vec3 orangeFire = mix(vec3(1.0, 0.5, 0.0), vec3(1.0, 0.85, 0.3), fire);
        float whiteBlend = (uIntensity - 0.8) * 5.0; // 0→1 over 0.8→1.0
        color = mix(orangeFire, vec3(1.0, 1.0, 1.0), whiteBlend * fire);
    }

    // Alpha: semi-transparent overlay that builds with intensity
    float alpha = fire * (0.4 + 0.5 * uIntensity);

    fragColor = vec4(color * alpha, alpha);
}
