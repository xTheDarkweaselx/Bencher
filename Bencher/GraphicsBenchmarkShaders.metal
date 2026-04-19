#include <metal_stdlib>
using namespace metal;

kernel void bencherGraphics(
    device float4 *output [[buffer(0)]],
    constant uint &iterations [[buffer(1)]],
    constant uint &seed [[buffer(2)]],
    uint gid [[thread_position_in_grid]]
) {
    float4 value = float4(
        float(gid) * 0.000031f + float(seed) * 0.013f,
        float(gid) * 0.000047f + 0.11f,
        float(gid) * 0.000059f + 0.23f,
        float(gid) * 0.000071f + 0.37f
    );

    for (uint i = 0; i < iterations; ++i) {
        float4 rotated = value.yzwx;
        value = sin(value * 1.017f + rotated * 0.913f + 0.07f);
        value += cos(rotated * 1.031f + float(i) * 0.00091f + 0.13f);
        value = sqrt(fabs(value) + 0.0001f);
    }

    output[gid] = value;
}
