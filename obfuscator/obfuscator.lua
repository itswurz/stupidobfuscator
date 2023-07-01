package.path = "../?.lua;" .. package.path
local lexer = require("lexer")
local file = io.open("source.lua", "r")
local src = file:read("*all")
file:close()
local finalLex = lexer(src)
local Stack = {}

local StackCount = 0
local inParen = false
local inString = false

for i,v in pairs(finalLex) do
    if type(v) == "table" then
        for a,b in pairs(v) do
            if type(b) == "table" then
                if b["type"] == "ident" then
                    table.insert(Stack, {b["data"]})
                    StackCount = StackCount + 1
                elseif b["type"] == "symbol" then
                    if b["data"] == "(" then
                        inParen = true
                    elseif b["data"] == ")" then
                        inParen = false
                    end
                elseif b["type"] == "string_start" then
                    inString = true
                elseif b["type"] == "string_end" then
                    inString = false
                elseif b["type"] == "string" and inParen == true and inString == true then
                    Stack[StackCount][2] = b["data"]
                end
            end
        end
    end
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local count = 1
local script = [[
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end
return(function(...)]]

for i,v in pairs(Stack) do
    script = script .. "\n(({...})[" .. tostring(count) .. "])[1]=getfenv()[dec('" .. enc(v[1]) .. "')];"
    script = script .. "\n(({...})[" .. tostring(count) .. "])[2]=dec('" .. enc(v[2]) .. "');"
    script = script .. "\n(({...})[" .. tostring(count) .. "])[1]((({...})[" .. tostring(count) .. "])[2]);"
end

script = script .. "\nend)({},getfenv,table.remove)"

file = io.open("output.lua", "w")
file:write(script)
file:close()

print("ur script has been obfuscated cuz youre retarded as fuck")
