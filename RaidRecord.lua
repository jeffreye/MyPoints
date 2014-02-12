--Features:
--核心功能:自动事件记录,进团/离团记录,物品拾取记录

--here is the model

RaidRecord = {}

TYPE_PLAYER = "Member"
TYPE_ITEM = "Item"
TYPE_EVENT = "Event"

CHANGE_TYPE_MODIFY = "MODIFY"
CHANGE_TYPE_REMOVE ="REMOVE"
CHANGE_TYPE_ADD = "ADD"

function CurrentTime()
	return { date("%Y.%m.%d %H:%M"),time() }--DO NOT USE 2nd element,it's a fake value
end

function DefaultRaidRecord()
	for k,v in pairs(GetRawRecords()) do
		if not v.endTime then -- it's current record
			return RaidRecord:Read(v)
		end
	end

	-- create a default record that contains all members
	local record = RaidRecord:Default()	
	for name,v in pairs(MiDKPData["dkp"][1]["members"]) do
		record:AddMember(name,v["class"])
	end
	return record
end

function GetRawRecords()
	local list = {}
	for k,v in pairs(MiDKP3_Config["raids"]) do
		v.id = k
		table.insert(list,v)
	end
	return list
end

function RaidRecord:Default()
	local record_name = ""
	local dkp_name = MiDKPData["dkp"][1]["name"]
	local obj={ name=record_name ,createtime = CurrentTime()[1] ,endtime = nil , members={} , events={} , loots={} , gain = {} , cost ={},
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

	local obj={ name=dkpData["name"] ,createtime = dkpData["ctime"][1], members={} , events={} , loots={} , gain = {} , cost ={}, saveVar = dkpData }
	if dkpData["endTime"] then
		obj.endtime = dkpData["endTime"][1]
	else
		obj.endtime = nil
	end

	self.__index=self
	local record=setmetatable(obj,self)


	local indexedPlayers = {}

	for k,v in pairs(dkpData["entities"]) do		
		if v["type"] == TYPE_PLAYER then
			v.id = FindOrAdd(indexedPlayers,v.id or k)
			record.members[v.id]=v
			record.gain[v.id] = 0
			record.cost[v.id] = 0
		elseif v["type"] == TYPE_EVENT then
			table.insert(record.events,v)
			v.id = #record.events
		elseif v["type"] == TYPE_ITEM then
			table.insert(record.loots,v)
			v.id = #record.loots
		end
		v.entityId = k
	end

	obj.idTable = indexedPlayers

	-- refresh gain,cost
	for _,e in pairs(record.events) do
		for i,v in pairs(e.players) do
			v = FindOrAdd(indexedPlayers,v)
			e["players"][i] = v
			record.gain[v] = record.gain[v] + e.point
		end
	end

	for _,e in pairs(record.loots) do
		p = FindOrAdd(indexedPlayers,e.player)
		e["player"] = p
		record.cost[p] = record.cost[p] + e.point
	end

	return record
end

function RaidRecord:new( record_name , dkp_name )
	if record_name == "" then
		print("error:record_name cannot be empty")
		return
	end
	local saveVar = {
	 		["id"] =  MiDKP.OO.Entity:GenerateID(),
			["name"] = record_name or "团队活动" .. CurrentTime()[1],
			["dkp"] = dkp_name or MiDKPData["dkp"][1]["name"],
			["ctime"] = CurrentTime(),
			["startTime"] = CurrentTime(),
			["creator"] = UnitName("player"),
			["active"] = false,
			["status"] = 1,
			["zones"] = {},
			["entities"] = {}
		} 

	MiDKP3_Config["raids"][saveVar.id] = saveVar -- update the var on account's profile
	return RaidRecord:Read(saveVar)
end

function RaidRecord:Delete()
	MiDKP3_Config["raids"][self.saveVar.id] = nil
end

function RaidRecord:IsDefault()
	return self.name == ""
end

function RaidRecord:IsClose()
	return self.endtime
end

--the id in saveVar (Backward compatibility)
function RaidRecord:GetMemberId( index )
	return self.idTable[index] or index
end

-- only support add/remove event
function RaidRecord:RegisterDataChangedEvent( callback )
	DataChangedEvent = callback
end

function RaidRecord:RaiseDataChangedEvent(data,type,change_type)
	if DataChangedEvent then
		DataChangedEvent(data,type,change_type)
	end
end

function RaidRecord:UnregisterDataChangedEvent(  )
	DataChangedEvent = nil
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
	member["id"] = #self.members
	member.entityId = #self.saveVar["entities"]

	self.gain[member["id"]] = 0
	self.cost[member["id"]] = 0

	self:RaiseDataChangedEvent(member,TYPE_PLAYER,CHANGE_TYPE_ADD)

	return member
end

function RaidRecord:AddEvent( eventName , playerList , eventPoint )
	--update members' gain point
	for k,v in pairs(playerList) do
		self.gain[v] = self.gain[v] + eventPoint
		playerList[k] = self:GetMemberId(v)
	end

	local event = {
		["players"] = playerList,
		["type"] = TYPE_EVENT,
		["point"] = eventPoint,
		["ctime"] = CurrentTime(),
		["name"] = eventName,
	}
	table.insert(self.events,event)
	table.insert(self.saveVar.entities,event)
	event.id = #self.events
	event.entityId = #self.saveVar.entities

	self:RaiseDataChangedEvent(event,TYPE_EVENT,CHANGE_TYPE_ADD)
	return event
end

function RaidRecord:Loot( itemName , looter ,eventPoint)
	local item =  {
		["type"] = TYPE_ITEM,
		["point"] = eventPoint,
		["ctime"] = CurrentTime(),
		["player"] = self:GetMemberId(looter),
		["name"] = itemName,
	}
	table.insert(self.loots,item)
	table.insert(self.saveVar["entities"],item)
	item["id"] = #self.loots
	item.entityId = #self.saveVar["entities"]

	--update members' cost point
	self.cost[looter] = self.cost[looter] + eventPoint
	self:RaiseDataChangedEvent(item,TYPE_ITEM,CHANGE_TYPE_ADD)
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
			local player = shallowcopy(v)
			player.previous = self:GetPrevDKP(name)
			player.factor = GetFactor(player.previous)
			player.gain = self.gain[player.id]
			player.cost = self.cost[player.id]
			player.events = {}
			for k,v in pairs(self.events) do
				if tContains(v.players,player.id) then
					table.insert(player.events,v)
				end
			end
			player.loots = {}
			for k,v in pairs(self.loots) do
				if v.player == player.id then
					table.insert(player.loots,v)
				end
			end
			return player
		end
	end
	return nil
end

--- get avaliable dkp
function RaidRecord:Lookup( memberName )
	local prev = self:GetPrevDKP(memberName)
	local details = self:GetDetails(memberName)
	return prev - self.cost[details.id]
end

function RaidRecord:GetPrevDKP( memberName )
	if not MiDKPData then
		return 0
	end

	local m = nil
	for k,v in pairs(MiDKPData["dkp"]) do
		if v.name == self.saveVar.dkp then
			m = v.members
			break
		end
	end

	if not memberName or not m[memberName] then
		return 0
	end
	return m[memberName]["score"]
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

function RaidRecord:RemoveByName( index , content_type)
	local mapping = {
		[TYPE_ITEM] = self.loots,
		[TYPE_EVENT] = self.events,
		[TYPE_PLAYER] = self.members
	}
	local data = mapping[content_type][index]
	if data == nil then
		print("error:data not found")
		return
	end

	local key = data.entityId
	if type(key) == "number" then
		table.remove(self.saveVar["entities"],key)
	else
		self.saveVar["entities"][key] = nil
	end
	table.remove(mapping[content_type],index)
	self:RaiseDataChangedEvent(data,content_type,CHANGE_TYPE_REMOVE)
end

function RaidRecord:Finish()
	self.saveVar.status = 3 -- finish flag
	self.saveVar.endTime = CurrentTime()
	self.endtime = self.saveVar.endTime[1]

	--calculate extra points
	local dict = {}
	for _,v in pairs(self.members) do
		dict[v.id] = 0
	end

	-- remove extra events
	for i=#self.events,1,-1 do
	    if self.events[i].extra or StartsWith(self.events[i].name,"DKP额外增长") then
	        if type(self.events[i].entityId) == "number" then
	        	table.remove(self.saveVar.entities,self.events[i].entityId)
	        else
	        	self.saveVar.entities[self.events[i].entityId] = nil
	        end
	        table.remove(self.events, i)
	    end
	end

	for k,e in pairs(self.events) do
		if e.point > 0 then
			for _,playerId in pairs(e.players) do
				dict[playerId] = dict[playerId] + e.point 
			end
		end
	end

	for id,acquired in pairs(dict) do
		local prev = self:GetPrevDKP(self.members[id].name)
		local factor = GetFactor(prev)
		local event = {
			["players"] = { id },
			["type"] = TYPE_EVENT,
			["point"] = acquired*factor,
			["ctime"] = CurrentTime(),
			["name"] = "DKP额外增长（上次DKP分值："..prev.." ,系数："..factor.."）",
			["extra"] = true
		}
		table.insert(self.events,event)
		table.insert(self.saveVar["entities"],event)
		event.id = #self.events
		event.entityId = #self.saveVar.entities
	end

	-- export to xml
	MiDKP.OO.Raid:Load(self.saveVar.id):SaveAll()
end