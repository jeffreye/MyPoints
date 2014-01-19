
SlashCmdList["MYPOINTS"] = function(arg1, ...)
	if MyPointsFrame:IsShown() then
		MyPointsFrame:Hide()
	else
		MyPointsFrame:Show()
	end
end

SLASH_MYPOINTS1 = "/MYPOINTS"
SLASH_MYPOINTS2 = "/MP"

if MyPointsFrame then
    MyPointsFrame:RegisterEvent("ADDON_LOADED")
    MyPointsFrame:RegisterEvent("PLAYER_LOGOUT")
end

local SCROLLFRAME_BUTTON_OFFSET = 2
local SCROLLFRAME_MAX_COLUMNS = 4
local groupFrames = {}
local TableColumns = {
            ["MemberFrame"] = { "名字" , "职业" , "分数" , "系数" },
            ["EventFrame"]  = { "名称" , "时间" , "分数" },
            ["ItemFrame"]   = { "名称" , "拾取" , "分数"}                                       
}

--total length  = 121 + 64*3 =313
local ColumnData = {
            ["名字"] = { width = 121, text = "名字", stringJustify="LEFT" },
            ["名称"] = { width = 149, text = "名称", stringJustify="LEFT" },
            ["拾取"] = { width = 100, text = "拾取", stringJustify="CENTER" },
            ["职业"] = { width = 64, text = "职业", stringJustify="CENTER" },
            ["分数"] = { width = 64, text = "分数", stringJustify="CENTER" },
            ["系数"] = { width = 64, text = "系数", stringJustify="CENTER" },
            ["时间"] = { width = 100, text = "时间", stringJustify="CENTER" },
}

local CurrentView = "MemberFrame"

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

    MyPointsFrame.TitleText:SetText("My Points")
    SetPortraitToTexture(MyPointsFrame.portrait, "Interface\\LFGFrame\\UI-LFG-PORTRAIT")

    groupFrames ={ OverviewFrame , MemberFrame , EventFrame , ItemFrame , SettingFrame }
end


function TabsFrame_OnShow(self)
    ShowGroupFrame()
end


function MyPointsFrameGroupButton_OnClick( self )
    ShowGroupFrame(groupFrames[self:GetID()])
end

function ShowGroupFrame(frame)
    frame = frame or groupFrames[1]
    -- hide the other frames and select the right button
    for index, groupFrame in ipairs(groupFrames) do
        local button = TabsFrame["groupButton"..index]
        if ( groupFrame == frame ) then
            button.bg:SetTexCoord(0.00390625, 0.87890625, 0.59179688, 0.66992188)
        else
            groupFrame:Hide()
            button.bg:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813)
        end
    end
    frame:Show()
end

function RaidInfo_OnShow( self )
    self.RaidNameLabel:SetText("活动名称:")
    self.CreateTimeLabel:SetText("创建时间:"..date())
    self.EndTimeLabel:SetText("结束时间:"..date())
end

function SwitchAutoAnnounce( checked )
    if checked then
        print("on")
    else
        print("off")
    end
end

function AnnounceBox_OnTextChanged( self )
    print("announce" .. self:GetText())
end

function AnnounceIntervalBox_OnTextChanged( self )
    print("announce time" .. self:GetText())
end

function GetRosterInfo( index )
    local mem = CurrentRecord.members[index]
    return mem.name,mem.class,CurrentRecord:Lookup(mem.name),mem.factor
end

function SubFrame_OnShow( self )
    ScrollFrameInit(self)
end



function ScrollFrameInit( view )
    scrollFrame = view["Container"]
    HybridScrollFrame_CreateButtons(scrollFrame, "RaidRosterButtonTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, -SCROLLFRAME_BUTTON_OFFSET, "TOP", "BOTTOM")
    scrollFrame.update = function ()
        ScrollFrameUpdate(scrollFrame)
    end

    local numColumns = #TableColumns[view:GetName()]
    local stringsInfo = {}
    local stringOffset = 0;

    for col=1,SCROLLFRAME_MAX_COLUMNS do
        local button = view["RaidRosterColumnButton" .. col]
        local columnHeader = TableColumns[view:GetName()][col]
        if columnHeader then
            local data = ColumnData[columnHeader]
            button:SetText(data.text)
            WhoFrameColumn_SetWidth(button,data.width)
            button:Show()
            data["stringOffset"] = stringOffset
            table.insert(stringsInfo, data)
            stringOffset = stringOffset + data.width - 2
        else
            button:Hide()
        end
    end

    local buttons = scrollFrame.buttons
    for i=1,#buttons do
        local btn = buttons[i]
        for stringIndex=1,SCROLLFRAME_MAX_COLUMNS do
            local fontString = btn["string" .. stringIndex]
            local stringData = stringsInfo[stringIndex]
            if stringData then
            -- want strings a little inside the columns, 6 pixels from the left and 8 from the right
                fontString:SetPoint("LEFT" , stringData.stringOffset + 6, 0)
                fontString:SetWidth(stringData.width - 14)
                fontString:SetJustifyH(stringData.stringJustify)
                fontString:Show()
            else
                fontString:Hide()
            end
        end

        btn.barTexture:Hide()
    end

end

function GetInfoCount( view )
    if CurrentView == "MemberFrame" then
        return #CurrentRecord.members
    elseif CurrentView == "ItemFrame" then
        return #CurrentRecord.loots
    elseif CurrentView == "EventFrame" then
        return #CurrentRecord.events
    else
        return 0
    end
end

function ScrollFrameUpdate( scrollFrame )
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local buttons = scrollFrame
    local count = GetInfoCount(CurrentView)

    for i=1,#buttons do
        local btn = buttons[i]

        if i >= count then
            btn:Hide()
        else
            if CurrentView == "MemberFrame" then
                local name,class,dkp,factor = GetRosterInfo(i+offset)
                btn.string1:SetText(name)
                btn.string2:SetText(class)
                btn.string3:SetText(dkp)
                btn.string4:SetText(factor)
            elseif CurrentView == "EventFrame" then
                local name,time,point = GetEventInfo(i+offset)
                btn.string1:SetText(name)
                btn.string2:SetText(class)
                btn.string3:SetText(point)
            elseif CurrentView == "ItemFrame" then
                local name,looter,point = GetLootInfo(i+offset)
                btn.string1:SetText(name)
                btn.string2:SetText(looter)
                btn.string3:SetText(point)
            end

            btn:Show()
        end

    end

    local totalHeight = count * (20 + 2)
    local displayedHeight = #buttons * (20 + 2)
    HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)
end

function SortByColumn( self )
    print("click" .. self:GetName())
end

function RaidRosterButton_OnClick( self )
    print("click" .. self:GetName())
end