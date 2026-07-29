local fs = require('@lune/fs')

local currentVersion = require('./currentVersion')
local processBundle = require('./processBundle')
local processRoblox = require('./processRoblox')
local utils = require('./utils')

local function readRootProjectName()
    return utils.readJsonFile('package.json').name
end

local function extractArgumentFlag(args: { string }, names: { string })
    for _, name in names do
        local index = table.find(args, name)
        if index then
            table.remove(args, index)
            return true
        end
    end
    return false
end

local function extractArgumentWithValue(args: { string }, names: { string }): string?
    for _, name in names do
        local index = table.find(args, name)
        if index then
            table.remove(args, index)
            local value = table.remove(args, index)
            return value
        end
    end
    return nil
end

local VALID_TARGETS = {
    'roblox',
    'lune',
}

local HELP_MESSAGE = `Running luaubox v{currentVersion}\n\n`
    .. [[
luaubox <project-name> --target <target>

Optional:
    <project-name>: The name of the project to build. If not specified,
                    luaubox will expect and use the root package.json file.

Required:
    <target>:        The target to build ('roblox' or 'lune')

Options:
    --show-commands  Show the commands being executed
    --parallel       Run the build in parallel
    --dev            Define development mode variables to when processing
                     Luau code
    --base-darklua   The path to the base darklua config file
    --bundle         Bundle the project into a single file
    --no-type        Remove Luau types from the output
    --compact        Shorten variables and minify source code

Roblox options:
    --test           Build the project as a Roblox testing place file with
                     scripts to run it with run-in-roblox]]

local function runWithArgs(args: { string })
    -- copy the args to avoid modifying the original list (which could be readonly too)
    local args = table.clone(args)

    local help = extractArgumentFlag(args, { 'help', '--help', '-h' })
    local version = extractArgumentFlag(args, { 'version', '--version', '-V' })
    local parallelMode = extractArgumentFlag(args, { '--parallel' })
    local showCommands = extractArgumentFlag(args, { '--show-commands', '--show-command' })
    local testMode = extractArgumentFlag(args, { '--test', '--tests' })
    local devMode = extractArgumentFlag(args, { '--dev', '-d' })
    local compact = extractArgumentFlag(args, { '--compact' })
    local noTypes = extractArgumentFlag(args, { '--no-type', '--no-types' })
    local bundle = extractArgumentFlag(args, { '--bundle', '-b' })

    local baseDarkluaConfigPath = extractArgumentWithValue(args, { '--base-darklua' })

    if help then
        print(HELP_MESSAGE)
        return
    end

    if version then
        print(`v{currentVersion}`)
        return
    end

    local target = extractArgumentWithValue(args, { '--target', '-t' })

    if target == nil then
        error('unspecified target, use --target <target> to specify what luaubox should build')
    end

    local normalizedTarget = string.lower(target)

    if not table.find(VALID_TARGETS, normalizedTarget) then
        error(`invalid target '{target}', valid targets are: {table.concat(VALID_TARGETS, ', ')}`)
    end

    if #args > 1 then
        error(
            `received too many arguments, expected only the project name but received {#args} arguments: '{table.concat(
                args,
                "', '"
            )}'`
        )
    end

    local projectName = args[1]

    local rootProjectName = readRootProjectName()

    if projectName == nil then
        projectName = rootProjectName
    end

    local options = {
        environment = normalizedTarget :: processBundle.Environment,
        projectName = projectName,
        packageJsonPath = 'package.json',
        parallelMode = parallelMode,
        showCommands = showCommands,
        compact = compact,
        noTypes = noTypes,
        testMode = testMode,
        devMode = devMode,
        baseDarkluaConfigPath = baseDarkluaConfigPath,
    }

    if projectName ~= rootProjectName then
        local potentialFile = `node_modules/{projectName}/package.json`
        if fs.isFile(potentialFile) then
            options.packageJsonPath = potentialFile
        else
            error(`package '{projectName}' not found`)
        end
    end

    if normalizedTarget == 'roblox' then
        if bundle then
            processBundle(options)
        else
            processRoblox(options)
        end
    elseif normalizedTarget == 'lune' then
        if bundle then
            processBundle(options)
        else
            error(
                `the lune target is currently only supported with the bundle option, re-run with the '--bundle' argument`
            )
        end
    end
end

return {
    runWithArgs = runWithArgs,
}
