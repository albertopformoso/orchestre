return function(apps)
    local mainMod = "SUPER"
    local secndMod = "SUPER + SHIFT"

    -- Core Binds
    hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(apps.terminal))
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(apps.fileManager))
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(apps.menu))
    hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(apps.menu))
    hl.bind("CTRL + SPACE", hl.dsp.exec_cmd(apps.menu))
    hl.bind(secndMod .. " + SPACE", hl.dsp.exec_cmd(apps.runner))

    hl.bind(mainMod .. " + Q", hl.dsp.window.close())
    hl.bind(secndMod .. " + Q", hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf"))
    hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
    hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
    hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
    hl.bind(secndMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
    hl.bind("CTRL + SHIFT + 4", hl.dsp.exec_cmd("hyprshot -z -m region --clipboard-only"))
    hl.bind("CTRL + SHIFT + 3", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))
    hl.bind(secndMod .. " + C", hl.dsp.exec_cmd("hyprctl dispatch submap reset && hyprctl kill"))

    -- Navigation (Arrows & Vim keys)
    local dirs = { left = "h", right = "l", up = "k", down = "j" }
    for dir, key in pairs(dirs) do
        hl.bind(mainMod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
        hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = dir }))
        hl.bind(secndMod .. " + " .. key, hl.dsp.window.move({ direction = dir }))
    end

    -- Workspaces
    for i = 1, 10 do
        local key = i % 10
        hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    hl.bind(secndMod .. " + Left", hl.dsp.exec_cmd("hyprctl dispatch workspace e-1"))
    hl.bind(secndMod .. " + Right", hl.dsp.exec_cmd("hyprctl dispatch workspace e+1")) 

    -- Scratchpad & Mouse
    hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- Media Keys
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
    hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
end