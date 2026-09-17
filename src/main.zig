const std = @import("std");
const Io = std.Io;
const math = std.math;
const differencing = @import("differencing.zig");

/// Fixed notation while the value fits the column, scientific once it does not.
fn col(buf: []u8, v: f64) []const u8 {
    const a = @abs(v);
    if (a != 0 and (a >= 1e6 or a < 1e-4)) {
        return std.fmt.bufPrint(buf, "{e:.6}", .{v}) catch "?";
    }
    return std.fmt.bufPrint(buf, "{d:.6}", .{v}) catch "?";
}

/// Solve a 3x3 system by Cramer's rule. Returns null if the matrix is singular.
/// Rows of `a` are the conditions (n = 0,1,2); `b` is the right-hand side.
fn solve3(a: [3][3]f64, b: [3]f64) ?[3]f64 {
    const det = det3(a);
    if (@abs(det) < 1e-12) return null;

    var out: [3]f64 = undefined;
    for (0..3) |cl| {
        var m = a;
        for (0..3) |row| m[row][cl] = b[row];
        out[cl] = det3(m) / det;
    }
    return out;
}

/// The n=0 condition: any derivative stencil must annihilate a constant.
/// Catches transposed matrices, sign errors, and singular systems.
fn weightsSumToZero(w: [3]f64) bool {
    return @abs(w[0] + w[1] + w[2]) < 1e-10;
}

fn det3(m: [3][3]f64) f64 {
    return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
}

pub fn main() !void {
    std.debug.print("================== Problem 2.7 ==================\n\n", .{});

    // 2.7
    {
        const steps = [_]f64{ 0.01, 0.1, 0.25 };
        const x0: f64 = 0.25;
        const exact: f64 = -math.pi * @sin(math.pi * x0);
        const center: usize = 2;

        var prev_err: f64 = 0;

        std.debug.print("f(x) = cos(pi*x),  f'({d}) exact = {d:.9}\n\n", .{ x0, exact });
        std.debug.print("{s:>6} {s:>14} {s:>12} {s:>14} {s:>12} {s:>7}\n", .{ "dx", "forward", "fwd %err", "backward", "bwd %err", "ratio" });
        std.debug.print("{s:->6} {s:->14} {s:->12} {s:->14} {s:->12} {s:->7}\n", .{ "", "", "", "", "", "" });

        for (steps) |dx| {
            var in: [5]f64 = undefined;
            for (&in, 0..) |*v, k| {
                const offset: f64 = @floatFromInt(@as(i32, @intCast(k)) - 2);
                v.* = @cos(math.pi * (x0 + offset * dx));
            }

            var fwd: [5]f64 = .{0} ** 5;
            var bwd: [5]f64 = .{0} ** 5;

            differencing.apply(differencing.fwd_d1_o2, &in, &fwd, dx);
            differencing.apply(differencing.bwd_d1_o2, &in, &bwd, dx);
            const err_f = 100.0 * @abs((fwd[center] - exact) / exact);
            const err_b = 100.0 * @abs((bwd[center] - exact) / exact);

            const ratio = if (prev_err == 0) 0 else err_f / prev_err;
            prev_err = err_f;

            var b: [4][32]u8 = undefined;
            std.debug.print("{d:>6.4} {s:>14} {s:>12} {s:>14} {s:>12} {d:>7.2}\n", .{
                dx,
                col(&b[0], fwd[center]),
                col(&b[1], err_f),
                col(&b[2], bwd[center]),
                col(&b[3], err_b),
                ratio,
            });
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("================== Problem 2.9 ==================\n\n", .{});

    // 2.9
    {
        const steps = [_]f64{ 0.01, 0.1, 0.5, 0.8 };
        const x0: f64 = 1.5;
        const c = @cos(math.pi * x0 / 4.0);
        const exact: f64 = (math.pi / 4.0) / (c * c);

        const center: usize = 2;

        std.debug.print("f(x) = tan(pi*x/4),  f'({d}) exact = {d:.9}\n\n", .{ x0, exact });
        std.debug.print("{s:>6} {s:>14} {s:>12} {s:>14} {s:>12}\n", .{ "dx", "forward", "fwd %err", "backward", "bwd %err" });
        std.debug.print("{s:->6} {s:->14} {s:->12} {s:->14} {s:->12}\n", .{ "", "", "", "", "" });

        for (steps) |dx| {
            var in: [5]f64 = undefined;
            for (&in, 0..) |*v, k| {
                const offset: f64 = @floatFromInt(@as(i32, @intCast(k)) - 2);
                v.* = @tan(math.pi * (x0 + offset * dx) / 4.0);
            }

            var fwd: [5]f64 = .{0} ** 5;
            var bwd: [5]f64 = .{0} ** 5;

            differencing.apply(differencing.fwd_d1_o1, &in, &fwd, dx);
            differencing.apply(differencing.bwd_d1_o1, &in, &bwd, dx);
            const err_f = 100.0 * @abs((fwd[center] - exact) / exact);
            const err_b = 100.0 * @abs((bwd[center] - exact) / exact);

            var b: [4][32]u8 = undefined;
            std.debug.print("{d:>6.4} {s:>14} {s:>12} {s:>14} {s:>12}\n", .{
                dx,
                col(&b[0], fwd[center]),
                col(&b[1], err_f),
                col(&b[2], bwd[center]),
                col(&b[3], err_b),
            });

            // tan(pi*x/4) has a pole at x = 2; at large dx the forward stencil
            // straddles it, so show the raw nodes rather than inferring the
            // blowup from a nonsense error percentage.
            if (dx > 0.25) {
                for (&in, 0..) |v, k| {
                    const off: f64 = @floatFromInt(@as(i32, @intCast(k)) - 2);
                    var nb: [32]u8 = undefined;
                    std.debug.print("{s:>6} x={d:>6.2}  f={s:>14}\n", .{ "", x0 + off * dx, col(&nb, v) });
                }
            }
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("================== Problem 2.11 ==================\n\n", .{});

    // 2.11
    {
        const steps = [_]f64{ 0.0005, 0.001, 0.01, 0.1, 0.2, 0.3, 0.4 };
        const x0: f64 = 1.5;
        const center: usize = 2;
        const k = math.pi / 2.0;

        const stencils = [_]differencing.Stencil{
            differencing.ctr_d1_o2,
            differencing.ctr_d2_o2,
            differencing.ctr_d3_o2,
            differencing.ctr_d4_o2,
        };
        const exact = [_]f64{
            k * @cos(k * x0),
            -k * k * @sin(k * x0),
            -k * k * k * @cos(k * x0),
            k * k * k * k * @sin(k * x0),
        };

        var vals: [steps.len][stencils.len]f64 = undefined;
        var errs: [steps.len][stencils.len]f64 = undefined;

        for (steps, 0..) |dx, r| {
            var in: [5]f64 = undefined;
            for (&in, 0..) |*v, j| {
                const offset: f64 = @floatFromInt(@as(i32, @intCast(j)) - 2);
                v.* = @sin(k * (x0 + offset * dx));
            }

            for (stencils, 0..) |s, c| {
                var out: [5]f64 = .{0} ** 5;
                differencing.apply(s, &in, &out, dx);
                vals[r][c] = out[center];
                errs[r][c] = 100.0 * @abs((out[center] - exact[c]) / exact[c]);
            }
        }

        std.debug.print("f(x) = sin(pi*x/2),  central 2nd-order at x = {d}\n\n", .{x0});
        for (exact, 0..) |e, c| {
            std.debug.print("  exact d{d}: {d:.9}\n", .{ c + 1, e });
        }

        std.debug.print("\nvalues\n", .{});
        std.debug.print("{s:>8} {s:>14} {s:>14} {s:>14} {s:>14}\n", .{ "dx", "d1", "d2", "d3", "d4" });
        std.debug.print("{s:->8} {s:->14} {s:->14} {s:->14} {s:->14}\n", .{ "", "", "", "", "" });
        for (steps, 0..) |dx, r| {
            var b: [4][32]u8 = undefined;
            std.debug.print("{d:>8.4} {s:>14} {s:>14} {s:>14} {s:>14}\n", .{
                dx,
                col(&b[0], vals[r][0]),
                col(&b[1], vals[r][1]),
                col(&b[2], vals[r][2]),
                col(&b[3], vals[r][3]),
            });
        }

        std.debug.print("\n%err  (truncation falls with dx, roundoff rises; d4 divides by dx^4)\n", .{});
        std.debug.print("{s:>8} {s:>14} {s:>14} {s:>14} {s:>14}\n", .{ "dx", "d1", "d2", "d3", "d4" });
        std.debug.print("{s:->8} {s:->14} {s:->14} {s:->14} {s:->14}\n", .{ "", "", "", "", "" });
        for (steps, 0..) |dx, r| {
            var b: [4][32]u8 = undefined;
            std.debug.print("{d:>8.4} {s:>14} {s:>14} {s:>14} {s:>14}\n", .{
                dx,
                col(&b[0], errs[r][0]),
                col(&b[1], errs[r][1]),
                col(&b[2], errs[r][2]),
                col(&b[3], errs[r][3]),
            });
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("================== Problem 2.13 ==================\n\n", .{});

    // 2.13
    {
        // Rows are the Taylor conditions n = 0,1,2 with 1/n! folded in:
        // V[n][j] = m_j^n / n!, so the solved weights apply to f directly.
        const rhs = [_]f64{ 0.0, 1.0, 0.0 }; // p = 1

        // f'(3): points x = 2, 3, 3.6  ->  m = -1, 0, 0.6
        const mtx3 = [_][3]f64{
            .{ 1.0, 1.0, 1.0 },
            .{ -1.0, 0.0, 0.6 },
            .{ 0.5, 0.0, 0.18 },
        };
        const sol3 = solve3(mtx3, rhs).?;
        std.debug.assert(weightsSumToZero(sol3));

        // f'(4): points x = 3.6, 4, 5  ->  m = -0.4, 0, 1.0
        const mtx4 = [_][3]f64{
            .{ 1.0, 1.0, 1.0 },
            .{ -0.4, 0.0, 1.0 },
            .{ 0.08, 0.0, 0.5 },
        };
        const sol4 = solve3(mtx4, rhs).?;
        std.debug.assert(weightsSumToZero(sol4));

        const fp1 = (4.0 - 0.0) / 2.0; // uniform spacing, standard central
        const fp3 = sol3[0] * 4.0 + sol3[1] * 3.0 + sol3[2] * 2.4;
        const fp4 = sol4[0] * 2.4 + sol4[1] * 2.0 + sol4[2] * 1.0;

        std.debug.print("x  = {{ 0, 1, 2, 3, 3.6, 4, 5 }}\n", .{});
        std.debug.print("f  = {{ 0, 1, 4, 3, 2.4, 2, 1 }}\n\n", .{});
        std.debug.print("  f'(3) weights: ({d:.6}, {d:.6}, {d:.6})\n", .{ sol3[0], sol3[1], sol3[2] });
        std.debug.print("  f'(4) weights: ({d:.6}, {d:.6}, {d:.6})\n\n", .{ sol4[0], sol4[1], sol4[2] });
        std.debug.print("  f'(1) = {d:.6}\n", .{fp1});
        std.debug.print("  f'(3) = {d:.6}\n", .{fp3});
        std.debug.print("  f'(4) = {d:.6}\n", .{fp4});
    }
}
