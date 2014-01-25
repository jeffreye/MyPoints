--Features:
--核心功能:自动事件记录,进团/离团记录,物品拾取记录

--here is the model

RaidRecord = {}

function CurrentTime()
	return date("%Y.%m.%d %H:%M")
end

function RaidRecord:new( record_name , calculateOnHistory )
	local obj={ name=record_name , members={count=0} , events={id=0} , loots={id=0} , createtime =CurrentTime() }
	obj.calculateOnHistory = calculateOnHistory
	self.__index=self
	setmetatable(obj,self)
	return obj
end
function RaidRecord:AddMember( memberName , className )
	local dkp = self:Lookup(memberName)
	local member = { 	name=memberName , content="player"  , previous = dkp , gain=0 , cost = 0 , 	class = className , entertime=CurrentTime() , events={},loots={},factor = GetFactor(dkp)}
	self.members[memberName] = member
	self.members.count = self.members.count + 1
	self.members[self.members.count] = member
	return member
end

function DefaultRaidRecord()
	local record = RaidRecord:new("global" , true)
	for name,v in pairs(MiDKPData["dkp"][1]["members"]) do
		record:AddMember(name,v["class"])
	end
	return record
end


function RaidRecord:GetDetails( name )
	return self.members[name]
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

function RaidRecord:AddEvent( eventName , playerList , eventPoint )
	local index =  tostring(self.events.id)
	self.events.id = self.events.id + 1
	local event = { id = index , name=eventName , content="event" , players=playerList ,point=eventPoint , time= CurrentTime()}
	self.events[index] = event
	if self.calculateOnHistory then
		for i=1,#playerList do
			playerList[i].gain = playerList[i].gain + eventPoint
			playerList[i].events[index]=event
		end
	end
	return event
end

function RaidRecord:Loot( itemName , looter ,cost)
	local index =  tostring(self.loots.id)
	self.loots.id = self.loots.id + 1
	local item = { id = index , name=itemName, content="item" , player=looter, point=cost}
	looter.cost =looter.cost +cost
	looter.loots[id] =item
	self.loots[id] = item
	return item
end

function RaidRecord:Remove( entity )
	if entity.content == "player" then
		self.members[entity.name] = nil
	elseif entity.content == "event" then
		self.events[entity.id] = nil
	elseif entity.content == "item" then
		self.loots[entity.id] = nil
	else
		-- do what?
		return
	end

end

function GetFactor( dkp )
	for i,v in ipairs(DKP_Options["dkp_factors"]) do
		if dkp > v["gt"] and dkp <= v["le"] then
			return v["factor"]
		end
	end
	print(dkp .. " is outrange")
	return 1
end