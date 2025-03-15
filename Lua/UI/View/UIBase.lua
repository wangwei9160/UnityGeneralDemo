local UIBase = Class("UIBase")

function UIBase:ctor(...)
end

function UIBase:mapComponent(name , parent)
    local obj = self[name]
    if obj == nil then
       obj = parent:GetChild(name) 
    end
    self[name] = obj
    return self[name]
end



return UIBase