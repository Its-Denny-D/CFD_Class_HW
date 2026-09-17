const std = @import("std");
const math = std.math;

// TODO: Make a generator function for the weights and unique distances. Not sure if it should be dynamic or not
pub const Stencil = struct {
    weights: []const f64, // indexed by position in the point set
    offset: isize, // index offset of weights[0] relative to center node
    deriv_order: usize, // p; divisor is dx^p
};
pub const fwd_d1_o2 = Stencil{ .weights = &.{ -1.5, 2.0, -0.5 }, .offset = 0, .deriv_order = 1 };
pub const bwd_d1_o2 = Stencil{ .weights = &.{ 0.5, -2.0, 1.5 }, .offset = -2, .deriv_order = 1 };
pub const fwd_d1_o1 = Stencil{ .weights = &.{ -1.0, 1.0 }, .offset = 0, .deriv_order = 1 };
pub const bwd_d1_o1 = Stencil{ .weights = &.{ -1.0, 1.0 }, .offset = -1, .deriv_order = 1 };

// Central, second-order accurate. Weights solve sum_k w_k m_k^n = p! at n = p,
// 0 otherwise, so apply() divides by dx^p alone.
pub const ctr_d1_o2 = Stencil{ .weights = &.{ -0.5, 0.0, 0.5 }, .offset = -1, .deriv_order = 1 };
pub const ctr_d2_o2 = Stencil{ .weights = &.{ 1.0, -2.0, 1.0 }, .offset = -1, .deriv_order = 2 };
pub const ctr_d3_o2 = Stencil{ .weights = &.{ -0.5, 1.0, 0.0, -1.0, 0.5 }, .offset = -2, .deriv_order = 3 };
pub const ctr_d4_o2 = Stencil{ .weights = &.{ 1.0, -4.0, 6.0, -4.0, 1.0 }, .offset = -2, .deriv_order = 4 };

pub fn apply(s: Stencil, in: []const f64, out: []f64, dx: f64) void {
    if (out.len < in.len) return;
    if (in.len < s.weights.len) return;

    const n: isize = @intCast(in.len);
    const w_len: isize = @intCast(s.weights.len);

    // Valid out range is in[i + offset + j] for j in [0, w_len)
    const lo: isize = @max(0, -s.offset);
    const hi: isize = n - w_len - s.offset;
    const divisor = math.pow(f64, dx, @floatFromInt(s.deriv_order));

    var i: isize = lo;
    while (i <= hi) : (i += 1) {
        const base: usize = @intCast(i + s.offset);
        var sum: f64 = 0;
        for (s.weights, 0..) |w, j| {
            sum += w * in[base + j];
        }
        out[@intCast(i)] = sum / divisor;
    }
}
// with zig I can use compile time checks to verify all the stencils are valid, i.e. weights sum to zero
comptime {
    for (&[_]Stencil{ fwd_d1_o2, bwd_d1_o2, ctr_d1_o2, ctr_d2_o2, ctr_d3_o2, ctr_d4_o2 }) |s| {
        var sum: f64 = 0;
        for (s.weights) |w| sum += w;
        if (@abs(sum) > 1e-12) @compileError("stencil weights must sum to zero");
    }
}
