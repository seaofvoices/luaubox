local fs = require('@lune/fs')
local serde = require('@lune/serde')

local PathModule = require('@pkg/luau-path')

local awaitAll = require('./awaitAll')

type AsPath = PathModule.AsPath

local function writeDir(path: AsPath)
    fs.writeDir(tostring(path))
end

local function writeFile(path: AsPath, content: string)
    fs.writeFile(tostring(path), content)
end

local function writeJsonFile(path: AsPath, data: any)
    fs.writeFile(tostring(path), serde.encode('json', data))
end

local function readJsonFile(path: AsPath): any
    return serde.decode('json', fs.readFile(tostring(path)))
end

local function isFile(path: AsPath): boolean
    return fs.isFile(tostring(path))
end

local function move(from: AsPath, to: AsPath)
    fs.move(tostring(from), tostring(to), true)
end

local function copy(from: AsPath, to: AsPath)
    fs.copy(tostring(from), tostring(to), true)
end

local function removeFile(path: AsPath)
    fs.removeFile(tostring(path))
end

local function removeDirAll(path: AsPath)
    local path = tostring(path)
    if fs.isFile(path) then
        fs.removeFile(path)
    elseif fs.isDir(path) then
        local jobs = {}

        for _, entry in fs.readDir(path) do
            local entryPath = path .. '/' .. entry
            table.insert(jobs, function()
                removeDirAll(entryPath)
            end)
        end

        awaitAll(unpack(jobs))

        fs.removeDir(path)
    end
end

return {
    writeDir = writeDir,
    writeFile = writeFile,
    writeJsonFile = writeJsonFile,
    readJsonFile = readJsonFile,
    isFile = isFile,
    move = move,
    copy = copy,
    removeFile = removeFile,
    removeDirAll = removeDirAll,
}
