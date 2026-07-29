local process = require('@lune/process')

local luaubox = require('./src')

luaubox.runWithArgs(process.args)
