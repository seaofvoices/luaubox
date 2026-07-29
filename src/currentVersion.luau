--!nocheck
local packageJson = require('../package.json')

local versionLabel: string = packageJson.version

return versionLabel
