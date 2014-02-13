--额外功能:自动邀请,自动喊话,发布拾取信息,自动拍卖物品并记录,DKP查询
-- SavedVariables: DKP_Options

CurrentRecord = nil

convert_table = {
	["Hunter"] = "Hunter",
	["Warrior"] = "Warrior",
	["Shaman"] = "Shaman",
	["Monk"] = "Monk",
	["Rogue"] = "Rogue",
	["Mage"] = "Mage",
	["Druid"] = "Druid",
	["Deathknight"] = "Deathknight",
	["Paladin"] = "Paladin",
	["Priest"] = "Priest",
	["Warlock"] = "Warlock",


	["猎人"]    ="Hunter",
	["战士"]    ="Warrior",
	["萨满"]    ="Shaman",
	["武僧"]    ="Monk" ,
	["盗贼"]    ="Rogue" ,
	["法师"]    ="Mage" ,
	["德鲁伊"]  ="Druid" ,
	["死亡骑士"]="Deathknight",
	["圣骑士"]  ="Paladin",
	["牧师"]    ="Priest",
	["术士"]    ="Warlock",

	["LR"]  ="Hunter",
	["ZS"]  ="Warrior",
	["SM"]  ="Shaman",
	["WS"]  ="Monk" ,
	["DZ"]  ="Rogue" ,
	["FS"]  ="Mage" ,
	["DLY"] ="Druid" ,
	["SWQS"]="Deathknight",
	["QS"]  ="Paladin",
	["MS"]  ="Priest",
	["SS"]  ="Warlock",


	["XD"] = "Druid",
	["DK"] = "Deathknight",

}

EventList = {
	["ADDON_LOADED"] = {OnAddonLoaded},
	["PLAYER_LOGOUT"] ={OnPlayerLogout},
	["CHAT_MSG_WHISPER"] = {ProcessDKPWhisper,ProcessAutoInvite},
	["GROUP_ROSTER_UPDATE"] = {OnRosterUpdate},
}

function OnEvent(  frame , event , arg1 , arg2 ,arg3 , arg4 ,arg5 ,arg6,arg7,arg8,arg9,arg10,arg11 , arg12 ,arg13 , arg14 ,arg15 ,arg16,arg17,arg18)	
	if EventList[event] then
		for _,e in pairs(EventList[event]) do
				e( frame , event , arg1 , arg2 ,arg3 , arg4 ,arg5 ,arg6,arg7,arg8,arg9,arg10,arg11 , arg12 ,arg13 , arg14 ,arg15 ,arg16,arg17,arg18)	
		end
	end
end

function RegisterEvent( event , callback )
	if not EventList[event] then
		EventList[event] = {}
		MyPointsFrame:RegisterEvent(event)
	end
	if not tContains(EventList[event],callback) then
		table.insert(EventList[event],callback)
	end
end

function UnregisterEvent( event , callback )
	local list = EventList[events]
	if list then
		for i=1,#list do
			if list[i] == callback then
				table.remove(list,i)
				return
			end
		end
	end
end

function CreateTimer( triggerFunc )
	local f =  CreateFrame("frame")
  	f:SetScript("OnUpdate",triggerFunc)
end

FilterMessageList = {}

function MessageFiliter( self, event, msg, author, ... )
	for i=1,#FilterMessageList do
		if FilterMessageList[i] == msg then
			table.remove(FilterMessageList,i)
			return true
		end
	end
	return StartsWith(msg, DKP_Options["whisper_command"]) and author == UnitName("player")
end

function SendWhisper( msg , target )
	SendChatMessage(msg,"WHISPER",nil,target)
	table.insert(FilterMessageList,msg)
end

function SendDetails( name )
	local NewLine = "\n"
	if not CurrentRecord then 
	end

	local player = CurrentRecord:GetDetails(name) --- wrong way!
	if not player then
		local dkp = CurrentRecord:GetPrevDKP(name)
		SendWhisper("您当前的DKP:" .. dkp .. "分",name)
		SendWhisper("当前系数为" .. GetFactor(dkp),name)
		return
	end
	SendWhisper("您当前可用的DKP:" .. CurrentRecord:Lookup(name) .. "分",name)
	SendWhisper("进团分数:" .. player.previous .."分，" .. "当前系数为:" .. player.factor,name)
	SendWhisper("本次活动总共获得" .. player.gain .. "分",name)
	local count = 1
	for id,e in pairs(player.events) do
		SendWhisper(count .. ":" ..e.name .. "--" .. e.point .."分" ,name)
		count = count + 1
	end
	SendWhisper("本次活动物品总共花费" ..player.cost .. "分",name)
	count = 1
	for id,item in pairs(player.loots) do
		SendWhisper( count .. ":" ..item.name .. "--" .. item.point .."分",name)
		count = count + 1
	end	
	SendWhisper("活动结束后,你的分数为:" .. player.previous - player.cost + player.gain * player.factor .."分",name)
end

function ProcessAutoInvite( frame , event , msg , sender )
	if  string.find(DKP_Options["auto_invite_command"],msg) then
		if GetNumGroupMembers() == 5 then
			ConvertToRaid()
		end
		InviteUnit(sender)
	end
end

function ProcessDKPWhisper( frame , event , msg , sender )
	if msg:upper()==DKP_Options["whisper_command"]:upper() then
			SendDetails(sender)
	elseif StartsWith(msg:upper(),DKP_Options["whisper_command"]:upper()) then
		local arg = string.gsub(msg:upper(), "%s+", "")
		local class = string.sub( arg,string.len(DKP_Options["whisper_command"])+1,string.len(arg))
		local players = CurrentRecord:GetPlayersByClass(convert_table[class])
		for i=1,#players do
			local name = players[i]
			SendWhisper(i .. ":" .. name .. "\t当前可用分数:" .. CurrentRecord:Lookup(name) .. "分",sender)
		end
	end
end

function OnLootingItems()
	-- publish the items
	local looted = false
	for slot=1,GetNumLootItems() do
		if GetLootSlotType(slot) == LOOT_SLOT_ITEM  then
			local link = GetLootSlotLink(slot)
			local _, _, quality, iLevel  = GetItemInfo(link)
			if quality >= DKP_Options["item_quality"] and iLevel >= DKP_Options["item_level"] then
				looted = true
				table.insert(CurrentRecord:GetLootItems(),link)
				if DKP_Options["auto_publish_loots"] then
					SendChatMessage(link,"RAID")
				end
			end
		end
	end

	if AuctionFrame:IsShown() then
		AuctionFrame_UpdateList()
	elseif DKP_Options["auto_open_auction"] or looted then
		AuctionFrame:Show()
	end
	-- and popup the auction frame
end

function OnRosterUpdate()
	-- welcome new member!
	-- or someone get online
	-- or...leave one
	for i=1,GetNumGroupMembers() do
		local name, rank, subgroup, level, class, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		if CurrentRecord:GetDetails(name) == nil then
			CurrentRecord:AddMember(name,class)
		end
	end
end

function OnRecordChanged( data , content_type , change_type )
    local strMaping = {
        ["MemberFrame"] = "玩家",
        ["ItemFrame"] = "物品拾取",
        ["EventFrame"] = "事件",        
    }

    Save()

	if content_type ~= TYPE_EVENT then
		return
	end

	if content_type == TYPE_EVENT then
		if change_type == CHANGE_TYPE_REMOVE then
	   		SendChatMessage("新增"..strMaping[CurrentView].."(".. data.name .."),分数为:"..data.point .. ",人数:"..#data.players,"RAID")
		else
	   		SendChatMessage(strMaping[CurrentView].."(".. data.name ..")更新,分数为:"..data.point .. ",人数:"..#data.players,"RAID")
	   	end
	end
end

function OnAddonLoaded()
	-- acquire the options
	-- or initialize data
    if not CurrentRecord then
        CurrentRecord = DefaultRaidRecord()
    end

    CurrentRecord:RegisterDataChangedEvent(OnRecordChanged)

	if not DKP_Options  then
		initialize()
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", MessageFiliter)
	RegisterEvent("LOOT_OPENED",OnLootingItems)
	-- if  IsInRaid() then
	-- 	for i=1,GetNumGroupMembers() do
	-- 		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
	-- 		if CurrentRecord:GetDetails(name) == nil then
	-- 			CurrentRecord:AddMember(name,convert_table[class])
	-- 		end
	-- 	end
	-- end
end

function OnPlayerLogout()
	-- save the variable
	if CurrentRecord:IsClose() then
		CurrentRecord:Finish()
	end
	Save()
end

function Save( )
	local new = {}
	MiDKP3_Config = DeepCopy(MiDKP3_Config,new)
end

function GetFactor( dkp )
	for i,v in pairs(DKP_Options["dkp_factors"]) do
		if dkp > v["gt"] and dkp <= v["le"] then
			return v["factor"]
		end
	end
	print(dkp .. " is outrange")
	return 1
end





function initialize()
	DKP_Options = {
		["ignore"] =  {
			"狮眼石", -- [1]
			"影歌紫玉", -- [2]
			"天蓝宝石", -- [3]
			"赤尖石", -- [4]
			"海浪翡翠", -- [5]
			"焚石", -- [6]
			"黑暗之心", -- [7]
			"太阳之尘", -- [8]
			"连结水晶", -- [9]
			"大块棱光碎片", -- [10]
			"小块棱光碎片", -- [11]
			"虚空水晶", -- [12]
			"瓦解法杖", -- [13]
			"灵弦长弓", -- [14]
			"无尽之刃", -- [15]
			"相位壁垒", -- [16]
			"虚空尖刺", -- [17]
			"宇宙灌注者", -- [18]
			"迁跃切割者", -- [19]
			"毁灭", -- [20]
			"深渊水晶", -- [21]
			"恐惧石", -- [22]
			"祖尔之眼", -- [23]
			"紫黄晶", -- [24]
			"赤玉石", -- [25]
			"王者琥珀", -- [26]
			"巨锆石", -- [27]
			"梦境碎片", -- [28]
			"漩涡水晶", -- [29]
			"天界碎片", -- [30]
			"暗烬黄玉", -- [31]
			"梦境翡翠", -- [32]
			"恶魔之眼", -- [33]
			"琥珀晶石", -- [34]
			"海洋青玉", -- [35]
			"地狱炎石", -- [36]
			"力量印记", -- [37]
			"智慧印记", -- [38]
			"帝国秘史", -- [39]
			"邪煞水晶",
			"泰坦符文石"
		},
		["item_level"] = 551,
		["item_quality"] = 3,
		["item_auction_timelimit"] = -1,
		["item_auction_countdown_after_slience"] = 30 , -- count down after 10-second-silence


		["hide_whisper_reply"] = true,		
		["whisper_command"] = "dkp",
		["whisper_enable"] = true,
		["whisper_content"] = {
			true, -- [1]
			true, -- [2]
			true, -- [3]
		},
		["announce_data_changed"] = true,
		["announce_to_channel"] = 1,
		["use_history"] = true,
		["auto_invite_command"] = "1,组,",
		["auto_announce"] = "开组啦开组啦,密我1进组",
		["auto_announce_interval"] = 180,
		["auto_publish_loots"] = true,
		["auto_open_auction"] = true,
		["dkp_factors"] ={
			{
				["gt"] = -1000,
				["le"] = 300,
				["factor"] = 2
			},

			{
				["gt"] = 300,
				["le"] = 500,
				["factor"] = 1
			},

			{
				["gt"] = 500,
				["le"] = 700,
				["factor"] = 0.5
			},

			{
				["gt"] = 700,
				["le"] = 100000,
				["factor"] = 0.1
			}
		}
	}
end