ENT.Type = "point"
ENT.Base = "base_point"

ENT.BaseHullHealth = 1
ENT.Rooms = nil
ENT._roomlist = nil
ENT.Doors = nil

ENT.Bounds = nil

ENT._players = nil

function ENT:KeyValue(key, value)
	if key == "hullhealth" then
		self.BaseHullHealth = tonumber(value)
	end
end

function ENT:Initialize()
	self.Rooms = {}
	self._roomlist = {}
	self.Doors = {}
	self.Bounds = Bounds()
	self._players = {}
end

function ENT:InitPostEntity()
	ships.Add(self)
end

function ENT:AddRoom(room)
	local name = room:GetName()
	if not name then return end

	self.Rooms[name] = room
	table.insert(self._roomlist, room)
	self.Bounds:AddBounds(room.Bounds)
	
	room.Index = #self._roomlist
end

function ENT:GetRooms()
	return self._roomlist
end

function ENT:GetRoomByIndex(index)
	return self._roomlist[index]
end

function ENT:AddDoor(door)
	if not table.HasValue(self.Doors, door) then
		table.insert(self.Doors, door)
		door.Index = #self.Doors
	end
end

util.AddNetworkString("InitShipData")
util.AddNetworkString("ShipStateUpdate")

function ENT:SendInitShipData(ply)
	net.Start("InitShipData")
		net.WriteString(self:GetName())
		net.WriteInt(table.Count(self.Rooms), 8)
		
		for name, room in pairs(self.Rooms) do
		
			net.WriteString(name)
			net.WriteInt(room.Index, 8)
			if room.System then
				net.WriteString(room.System.Name)
			else
				net.WriteString("")
			end
			net.WriteInt(table.Count(room.Corners), 8)
			for i, v in pairs(room.Corners) do
				net.WriteInt(i, 8)
				net.WriteFloat(v.x)
				net.WriteFloat(v.y)
			end
		end
		
		net.WriteInt(#self.Doors, 8)
		for _, door in ipairs(self.Doors) do
			local pos = door:GetPos()
			net.WriteFloat(pos.x)
			net.WriteFloat(pos.y)
			net.WriteFloat(door:GetAngles().y)
			net.WriteInt(door.Rooms[1].Index, 8)
			net.WriteInt(door.Rooms[2].Index, 8)
		end
	net.Send(ply)
end

local function IsDifferent(valA, valB, err)
	err = err or 0.001
	local diff = math.abs((valA - valB) / valA)
	return diff > err
end

function ENT:SendShipRoomStates(ply)
	local name = self:GetName()

	ply.ShipCaches = ply.ShipCaches or {}
	ply.ShipCaches[name] = ply.ShipCaches[name] or {}
	
	local shipCache = ply.ShipCaches[name]
	local send = false

	net.Start("ShipStateUpdate")
		net.WriteString(self:GetName())
		net.WriteFloat(CurTime())
		
		shipCache.Rooms = shipCache.Rooms or {}
		local roomCache = shipCache.Rooms
		for index, room in ipairs(self._roomlist) do
			shipCache[index] = shipCache[index] or { temp = 0, atmo = 0, shld = 0 }
			local cache = shipCache[index]
			local temp = room:GetTemperature()
			local atmo = room:GetAtmosphere()
			local shld = room:GetShields()
			
			if IsDifferent(cache.temp, temp) or
				IsDifferent(cache.atmo, atmo) or
				IsDifferent(cache.shld, shld) then
				
				net.WriteInt(index, 8)
				net.WriteFloat(room:GetTemperature())
				net.WriteFloat(room:GetAtmosphere())
				net.WriteFloat(room:GetShields())
				
				cache.temp = temp
				cache.atmo = atmo
				cache.shld = shld
				
				send = true
			end
		end
		net.WriteInt(0, 8)
		
		shipCache.Doors = shipCache.Doors or {}
		local doorCache = shipCache.Doors
		for index, door in ipairs(self.Doors) do
			local flags = 0
			if door:IsOpen() then flags = flags + 1 end
			if door:IsLocked() then flags = flags + 2 end
			if doorCache[index] ~= flags then
				net.WriteInt(index, 8)
				net.WriteInt(flags, 8)
				doorCache[index] = flags
				send = true
			end
		end
		net.WriteInt(0, 8)
	if send then net.Send(ply) end
end

local ply_mt = FindMetaTable("Player")
function ply_mt:SetShip(ship)
	if self._ship == ship then return end
	if self._ship then
		--print(self:Nick() .. " is leaving " .. self._ship:GetName())
		self._ship:_removePlayer(self)
	end
	--print(self:Nick() .. " is boarding " .. ship:GetName())
	ship:_addPlayer(self)
	self._ship = ship
	self:SetNWString("ship", ship:GetName())
end

function ply_mt:GetShip()
	return self._ship
end

function ENT:_addPlayer(ply)
	if not table.HasValue(self._players, ply) then
		table.insert(self._players, ply)
	end
end

function ENT:_removePlayer(ply)
	if table.HasValue(self._players, ply) then
		table.remove(self._players, table.KeyFromValue(self._players, ply))
	end
end

function ENT:IsPointInside(x, y)
	return self.Bounds:IsPointInside(x, y)
end
