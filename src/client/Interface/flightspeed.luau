local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

return function(MainGui)
	local input: TextBox = MainGui.FlightSpeedInput
	
	input.FocusLost:Connect(function()
		local number = tonumber(input.Text)
		if number then
			number = math.clamp(number, 15, 5000)
			LocalPlayer:SetAttribute('MaxSpeed', number)
			input.Text = number
		elseif input.Text ~= "" then
			input.Text = "Not a number"
			task.wait(0.2)
			input.Text = ""
		else
			LocalPlayer:SetAttribute('MaxSpeed', 350)
			input.Text = 350
		end
	end)
end