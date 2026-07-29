local PathModule = require('@pkg/luau-path')

local BaseOptions = require('./BaseOptions')
local awaitAll = require('./awaitAll')
local createDarkluaRunner = require('./darklua')
local displayCreatedMessage = require('./displayCreatedMessage')
local getNameWithoutScope = require('./getNameWithoutScope')
local prepareDarkluaConfig = require('./prepareDarkluaConfig')
local utils = require('./utils')

type AsPath = PathModule.AsPath
type Path = PathModule.Path

local Path = PathModule.Path

export type Environment = 'roblox' | 'lune'

export type Options = BaseOptions.BaseOptions & {
    environment: Environment,
}

local function processBundle(options: Options)
    local tempPath = Path.from('temp')
    local buildPath = Path.from('build')

    local projectName = options.projectName
    local environment: Environment = options.environment
    local packageJsonPath = Path.from(options.packageJsonPath)
    -- local parallelMode = options.parallelMode == true
    local showCommands = options.showCommands == true
    local compact = options.compact == true
    local noTypes = options.noTypes == true
    local devMode = options.devMode == true
    local tempDarkluaConfigName = options.tempDarkluaConfigName or 'temp-darklua-config.json'

    local nameWithoutScope = getNameWithoutScope(projectName)

    prepareDarkluaConfig(tempDarkluaConfigName, {
        bundle = true,
        environment = environment,
        testMode = false,
        devMode = devMode,
        compact = compact,
        noTypes = noTypes,
        baseDarkluaConfigPath = options.baseDarkluaConfigPath,
    })

    local darklua = createDarkluaRunner(showCommands)

    local packageJson = utils.readJsonFile(packageJsonPath)

    if not packageJson.main then
        error(`package '{projectName}' does not have a main entry point`)
    end

    local mainExtension = Path.from(packageJson.main):extension()
    if mainExtension ~= 'luau' and mainExtension ~= 'lua' then
        error(`package '{projectName}' main entry point must be a 'luau' or 'lua' file`)
    end

    local bundleOutput = buildPath:join(`{nameWithoutScope}{if devMode then '-dev' else ''}.luau`)

    darklua.process(
        tempDarkluaConfigName,
        packageJsonPath:parent():join(packageJson.main),
        bundleOutput
    )

    awaitAll(function()
        utils.removeFile(tempDarkluaConfigName)
    end)

    displayCreatedMessage(bundleOutput)

    utils.removeDirAll(tempPath)
end

return processBundle
