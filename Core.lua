--额外功能:自动邀请,自动喊话,发布拾取信息,自动拍卖物品并记录,DKP查询
-- SavedVariables: DKP_Options

CurrentRecord = nil
LootItemList = {}

robot_flag = "~:"
last_bid = { looter = "无人" , bid = 0 , time = 0 } -- time

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

EventList = {}

function OnEvent( self , event , arg1 , arg2 , ... )
	if EventList[event] then
		for _,e in pairs(EventList[event]) do
			e(self,event,unpack(arg))	
		end
	end
end

function CreateTimer( triggerFunc )
    CreateFrame("frame"):SetScript("OnUpdate",triggerFunc)
end

FilterMessageList = {}

function MessageFiliter( self, event, msg, author, ... )
	for i=1,#FilterMessageList do
		if FilterMessageList[i] == msg then
			table.remove(FilterMessageList,i)
			return true
		end
	end
	return false
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
		local class = string.sub(msg:upper(),string.len(DKP_Options["whisper_command"])+1,string.len(msg))
		local players = CurrentRecord:GetPlayersByClass(convert_table[class])
		for i=1,#players do
			local name = players[i]
			SendWhisper(i .. ":" .. name .. "\t当前可用分数:" .. CurrentRecord:Lookup(name) .. "分",sender)
		end
	end
end

function OnLootingItems()
	-- publish the items
	if DKP_Options["auto_publish_loots"] then
		for slot=1,GetNumLootItems() do
			if GetLootSlotType(slot) == LOOT_SLOT_ITEM  then
				local link = GetLootSlotLink(slot)
				table.insert(LootItemList,link)
				SendChatMessage(link,"RAID")
			end
		end
	end

	AuctionFrame:Show()
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

function OnAddonLoaded()
	-- acquire the options
	-- or initialize data
    if not CurrentRecord then
        CurrentRecord = DefaultRaidRecord()
    end

	if not DKP_Options  then
		initialize()
	end
	self:RegisterEvent("CHAT_MSG_WHISPER",OnEvent)
	self:RegisterEvent("GROUP_ROSTER_UPDATE",OnEvent)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", MessageFiliter)
	if DKP_Options["auto_publish_loots"] then
		self:RegisterEvent("LOOT_OPENED",OnEvent)
	end
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
	print("remember to save options")
end

function VerifyBid( message , sender )
	if not Auctioning or StartsWith(message,robot_flag) then
		return
	end

	if string.match(message,"%d") then
		local bid = tonumber(message)
		if CurrentRecord:Lookup(sender) > bid then
			SendChatMessage(robot_flag.."亲,好像你的分数不够喔~","OFFICER")
		elseif bid <= 0 then
			SendChatMessage(robot_flag.."这么点分就想拿东西,太天真了~","OFFICER")
		else
			last_bid.looter = sender
			last_bid.bid = bid
			last_bid.time = time()
		end
	else 
		SendChatMessage(robot_flag.."你真的是在出分吗?别闹~","OFFICER")
	end
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
		["use_history"] = true,
		["auto_invite_command"] = "1,组,",
		["auto_announce"] = "开组啦开组啦,密我1进组",
		["auto_announce_interval"] = 180,
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