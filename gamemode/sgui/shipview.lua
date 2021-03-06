local BASE = "container"

GUI.BaseName = BASE

GUI._ship = nil

GUI._rooms = nil
GUI._doors = nil

function GUI:GetCurrentShip()
	return self._ship
end

function GUI:SetCurrentShip(ship)
	if self._ship == ship then return end

	self._ship = ship

	print(ship:GetName())

	if not ship then
		self:RemoveAllChildren()

		self._rooms = nil
		self._doors = nil
	else
		print(ship:GetName())
		self._doors = {}
		for _, door in ipairs(ship.Doors) do
			local doorview = sgui.Create(self, "doorview")
			doorview:SetCurrentDoor(door)
			self._doors[door] = doorview
		end

		self._rooms = {}
		for _, room in ipairs(ship:GetRooms()) do
			local roomview = sgui.Create(self, "roomview")
			roomview:SetCurrentRoom(room)
			self._rooms[room] = roomview
		end

		if CLIENT then
			self:FindTransform()
		end
	end
end

function GUI:GetRoomElements()
	return self._rooms
end

function GUI:GetDoorElements()
	return self._doors
end

if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if self._ship then
			layout.ship = self._ship:GetName()
		else
			layout.ship = nil
		end
	end
end

if CLIENT then
	GUI._transform = nil

	function GUI:SetBounds(bounds)
		self.Super[BASE].SetBounds(self, bounds)
		self:FindTransform()
	end

	function GUI:FindTransform()
		if not self._ship then return end

		local shipBounds = Bounds()
		for _, room in pairs(self._ship.Rooms) do
			shipBounds:AddBounds(room.Bounds)
		end

		self:ApplyTransform(FindBestTransform(shipBounds,
			self:GetGlobalBounds(), true, true))
	end

	function GUI:ApplyTransform(transform)
		if self._transform == transform or not self._ship then return end

		self._transform = transform

		for _, room in pairs(self._rooms) do
			room:ApplyTransform(transform, true)
		end

		for _, door in pairs(self._doors) do
			door:ApplyTransform(transform)
		end
	end

	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)

		if layout.ship then
			if not self._ship or self._ship.Name ~= layout.ship then
				self:SetCurrentShip(ships.FindByName(layout.ship))
			end
		else
			self._ship = nil
		end
	end
end
