local GroupBattleMain = Class("GroupBattleMain" , UIShowBase)

function GroupBattleMain:ctor(...)
end

function GroupBattleMain:OnInit(ui)
    self.uiView = ui
    self.mPagedata = ui
    for i = 1 , 3 do 
        self:mapComponent( "aBtn" .. i , self.uiView)
    end
    for i = 1, 3 do
        self:mapComponent( "checkBtn" .. i , self.uiView)
    end
    self:mapComponent("createBtn" , self.uiView)
    
    self["currentSelectdIndex"] = 1
    self:AddUI(self.uiView)
    self:AddUIEvent()
    
end

function GroupBattleMain:AddUI(uiView)
    
end

function GroupBattleMain:AddUIEvent()
    for i = 1 , 3 do 
        local btn = self["aBtn" .. i]
        if btn ~= nil then
            btn.onClick:Add(function(...)
                self.currentSelectdIndex = i
                print("aBtn" .. i)
            end)
        else
            print("不存在aBtn"..i) 
        end
    end
    self.checkBtn1.onClick:Add(function(...)
        self["currentSelectdIndex"] = 1
        print(self.currentSelectdIndex)
    end)
    self.checkBtn2.onClick:Add(function(...)
        self["currentSelectdIndex"] = 2
        print(self.currentSelectdIndex)
    end)
    self.checkBtn3.onClick:Add(function(...)
        self["currentSelectdIndex"] = 3
        print(self.currentSelectdIndex)
    end)
    
    self.createBtn.onClick:Add(function(...)
        UIManager:Show("GroupBattleCreateRoom" , {id = self.currentSelectdIndex})
    end)
end



return GroupBattleMain
