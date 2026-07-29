return [[local ReplicatedStorage = game:GetService('ReplicatedStorage')

local jest = require(
    ReplicatedStorage:FindFirstChild('node_modules'):FindFirstChild('.luau-aliases'):FindFirstChild('@jsdotlua'):FindFirstChild('jest')
)

local jestRoots = {
    ReplicatedStorage:FindFirstChild('node_modules'):FindFirstChild('TestTarget'),
}

local success, result = jest.runCLI(ReplicatedStorage, {}, jestRoots):await()

if not success then
    error(result)
end

task.wait(0.5)
]]
