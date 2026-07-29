local PathModule = require('@pkg/luau-path')

type AsPath = PathModule.AsPath

export type BaseOptions = {
    projectName: string,
    packageJsonPath: AsPath,
    parallelMode: boolean?,
    showCommands: boolean?,
    compact: boolean?,
    noTypes: boolean?,
    devMode: boolean?,
    tempDarkluaConfigName: string?,
    baseDarkluaConfigPath: string?,
}

return {}
