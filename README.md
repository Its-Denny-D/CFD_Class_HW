# zig_cfd

Finite-difference exercises (problems 2.7, 2.9, 2.11, 2.13) written in Zig.

Running it prints four tables to the terminal. There is nothing to configure and
no input files — `zig build run` does everything.

## Installing Zig on Linux

**This project needs Zig 0.16.0 specifically.** Zig is pre-1.0 and makes breaking
language changes between minor versions, so 0.15 or 0.17 will not compile it.

Do not install Zig from `apt`, `dnf`, or `snap` — those packages are usually a
version or two behind. Instead grab the official binary. Zig ships as a single
self-contained tarball: no compiler to build, no dependencies, no root needed.

```bash
curl -LO https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
tar xf zig-x86_64-linux-0.16.0.tar.xz
export PATH="$PWD/zig-x86_64-linux-0.16.0:$PATH"

zig version   # should print: 0.16.0
```

The `export` line only lasts for the current terminal. To make it permanent, append
it to your shell config with an absolute path:

```bash
echo "export PATH=\"$PWD/zig-x86_64-linux-0.16.0:\$PATH\"" >> ~/.bashrc
```

Other releases are listed at <https://ziglang.org/download/>.

## Building and running

From the project root:

```bash
zig build run
```

That compiles and runs in one step, printing all four problem tables. Other
useful commands:

```bash
zig build        # compile only; binary lands in zig-out/bin/zig_cfd
zig build test   # run test blocks (none defined yet, so this passes trivially)
```

The first build takes a few seconds while Zig populates `.zig-cache/`; later
builds are near-instant. To start clean, delete `.zig-cache/` and `zig-out/` —
both are regenerated and neither is checked into git.

## What it computes

| Problem | Function | Computed |
| --- | --- | --- |
| 2.7 | `cos(pi*x)` at x = 0.25 | f′ by 2nd-order forward and backward differences, Δx = 0.01 … 0.25 |
| 2.9 | `tan(pi*x/4)` at x = 1.5 | f′ by 1st-order forward and backward differences, Δx = 0.01 … 0.8 |
| 2.11 | `sin(pi*x/2)` at x = 1.5 | f′ through f⁗ by 2nd-order central differences, Δx = 0.0005 … 0.4 |
| 2.13 | tabulated data, unequal spacing | f′(1), f′(3), f′(4) from weights solved at runtime |
