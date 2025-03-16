local DialoguePanel = Class("DialoguePanel" , UIShowBase)

function DialoguePanel:ctor(...)
end

function DialoguePanel:OnInit(ui , data)
    self.uiView = ui
    self.mPagedata = ui
    self:AddUI(self.uiView)
    self:AddUIEvent()
    if data ~= nil then
        self.data_list = data.data_list
        self.start_id = data.start_id
        self:SetData(self.start_id)
    end
end

function DialoguePanel:AddUI(uiView)
    self:mapComponent("msg" , uiView)
    self:mapComponent("closeBtn" , uiView)
    self:mapComponent("maskCom" , uiView)
    self.maskCom.visible = true
    self.maskCom.touchable = true
end

function DialoguePanel:AddUIEvent()
    self.closeBtn.onClick:Add(function()
        UIManager:Hide("DialoguePanel")
    end)
    self.maskCom.onTouchBegin:Add(function(context)
        self:OnMaskTouchBegin(context)  -- 闭包
    end)
    -- self.maskCom.onTouchBegin:Add(self.OnMaskTouchBegin , self)
end

function DialoguePanel:OnMaskTouchBegin(...)
    local id = self.start_id
    if id == -1 then
        return 
    end
    self.start_id = self.data_list[id].next
    self:SetData(self.start_id)
end

function DialoguePanel:SetData(id)
    local s_id = self.start_id
    if id ~= nil then
        s_id = id -- 强制改成传进来的id
    end
    if s_id == -1 then
        print("剧情结束了")
        return 
    end
    if self.data_list[s_id].message ~= nil then
        self.msg.text = self.data_list[s_id].message
    end
end

return DialoguePanel
