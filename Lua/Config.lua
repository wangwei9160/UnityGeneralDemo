local Config = {}

function Config:GetConfig(name)
    if Config[name] ~= nil then
        return Config[name]    
    end
    Config[name] = require("Config/" .. name)
    return Config[name]
end

return Config