#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform vec2 uRange;
uniform float uBottom;
uniform float uPhase;
uniform float uPitch;
uniform float uEnergy;
uniform vec3 uTint;
uniform float uPerspective;
uniform float uSurface[65];

out vec4 fragColor;

// Skia runtime effects require constant uniform-array indices. Balanced
// branches keep neighbouring pixels coherent and work on Impeller as well.
float surfaceSample(int index) {
    if (index < 32) {
        if (index < 16) {
            if (index < 8) {
                if (index < 4) {
                    if (index < 2) {
                        if (index < 1) {
                            return uSurface[0];
                        } else {
                            return uSurface[1];
                        }
                    } else {
                        if (index < 3) {
                            return uSurface[2];
                        } else {
                            return uSurface[3];
                        }
                    }
                } else {
                    if (index < 6) {
                        if (index < 5) {
                            return uSurface[4];
                        } else {
                            return uSurface[5];
                        }
                    } else {
                        if (index < 7) {
                            return uSurface[6];
                        } else {
                            return uSurface[7];
                        }
                    }
                }
            } else {
                if (index < 12) {
                    if (index < 10) {
                        if (index < 9) {
                            return uSurface[8];
                        } else {
                            return uSurface[9];
                        }
                    } else {
                        if (index < 11) {
                            return uSurface[10];
                        } else {
                            return uSurface[11];
                        }
                    }
                } else {
                    if (index < 14) {
                        if (index < 13) {
                            return uSurface[12];
                        } else {
                            return uSurface[13];
                        }
                    } else {
                        if (index < 15) {
                            return uSurface[14];
                        } else {
                            return uSurface[15];
                        }
                    }
                }
            }
        } else {
            if (index < 24) {
                if (index < 20) {
                    if (index < 18) {
                        if (index < 17) {
                            return uSurface[16];
                        } else {
                            return uSurface[17];
                        }
                    } else {
                        if (index < 19) {
                            return uSurface[18];
                        } else {
                            return uSurface[19];
                        }
                    }
                } else {
                    if (index < 22) {
                        if (index < 21) {
                            return uSurface[20];
                        } else {
                            return uSurface[21];
                        }
                    } else {
                        if (index < 23) {
                            return uSurface[22];
                        } else {
                            return uSurface[23];
                        }
                    }
                }
            } else {
                if (index < 28) {
                    if (index < 26) {
                        if (index < 25) {
                            return uSurface[24];
                        } else {
                            return uSurface[25];
                        }
                    } else {
                        if (index < 27) {
                            return uSurface[26];
                        } else {
                            return uSurface[27];
                        }
                    }
                } else {
                    if (index < 30) {
                        if (index < 29) {
                            return uSurface[28];
                        } else {
                            return uSurface[29];
                        }
                    } else {
                        if (index < 31) {
                            return uSurface[30];
                        } else {
                            return uSurface[31];
                        }
                    }
                }
            }
        }
    } else {
        if (index < 48) {
            if (index < 40) {
                if (index < 36) {
                    if (index < 34) {
                        if (index < 33) {
                            return uSurface[32];
                        } else {
                            return uSurface[33];
                        }
                    } else {
                        if (index < 35) {
                            return uSurface[34];
                        } else {
                            return uSurface[35];
                        }
                    }
                } else {
                    if (index < 38) {
                        if (index < 37) {
                            return uSurface[36];
                        } else {
                            return uSurface[37];
                        }
                    } else {
                        if (index < 39) {
                            return uSurface[38];
                        } else {
                            return uSurface[39];
                        }
                    }
                }
            } else {
                if (index < 44) {
                    if (index < 42) {
                        if (index < 41) {
                            return uSurface[40];
                        } else {
                            return uSurface[41];
                        }
                    } else {
                        if (index < 43) {
                            return uSurface[42];
                        } else {
                            return uSurface[43];
                        }
                    }
                } else {
                    if (index < 46) {
                        if (index < 45) {
                            return uSurface[44];
                        } else {
                            return uSurface[45];
                        }
                    } else {
                        if (index < 47) {
                            return uSurface[46];
                        } else {
                            return uSurface[47];
                        }
                    }
                }
            }
        } else {
            if (index < 56) {
                if (index < 52) {
                    if (index < 50) {
                        if (index < 49) {
                            return uSurface[48];
                        } else {
                            return uSurface[49];
                        }
                    } else {
                        if (index < 51) {
                            return uSurface[50];
                        } else {
                            return uSurface[51];
                        }
                    }
                } else {
                    if (index < 54) {
                        if (index < 53) {
                            return uSurface[52];
                        } else {
                            return uSurface[53];
                        }
                    } else {
                        if (index < 55) {
                            return uSurface[54];
                        } else {
                            return uSurface[55];
                        }
                    }
                }
            } else {
                if (index < 60) {
                    if (index < 58) {
                        if (index < 57) {
                            return uSurface[56];
                        } else {
                            return uSurface[57];
                        }
                    } else {
                        if (index < 59) {
                            return uSurface[58];
                        } else {
                            return uSurface[59];
                        }
                    }
                } else {
                    if (index < 62) {
                        if (index < 61) {
                            return uSurface[60];
                        } else {
                            return uSurface[61];
                        }
                    } else {
                        if (index < 63) {
                            return uSurface[62];
                        } else {
                            if (index < 64) {
                                return uSurface[63];
                            } else {
                                return uSurface[64];
                            }
                        }
                    }
                }
            }
        }
    }
}

// The same gravity-aligned surface as the volume solver, with continuous
// tangents so reflections do not step between simulation samples.
vec2 surfaceAt(float x) {
    float position = clamp((x - uRange.x) / (uRange.y - uRange.x), 0.0, 1.0) * 64.0;
    int i = int(floor(position));
    float t = fract(position);
    float a = surfaceSample(i - 1);
    float b = surfaceSample(i);
    float c = surfaceSample(i + 1);
    float d = surfaceSample(i + 2);
    float c1 = .5 * (c - a);
    float c2 = a - 2.5 * b + 2.0 * c - .5 * d;
    float c3 = .5 * (d - a) + 1.5 * (b - c);
    float height = b + t * (c1 + t * (c2 + t * c3));
    float slope = (c1 + t * (2.0 * c2 + 3.0 * t * c3)) * 64.0 / (uRange.y - uRange.x);
    return vec2(height, slope);
}

void main() {
    vec2 p = FlutterFragCoord().xy;
    float shortSide = max(min(uSize.x, uSize.y), 1.0);
    vec2 surface = surfaceAt(p.x);
    float depth = max(p.y - surface.x, 0.0);
    float waterDepth = max(uBottom - surface.x, 1.0);
    float immersion = clamp(depth / waterDepth, 0.0, 1.0);
    vec2 q = vec2((p.x - uRange.x) / shortSide, depth / shortSide);

    // Long gravity waves carry finer capillary ripples. Analytic derivatives
    // steer the light continuously instead of scrolling a noise texture.
    vec2 d1 = vec2(2.1, 1.3);
    vec2 d2 = vec2(4.8, -2.8);
    vec2 d3 = vec2(9.2, 6.1);
    vec2 d4 = vec2(16.4, -10.2);
    float w1 = dot(q, d1) - uPhase * .6;
    float w2 = dot(q, d2) + uPhase * .4 + 1.7;
    float w3 = dot(q, d3) - uPhase * 1.1 + .6 * sin(w1);
    float w4 = dot(q, d4) + uPhase * 1.4;
    vec2 gradient = .055 * d1 * cos(w1)
                  + .018 * d2 * cos(w2)
                  + .006 * (d3 + .6 * cos(w1) * d1) * cos(w3)
                  + .0018 * d4 * cos(w4);
    gradient *= .75 + uEnergy * 1.4;
    vec3 normal = normalize(vec3(-surface.y * .75 - gradient.x * .65,
                                 -gradient.y * .65 + sin(uPitch) * .12, 1.0));

    // Depth-dependent transmission: clear crystal blue water, rich sapphire blue in depth.
    vec3 shallow = mix(uTint * 1.12, vec3(.28, .68, 1.0), .24);
    vec3 deep = mix(uTint * .75, vec3(.02, .24, .68), .48 * uPerspective);
    vec3 colour = mix(shallow, deep, smoothstep(0.0, 1.0, immersion));
    colour *= exp(-vec3(.32, .10, .02) * immersion * uPerspective);

    // Soft, natural internal fluid light flow with no sharp marks or lines.
    float fluidFlow = .5 + .5 * sin(dot(q, vec2(1.6, 1.1)) - uPhase * .6 + .4 * sin(w1));
    float fluidShimmer = .5 + .5 * sin(dot(q, vec2(-1.2, 2.2)) + uPhase * .4);
    float internalLight = fluidFlow * fluidShimmer * mix(.06, .14, immersion) * mix(.5, 1.0, uPerspective);
    colour += (uTint * .75 + vec3(.15, .35, .65)) * internalLight;

    // A shallow visible surface catches a broad studio reflection and small
    // specular glints. Its depth follows the actual fill and camera pitch.
    float surfaceDepth = max(.8, min(waterDepth * .38,
        shortSide * mix(.065, .085, uPerspective) * (1.0 + sin(uPitch) * .2)));
    float top = 1.0 - smoothstep(surfaceDepth * .15, surfaceDepth, depth);
    vec3 view = normalize(vec3(0.0, .5, 1.0));
    float fresnel = .02 + .98 * pow(1.0 - max(dot(normal, view), 0.0), 5.0);
    float specular = pow(max(dot(normal, normalize(vec3(-.18, -.12, 1.0))), 0.0), 90.0);
    float reflection = .5 + .5 * sin(q.x * 1.8 + gradient.x * 3.0 + uPhase * .2);
    vec3 reflected = mix(uTint * .65, vec3(.85, .94, 1.0), reflection);
    colour = mix(colour, reflected, top * (.18 + fresnel * 2.0));
    colour += vec3(.75, .88, .98) * specular * top * .27;

    float lip = exp(-depth / .65);
    colour += vec3(.70, .85, .95) * lip * (.10 + specular * .18);
    // A lens-like side falloff gives the vessel thickness without a flat rim.
    float side = min(p.x - uRange.x, uRange.y - p.x) / shortSide;
    colour *= 1.0 - .08 * exp(-max(side, 0.0) * 32.0);
    fragColor = vec4(clamp(colour, 0.0, 1.0), 1.0);
}
