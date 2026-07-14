-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
return function(apps)
    -- See https://wiki.hypr.land/Configuring/Basics/Autostart/
    hl.on("hyprland.start", function () 
        hl.exec_cmd("awww-daemon")
        hl.exec_cmd("awww img " .. os.getenv("HOME") .. "/.config/hypr/current_wallpaper --transition-type wipe")
        hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 12")
        hl.exec_cmd("hypridle")
        -- hl.exec_cmd(apps.terminal)
        -- hl.exec_cmd("nm-applet")
        hl.exec_cmd("systemctl --user start hyprpolkitagent")
    end)
end
