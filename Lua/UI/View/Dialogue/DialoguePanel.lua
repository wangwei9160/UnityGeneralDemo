local DialoguePanel = Class("DialoguePanel" , UIShowBase)

function DialoguePanel:ctor(...)
end

function DialoguePanel:OnInit(data)
    self.uiView = data
    self.mPagedata = data
    self:AddUI(self.uiView)
    self:AddUIEvent()
end

function DialoguePanel:AddUI(uiView)
    self:mapComponent("msg" , uiView)
    self.msg.text = "22"
    self:mapComponent("closeBtn" , uiView)
end

function DialoguePanel:AddUIEvent()
    self.closeBtn.onClick:Add(function()
        UIManager:Hide("DialoguePanel")
    end)
end

return DialoguePanel
