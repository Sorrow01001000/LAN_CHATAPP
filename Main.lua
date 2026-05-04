local iup =require("iuplua")
local db_manager = require("db_manager")
local net = require("network")

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

-- ROOMS
local list_contacts = iup.list{expand="YES"}
local screen_contacts = iup.vbox{
    iup.label{title="Active Users on LAN",font="Arial , Bold 12"},
    list_contacts,
    iup.button{title="Join Selected Chat", expand="HORIZONTAL"},
    margin="10x10",gap="5"
}

--CHAT WINDOW
local chat_display = iup.text{multiline="YES", readonly="YES",expand="YES",font="Courier, 10"}
local chat_input = iup.text{expand="HORIZONTAL"}
local btn_send = iup.button{title="Send", size="50x"}

local text_ip = iup.text{value="127.0.0.1", size="100x"}

local screen_chat = iup.vbox{
    iup.hbox{iup.label{title="Target IP:"},text_ip},
    iup.label{title="Chatting with: Room 1 ", font ="Arial , Bold 12"},
    chat_display,
    iup.hbox{chat_input,btn_send,gap="5"},
    margin="10x10", gap="5"
}

--PROFILE
local screen_profile = iup.vbox{
    iup.label{title="User Profile", font="Arial , Bold 12"},
    iup.label{title="Change Status:"},
    iup.text{value="Available", expand="HORIZONTAL"},
    iup.button{title="Save Changes"},
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

function btn_login:action()
    if txt_username.value ~= "" then
    print("Logging in as: " .. txt_username.value)
    state.title="Status: Online"
    state.fgcolor= "0 155 0"
    show_screen(2)
    else
        iup.Message("Login Error", "Please enter a username first!")
    end
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