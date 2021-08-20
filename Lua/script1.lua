function init (args)
    local needs = {}
    needs["protocol"] = "http" 
    return needs
end

http_ua = HttpGetRequestHeader("User-Agent")
if http_ua == nil then
    http_ua = "<useragent unknown>"
    return 0
else
    return 1
end