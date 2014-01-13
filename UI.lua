
SlashCmdList["MYPOINTS"] = function(arg1, ...)
	if MyPointsFrame:IsShown() then
		MyPointsFrame:Hide()
	else
		MyPointsFrame:Show()
	end
end

SLASH_MYPOINTS1 = "/MYPOINTS"
SLASH_MYPOINTS2 = "/MP"


groupFrames = { }

function TabsFrame_OnLoad( self )
	SetPortraitToTexture(self.groupButton1.icon, "Interface\\Icons\\INV_Helmet_08")
    self.groupButton1.name:SetText("活动")
    SetPortraitToTexture(self.groupButton2.icon, "Interface\\LFGFrame\\UI-LFR-PORTRAIT")
    self.groupButton2.name:SetText("人员")
    SetPortraitToTexture(self.groupButton3.icon, "Interface\\Icons\\Icon_Scenarios")
    self.groupButton3.name:SetText("事件")
    SetPortraitToTexture(self.groupButton4.icon, "Interface\\Icons\\Icon_Scenarios")
    self.groupButton4.name:SetText("物品")
    SetPortraitToTexture(self.groupButton5.icon, "Interface\\Icons\\Icon_Scenarios")
    self.groupButton5.name:SetText("设置")

    groupFrames = { RaidFrame , PlayerFrame , EventFrame , ItemFrame , SettingFrame }
    
end


function TabsFrame_OnShow(self)
    SetPortraitToTexture(MyPointsFrame.portrait, "Interface\\LFGFrame\\UI-LFG-PORTRAIT");
    MyPointsFrame.TitleText:SetText("My Points");
    ShowGroupFrame()
end


function MyPointsFrameGroupButton_OnClick( self )
    print("click-" .. self:GetID())	
    ShowGroupFrame(groupFrames[self:GetID()])
end

function ShowGroupFrame(frame)
    print(frame ~= nil)
    frame = frame or groupFrames[1]
    -- hide the other frames and select the right button
    for index, groupFrame in ipairs(groupFrames) do
        if ( groupFrame == frame ) then
            SelectGroupButton(index)
        else
            groupFrame:Hide()
        end
    end
    frame:Show()
end
 
function SelectGroupButton(index)
    local self = TabsFrame
    for i = 1, #groupFrames do
        local button = self["groupButton"..i]
        if ( i == index ) then
            button.bg:SetTexCoord(0.00390625, 0.87890625, 0.59179688, 0.66992188)
        else
            button.bg:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813)
        end
    end
end