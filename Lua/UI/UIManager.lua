local UIManager = Class("UIManager")

function UIManager:ctor(...)
    self.ActiveUI = {}
    self.uiStack = nil
end

function UIManager:Show(uiName , data)
    local tmp = UIConfig[uiName]
    if tmp == nil then
        print("不存在这个uiName" , uiName)
        return 
    end
    local ui = LuaHelper.LoadUI(tmp.packagename , tmp.uiSkin)
    -- print(ui == nil)
    if data == nil then
        data = {}
    end
    data["name"] = uiName
    local uiClass = require(tmp.luapath).new()
    uiClass:OnInit(ui , data)
    self.ActiveUI[uiName] = ui
    return uiClass
end

function UIManager:Hide(uiName)
    if self.ActiveUI[uiName] ~= nil then
        if self.ActiveUI[uiName].Dispose then
            self.ActiveUI[uiName]:Dispose()  -- 调用 Dispose 方法
        else
            print("警告：对象没有 Dispose 方法", uiName)
        end
    end
    self.ActiveUI[uiName] = nil
end

return UIManager