local GroupBattleMain = Class("GroupBattleMain" , UIShowBase)

function GroupBattleMain:ctor(...)
end

function GroupBattleMain:OnInit(ui , data)
    self.uiView = ui
    self.mPageData = data
    for i = 1 , 3 do 
        self:mapComponent( "aBtn" .. i , self.uiView)
    end
    for i = 1, 3 do
        self:mapComponent( "checkBtn" .. i , self.uiView)
    end
    self:mapComponent( "closeBtn" , self.uiView)
    self:AddUI(self.uiView)
    self:AddUIEvent()
    local id = data.id
    local c1 = self.uiView:GetController("c1")
    c1.selectedIndex = id - 1   -- 索引 0 1 2
end

function GroupBattleMain:AddUI(uiView)
    
end

function GroupBattleMain:AddUIEvent()
    self.closeBtn.onClick:Add(function(...)
        UIManager:Hide(self.mPageData.name)
    end)
    for i = 1 , 3 do
        local btn = self["checkBtn" .. i]
        btn.onClick:Add(function(...)
            print("checkBtn" .. i)
        end)
    end
    for i = 1 , 3 do
        local btn = self["aBtn" .. i]
        btn.onClick:Add(function(...)
            print("[GroupBattleMain] aBtn" .. i)
        end)
    end
    
end

return GroupBattleMain
