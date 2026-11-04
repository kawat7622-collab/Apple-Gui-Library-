local GlassUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/GlassUI/main/GlassUI.lua"))()

local Window = GlassUI:CreateWindow({
	Title = "My Hub",
	Logo = 136593826397730,
	ToggleKey = Enum.KeyCode.K,
	ConfigName = "MyHub",
	Discord = "https://discord.gg/your-invite",
	DiscordIcon = 109662717019197,
})

local Main = Window:CreateTab("Main")

Main:CreateSection("Player")

Main:CreateSlider({
	Title = "WalkSpeed",
	Description = "How fast your character walks",
	Min = 16,
	Max = 100,
	Default = 16,
	Increment = 1,
	Flag = "WalkSpeed",
	Callback = function(value)
		local character = game.Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end,
})

Main:CreateToggle({
	Title = "Infinite Jump",
	Description = "Jump again while in the air",
	Default = false,
	Flag = "InfiniteJump",
	Callback = function(enabled)
		print("Infinite Jump:", enabled)
	end,
})

Main:CreateButton({
	Title = "Reset Character",
	Description = "Respawns your character",
	Style = "Destructive",
	Callback = function()
		local character = game.Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end,
})

local Extra = Window:CreateTab("Extra")

Extra:CreateParagraph({
	Title = "Welcome",
	Content = "This tab shows every element GlassUI offers. Everything with a Flag is saved automatically.",
})

Extra:CreateInput({
	Title = "Username",
	Placeholder = "Type a name…",
	Flag = "Username",
	Callback = function(text, enterPressed)
		print("Input:", text, enterPressed)
	end,
})

Extra:CreateKeybind({
	Title = "Print Keybind",
	Description = "Press the key to print a message",
	Default = Enum.KeyCode.P,
	Flag = "PrintKey",
	Callback = function()
		print("Keybind pressed!")
	end,
})

local teamDropdown = Extra:CreateDropdown({
	Title = "Team",
	Options = { "Red", "Blue", "Green" },
	Default = "Red",
	Flag = "Team",
	Callback = function(option)
		print("Team:", option)
	end,
})

Extra:CreateDropdown({
	Title = "Features",
	Description = "Pick as many as you want",
	Options = { "ESP", "Tracers", "Names", "Health" },
	Multi = true,
	Default = { "ESP" },
	Flag = "Features",
	Callback = function(selected)
		print("Features:", table.concat(selected, ", "))
	end,
})

Extra:CreateButton({
	Title = "Add Yellow Team",
	Style = "Primary",
	Callback = function()
		teamDropdown:SetOptions({ "Red", "Blue", "Green", "Yellow" })
		Window:Notify({ Title = "Dropdown", Content = "Yellow was added to the team list", Duration = 3 })
	end,
})

Extra:CreateLabel("Made with GlassUI")

Window.Settings:CreateSection("Script")
Window.Settings:CreateButton({
	Title = "Unload Script",
	Style = "Destructive",
	Callback = function()
		Window:Destroy()
	end,
})

Window:Notify({ Title = "My Hub", Content = "Loaded! Press K to toggle the menu.", Duration = 4 })
