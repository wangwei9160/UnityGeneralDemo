local MainDialogue = Class("MainDialogue" , UIShowBase)

function MainDialogue:ctor(...)
end

function MainDialogue:OnInit(data)
    self.uiView = data
    self.mPagedata = data
    self:AddUI(self.uiView)
    self:AddUIEvent()
end

function MainDialogue:AddUI(uiView)
    self:mapComponent("skipBtn" , uiView)
end

function MainDialogue:AddUIEvent()
    self.skipBtn.onClick:Add(function()
        UIManager:Show("DialoguePanel")
    end)
end

return MainDialogue
