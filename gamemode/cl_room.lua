local ROOM_UPDATE_FREQ = 1

local _mt = {}
_mt.__index = _mt
_mt._lastUpdate = 0

_mt._temperature = 0
_mt._oldTemp = 0
_mt._atmosphere = 0
_mt._oldAtmo = 0
_mt._shields = 0
_mt._oldShld = 0

function _mt:ReadFromNet()
	self.Name = net.ReadString()
	self.Index = net.ReadInt(8)
	self.System = sys.Create(net.ReadString(), self)
	
	local cornerCount = net.ReadInt(8)
	for cNum = 1, cornerCount do
		local index = net.ReadInt(8)
		local pos = { x = net.ReadFloat(), y = net.ReadFloat() }
		
		self.Corners[index] = pos
		self.Bounds:AddPoint(pos.x, pos.y)
	end
	
	self.ConvexPolys = FindConvexPolygons(self.Corners)
end

function _mt:GetName()
	return self.Name
end

function _mt:GetStatusLerp()
	return math.Clamp((CurTime() - self._lastUpdate) / ROOM_UPDATE_FREQ, 0, 1)
end

function _mt:GetTemperature()
	return self._oldTemp + (self._temperature - self._oldTemp) * self:GetStatusLerp()
end

function _mt:GetAtmosphere()
	return self._oldAtmo + (self._atmosphere - self._oldAtmo) * self:GetStatusLerp()
end

function _mt:GetShields()
	return self._oldShld + (self._shields - self._oldShld) * self:GetStatusLerp()
end

function _mt:GetPermissionsName()
	return "p_" .. self.Ship.Name .. "_" .. self.Index
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetPermission(room)
	return self:GetNWInt(room:GetPermissionsName(), 0)
end

function ply_mt:HasPermission(room, perm)
	return self:GetPermission(room) >= perm
end

function ply_mt:SetPermission(room, perm)
	self:SetNWInt(room:GetPermissionsName(), perm)
	net.Start("SetPermission")
		net.WriteString(room.Ship.Name)
		net.WriteInt(room.Index, 8)
		net.WriteEntity(self)
		net.WriteInt(perm, 8)
	net.SendToServer()
end

function ply_mt:HasDoorPermission(door)
	return self:HasPermission(door.Rooms[1], permission.ACCESS)
		or self:HasPermission(door.Rooms[2], permission.ACCESS)
end

function ply_mt:GetRoom()
	if not self:GetNWInt("room") then return nil end
	if not self:GetNWString("ship") then return nil end
	return self:GetShip():GetRoomByIndex(self:GetNWInt("room"))
end

function ply_mt:IsInRoom(room)
	if self:GetNWString("ship") == room.Ship.Name
		and self:GetNWInt("room") == room.Index then
		return true
	end
end

function Room(ship)
	local room = { Ship = ship }

	room.Bounds = Bounds()
	room.Doors = {}
	room.Corners = {}

	return setmetatable(room, _mt)
end
