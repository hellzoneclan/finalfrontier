SYS.FullName = "Life Support"

if SERVER then
	resource.AddFile("materials/systems/lifesupport.png")
elseif CLIENT then
	SYS.Icon = Material("systems/lifesupport.png", "smooth")
end
