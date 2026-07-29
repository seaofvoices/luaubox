local process = require('@lune/process')

export type Runner = (command: string, ...any) -> ()

local function runCommandVerbose(command: string, ...: any)
    local args = {}
    for i = 1, select('#', ...) do
        local argument = select(i, ...)
        args[i] = tostring(argument)
    end
    print(`running command '{command} {table.concat(args, ' ')}'`)

    local result = process.exec(command, args, {
        stdio = 'forward',
    })

    if not result.ok then
        error(`> {command} failed`)
    end

    if result.code ~= 0 then
        error(`> {command} failed with code {result.code}`)
    end
end

local function runCommandQuiet(command: string, ...: any)
    local args = {}
    for i = 1, select('#', ...) do
        local argument = select(i, ...)
        args[i] = tostring(argument)
    end

    local result = process.exec(command, args, {
        stdio = 'default',
    })

    if not result.ok then
        error(`> {command} failed:\n{result.stderr}`)
    end

    if result.code ~= 0 then
        error(`> {command} failed with code {result.code}:\n{result.stderr}`)
    end
end

return {
    verbose = runCommandVerbose,
    quiet = runCommandQuiet,
}
