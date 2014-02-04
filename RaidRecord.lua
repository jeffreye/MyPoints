--Features:
--核心功能:自动事件记录,进团/离团记录,物品拾取记录

--here is the model

RaidRecord = {}

TYPE_PLAYER = "Member"
TYPE_ITEM = "Item"
TYPE_EVENT = "Event"

function CurrentTime()
	return { date("%Y.%m.%d %H:%M"),time() }--DO NOT USE 2nd element,it's a fake value
end

function DefaultRaidRecord()
	local record = RaidRecord:Default()	
	for name,v in pairs(MiDKPData["dkp"][1]["members"]) do
		record:AddMember(name,v["class"])
	end
	return record
end

function RaidRecord:Default()
	local record_name = "选择"
	local dkp_name = MiDKPData["dkp"][1]["name"]
	local obj={ name=record_name , members={} , events={} , loots={} , gain = {} , cost ={},
	 saveVar = {
			["name"] = record_name,
			["dkp"] = dkp_name,
			["ctime"] = CurrentTime(),
			["startTime"] = CurrentTime(),
			["entities"] = {}
		} 
	}

	self.__index=self
	setmetatable(obj,self)
	return obj
end

function FindOrAdd( t , element )
	for i,v in pairs(t) do
		if v == element then
			return i
		end
	end
	table.insert(t,element)
	return #t
end

function RaidRecord:Read( dkpData )

	local obj={ name=dkpData["name"] ,createtime = dkpData["ctime"], members={} , events={} , loots={} , gain = {} , cost ={}, saveVar = dkpData }

	self.__index=self
	local record=setmetatable(obj,self)


	local indexedPlayers = {}

	for k,v in pairs(dkpData["entities"]) do
		if v["type"] == TYPE_PLAYER then
			if type(k) ~= "number" then
				k = FindOrAdd(indexedPlayers,k)
			end
			record.members[k]=v
			record.gain[k] = 0
			record.cost[k] = 0
		elseif v["type"] == TYPE_EVENT then
			table.insert(record.events,v)
		elseif v["type"] == TYPE_ITEM then
			table.insert(record.loots,v)
		end
	end

	-- refresh gain,cost
	for _,e in pairs(record.events) do
		for i,v in pairs(e["players"]) do
			v = FindOrAdd(indexedPlayers,v)
			table[i] = v
			record.gain[v] = record.gain[v] + e["point"]
		end
	end

	for _,e in pairs(record.loots) do
		p = FindOrAdd(indexedPlayers,e["player"])
		e["player"] = p
		record.cost[p] = record.cost[p] + e["point"]
	end

	return record
end

function RaidRecord:new( record_name , dkp_name )
	local obj={ name=record_name , members={} , events={} , loots={} , gain = {} , cost ={},
	 saveVar = {
			["name"] = record_name,
			["dkp"] = dkp_name,
			["ctime"] = CurrentTime(),
			["startTime"] = CurrentTime(),
			["entities"] = {}
		} 
	}

	table.insert(MiDKP3_Config["raids"],obj.saveVar) -- update the var on account's profile
	self.__index=self
	setmetatable(obj,self)
	return obj
end

function RaidRecord:AddMember( memberName , className )
	local member = {
		["starttime"] = CurrentTime(),
		["type"] = TYPE_PLAYER,
		["name"] = memberName,
		["class"] = className
	}
	table.insert(self.members,member)
	table.insert(self.saveVar["entities"],member)
	member["id"] = #self.saveVar["entities"]

	self.gain[member["id"]] = 0
	self.cost[member["id"]] = 0
	return member
end

function RaidRecord:AddEvent( eventName , playerList , eventPoint )
	local event = {
		["players"] = playerList,
		["type"] = TYPE_EVENT,
		["point"] = eventPoint,
		["ctime"] = CurrentTime(),
		["name"] = eventName,
	}
	table.insert(self.events,event)
	table.insert(self.saveVar["entities"],event)
	event["id"] = #self.saveVar["entities"]

	--update members' gain point
	for _,v in pairs(playerList) do
		self.gain[v] = self.gain[v] + eventPoint
	end
	return event
end

function RaidRecord:Loot( itemName , looter ,eventPoint)
	local item =  {
		["type"] = TYPE_ITEM,
		["point"] = eventPoint,
		["ctime"] = CurrentTime(),
		["player"] = GetMemberId(looter),
		["name"] = itemName,
	}
	table.insert(self.loots,item)
	table.insert(self.saveVar["entities"],item)
	item["id"] = #self.saveVar["entities"]


	--update members' cost point

	for _,v in pairs(playerList) do
		self.cost[v] = self.cost[v] + eventPoint
	end
	return item
end

function RaidRecord:GetPlayersByClass( class )
	local result = {}
	for n,v in pairs(self.members) do
		if v.class == class then
			result[#result] = n
		end
	end
	return result
end

function RaidRecord:GetDetails( name )
	for n,v in pairs(self.members) do
		if v.name == name then
			return v
		end
	end
	return nil
end

function RaidRecord:Lookup( memberName )
	if self.members[memberName] then
		local player = self.members[memberName]
		return self.calculateOnHistory and player.previous - player.cost or player.previous - player.cost + player.gain*player.factor
	else
		-- TODO:look up in the database
		return Lookup(1,memberName)
	end
end

function Lookup( index , member )
	if not MiDKPData then
		return 0
	end
	if not MiDKPData["dkp"][index] then
		return 0
	end

	local members = MiDKPData["dkp"][index]["members"]
	if not members or not members[member] then
		return 0
	end
	return members[member]["score"]
end

function RaidRecord:Remove( entity )
	if entity.content == TYPE_PLAYER then
		self.members[entity.name] = nil
	elseif entity.content == TYPE_EVENT then
		self.events[entity.id] = nil
	elseif entity.content == TYPE_ITEM then
		self.loots[entity.id] = nil
	end
	self.saveVar["entities"][entity["id"]] = nil
end

function GetRecords()
	local list = {}
	for k,v in pairs(MiDKP3_Config["raids"]) do
		table.insert(list,v)
	end
	return list
end