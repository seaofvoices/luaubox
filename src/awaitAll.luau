local task = require('@lune/task')

local function isCallable(value)
    return type(value) == 'function'
end

local function isThreadDone(t: thread): boolean
    return coroutine.status(t) == 'dead'
end

local function awaitAll<T>(...: (() -> T) | (() -> ()) | thread): { T? }
    local total = select('#', ...)

    if total == 0 then
        return {}
    end

    local results = {}

    local wakeUpThread: thread? = nil
    local remaining = total

    local firstError: { any }? = nil

    for i = 1, total do
        local fn = select(i, ...)

        if fn == nil then
            remaining -= 1
        elseif type(fn) == 'thread' then
            if isThreadDone(fn) then
                remaining -= 1
            else
                task.defer(function()
                    while not isThreadDone(fn) do
                        task.wait()
                    end

                    remaining -= 1

                    if wakeUpThread and remaining <= 0 then
                        local current = wakeUpThread
                        wakeUpThread = nil
                        coroutine.resume(current)
                        wakeUpThread = nil
                    end
                end)
            end
        elseif isCallable(fn) then
            task.spawn(function()
                local success, fnResult = pcall(fn)
                if success then
                    results[i] = fnResult
                elseif firstError == nil then
                    firstError = { fnResult }
                end

                remaining -= 1

                if wakeUpThread and remaining <= 0 then
                    local current = wakeUpThread
                    wakeUpThread = nil
                    coroutine.resume(current)
                end
            end)
        else
            error(
                `argument #{i} passed to awaitAll function must be a callable or a thread, received '{typeof(
                    fn
                )}'`
            )
        end
    end

    if remaining > 0 then
        wakeUpThread = coroutine.running()
        coroutine.yield()
    end

    if firstError then
        error(firstError[1])
    end

    return results
end

return awaitAll
