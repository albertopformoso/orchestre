-- 1. Load baseline layout/monitors/settings
require("modules/monitors")
require("modules/settings")
require("modules/rules")

-- 2. Extract application variables
local apps = require("modules/programs")

-- 3. Pass application configurations to dependent modules
require("modules/autostart")(apps)
require("modules/keybindings")(apps)
