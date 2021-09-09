function init (args)
    local needs = {}
    needs["http.request_headers"] = tostring(true)
    return needs
end

function match(args)
    a = tostring(args["http.request_headers"])
    if #a > 0 then
        if a:find("headerVal: value") then
            return 1
        elseif a:find("headerVal: AndThisValue") then
            return 1
        end
    end
    return 0
end

return 0