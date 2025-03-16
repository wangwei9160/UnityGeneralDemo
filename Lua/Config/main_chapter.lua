local data = {
    [1] = {
        [0] = 10010 -- start_id
    }
}

local s_id = {["start_id"] = 0}

local mt = {
    __index = function(table,key)
        local k = key
        if s_id[key] ~= nil then
            k = s_id[key]            
        end
        return table[k]
    end
}

for k , v in pairs(data) do
    setmetatable(v , mt)
end

return data