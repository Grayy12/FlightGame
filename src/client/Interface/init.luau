local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local mainGUI = LocalPlayer.PlayerGui:WaitForChild("MainGui")

local Interface = {}

function Interface.Start()
	for i, v in script:GetChildren() do
		if v:IsA("ModuleScript") then
			require(v)(mainGUI)
		end
	end
end


return Interface
