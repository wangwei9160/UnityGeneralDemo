local data = {
    [10010] = {
        ["next"] = 10011,
        ["belong"] = 1,
        ["message"] = "你好1",
    },
    [10011] = {
        ["next"] = 10012,
        ["belong"] = 1,
        ["message"] = "剧情1",
    },
    [10012] = {
        ["next"] = -1,
        ["belong"] = 1,
        ["message"] = "对话结束了1",
    },
    [20010] = {
        ["next"] = 20011,
        ["belong"] = 2,
        ["message"] = "你好2",
    },
    [20011] = {
        ["next"] = 20012,
        ["belong"] = 2,
        ["message"] = "剧情2",
    },
    [20012] = {
        ["next"] = -1,
        ["belong"] = 2,
        ["message"] = "对话结束了2",
    }
}

local new_data = {

}

for k , v in pairs(data) do 
    local bl = v.belong
    if not new_data[bl] then
        new_data[bl] = {}
    end
    new_data[bl][k] = v
end

return new_data