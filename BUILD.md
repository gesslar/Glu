# Glu Build Process

The Glu build process consists of two separate tools that work together:

## 1. Unifier (`unify.py`)

The unifier concatenates all Glu source files into a single unified file.

**Usage:**

```bash
python unify.py src/scripts build/Glu-single.lua
```

**What it does:**

- Reads all scripts from `scripts.json` in order
- Concatenates them into a single file
- Adds file markers as comments
- Appends `return Glu` at the end for module usage

**Output:**

- `build/Glu-single.lua` - The unified, unminified distribution

## 2. Minifier (`mini.py`)

The minifier takes a unified Lua file and creates a minified version.

**Usage:**

```bash
python mini.py input.lua output.lua
```

**What it does:**

- Removes comments
- Removes unnecessary whitespace
- Preserves functionality

**Output:**

- `build/Glu-min.lua` - The minified distribution

## NPM Scripts

The build process is automated through npm scripts:

### `npm run build:single`

Creates the unminified single-file distribution:

```bash
python unify.py src/scripts build/Glu-single.lua
```

### `npm run build:min`

Creates the minified distribution:

```bash
python unify.py src/scripts build/tmp/Glu-unified.lua && \
python mini.py build/tmp/Glu-unified.lua build/Glu-min.lua
```

### `npm run build`

Runs the full build process (muddy + single + min)

## Distribution Usage

Both distributions can be used with the same pattern:

```lua
-- Single-file (unminified)
local glu = require("MyPackage/Glu/Glu-single").new("MyPackage")

-- Minified
local glu = require("MyPackage/Glu/Glu-min").new("MyPackage")
```

The `return Glu` statement at the end of both files enables this chaining pattern.
