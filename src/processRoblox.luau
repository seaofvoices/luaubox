local PathModule = require('@pkg/luau-path')

local BaseOptions = require('./BaseOptions')
local awaitAll = require('./awaitAll')
local displayCreatedMessage = require('./displayCreatedMessage')
local generateScripts = require('./generateScripts')
local getNameWithoutScope = require('./getNameWithoutScope')
local prepareDarkluaConfig = require('./prepareDarkluaConfig')
local processSources = require('./processSources')
local robloxTestRunner = require('./robloxTestRunner')
local rojo = require('./rojo')
local utils = require('./utils')

type AsPath = PathModule.AsPath
type Path = PathModule.Path

local Path = PathModule.Path

local DEFAULT_SOURCE_PATH = 'src'

export type Options = BaseOptions.BaseOptions & {
    testMode: boolean?,
    tempRojoFileName: string?,
}

local function processRoblox(options: Options)
    local tempPath = Path.from('temp')
    local buildPath = Path.from('build')

    local projectName = options.projectName
    local startPackageJsonPath = Path.from(options.packageJsonPath)
    local parallelMode = options.parallelMode == true
    local showCommands = options.showCommands == true
    local compact = options.compact == true
    local noTypes = options.noTypes == true
    local testMode = options.testMode == true
    local devMode = options.devMode == true
    local tempDarkluaConfigName = options.tempDarkluaConfigName or 'temp-darklua-config.json'
    local tempRojoFileName = options.tempRojoFileName or 'temp-rojo-file.project.json'

    local rojoRunner = rojo.createRunner(showCommands)

    local nameWithoutScope = getNameWithoutScope(projectName)

    local isNodeModuleProject = startPackageJsonPath:startsWith('node_modules')

    local rojoConfig = if testMode
        then rojo.getTestPlaceConfig(
            if isNodeModuleProject then nil else DEFAULT_SOURCE_PATH,
            false
        )
        else rojo.getModelConfig(
            nameWithoutScope,
            if isNodeModuleProject
                then `node_modules/.luau-aliases/{projectName}.luau`
                else DEFAULT_SOURCE_PATH
        )

    utils.writeJsonFile(tempRojoFileName, rojoConfig)
    rojoRunner.sourcemap(tempRojoFileName, 'sourcemap.json')

    prepareDarkluaConfig(tempDarkluaConfigName, {
        environment = 'roblox',
        bundle = false,
        testMode = testMode,
        devMode = devMode,
        compact = compact,
        noTypes = noTypes,
        baseDarkluaConfigPath = options.baseDarkluaConfigPath,
    })

    processSources({
        startPath = startPackageJsonPath,
        testMode = testMode,
        parallelMode = parallelMode,
        showCommands = showCommands,
        tempPath = tempPath,
        tempDarkluaConfigName = tempDarkluaConfigName,
    })

    local tempRojoFile = tempPath:join(tempRojoFileName)
    local robloxBuildPath = if testMode then buildPath:join('roblox-test') else buildPath

    awaitAll(function()
        utils.removeFile(tempDarkluaConfigName)
    end, function()
        utils.writeDir(robloxBuildPath)
    end)

    if testMode then
        awaitAll(function()
            utils.removeFile(tempRojoFileName)
        end, function()
            utils.writeJsonFile(
                tempRojoFile,
                rojo.getTestPlaceConfig(
                    if isNodeModuleProject then nil else DEFAULT_SOURCE_PATH,
                    true
                )
            )
        end, function()
            local jestConfigPath = tempPath:join('jest.config.luau')
            if not utils.isFile(jestConfigPath) then
                utils.writeFile(jestConfigPath, "return { testMatch = { '**/*.test' } }")
            end
        end)

        local placeName = `test-{nameWithoutScope}.rbxl`

        awaitAll(function()
            utils.writeFile(tempPath:join('run-tests.server.luau'), robloxTestRunner)
        end, function()
            utils.writeFile(robloxBuildPath:join('run-tests.luau'), robloxTestRunner)
        end, function()
            generateScripts(robloxBuildPath:join('run'), function(basedir, expandArgs)
                return `run-in-roblox --place "{basedir}/{placeName}" --script "{basedir}/run-tests.luau"`
            end)
        end)

        local placeFile = robloxBuildPath:join(placeName)

        rojoRunner.buildPlace(tempRojoFile, placeFile)
        displayCreatedMessage(placeFile)
    else
        utils.move(tempRojoFileName, tempRojoFile)
        local modelFile = robloxBuildPath:join(
            if devMode then `{nameWithoutScope}-dev.rbxm` else `{nameWithoutScope}.rbxm`
        )
        rojoRunner.buildModel(tempRojoFile, modelFile)

        displayCreatedMessage(modelFile)
    end

    utils.removeFile(tempRojoFile)
    utils.removeDirAll(tempPath)
end

return processRoblox
