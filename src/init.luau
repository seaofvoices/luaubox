local fs = require('@lune/fs')

local currentVersion = require('./currentVersion')
local processBundle = require('./processBundle')
local processLune = require('./processLune')
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
    'roblox-plugin',
    'lune',
    'bundle',
}

local VALID_ENVIRONMENTS = {
    'roblox',
    'lune',
}

local TARGET_TO_ENVIRONMENT: { [string]: processBundle.Environment } = {
    roblox = 'roblox',
    ['roblox-plugin'] = 'roblox',
    lune = 'lune',
}

local HELP_MESSAGE = `Running luaubox v{currentVersion}\n\n`
    .. [[
luaubox [project-name] --target <target>

Optional:
    project-name:    The name of the project to build. If not specified,
                     luaubox will expect and use the root package.json file.

Required:
    --target, -t     The target to build: 'roblox', 'roblox-plugin',
                     'lune' or 'bundle'

Options:
    --help, -h       Show this help message
    --version, -V    Print the luaubox version
    --show-commands  Show the commands being executed
    --parallel       Run the build in parallel
    --dev, -d        Define development mode variables when processing
                     Luau code
    --base-darklua   The path to the base darklua config file
    --no-type        Remove Luau types from the output
    --compact        Shorten variables and minify source code

Bundle options:
    --environment, --env, -e
                     The environment to bundle for ('roblox' or 'lune')

Roblox options:
    --test           Build the project as a Roblox testing place file with
                     scripts to run it with run-in-roblox

Roblox plugin options:
    --plugin-function  The name of the function to call when the plugin is
                       started (default: 'start')]]

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

    local environment = extractArgumentWithValue(args, { '--environment', '--env', '-e' })
    local baseDarkluaConfigPath = extractArgumentWithValue(args, { '--base-darklua' })
    local pluginStartFunctionName = extractArgumentWithValue(args, { '--plugin-function' })

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

    local normalizedEnvironment = environment and string.lower(environment)

    if
        normalizedEnvironment ~= nil and not table.find(VALID_ENVIRONMENTS, normalizedEnvironment)
    then
        error(
            `invalid environment '{environment}', valid environments are: {table.concat(
                VALID_ENVIRONMENTS,
                ', '
            )}`
        )
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
        environment = TARGET_TO_ENVIRONMENT[normalizedTarget],
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
        processRoblox(options)
    elseif normalizedTarget == 'roblox-plugin' then
        options.pluginMode = true
        options.pluginStartFunctionName = pluginStartFunctionName
        processRoblox(options)
    elseif normalizedTarget == 'bundle' then
        options.environment = normalizedEnvironment :: processBundle.Environment
        processBundle(options)
    elseif normalizedTarget == 'lune' then
        processLune(options)
    end
end

return {
    runWithArgs = runWithArgs,
}
