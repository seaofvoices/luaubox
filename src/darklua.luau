local PathModule = require('@pkg/luau-path')

local runCommand = require('./runCommand')

type AsPath = PathModule.AsPath

local function createDarkluaRunner(verbose: boolean)
    local runner: runCommand.Runner = if verbose then runCommand.verbose else runCommand.quiet

    local function process(configPath: AsPath, inputPath: AsPath, outputPath: AsPath)
        runner('darklua', 'process', '--config', configPath, inputPath, outputPath)
    end

    return {
        process = process,
    }
end

return createDarkluaRunner
