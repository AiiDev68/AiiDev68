# MitHub UI Library

Custom UI library for Roblox, designed for **Violence District** game.
Inspired by a dark slate + lime-green accent design with iOS-style pill toggles.

## Files
- `source.luau` — UI library (load this from your script)
- `loader.luau` — Violence District script (uses the library above)

## Usage

### Option 1: Use the included loader directly
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/MitHubUI/main/loader.luau"))()
```

### Option 2: Use only the library, build your own UI
```lua
local MitHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/MitHubUI/main/source.luau"))()

local Window = MitHub:CreateWindow({
    Name = "My App",
    Content = "v1.0",
    Size = MitHub.Scales.Default,
    Keybind = "Insert",
})

local Tab = Window:AddTab({Name = "Main", Icon = "rbxassetid://6035047377"})
local Section = Tab:AddSection({Name = "Section"})

Section:AddLabel("My Toggle"):AddToggle({
    Default = false,
    Flag = "my_toggle",
    Callback = function(v) print("Toggle:", v) end,
})
```

## API Reference

### Window
- `MitHub:CreateWindow({Name, Content, Size, Keybind})` — creates the main window
- `Window:AddTab({Name, Icon})` — creates a tab (returns Tab)
- `Window:ToggleInterface()` — show/hide the menu
- `Window:SetSize(UDim2)` — resize the window
- `Window.UserSettings` — built-in Settings tab (gear icon)

### Tab
- `Tab:AddSection({Name, Position})` — creates a section (Position kept for compat, single column)

### Section
- `Section:AddLabel(text, warp)` — creates a row, returns Label handle
- `Section:AddButton({Name, Callback})` — direct button

### Label handle (chained API like NeverLose)
- `Label:AddToggle({Default, Flag, Callback})` — iOS pill toggle
- `Label:AddSlider({Min, Max, Default, Flag, Callback})` — draggable slider
- `Label:AddDropdown({Default, Values, Multi, Flag, Callback})` — dropdown
- `Label:AddKeybind({Default, Flag, Callback})` — keybind picker
- `Label:AddButton({Name, Callback})` — button

### Other
- `MitHub:CreateNotification()` — `Notification.new({Title, Content, Duration})`
- `MitHub:CreateLogger()` — `Logger.new(icon, text, duration)`
- `MitHub:CreateWatermark(Window)` — watermark with `:AddBlock(icon, text)` -> `:SetText(t)` / `:Input(cb)`
- `MitHub.Scales` — `Small`, `Mobile`, `Default`, `Large`
- `MitHub.Accent` — lime green `Color3.fromRGB(170, 255, 80)`
- `MitHub.Flags[flagName]` — table of all flagged elements with `:GetValue()` / `:SetValue(v)`

## Menu Toggle (Multiple Ways)
- **Insert** key (default)
- **RightShift** key
- **F4** key
- **P** key
- **Tap the "X" button** (top-right of window)
- **Tap the "-" minimize button** (top-right of window)
- **Tap the "M" floating button** (bottom-left, appears when minimized — works on mobile!)

## Visual Style
- Background: `#14161E` (dark slate)
- Sidebar: `#181A24`
- Rows: `#222430`
- Accent: `#AAFF50` (lime green) — for active toggles, sliders, highlights
- Toggles: iOS-style pill (38×18, 14×14 dot)
- Window: rounded corners (10px) + accent bar on top
- Sidebar tabs: 130px wide, icon (16×16) + text

## License
MIT — see [LICENSE](LICENSE)
