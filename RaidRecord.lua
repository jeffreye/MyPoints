--Features:
--核心功能:自动事件记录,进团/离团记录,物品拾取记录

--here is the model

RaidRecord = {}

function CurrentTime()
	return date("%Y.%m.%d %H:%M")
end

function RaidRecord:new( record_name , calculateOnHistory )
	local obj={ name=record_name , members={} , events={id=0} , loots={id=0} , createtime =CurrentTime() }
	obj.calculateOnHistory = calculateOnHistory
	self._index=self
	return setmetatable(obj,self)
end

function RaidRecord:AddMember( memberName , className )
	local dkp = self.Lookup(memberName)
	local member = { name=memberName , content="player"  , previous = dkp , gain=0 , cost = 0 , class = className , entertime=CurrentTime() , events={},loots={}}
	self.members[memberName] = member
	return member
end

function RaidRecord:GetDetails( name )
	return self.members[name]
end

function GetPlayersByClass( calss )
	local result = {}
	for n,v in pairs(self.members) do
		if v.class == class then
			result[#result] = n
	end
	return result
end


function RaidRecord:Lookup( memberName )
	if self.members[memberName] ~= nil then
		local player = self.members[memberName]
		return self.calculateOnHistory and player.previous - player.cost or player.previous - player.cost + player.gain*player.factor
	else
		-- TODO:look up in the database
	end
end

function RaidRecord:AddEvent( eventName , playerList , eventPoint )
	local index =  tostring(self.events.id)
	self.events.id = self.events.id + 1
	local event = { id = index , name=eventName , content="event" , players=playerList ,point=eventPoint}
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
	end

end