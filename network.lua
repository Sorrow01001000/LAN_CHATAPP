local socket = require("socket")
local M ={}

M.port=44444
M.server=nil

-- for listening
function M.start_server()
    local server,err = socket.bind("*",M.port)
    if not server then return false ,err end
        server:settimeout(0)
        M.tcp_server = server
        return true
end


-- send message to specific ip
function M.send_to(ip,sender,message)
    local client=socket.tcp()
    client:settimeout(2)
    local ok,err = client:connect(ip,M.port)
    
    if ok then
        client:send(sender .. "|" .. message .. "\n")
        client:close()
        return true
    else
        return false, err
    end
end



function M.listen()
    if not M.tcp_server then return nil end
    local client = M.tcp_server:accept()
    if client then
        client:settimeout(1)
        local line, err = client:receive()
        client:close()
        if not err and line then
            local name , msg = line:match("([^|]+)|(.+)")
            return name, msg
        end
    end
    return nil
end

return M
