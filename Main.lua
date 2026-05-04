local iup =require("iuplua")
local db_manager = require("db_manager")
local net = require("network")
local socket = require("socket")

function get_my_ip()
    local s = socket.udp()
    local ok = s:setpeername("8.8.8.8", 80)
    if not ok then return "127.0.0.1" end
    local ip = s:getsockname()
    s:close()
    return ip
end

net.start_server()

-- login screen
local txt_username = iup.text{expand = "HORIZONTAL"}
local state = iup.label{title="Status:Offline", fgcolor="255 0 0"}
local btn_login = iup.button{title="Login",expand={"HORIZONTAL"}}

local screen_login = iup.vbox{
    iup.label{title="Welcome to Chatapp",font="Arial , Bold 24"},
    iup.label{title="Enter Username: "},
    txt_username,
    btn_login,
    state,
    alignment="ACENTER" ,gap="10", margin="20x20"
}

-- Contacts
local list_contacts = iup.list{expand="YES"}
local txt_friend_name = iup.text{placeholder="Friend's Name", expand="HORIZONTAL"}
local txt_friend_ip = iup.text{placeholder="192.168.1.X", expand="HORIZONTAL"}
local btn_add_server = iup.button{title="Save to Server List", expand="HORIZONTAL"}

local screen_contacts = iup.vbox{
    iup.label{title="Saved Servers", font="Arial, Bold 12"},
    list_contacts,
    iup.label{title="Add New Friend:"},
    txt_friend_name,
    txt_friend_ip,
    btn_add_server,
    iup.button{title="Connect & Chat", expand="HORIZONTAL", action=function() show_screen(3) end},
    margin="10x10", gap="5"
}

--CHAT WINDOW
local chat_display = iup.text{multiline="YES", readonly="YES",expand="YES",font="Courier, 10"}
local chat_input = iup.text{expand="HORIZONTAL"}
local btn_send = iup.button{title="Send", size="50x"}
local lbl_chat_title = iup.label{title="Select a friend to start chatting", font ="Arial, Bold 12"}

local text_ip = iup.text{value="127.0.0.1", size="100x"}

local screen_chat = iup.vbox{
    lbl_chat_title,
    iup.hbox{iup.label{title="Target IP:"},text_ip},
    chat_display,
    iup.hbox{chat_input,btn_send,gap="5"},
    margin="10x10", gap="5"
}

--PROFILE
local lbl_my_nick = iup.label{title="Your Nickname: Not set"}

local screen_profile = iup.vbox{
    iup.label{title="User Profile", font="Arial , Bold 14"},
    lbl_my_nick,
    iup.label{title="Your LAN IP Adress: ", font="Arial , Bold 10"},
    iup.label{title=get_my_ip(),fgcolor="0 0 255"},
    iup.label{"Share this IP with your friends so they can chat with you."},
    margin="10x10", gap="10"
}

--HISTORY LOG
local history_list = iup.list{expand="YES"}
local screen_histroy= iup.vbox{
    iup.label{title="Past Converstations", font="Arial , Bold 12"},
    history_list,
    iup.button{title="View Log"},
    margin="10x10", gap ="5"
}

local screen_contanier = iup.zbox{
    screen_login, --1
    screen_contacts, --2
    screen_chat, -- 3
    screen_profile, -- 4
    screen_histroy -- 5
}

-- -------------------------------------------------------END OF GUI------------------------------------------------------------
-- ---------------------------------------------------START OF FUNCTIONS------------------------------------------------------------


function show_screen(index)
    screen_contanier.value= screen_contanier[index]

    if index == 3 then
        chat_display.value = db_manager.load_chat_history()
    elseif index == 5 then
        update_history_list()
    end
end

function btn_add_server:action()
    if txt_friend_name.value ~= "" and txt_friend_ip.value ~= "" then
        db_manager.add_server(txt_friend_name.value, txt_friend_ip.value)
        update_server_list_ui()
        txt_friend_name.value = ""
        txt_friend_ip.value = ""
    end
end

function update_server_list_ui()
    list_contacts.removeitem = "ALL"
    local servers = db_manager.get_servers()
    if #servers==0 then
        print("Debug: No servers found in database.")
    end
    for i, s in ipairs(servers) do
        list_contacts[i] = s.name .. " (" .. s.ip .. ")"
    end
end

function list_contacts:action(text, item, state)
    if state == 1 then 
        local name, ip = text:match("(.+) %((.-)%)")
        if ip and name then
            text_ip.value = ip
            lbl_chat_title.title= "Chatting with: " .. name .."(" .. ip ..")"
        end
    end
end

function btn_login:action()
    if txt_username.value ~= "" then
        lbl_my_nick.title="Your Nickname: " .. txt_username.value
        state.title="Status: Online"
        state.fgcolor= "0 155 0"
        update_server_list_ui()
        show_screen(2)
    else
        iup.Message("Login Error", "Please enter a username first!")
    end
    return iup.DEFAULT
end

function btn_send:action()
    local msg = chat_input.value
    local user = txt_username.value
    local target_ip = text_ip.value

    if msg ~= "" then
        local success, err = net.send_to(target_ip,user,msg)

        if success then
            db_manager.save_message_to_db(user,msg)
            chat_input.value=""
            chat_display.value = db_manager.load_chat_history()
        else
            iup.Message("Network Error ", "Could not reach " .. target_ip .. "\n")
        end
    end    
    return iup.DEFAULT
end

function update_history_list()
    history_list.removeitem="ALL"

    local cursor = db_manager.get_cursor_only()
    if cursor then
        local count = 1
        local row = cursor:fetch({},"a")
        while row do 
            history_list[count] = string.format("%s: %s", row.sender, row.content)
            count = count +1
            row = cursor:fetch(row,"a")
        end
        cursor:close()
    end
end

local menu = iup.menu{
    iup.item{title="Contacts",action=function() show_screen(2) end},
    iup.item{title="Chat", action=function () show_screen (3) end},
    iup.item{title="Profile", action=function () show_screen (4) end},
    iup.item{title="History", action=function () show_screen (5) end},
    iup.separator{},
    iup.item{title="Exit", action=function()
        db_manager.close()
        return iup.CLOSE end}
}

local main_window = iup.dialog{
    screen_contanier,
    title= "Lua LAN Chat",
    size= "QUARTERxHALF",
    menu = menu
}

local timer =iup.timer{time=500}
function timer:action_cb()
   local sender,msg=net.listen()
   if sender and msg then
    db_manager.save_message_to_db(sender,msg)
    if screen_contanier.value == screen_chat then
        chat_display.value = db_manager.load_chat_history()
    end
   end
   return iup.DEFAULT
end
timer.run="YES"


main_window:show()
iup.MainLoop()