# Nix Templates

A collection of Nix flake templates for development environments.

## Available Templates

| Template   | Description                               |
| ---------- | ----------------------------------------- |
| `mitsuba3` | Build environment for Dr.Jit and Mitsuba3 |
| `writeup`  | LaTeX development environment             |

## Usage

Initialize a new project with a template:

```bash
nix flake init -t github:DoeringChristian/nix-templates#<template-name>
```

For example:

```bash
# LaTeX project
nix flake init -t github:DoeringChristian/nix-templates#writeup

# Mitsuba3 development
nix flake init -t github:DoeringChristian/nix-templates#mitsuba3
```

Then enter the development shell:

```bash
nix develop
```

Or with direnv (if `.envrc` is present):

```bash
direnv allow
```

## Listing Templates

To see all available templates:

```bash
nix flake show github:DoeringChristian/nix-templates
```
