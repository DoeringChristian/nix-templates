# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of Nix flake templates for development environments. Templates are defined in the root `flake.nix` and their implementations live in subdirectories.

## Available Templates

- **mitsuba3**: Development environment for Dr.Jit and Mitsuba3 (physics-based rendering)
- **writeup**: LaTeX development environment (tectonic, biber, texlive full)

## Using Templates

To use a template in a new project:
```bash
nix flake init -t github:USER/nix-templates#mitsuba3
```

## Mitsuba3 Template Commands

After entering the dev shell (`nix develop` or via direnv), these commands are available:

**Mitsuba3:**
- `configure-mitsuba` - Configure CMake build
- `build-mitsuba` - Build Mitsuba3
- `test-mitsuba [pytest args]` - Run tests (e.g., `test-mitsuba tests/test_render.py -k test_name`)
- `debug-mitsuba [pytest args]` - Debug tests with GDB

**Dr.Jit:**
- `configure-drjit` - Configure CMake build
- `build-drjit` - Build Dr.Jit
- `test-drjit [pytest args]` - Run tests
- `debug-drjit [pytest args]` - Debug tests with GDB

All build commands use `$FLAKE_ROOT` to reference the project root.

## Architecture

```
flake.nix              # Root flake exposing templates
README.md              # Usage instructions
mitsuba3/
  flake.nix            # Dev shell with CUDA, LLVM, Python, build scripts
  .envrc               # direnv configuration (uses --impure)
  requirements.txt     # Python dependencies (pytest, numpy, torch, etc.)
writeup/
  flake.nix            # Dev shell with tectonic, biber, texlive
  .envrc               # direnv configuration
  main.tex             # Document template with biblatex
  main.bib             # Bibliography file
  README.md
```

The mitsuba3 template expects the mitsuba3 source to be cloned into a `mitsuba3/` subdirectory within the project using the template.
