<div align="center">

[![checks](https://github.com/seaofvoices/luaubox/actions/workflows/test.yml/badge.svg)](https://github.com/seaofvoices/luaubox/actions/workflows/test.yml)
![version](https://img.shields.io/github/package-json/v/seaofvoices/luaubox)
[![GitHub top language](https://img.shields.io/github/languages/top/seaofvoices/luaubox)](https://github.com/luau-lang/luau)
![license](https://img.shields.io/npm/l/luaubox)
![npm](https://img.shields.io/npm/dt/luaubox)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/seaofvoices)

</div>

# luaubox

A Luau tool built with [`lune`](https://github.com/lune-org/lune) to process Luau packages following the [Sea of Voices Luau Package Standard](https://github.com/seaofvoices/luau-package-standard) for:

- building Roblox model files (`.rbxm`)
- creating a Roblox test place file (`.rbxl`) to run unit tests with [`run-in-roblox`](https://github.com/rojo-rbx/run-in-roblox)
- bundling into a single Luau file

luabox uses [other tools](#required-tools), such as [`darklua`](https://github.com/seaofvoices/darklua) to process Luau code (for compatibility and to inject global variables).

Here are some examples of luaubox commands:

- `luaubox --target bundle`: Create a single luau file `<project-name>.luau`
- `luaubox --target roblox`: Create a Roblox model `<project-name>.rbxm`
- `luaubox --target roblox --test`: Create a Roblox test place file `test-<project-name>.rbxl` and a `run` script which invokes [`run-in-roblox`](https://github.com/rojo-rbx/run-in-roblox) with the place

Note that the `--dev` argument can be added to inject the development globals (`_G.DEV` and `_G.__DEV__`) as `true` (instead of the default being `false`).

## Usage

This project uses `npm` built-in executable installation feature, so once installed, it will automatically create an executable script to run `luaubox`.

```bash
yarn exec luaubox --help
# or with npm
npm exec luaubox --help
```

Use `luaubox` within the usual `scripts` section of your `package.json`:

```json
{
  "scripts": {
    "build": "luaubox --target roblox && luaubox --target roblox --bundle",
    "test": "luaubox --target roblox --test && ./build/roblox-test/run"
  }
}
```

## Required Tools

`luaubox` needs a few common other tools installed:

- [`lune`](https://github.com/lune-org/lune): to run luaubox itself!
- [`darklua`](https://github.com/seaofvoices/darklua): to process Luau code
- [`rojo`](https://github.com/rojo-rbx/rojo): to build Roblox models

For [`rokit`](https://github.com/rojo-rbx/rokit) users, simply run the following commands to include the tools in your `rokit.toml` file:

```bash
rokit add seaofvoices/darklua
rokit add lune
rokit add rojo
```

## Installation

Add `luaubox` in your dev-dependencies:

```bash
yarn add -D luaubox
```

Or if you are using `npm`:

```bash
npm install --save-dev luaubox
```

## Building Roblox Plugins

Use `--target roblox-plugin` to produce a Roblox model that can be installed as a Studio plugin (`build/<project-name>-plugin.rbxm`, or `build/<project-name>-plugin-dev.rbxm` with `--dev`).

luaubox wraps the package in a [`Script`](https://create.roblox.com/docs/reference/engine/classes/Script) that requires the module and calls an exported function with the Studio `plugin` object. That function should set up the plugin and may return a cleanup callback, which will run when `plugin.Unloading` fires.

```luau
-- the root of the package should export a function that
-- receives the plugin object
local function start(plugin: Plugin)
    -- create toolbar buttons, widgets, etc.

    return function()
        -- this will run when plugin.Unloading fires
    end
end

return {
    start = start,
}
```

The default export name is `start`. Pass `--plugin-function <name>` to use a different function name.

```bash
luaubox --target roblox-plugin
luaubox --target roblox-plugin --plugin-function init
```

## License

This project is available under the MIT license. See [LICENSE.txt](LICENSE.txt) for details.
