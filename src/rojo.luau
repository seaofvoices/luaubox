local PathModule = require('@pkg/luau-path')

local runCommand = require('./runCommand')

type AsPath = PathModule.AsPath

local Path = PathModule.Path

local function createRojoRunner(verbose: boolean)
    local runner: runCommand.Runner = if verbose then runCommand.verbose else runCommand.quiet

    local function buildModel(projectFile: AsPath, output: AsPath)
        local output = Path.from(output)
        local outputExtension = output:extension()

        if outputExtension ~= 'rbxm' and outputExtension ~= 'rbxmx' then
            output:setExtension('rbxm')
        end

        runner('rojo', 'build', projectFile, '--output', output)
    end

    local function buildPlace(projectFile: AsPath, output: AsPath)
        local output = Path.from(output)
        local outputExtension = output:extension()

        if outputExtension ~= 'rbxl' and outputExtension ~= 'rbxlx' then
            output:setExtension('rbxl')
        end

        runner('rojo', 'build', projectFile, '--output', output)
    end

    local function sourcemap(projectFile: AsPath, output: AsPath)
        runner('rojo', 'sourcemap', projectFile, '--output', output)
    end

    return {
        buildModel = buildModel,
        buildPlace = buildPlace,
        sourcemap = sourcemap,
    }
end

local function getModelConfig(modelName: string, rootPath: string)
    return {
        name = modelName,
        emitLegacyScripts = false,
        tree = {
            ['$path'] = rootPath,
            node_modules = {
                ['$path'] = 'node_modules',
            },
        },
    }
end

local function getPluginConfig(pluginName: string, rootPath: string, entrypointPath: string?)
    return {
        name = `{pluginName}-plugin`,
        emitLegacyScripts = false,
        tree = {
            ['$className'] = if entrypointPath then nil else 'Folder',
            ['$path'] = entrypointPath,
            [pluginName] = {
                ['$path'] = rootPath,
            },
            node_modules = {
                ['$path'] = 'node_modules',
            },
        },
    }
end

local function getTestPlaceConfig(rootPath: string?, buildMode: boolean)
    local modules = {
        ['$path'] = 'node_modules',
    }
    if rootPath then
        modules.TestTarget = {
            ['$path'] = rootPath,
            ['jest.config'] = if buildMode
                then {
                    ['$path'] = 'jest.config.luau',
                }
                else nil,
        }
    end
    return {
        name = 'test-place',
        emitLegacyScripts = false,
        tree = {
            ['$className'] = 'DataModel',
            ReplicatedStorage = {
                node_modules = modules,
            },
            ServerScriptService = {
                RunTests = if buildMode
                    then {
                        ['$path'] = 'run-tests.server.luau',
                    }
                    else nil,
            },
            HttpService = {
                ['$properties'] = {
                    HttpEnabled = true,
                },
            },
            Players = {
                ['$properties'] = {
                    CharacterAutoLoads = false,
                },
            },
        },
    }
end

return {
    createRunner = createRojoRunner,
    getModelConfig = getModelConfig,
    getPluginConfig = getPluginConfig,
    getTestPlaceConfig = getTestPlaceConfig,
}
