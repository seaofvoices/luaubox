local stdio = require('@lune/stdio')

local PathModule = require('@pkg/luau-path')

local awaitAll = require('./awaitAll')
local createDarkluaRunner = require('./darklua')
local utils = require('./utils')

type AsPath = PathModule.AsPath
type Path = PathModule.Path

local Path = PathModule.Path

local DEFAULT_SOURCE_PATH = 'src'

export type Options = {
    startPath: Path,
    testMode: boolean,
    parallelMode: boolean,
    showCommands: boolean,
    tempDarkluaConfigName: string,
    tempPath: Path,
    nodeModulesPath: AsPath?,
    workingDir: AsPath?,
}

local SKIP_PACKAGES = {
    luaubox = true,
}

local DIM = stdio.style('dim')
local RESET = stdio.style('reset')
local GREEN = stdio.color('green')

local function processSources(options: Options)
    local testMode = options.testMode
    local tempPath = options.tempPath
    local tempDarkluaConfigName = options.tempDarkluaConfigName
    local nodeModulesPath = Path.from(options.nodeModulesPath or 'node_modules')
    local workingDir = Path.from(options.workingDir or '')

    local darklua = createDarkluaRunner(options.showCommands)

    local visited = {}

    local function processPackage(packageJsonPath: Path, followDevDependencies: boolean?)
        local root = packageJsonPath:parent() :: Path
        local visitedKey = root:toString()
        if visited[visitedKey] then
            return
        end
        visited[visitedKey] = true

        if not utils.isFile(packageJsonPath) then
            print(`{stdio.color('yellow')}{DIM}skip '{packageJsonPath}'{RESET}`)
            return
        end
        local packageJson = utils.readJsonFile(packageJsonPath)

        if SKIP_PACKAGES[packageJson.name] or not packageJson.main then
            return
        end

        local mainExtension = Path.from(packageJson.main):extension()
        if mainExtension ~= 'luau' and mainExtension ~= 'lua' then
            return
        end

        awaitAll(function()
            if root:equal(workingDir) then
                darklua.process(
                    tempDarkluaConfigName,
                    workingDir:join(DEFAULT_SOURCE_PATH),
                    workingDir:join(tempPath:join(DEFAULT_SOURCE_PATH))
                )
            else
                darklua.process(tempDarkluaConfigName, root, tempPath:join(root))
            end
        end, function()
            local aliasFile = nodeModulesPath:join(`.luau-aliases/{packageJson.name}.luau`)
            if utils.isFile(aliasFile) then
                darklua.process(tempDarkluaConfigName, aliasFile, tempPath:join(aliasFile))
            end
        end)

        print(`{DIM}processed{GREEN} {packageJson.name}{RESET}`)

        local dependencies = {}

        if packageJson.dependencies then
            for dependencyName in packageJson.dependencies do
                table.insert(dependencies, dependencyName)
            end
        end

        if followDevDependencies and packageJson.devDependencies then
            for dependencyName in packageJson.devDependencies do
                table.insert(dependencies, dependencyName)
            end
        end

        local jobs = {}

        for _, dependencyName in dependencies do
            local dependencyJsonPath = nodeModulesPath:join(`{dependencyName}/package.json`)
            if options.parallelMode then
                table.insert(jobs, function()
                    processPackage(dependencyJsonPath)
                end)
            else
                processPackage(dependencyJsonPath)
            end
        end

        awaitAll(unpack(jobs))
    end

    processPackage(options.startPath, testMode)
end

return processSources
