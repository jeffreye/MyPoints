--额外功能:自动邀请,自动喊话,发布拾取信息,自动拍卖物品并记录,DKP查询
-- SavedVariables: DKP_Options

CurrentRecord = nil
Auctioning = false

local robot_flag = "天国的基器人:"
local last_bid = 0 -- time
local countdown = -1

local convert_table = {
	["猎人"] = "猎人",
	["战士"] = "战士",
	["萨满"] = "萨满",
	["武僧"] = "武僧",
	["盗贼"] = "盗贼",
	["法师"] = "法师",
	["德鲁伊"] = "德鲁伊",
	["死亡骑士"] = "死亡骑士",
	["圣骑士"] = "圣骑士",
	["牧师"] = "牧师",
	["术士"] = "术士",

	["LR"] = "猎人",
	["ZS"] = "战士",
	["SM"] = "萨满",
	["WS"] = "武僧",
	["DZ"] = "盗贼",
	["FS"] = "法师",
	["DLY"] = "德鲁伊",
	["SWQS"] = "死亡骑士",
	["QS"] = "圣骑士",
	["MS"] = "牧师",
	["SS"] = "术士",


	["XD"] = "德鲁伊",
	["DK"] = "死亡骑士",

}

function OnEvent( self , event , arg1 , arg2 )
		print(event)
	if event == "CHAT_MSG_WHISPER" then
		-- auto invite or lookup the dkp
		if  (not IsInGroup(LE_PARTY_CATEGORY_HOME) or UnitIsGroupLeader("player")) and string.find(DKP_Options["auto_invite_command"],arg1) then
			if GetNumGroupMembers() == 5 then
				ConvertToRaid()
			end
			InviteUnit(arg2)
		elseif arg1:upper()==DKP_Options["whisper_command"]:upper() then
			SendChatMessage(GetRecordByName(arg2),"WHISPER",nil,arg2)
		elseif StartsWith(arg1:upper(),DKP_Options["whisper_command"]:upper()) then
			local class = string.sub(arg1:upper(),string.len(DKP_Options["whisper_command"])+1,string.len(arg1))
			local players = CurrentRecord:GetPlayersByClass(convert_table[class])
			for i=1,#players do
				local name = players[i]
				SendChatMessage(i .. ":" .. name .. "\t当前可用分数:" .. CurrentRecord:Lookup(name) .. "分","WHISPER",nil,arg2)
			end
		end
	elseif event == "CHAT_MSG_OFFICER" then
		-- item auction
		if Auctioning then
			VerifyBid(arg1,arg2)
		end
	elseif event == "LOOT_OPENED" then
		-- publish the items
		if DKP_Options["auto_publish_loots"] then
			for slot=1,GetNumLootItems() do
				SendChatMessage(GetLootSlotLink(slot),"RAID")
			end
		end

		-- and popup the auction frame
	elseif event == "RAID_ROSTER_UPDATE" then
		-- welcome new member!
		-- or...leave one
		for i=1,GetNumGroupMembers() do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(index)
			if CurrentRecord:GetDetails(name) == nil then
				CurrentRecord:AddMember(name,class)
			end
		end
	elseif event == "ADDON_LOADED" then
		if not DKP_Options  then
			initialize()
		end

		self:RegisterEvent("CHAT_MSG_WHISPER",OnEvent)
		-- acquire the options
		-- or initialize data
	elseif event == "PLAYER_LOGOUT" then
		-- save the variable
		self:UnregisterEvent("CHAT_MSG_WHISPER",OnEvent)
	end
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
		["item_auction_countdown_after_slience"] = 10 , -- count down after 10-second-silence


		["hide_whisper_reply"] = true,		
		["whisper_command"] = "dkp",
		["whisper_enable"] = true,
		["whisper_content"] = {
			true, -- [1]
			true, -- [2]
			true, -- [3]
		},
		["announce_to_channel"] = 1,
		["use_history"] = false,
		["auto_invite_command"] = "1,组,",
		["auto_announce"] = "开组啦开组啦,密我1进组",
		["auto_publish_loots"] = true,
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

function StartNewRecording(name,frame)
	CurrentRecord = RaidRecord:new(name,DKP_Options["use_history"])

	--frame.RegisterEvent("CHAT_MSG_WHISPER",OnEvent)
	--frame.RegisterEvent("CHAT_MSG_OFFICER",OnEvent)
	frame.RegisterEvent("RAID_ROSTER_UPDATE",OnEvent)
	if DKP_Options["auto_publish_loots"] then
		frame.RegisterEvent("LOOT_OPENED",OnEvent)
	end

	DKP_Data[#DKP_Data] = CurrentRecord
end

function FinishRecording(frame)

	--frame.UnregisterEvent("CHAT_MSG_WHISPER")
	--frame.UnregisterEvent("CHAT_MSG_OFFICER")
	frame.UnregisterEvent("RAID_ROSTER_UPDATE")
	if DKP_Options["auto_publish_loots"] then
		frame.UnregisterEvent("LOOT_OPENED")
	end
	-- set the export xml

	CurrentRecord = nil
end

function StartsWith( str , other )
	if string.sub (str,1, string.len (other))==other then
		return
	end
end

function VerifyBid( message , sender )
	if  StartsWith(message,robot_flag) then
		return
	end

	if string.match(message,"%d") then
		local bid = tonumber(message)
		if CurrentRecord:Lookup(sender) > bid then
			SendChatMessage(robot_flag.."亲,好像你的分数不够喔~","OFFICER")
		elseif bid <= 0 then
			SendChatMessage(robot_flag.."这么点分就想拿东西,太天真了~","OFFICER")
		else
			last_bid = time()
		end
	else 
		SendChatMessage(robot_flag.."你真的是在出分吗?别闹~","OFFICER")
	end
end

function GetRecordByName( name )
	local player = CurrentRecord:GetDetails(name) --- wrong way!
	local NewLine = "\n"
	local overview = "您当前可用的DKP:" .. CurrentRecord:Lookup(name) .. "分" .. NewLine
	local last = "进团分数:" .. player.previous .."分，" .. "当前系数为:" .. player.factor
	local events = "本次活动总共获得" .. player.gain .. "分" .. NewLine
	local count = 1
	for id,e in pairs(player.events) do
		events = events .. count .. ":" ..e.name .. "--" .. e.point .."分" .. NewLine
		count = count + 1
	end
	local items = "本次活动物品总共花费" ..player.cost .. "分" .. NewLine
	for id,item in pairs(player.loots) do
		items = items .. count .. ":" ..item.name .. "--" .. item.point .."分" .. NewLine
		count = count + 1
	end	
	local total = "活动结束后,你的分数为:" .. player.previous - player.cost + player.gain * player.factor .."分"
	return overview .. last .. events ..items .. total
end

function LootAllItems()
	for slot=1,GetNumLootItems() do
		LootSlot(slot)
	end
end

function StartAuctioning(frame)
	Auctioning = true
	frame.RegisterEvent("CHAT_MSG_OFFICER",OnEvent)
	-- register time callbacks
end

function AuctioningTimerCallback()
	if countdown == 0 then
		SendChatMessage("禁止出分","OFFICER")
		countdown = countdown - 1
	elseif countdown ~= -1 then
		SendChatMessage(tostring(countdown),"OFFICER")
		countdown = countdown - 1
	end

	local delta = time() - last_bid
	if delta >= DKP_Options["item_auction_countdown_after_slience"] then
		SendChatMessage("无人出分,开始倒数","OFFICER")
		countdown = 5
	else 
		countdown = -1
	end
end

function FinishAuctioning( frame )
	Auctioning = false
	frame.UnregisterEvent("CHAT_MSG_OFFICER")
end