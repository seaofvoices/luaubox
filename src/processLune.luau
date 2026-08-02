local PathModule = require('@pkg/luau-path')

local BaseOptions = require('./BaseOptions')
local awaitAll = require('./awaitAll')
local displayCreatedMessage = require('./displayCreatedMessage')
local getNameWithoutScope = require('./getNameWithoutScope')
local prepareDarkluaConfig = require('./prepareDarkluaConfig')
local processSources = require('./processSources')
local utils = require('./utils')

type AsPath = PathModule.AsPath
type Path = PathModule.Path

local Path = PathModule.Path

local DEFAULT_SOURCE_PATH = 'src'

export type Options = BaseOptions.BaseOptions & {
    testMode: boolean?,
}

local function processLune(options: Options)
    local tempPath = Path.from('temp')
    local buildPath = Path.from('build')
    local luneBuildPath = buildPath:join('lune')

    utils.writeDir(luneBuildPath)
    utils.writeDir(tempPath)

    local projectName = options.projectName
    local startPackageJsonPath = Path.from(options.packageJsonPath)
    local parallelMode = options.parallelMode == true
    local showCommands = options.showCommands == true
    local compact = options.compact == true
    local noTypes = options.noTypes == true
    local testMode = options.testMode == true
    local devMode = options.devMode == true
    local tempDarkluaConfigName = options.tempDarkluaConfigName or 'temp-darklua-config.json'

    local nameWithoutScope = getNameWithoutScope(projectName)

    local isNodeModuleProject = startPackageJsonPath:startsWith('node_modules')

    local tempDarkluaConfigPath = tempPath:join(tempDarkluaConfigName)

    local modulesFolderName = `{nameWithoutScope}-dependencies`

    local aliases: { [string]: AsPath } = {
        ['@pkg'] = `{modulesFolderName}/.luau-aliases`,
    }

    prepareDarkluaConfig(tempDarkluaConfigPath, {
        environment = 'lune',
        bundle = false,
        testMode = testMode,
        devMode = devMode,
        compact = compact,
        noTypes = noTypes,
        baseDarkluaConfigPath = options.baseDarkluaConfigPath,
        aliases = aliases,
    })

    local tempNodeModulesPath = tempPath:join(modulesFolderName)

    utils.copy('node_modules', tempNodeModulesPath)

    if not isNodeModuleProject then
        awaitAll(function()
            utils.copy(DEFAULT_SOURCE_PATH, tempPath:join(DEFAULT_SOURCE_PATH))
        end, function()
            utils.copy(startPackageJsonPath, tempPath:join(startPackageJsonPath))
        end)

        startPackageJsonPath = tempPath:join('package.json')
    end

    processSources({
        startPath = startPackageJsonPath,
        testMode = testMode,
        parallelMode = parallelMode,
        showCommands = showCommands,
        tempPath = tempPath,
        tempDarkluaConfigName = tempDarkluaConfigPath,
        nodeModulesPath = tempNodeModulesPath,
        workingDir = tempPath,
    })

    local modulesOutput = luneBuildPath:join(modulesFolderName)

    local packageOutput = luneBuildPath:join(nameWithoutScope)

    awaitAll(function()
        utils.move(tempPath:join(tempNodeModulesPath), modulesOutput)
    end, function()
        utils.move(tempPath:join('temp'):join(DEFAULT_SOURCE_PATH), packageOutput)
    end)

    awaitAll(function()
        utils.writeJsonFile(modulesOutput:join('.luaurc'), {
            aliases = {
                pkg = './.luau-aliases',
            },
        })
    end, function()
        utils.writeJsonFile(packageOutput:join('.luaurc'), {
            aliases = {
                pkg = `../{modulesFolderName}/.luau-aliases`,
            },
        })
    end)

    displayCreatedMessage(packageOutput)

    utils.removeDirAll(tempPath)
end

return processLune
