local MainDialogue = Class("MainDialogue" , UIShowBase)

-- 进入对话

function MainDialogue:ctor(...)
end

function MainDialogue:OnInit(ui)
    self.uiView = ui
    self.mPagedata = ui
    self:AddUI(self.uiView)
    self:AddUIEvent()
end

function MainDialogue:AddUI(uiView)
    self:mapComponent("skipBtn" , uiView)
end

function MainDialogue:AddUIEvent()
    self.skipBtn.onClick:Add(function()
        local chapter = Config:GetConfig("main_chapter")
        local words = Config:GetConfig("story_word")[1]
        UIManager:Show("DialoguePanel" , {data_list = words , start_id = chapter[1].start_id})
    end)
end

return MainDialogue
