# zig_cfd

Finite-difference exercises (problems 2.7, 2.9, 2.11, 2.13) written in Zig.

Running it prints four tables to the terminal. There is nothing to configure
and no input files — `zig build run` does everything.

## Grading without installing anything

The exact output of `zig build run` is checked in at
[`sample_output.txt`](sample_output.txt). If you'd rather not install a
toolchain just to grade this, that file is the full, real output — nothing
trimmed or hand-edited.

## Quick start (Linux, x86_64)

```bash
curl -LO https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
tar xf zig-x86_64-linux-0.16.0.tar.xz
export PATH="$PWD/zig-x86_64-linux-0.16.0:$PATH"
zig build run
```

Four commands, no root, nothing left on your system beyond the extracted
folder. If you're not on Linux/x86_64, or want the reasoning, see below.

## Installing Zig

**This project needs Zig 0.16.0 specifically** (pinned in `build.zig.zon`).
Zig is pre-1.0 and makes breaking language changes between minor versions —
0.15 or 0.17 will fail to compile this with unrelated-looking errors.

Zig ships as a self-contained archive per platform: no build step, no
dependencies, no root/admin needed. Pick your OS:

**Already manage Zig versions with [zvm](https://www.zvm.app)?** (that's what
I use personally) — this works the same on Linux, macOS, and Windows:

```bash
zvm install 0.16.0
zvm use 0.16.0
zig version   # should print 0.16.0
```

Otherwise, grab the official archive for your platform:

<details open>
<summary><b>Linux</b></summary>

```bash
# x86_64 (most PCs)
curl -LO https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
tar xf zig-x86_64-linux-0.16.0.tar.xz
export PATH="$PWD/zig-x86_64-linux-0.16.0:$PATH"

# aarch64 (ARM, e.g. Raspberry Pi)
curl -LO https://ziglang.org/download/0.16.0/zig-aarch64-linux-0.16.0.tar.xz
tar xf zig-aarch64-linux-0.16.0.tar.xz
export PATH="$PWD/zig-aarch64-linux-0.16.0:$PATH"
```

If you'd rather use your distro's package manager (`apt`, `dnf`, `pacman`,
`snap`, ...), that's fine too — just check the version afterward, since
distro packages can lag behind or (less often) be ahead of what this project
pins:

```bash
sudo dnf install zig      # or apt, pacman, etc.
zig version                # must print 0.16.0 — if not, use the archive above
```

</details>

<details>
<summary><b>macOS</b></summary>

Official archive (works whether or not you have Homebrew):

```bash
# Apple Silicon (M1/M2/M3/M4)
curl -LO https://ziglang.org/download/0.16.0/zig-aarch64-macos-0.16.0.tar.xz
tar xf zig-aarch64-macos-0.16.0.tar.xz
export PATH="$PWD/zig-aarch64-macos-0.16.0:$PATH"

# Intel
curl -LO https://ziglang.org/download/0.16.0/zig-x86_64-macos-0.16.0.tar.xz
tar xf zig-x86_64-macos-0.16.0.tar.xz
export PATH="$PWD/zig-x86_64-macos-0.16.0:$PATH"
```

Or, if you already use Homebrew and don't mind a system-wide install:

```bash
brew install zig
```

As of this writing `brew install zig` gives 0.16.0, but Homebrew tracks
whatever is currently "stable" — if a newer Zig has shipped since, this may
install a version that won't compile the project. Run `zig version` after
installing to check; if it's not `0.16.0`, use the archive method above
instead.

</details>

<details>
<summary><b>Windows</b></summary>

PowerShell:

```powershell
Invoke-WebRequest -Uri "https://ziglang.org/download/0.16.0/zig-x86_64-windows-0.16.0.zip" -OutFile zig.zip
Expand-Archive zig.zip -DestinationPath .
$env:Path = "$PWD\zig-x86_64-windows-0.16.0;" + $env:Path
zig version
```

Or download the zip by hand from the link below, extract it, and add the
extracted folder to your `PATH` (or just `cd` into it and run `.\zig.exe`
directly).

</details>

Every official release for every platform is listed at
<https://ziglang.org/download/> if none of the above matches your machine.

Whichever method you use, confirm it worked before building:

```bash
zig version   # must print 0.16.0
```

### Making the PATH change permanent

The `export`/`$env:Path` lines above only last for the current terminal
session. To keep Zig on your PATH permanently, append the export line to your
shell config with the absolute path, e.g. on Linux/macOS:

```bash
echo "export PATH=\"$PWD/zig-x86_64-linux-0.16.0:\$PATH\"" >> ~/.bashrc
```

(swap `~/.bashrc` for `~/.zshrc` if you use zsh). This step is optional —
skip it if you're only running this once to grade the assignment.

### Troubleshooting

- **`zig: command not found`** — the `export PATH=...` line either wasn't
  run, was run in a different terminal tab, or the folder name doesn't match
  what you extracted (check with `ls` — the version number in the folder
  name must match the tarball you downloaded).
- **`zig version` prints something other than `0.16.0`** — you have a
  different Zig earlier on your `PATH` (commonly from `apt`/`brew`/an old
  download). Either remove it or make sure the 0.16.0 folder appears first
  in `PATH` (put its `export` line *after* any existing Zig-related PATH
  entries, or open a fresh terminal with only this export set).
- **Compile errors mentioning syntax that looks like it should work** — almost
  always a version mismatch. Re-run `zig version` and confirm `0.16.0`.

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
builds are near-instant. To start clean, delete `.zig-cache/` and `zig-out/`
— both are regenerated and neither is checked into git.

## What it computes

| Problem | Function | Computed |
| --- | --- | --- |
| 2.7 | `cos(pi*x)` at x = 0.25 | f′ by 2nd-order forward and backward differences, Δx = 0.01 … 0.25 |
| 2.9 | `tan(pi*x/4)` at x = 1.5 | f′ by 1st-order forward and backward differences, Δx = 0.01 … 0.8 |
| 2.11 | `sin(pi*x/2)` at x = 1.5 | f′ through f⁗ by 2nd-order central differences, Δx = 0.0005 … 0.4 |
| 2.13 | tabulated data, unequal spacing | f′(1), f′(3), f′(4) from weights solved at runtime |
