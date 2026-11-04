# GlassUI

GlassUI is a **Liquid Glass UI library for Roblox** inspired by Apple's design language. It gives your scripts a clean glass window with a sidebar, tabs, smooth animations, notifications and a built-in settings page, so you can focus on your features instead of building a GUI from scratch.

## Features

- Liquid Glass window with traffic light buttons (close, minimize, center)
- Sidebar with tabs and a sliding selection pill
- Buttons, Toggles, Sliders, Inputs, Keybinds, Dropdowns (single and multi)
- Sections, Labels and Paragraphs
- Custom notifications
- Minimize to a draggable app icon
- Built-in Settings page: menu keybind, menu transparency and notifications
- Automatic config saving per user with Flags
- Optional Discord button that copies your invite link

## Loading the library

```lua
local GlassUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/GlassUI/main/GlassUI.lua"))()
```

## Creating a window

```lua
local Window = GlassUI:CreateWindow({
	Title = "My Hub",
	Logo = 136593826397730,          -- optional image asset ID
	ToggleKey = Enum.KeyCode.K,      -- optional, default K
	ConfigName = "MyHub",            -- optional, enables config saving
	Discord = "https://discord.gg/x", -- optional, shows a Discord button
	DiscordIcon = 109662717019197,   -- optional image for the Discord button
})
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | string | `"GlassUI"` | Window title |
| `Logo` | number / string | none | Image asset ID shown in the title bar, notifications and minimized icon |
| `Size` | UDim2 | `580 x 390` | Window size (offset only) |
| `ToggleKey` | KeyCode | `K` | Key that opens and closes the menu |
| `Transparency` | number | `0.8` | Window glass transparency (0 to 0.95) |
| `ConfigName` | string | none | Saves every Flag and the settings per user |
| `Discord` | string | none | Invite link copied by the Discord button |
| `DiscordIcon` | number / string | `#` | Image for the Discord button |
| `SidebarHeader` | string | `"General"` | Small header above the tabs |
| `Settings` | boolean | `true` | Set to `false` to hide the built-in settings page |
| `Notifications` | boolean | `true` | Default state of notifications |

## Tabs

```lua
local Main = Window:CreateTab("Main")
```

The first tab you create is opened automatically. You can switch tabs from code with `Window:SelectTab("Main")` or `Main:Select()`.

## Elements

Every element returns an object. Elements with a `Flag` are saved automatically when `ConfigName` is set, and their callback runs once on load with the saved value.

### Section

```lua
Main:CreateSection("Player")
```

### Button

```lua
Main:CreateButton({
	Title = "Reset Character",
	Description = "Respawns your character", -- optional
	Style = "Destructive",                     -- "Default", "Primary" or "Destructive"
	Callback = function()
		print("Clicked")
	end,
})
```

### Toggle

```lua
local Toggle = Main:CreateToggle({
	Title = "Infinite Jump",
	Description = "Jump again while in the air",
	Default = false,
	Flag = "InfiniteJump",
	Callback = function(enabled)
		print(enabled)
	end,
})

Toggle:Set(true)
print(Toggle:Get())
```

### Slider

```lua
local Slider = Main:CreateSlider({
	Title = "WalkSpeed",
	Min = 16,
	Max = 100,
	Default = 16,
	Increment = 1,   -- use 0.1 for decimals
	Suffix = "",     -- e.g. "%" or " studs"
	Flag = "WalkSpeed",
	Callback = function(value)
		print(value)
	end,
})

Slider:Set(50)
```

### Input

```lua
local Input = Main:CreateInput({
	Title = "Username",
	Placeholder = "Type a name…",
	Default = "",
	Numeric = false,       -- only allow numbers
	ClearOnFocus = false,
	Flag = "Username",
	Callback = function(text, enterPressed)
		print(text)
	end,
})
```

### Keybind

```lua
local Keybind = Main:CreateKeybind({
	Title = "Fly",
	Default = Enum.KeyCode.F,
	Flag = "FlyKey",
	Callback = function()
		print("Key pressed")
	end,
	ChangedCallback = function(newKey)
		print("New key:", newKey and newKey.Name)
	end,
})
```

Click the key button and press a new key to change it. **Escape** cancels and **Backspace** clears the keybind.

### Dropdown

```lua
local Dropdown = Main:CreateDropdown({
	Title = "Team",
	Options = { "Red", "Blue", "Green" },
	Default = "Red",
	Multi = false,      -- true lets the user pick several options
	Flag = "Team",
	Callback = function(option)
		print(option) -- a table of options when Multi = true
	end,
})

Dropdown:Set("Blue")
Dropdown:SetOptions({ "Red", "Blue", "Yellow" })
```

### Label and Paragraph

```lua
local Label = Main:CreateLabel("Some text")
Label:Set("New text")

local Paragraph = Main:CreateParagraph({ Title = "Welcome", Content = "Longer text that wraps over several lines." })
Paragraph:SetContent("Updated text")
```

All elements with a title also have `:SetTitle(text)` and `:SetDescription(text)`.

## Notifications

```lua
Window:Notify({
	Title = "My Hub",
	Content = "Loaded successfully",
	Duration = 3,
})
```

Users can turn notifications off on the Settings page. Pass `Force = true` to always show a notification.

## Settings page

The gear button in the bottom left corner opens the built-in Settings page with the menu keybind, menu transparency and notifications. You can add your own elements to it:

```lua
Window.Settings:CreateSection("Script")
Window.Settings:CreateButton({
	Title = "Unload Script",
	Style = "Destructive",
	Callback = function()
		Window:Destroy()
	end,
})
```

## Window methods

| Method | Description |
| --- | --- |
| `Window:CreateTab(name)` | Creates a new tab |
| `Window:SelectTab(nameOrTab)` | Opens a tab |
| `Window:Notify(options)` | Shows a notification |
| `Window:Show()` / `Window:Hide()` / `Window:Toggle()` | Shows or hides the window |
| `Window:Minimize()` / `Window:Restore()` | Minimizes to the app icon and back |
| `Window:SetTransparency(number)` | Changes the glass transparency |
| `Window:SetToggleKey(KeyCode)` | Changes the menu keybind |
| `Window:SetTitle(text)` | Changes the window title |
| `Window:Destroy()` | Removes the window and disconnects everything |
| `Window.Flags` | Table with the current value of every Flag |

## Config saving

When `ConfigName` is set, GlassUI saves to `GlassUI/<ConfigName>/<UserId>.json` in your executor's workspace folder. Each Roblox account gets its own file. Saving requires `writefile` and `readfile`, which most executors support. Without them everything still works, just without saving.

## Example

See [`Example.lua`](Example.lua) for a full script that uses every element.
