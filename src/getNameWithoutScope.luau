local function getNameWithoutScope(projectName: string)
    local nameWithoutScope = string.split(projectName, '/')[2] or projectName
    return nameWithoutScope
end

return getNameWithoutScope
