local stdio = require('@lune/stdio')

local PathModule = require('@pkg/luau-path')

local Path = PathModule.Path

type AsPath = PathModule.AsPath

local DIM = stdio.style('dim')
local BOLD = stdio.style('bold')
local RESET = stdio.style('reset')
local COLOR = stdio.color('cyan')

local function displayCreated(location: AsPath)
    local location = Path.from(location)
    local fileName = location:fileName()

    local locationDisplay = location:toString()

    print(
        `{BOLD}Created {DIM}{COLOR}{string.sub(locationDisplay, 1, -#fileName - 1)}{RESET}{BOLD}{COLOR}{fileName}{RESET}`
    )
end

return displayCreated
