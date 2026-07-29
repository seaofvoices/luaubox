local PathModule = require('@pkg/luau-path')

local awaitAll = require('./awaitAll')
local utils = require('./utils')

local Path = PathModule.Path

type AsPath = PathModule.AsPath

local BASE_SH_SNIPPET = [[#!/usr/bin/env sh
basedir=$(dirname "$(echo "$0" | sed -e 's,\\,/,g')")

case `uname` in
    *CYGWIN*) basedir=`cygpath -w "$basedir"`;;
esac

]]

local BASE_CMD_SNIPPET = [[@SETLOCAL

]]

local function generateScripts(
    filePath: AsPath,
    renderer: (varName: string, expandArgs: string) -> string
)
    local filePath = Path.from(filePath)

    local shSnippet = renderer('$basedir', '"$@"')
    local cmdSnippet = renderer('%~dp0', '%*')

    awaitAll(function()
        utils.writeFile(filePath:withExtension(''), BASE_SH_SNIPPET .. shSnippet .. '\n')
    end, function()
        utils.writeFile(filePath:withExtension('cmd'), BASE_CMD_SNIPPET .. cmdSnippet .. '\n')
    end)
end

return generateScripts
