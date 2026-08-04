local PathModule = require('@pkg/luau-path')

local utils = require('./utils')

type AsPath = PathModule.AsPath

export type Environment = 'roblox' | 'lune'

type Options = {
    environment: Environment?,
    bundle: boolean,
    testMode: boolean,
    devMode: boolean,
    compact: boolean,
    noTypes: boolean,
    baseDarkluaConfigPath: AsPath?,
    aliases: { [string]: AsPath }?,
}

local function findRule(rules: { any }, name: string): number?
    for index, rule in rules do
        if type(rule) == 'string' and rule == name then
            return index
        elseif rule.rule == name then
            return index
        end
    end
    return nil
end

local function prepareDarkluaConfig(configPath: AsPath, options: Options)
    local environment = options.environment
    local bundle = options.bundle
    local testMode = options.testMode
    local devMode = options.devMode
    local compact = options.compact
    local noTypes = options.noTypes
    local baseDarkluaConfigPath = options.baseDarkluaConfigPath
    local aliases = options.aliases

    if environment == nil and not bundle then
        error('environment is required when bundling is not enabled')
    end

    local darkluaConfig = if baseDarkluaConfigPath and utils.isFile(baseDarkluaConfigPath)
        then utils.readJsonFile(baseDarkluaConfigPath)
        else {}

    if darkluaConfig.bundle and not bundle then
        darkluaConfig.bundle = nil
    end
    if darkluaConfig.loaders == nil then
        darkluaConfig.loaders = {}
    end
    if darkluaConfig.rules == nil then
        darkluaConfig.rules = {}
    end

    if compact then
        darkluaConfig.generator = 'dense'
    end

    if bundle then
        darkluaConfig.bundle = {
            require_mode = 'path',
            excludes = { '@lune/**' },
        }
    end

    if #darkluaConfig.rules then
        darkluaConfig.rules = {
            'remove_comments' :: any,
            'remove_spaces',
            'make_assignment_local',
            'compute_expression',
            'remove_unused_if_branch',
            'filter_after_early_return',
            'convert_index_to_field',
            'remove_unused_while',
            'remove_empty_do',
            'remove_method_definition',
            'remove_function_call_parens',
        }
    end

    if noTypes then
        table.insert(darkluaConfig.rules, 1, 'remove_types')
    end

    local injectValues = {}
    if environment then
        table.insert(
            injectValues,
            { variable = 'LUA_ENV', value = environment :: string | boolean }
        )
    end
    table.insert(injectValues, { variable = 'DEV', value = devMode })
    table.insert(injectValues, { variable = '__DEV__', value = devMode })

    for _, item in injectValues do
        local found = false
        for _, rule in darkluaConfig.rules do
            if
                type(rule) == 'table'
                and rule.rule == 'inject_global_value'
                and rule.identifier == item.variable
            then
                found = true
                break
            end
        end

        if not found then
            table.insert(darkluaConfig.rules, {
                rule = 'inject_global_value',
                identifier = item.variable,
                value = item.value,
            })
        end
    end

    local sources = nil

    if aliases then
        sources = {}
        for aliasName, aliasPath in aliases do
            sources[aliasName] = tostring(aliasPath)
        end
    end

    local convertRequireIndex = findRule(darkluaConfig.rules, 'convert_require')
    if bundle then
        if convertRequireIndex then
            table.remove(darkluaConfig.rules, convertRequireIndex)
        end
    else
        if convertRequireIndex == nil then
            local requireRule = if environment == 'roblox'
                then {
                    rule = 'convert_require',
                    current = {
                        name = 'path',
                        sources = sources,
                        use_luau_configuration = aliases == nil,
                    },
                    target = {
                        name = 'roblox',
                        rojo_sourcemap = 'sourcemap.json',
                        indexing_style = 'wait_for_child',
                    },
                }
                elseif environment == 'lune' then {
                    rule = 'convert_require',
                    current = {
                        name = 'path',
                        sources = sources,
                        use_luau_configuration = aliases == nil,
                    },
                    target = {
                        name = 'luau',
                        sources = sources,
                        use_luau_configuration = aliases == nil,
                    },
                }
                else error(`unexpected Lua environment '{environment}'`)

            table.insert(darkluaConfig.rules, 1, requireRule)
        else
            if environment == 'roblox' then
                if
                    darkluaConfig.rules[convertRequireIndex].target ~= 'roblox'
                    or darkluaConfig.rules[convertRequireIndex].target.name ~= 'roblox'
                then
                    darkluaConfig.rules[convertRequireIndex] = {
                        rule = 'convert_require',
                        current = darkluaConfig.rules[convertRequireIndex].current,
                        target = {
                            name = 'roblox',
                            rojo_sourcemap = 'sourcemap.json',
                            indexing_style = 'wait_for_child',
                        },
                    }
                end
            elseif environment == 'lune' then
                if
                    darkluaConfig.rules[convertRequireIndex].target ~= 'luau'
                    or darkluaConfig.rules[convertRequireIndex].target.name ~= 'luau'
                then
                    darkluaConfig.rules[convertRequireIndex] = {
                        rule = 'convert_require',
                        current = darkluaConfig.rules[convertRequireIndex].current,
                        target = 'luau',
                    }
                end
            end
        end
    end

    if compact and not findRule(darkluaConfig.rules, 'rename_variables') then
        table.insert(darkluaConfig.rules, {
            rule = 'rename_variables',
            globals = { '$default', '$roblox' },
        })
    end

    local skipPatterns = { 'LICENSE.txt' }

    if not testMode then
        skipPatterns =
            { '*.test.luau', '*.test.lua', '*.spec.luau', '__tests__', unpack(skipPatterns) }
    end

    for _, pattern in skipPatterns do
        darkluaConfig.loaders['**/' .. pattern] = 'skip'
    end

    utils.writeJsonFile(configPath, darkluaConfig)
end

return prepareDarkluaConfig
