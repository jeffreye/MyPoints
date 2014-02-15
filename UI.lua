
SlashCmdList["MYPOINTS"] = function(arg1, ...)
	if MyPointsFrame:IsShown() then
		MyPointsFrame:Hide()
	else
		MyPointsFrame:Show()
	end
end

SLASH_MYPOINTS1 = "/MYPOINTS"
SLASH_MYPOINTS2 = "/MP"

local SCROLLFRAME_BUTTON_OFFSET = 2
local SCROLLFRAME_MAX_COLUMNS = 4
local groupFrames ={ OverviewFrame , MemberFrame , EventFrame , ItemFrame , SettingFrame }

if MyPointsFrame then
    MyPointsFrame:RegisterEvent("ADDON_LOADED")
    MyPointsFrame:RegisterEvent("PLAYER_LOGOUT")
    MyPointsFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    MyPointsFrame:RegisterEvent("CHAT_MSG_WHISPER")
end

local lang_convert = {
    ["HUNTER"]       = "猎人",
    ["WARRIOR"]      = "战士",
    ["SHAMAN"]       = "萨满",
    ["MONK"]         = "武僧",
    ["ROGUE"]        = "盗贼",
    ["MAGE"]         = "法师",
    ["DRUID"]        = "小德",
    ["DEATHKNIGHT"]  = "死骑",
    ["PALADIN"]      = "圣骑",
    ["PRIEST"]       = "牧师",
    ["WARLOCK"]      = "术士"

}
local TableColumns = {
            ["MemberFrame"] = { "名字" , "职业" , "DKP" , "系数" },
            ["EventFrame"]  = { "名称" , "时间" , "分数" },
            ["ItemFrame"]   = { "物品" , "拾取" , "花费"}                                       
}

--total length  = 121 + 64*3 =313
local ColumnData = {
            ["名字"] = { width = 121, text = "名字", stringJustify="LEFT"   ,sort = function() table.sort( CurrentRecord.members, function(a, b) return b.name < a.name end ) end},
            ["物品"] = { width = 149, text = "物品", stringJustify="LEFT"   ,sort = function() table.sort( CurrentRecord.loots, function(a, b) return b.name < a.name end  ) end},
            ["名称"] = { width = 149, text = "名称", stringJustify="LEFT"   ,sort = function() table.sort( CurrentRecord.events, function(a, b) return b.name < a.name end  ) end},
            ["拾取"] = { width = 100, text = "拾取", stringJustify="CENTER" ,sort = function() table.sort( CurrentRecord.loots, function(a, b) return CurrentRecord.members[b.player].name < CurrentRecord.members[a.player].name end  ) end},
            ["职业"] = { width = 64, text = "职业", stringJustify="CENTER"  ,sort = function() table.sort( CurrentRecord.members, function(a, b) return b.class < a.class end  ) end},
            ["DKP"] = { width = 64, text = "DKP", stringJustify="CENTER"  ,sort = function() table.sort( CurrentRecord.members, function(a, b) return CurrentRecord:Lookup(b.name) < CurrentRecord:Lookup(a.name) end ) end},
            ["分数"] = { width = 64, text = "分数", stringJustify="CENTER"  ,sort = function() table.sort( CurrentRecord.events, function(a, b) return b.point < a.point  end ) end},
            ["花费"] = { width = 64, text = "花费", stringJustify="CENTER"  ,sort = function() table.sort( CurrentRecord.loots, function(a, b) return b.point < a.point end ) end},
            ["系数"] = { width = 64, text = "系数", stringJustify="CENTER"  ,sort = function() table.sort( CurrentRecord.members, function(a, b) return CurrentRecord:GetDetails(b.name).factor < CurrentRecord:GetDetails(a.name).factor end ) end},
            ["时间"] = { width = 100, text = "时间", stringJustify="CENTER" ,sort = function() table.sort( CurrentRecord.events, function(a, b) return b.ctime[1] < a.ctime[1] end  ) end},
}

CurrentView = "MemberFrame"
Selected = nil

AutoAnnounce = false


function TabsFrame_OnLoad( self )
    tinsert(UISpecialFrames, MyPointsFrame:GetName());
	SetPortraitToTexture(self.groupButton1.icon, "Interface\\EncounterJournal\\UI-EJ-PortraitIcon")
    self.groupButton1.name:SetText("活动")
    SetPortraitToTexture(self.groupButton2.icon, "Interface\\LFGFrame\\UI-LFR-PORTRAIT")
    self.groupButton2.name:SetText("人员")
    SetPortraitToTexture(self.groupButton3.icon, "Interface\\Icons\\Icon_Scenarios")
    self.groupButton3.name:SetText("事件")
    SetPortraitToTexture(self.groupButton4.icon, "Interface\\Icons\\INV_Weapon_Glave_01")
    self.groupButton4.name:SetText("物品")
    SetPortraitToTexture(self.groupButton5.icon, "Interface\\Icons\\INV_Misc_EngGizmos_37")
    self.groupButton5.name:SetText("设置")

    MyPointsFrame.TitleText:SetText("DKP记录仪")
    SetPortraitToTexture(MyPointsFrame.portrait, "Interface\\FriendsFrame\\FriendsFrameScrollIcon")

    
    groupFrames = { OverviewFrame , MemberFrame , EventFrame , ItemFrame , SettingFrame }

    -- create a timer
    local total = 0 
    local function onUpdate(self,elapsed)
        if not AutoAnnounce then
            return
        end

        total = total + elapsed
        if total >= DKP_Options["auto_announce_interval"] then
            SendChatMessage(DKP_Options["auto_announce"],"GUILD")
            total = 0
        end
    end
     
    CreateTimer(onUpdate)

    --need to support chatframe
    hooksecurefunc("HandleModifiedItemClick", OnModifiedClickItem)
end

function OnModifiedClickItem( link )
    if IsShiftKeyDown() and  NewFrame.name:HasFocus() then
        NewFrame.name:Insert(link)
    end
end


function TabsFrame_OnShow(self)
    ShowGroupFrame(OverviewFrame)
end


function MyPointsFrameGroupButton_OnClick( self )
    ShowGroupFrame(groupFrames[self:GetID()])
    NewFrame:Hide()
end

function ShowGroupFrame(frame)
    frame = frame or groupFrames[1]
    -- hide the other frames and select the right button
    for index, groupFrame in ipairs(groupFrames) do
        local button = TabsFrame["groupButton"..index]
        if ( groupFrame == frame ) then
            groupFrame:Show()
            button.bg:SetTexCoord(0.00390625, 0.87890625, 0.59179688, 0.66992188)
        else
            groupFrame:Hide()
            button.bg:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813)
        end
    end
end

function RaidInfo_OnShow( self )
    self.RaidNameLabel:SetText("活动名称:" .. CurrentRecord.name)
    self.CreateTimeLabel:SetText("创建时间:"..CurrentRecord.createtime)
    local endtime = CurrentRecord.endtime or "(活动尚未结束)"
    self.EndTimeLabel:SetText("结束时间:".. endtime)
    self.AnnounceBox:SetText(DKP_Options["auto_announce"])
    self.AnnounceIntervalBox:SetNumber(DKP_Options["auto_announce_interval"])
end

function SwitchAutoAnnounce( checked )
    AutoAnnounce = checked and true or false
end

function AnnounceBox_OnTextChanged( self )
    DKP_Options["auto_announce"] = self:GetText()
end

function AnnounceIntervalBox_OnTextChanged( self )
    if self:GetNumber() == 0 then
        return
    end
    DKP_Options["auto_announce_interval"] = self:GetNumber()
end

function OverviewFrameSelectionDropDown_SetUp(self)
    UIDropDownMenu_Initialize(self, OverviewFrameSelectionDropDown_Initialize);
    if ( OverviewFrame.selected ) then
        UIDropDownMenu_SetSelectedValue(OverviewFrameSelectionDropDown, OverviewFrame.selected);
    end
    UIDropDownMenu_SetText(self, strsub(CurrentRecord.name,1,4))
end

function OverviewFrameSelectionDropDown_Initialize(self)
    local info = UIDropDownMenu_CreateInfo();
     
    local records = GetRawRecords()
    for i=1, #records do
        local r = records[i]
        info.text = r.name; --Note that the dropdown text may be manually changed in OverviewFrame_SetRaid
        info.value = r;
        info.isTitle = nil;
        info.func = function() OverviewFrameSelectionDropDownButton_OnClick(r) end
        info.disabled = nil;
        info.checked = (OverviewFrame.selected == info.value);
        info.tooltipWhileDisabled = nil;
        info.tooltipOnButton = nil;
        info.tooltipTitle = nil;
        info.tooltipText = nil;
        UIDropDownMenu_AddButton(info);        
    end
end
 
function OverviewFrameSelectionDropDownButton_OnClick(value)
    OverviewFrame.selected = value;
    CurrentRecord = RaidRecord:Read(value)
    UIDropDownMenu_SetSelectedValue(OverviewFrameSelectionDropDown, value);
    RaidInfo_OnShow(OverviewFrame.RaidInfo)
end

function SubFrame_OnShow( self )
    CurrentView = self:GetName()
    ScrollFrameInit(self)
end

function ScrollFrameInit( view )
    local scrollFrame = view["Container"]
    scrollFrame.ScrollBar.doNotHide = true
    HybridScrollFrame_CreateButtons(scrollFrame, "RaidRosterButtonTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, -SCROLLFRAME_BUTTON_OFFSET, "TOP", "BOTTOM")
    scrollFrame.update = function ()
        ScrollFrameUpdate(scrollFrame)
    end

    -- update column headers
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
            button.sort = data.sort
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
        btn:Hide()
        btn.barTexture:Hide()
    end
    scrollFrame.update()
end

function GetInfoCount( view )
    if view == "MemberFrame" then
        return #(CurrentRecord.members)
    elseif view == "ItemFrame" then
        return #(CurrentRecord.loots)
    elseif view == "EventFrame" then
        return #(CurrentRecord.events)
    else
        return 0
    end
end

function ScrollFrameUpdate( scrollFrame )
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local buttons = scrollFrame.buttons
    local count = GetInfoCount(CurrentView)
    for i=1,#buttons do
        local btn = buttons[i]
        btn.id = i+offset
        if i + offset > count then
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
                btn.string2:SetText(time)
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
    self.sort()
    _G[CurrentView].Container.update()
end

function GetRosterInfo( index )
    local mem = CurrentRecord.members[index]
    local curr = CurrentRecord:Lookup(mem.name)
    return mem.name,lang_convert[string.upper(mem.class)] or mem.class,curr,GetFactor(curr)
end

function GetEventInfo( index )
    local e = CurrentRecord.events[index]
    return e.name ,string.sub(e.ctime[1],6) , e.point
end

function GetLootInfo( index )
    local l = CurrentRecord.loots[index]
    return l.name , CurrentRecord.members[l.player].name ,l.point    
end

function GetMembers()
    local members = {}
    for i,v in ipairs(CurrentRecord.members) do
        local entity = shallowcopy(v)
        entity.dkp = CurrentRecord:Lookup(entity.name)
        -- entity.id = CurrentRecord:GetMemberId(i)
        members[i] = entity
    end
    return members
end

function GetAllClasses()
    return {
            { name =   "猎人",  checked = false },
            { name =   "战士",  checked = false },
            { name =   "萨满",  checked = false },
            { name =   "武僧",  checked = false },
            { name =   "盗贼",  checked = false },
            { name =   "法师",  checked = false },
            { name =   "小德",  checked = false },
            { name =   "死骑",  checked = false },
            { name =   "圣骑",  checked = false },
            { name =   "牧师",  checked = false },
            { name =   "术士",  checked = false }
            }
end

function NewEvent(self,modifyData)
    if CurrentView == "MemberFrame" and IsModify then
        self:SetText("暂不支持")
        return
    elseif CurrentRecord.name == "选择" then
        print("请选择活动")
        return
    end

    local scrollFrame = NewFrame.Container
    scrollFrame.ScrollBar.doNotHide = true


    NewFrame.name:SetText("")
    if CurrentView == "MemberFrame" then
        NewFrame.point:Hide()
    else
        NewFrame.point:Show()
        NewFrame.point:SetNumber(0)
    end
    scrollFrame.data = CurrentView ~= "MemberFrame" and GetMembers() or GetAllClasses()

    if IsModify then
        NewFrame.id = modifyData.id
        NewFrame.name:SetText(modifyData.name)
        NewFrame.point:SetNumber(modifyData.point)
        for k,v in pairs(scrollFrame.data) do
            if modifyData.player then                       
                v.checked = v.id == modifyData.player
            else
                v.checked = tContains(modifyData.players,v.id)
            end
        end
    end

    if CurrentView == "EventFrame" then
        NewFrame.selectall:Show()
        NewFrame.selectraid:Show()
        NewFrame.selectonline:Show()
        NewFrame.selectinverse:Show()
    else
        NewFrame.selectall:Hide()
        NewFrame.selectraid:Hide()
        NewFrame.selectonline:Hide()
        NewFrame.selectinverse:Hide()
    end

    HybridScrollFrame_CreateButtons(scrollFrame, "NewEventButtonTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, -SCROLLFRAME_BUTTON_OFFSET, "TOP", "BOTTOM")
    
    scrollFrame.update = function ()
        local offset = HybridScrollFrame_GetOffset(scrollFrame)
        local buttons = scrollFrame.buttons
        local data = scrollFrame.data
        local count = #data
        for i=1,#buttons do
            local btn = buttons[i]

            if i + offset > count then
                btn:Hide()
            else
                local entity= data[i+offset]
                btn.data = entity
                btn.checkButton:SetChecked(entity.checked)
                btn.string1:SetText(entity.name) 
                if CurrentView ~= "MemberFrame" then
                    btn.string2:SetText(entity.dkp) -- dkp
                    btn.string3:SetText(UnitIsConnected(entity.name) and "在线" or "离线") -- online / offline
                else
                    btn.string2:SetText("")
                    btn.string3:SetText("")
                end
                btn:Show()
            end
        end

        local totalHeight = count * (20 + 2)
        local displayedHeight = #buttons * (20 + 2)
        HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)
    end
    scrollFrame.update()

    _G[CurrentView]:Hide()
    NewFrame:Show()
end

function BackToCurrentView()
    -- I use a copy of data,thus it's unnecessary to revert
    --RevertChange()
    NewFrame:Hide()
    _G[CurrentView]:Show()
end

function RevertChange()
    local data = NewFrame.Container.data
    for i=1,#data do
        data[i].checked = nil
    end
end

IsModify = false

function NewEvent_Submit(  )
    -- process new event
    local name = NewFrame.name:GetText()
    if name == "" then
         return
     end
    local point = NewFrame.point:GetNumber()
    local data = NewFrame.Container.data

    --convert data to useful info
    local players = {}
    local selectedClass  = nil
    if CurrentView ~= "MemberFrame" then
        for i=1,#data do
            if data[i].checked then
                table.insert(players,data[i].id)
            end
        end
    else
        for i=1,#data do
            if data[i].checked then
                selectedClass = data[i].name
                break
            end
        end
        if not selectedClass then
            return
        end
    end


    if IsModify then
        IsModify = false
        local modifyData = nil
        if CurrentView == "EventFrame" then
            modifyData = CurrentRecord.events[NewFrame.id]      
            modifyData.name = name
            modifyData.point = point
            modifyData.players = players
        elseif CurrentView == "ItemFrame" then
            modifyData = CurrentRecord.loots[NewFrame.id]      
            modifyData.name = name
            modifyData.point = point
            modifyData.player = players[1]        
        end
        CurrentRecord:Modify(modifyData)
    else
        if CurrentView == "EventFrame" then
            CurrentRecord:AddEvent(name,players,point)
        elseif CurrentView == "ItemFrame" then
            CurrentRecord:Loot(name,players[1],point)
        elseif CurrentView == "MemberFrame" then
            CurrentRecord:AddMember(name,selectedClass)
        end
    end
    BackToCurrentView()
end

function ModifyItem( btn )
    if CurrentView == "MemberFrame" then
        return
    end
    IsModify = true
    NewEvent(nil,CurrentView=="ItemFrame" and CurrentRecord.loots[btn.id] or CurrentRecord.events[btn.id])
    --refresh data
    _G[CurrentView].Container.update()
end

function DeleteItem( btn )
    local typeMapping = {
        ["MemberFrame"] = TYPE_PLAYER,
        ["ItemFrame"] = TYPE_ITEM,
        ["EventFrame"] = TYPE_EVENT,
    }
    CurrentRecord:RemoveByName(Selected.id,typeMapping[CurrentView])
    --refresh data
    _G[CurrentView].Container.update()
end

function SelectItem( btn )
    if Selected then
        Selected:UnlockHighlight()
    end
    btn:LockHighlight()
    Selected = btn
end

function CreateNewRec( )
    CurrentRecord = RaidRecord:new()
    OverviewFrame.selected = CurrentRecord
    OverviewFrameSelectionDropDown_SetUp(OverviewFrameSelectionDropDown)
    RaidInfo_OnShow(OverviewFrame.RaidInfo)
end

function DeleteRec( )
    CurrentRecord:Delete()
    Save()
    CurrentRecord = DefaultRaidRecord()
    
    OverviewFrame.selected = CurrentRecord
    OverviewFrameSelectionDropDown_SetUp(OverviewFrameSelectionDropDown)
    RaidInfo_OnShow(OverviewFrame.RaidInfo)
end

-- event from OverviewFrameExportButton
-- finish current rec & export
function ExportRec()
    CurrentRecord:Finish()
    Save()
    RaidInfo_OnShow(OverviewFrame.RaidInfo)
end