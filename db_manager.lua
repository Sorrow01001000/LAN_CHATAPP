local luasql = require "luasql.sqlite3"
local M = {}
local env = luasql.sqlite3()
local db = env:connect("lan_chat.db")

db:execute[[
  CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender TEXT,
    content TEXT,
    time_stamp DATETIME DEFAULT CURRENT_TIMESTAMP
  );
]]

db:execute[[
  CREATE TABLE IF NOT EXISTS servers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    ip TEXT UNIQUE
  );
]]

function M.add_server(name, ip)
    db:execute(string.format("INSERT OR IGNORE INTO servers (name, ip) VALUES ('%s', '%s')", name, ip))
end

function M.get_servers()
    local cursor = db:execute("SELECT name, ip FROM servers")
    local list = {}
    if cursor then
        local row = cursor:fetch({}, "a")
        while row do
            table.insert(list, {name = row.name, ip = row.ip})
            row = cursor:fetch(row, "a")
        end
        cursor:close()
    end
    return list
end

function M.save_message_to_db(user, msg)
    local clean_msg = msg:gsub("'", "''")
    db:execute(string.format(
        "INSERT INTO messages (sender, content) VALUES ('%s', '%s')", 
        user, clean_msg
    ))
end

function M.load_chat_history()
    local cursor = db:execute("SELECT sender, content, time_stamp FROM messages ORDER BY id ASC")
    local lines = {}

    if cursor then
    local row = cursor:fetch({}, "a")
    while row do
        table.insert(lines, string.format("[%s] %s: %s\n", row.time_stamp, row.sender, row.content))
        row = cursor:fetch(row, "a")
    end
    cursor:close()
end
    return table.concat(lines, "\n")
end

function M.get_cursor_only()
    return db:execute("SELECT sender, content FROM messages ORDER BY id DESC")
end

function M.close()
    db:close()
    env:close()
end

return M