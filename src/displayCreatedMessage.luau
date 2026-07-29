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
    print(
        `{BOLD}Created {DIM}{COLOR}{location:parent()}/{RESET}{BOLD}{COLOR}{location:fileName()}{RESET}`
    )
end

return displayCreated
