-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

-- wlogout's translucent fullscreen surface reveals the blurred desktop.
hl.layer_rule({
    name = "blur-power-menu",
    match = { namespace = "^logout_dialog$" },
    blur = true,
    ignore_alpha = 0.01,
})

-- Keep new windows in the Super+S scratch workspace detached.
hl.window_rule({
    name  = "float-magic-workspace",
    match = { workspace = "special:magic" },
    float = true,
    size  = "820 320"
})

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name  = "float-bluetui",
    -- Opened by right-clicking the waybar bluetooth pill
    -- (alacritty --class bluetui): a detached floating rectangle.
    match = { class = "^bluetui$" },
    float = true,
    size  = "560 620",
    pin   = true,
})

hl.window_rule({
    name  = "float-kcalc",
    match = { class = "^([Kk][Cc]alc|org\\.kde\\.kcalc)$" },
    size  = "260 390",
    float = true,
})

-- Applications that identify their temporary windows as modal dialogs.
hl.window_rule({
    name   = "float-modal-dialogs",
    match  = { modal = true },
    float  = true,
    center = true,
})

-- Zen publishes extension titles after mapping. Keep ambiguous new windows
-- out of the tiling layout while their titles settle (at most 300 ms).
local pending_tag = "orchestre-browser-pending"
local pending_windows = {}
local function is_zen(window)
    local class = (window.class or ""):lower()
    return class == "zen" or class:match("^zen%-") or class == "app.zen_browser.zen"
end

hl.window_rule({
    name = "stage-zen-windows",
    match = {
        class = "(?i)^(zen(-.*)?|app[.]zen_browser[.]zen)$",
        initial_title = "^(Zen Browser)?$",
        modal = false,
    },
    float = true,
})
hl.window_rule({
    name = "hide-pending-browser-windows",
    match = { tag = pending_tag },
    opacity = "0 override 0 override 0 override",
    no_anim = true,
    no_shadow = true,
    no_blur = true,
    border_size = 0,
})

local function is_extension(window)
    return (window.title or ""):match("^Extension: %(.+%)") ~= nil
end

local function finish_pending(window)
    if not window or not window.mapped then return end
    local id = window.stable_id
    if not pending_windows[id] then return end
    pending_windows[id] = nil
    if is_extension(window) then
        hl.dispatch(hl.dsp.window.resize({ window = window, x = 480, y = 600 }))
        hl.dispatch(hl.dsp.window.center({ window = window }))
    elseif not (window.workspace and window.workspace.name == "special:magic") then
        hl.dispatch(hl.dsp.window.float({ window = window, action = "disable" }))
    end
    hl.dispatch(hl.dsp.window.tag({ window = window, tag = "-" .. pending_tag }))
end

hl.on("window.open_early", function(window)
    if not window or not is_zen(window) then return end
    local title = window.initial_title or ""
    if title ~= "" and title ~= "Zen Browser" then return end
    -- This event precedes layout insertion and the first rendered frame.
    pending_windows[window.stable_id] = true
    hl.dispatch(hl.dsp.window.tag({ window = window, tag = "+" .. pending_tag }))
end)

-- Firefox remains covered by the late-title fallback too.
local extension_popups = {}
local function float_extension_popup(window)
    if not window or not window.mapped then return end

    local class = (window.class or ""):lower()
    local browser = class == "zen" or class:match("^zen%-")
        or class == "app.zen_browser.zen"
        or class == "firefox" or class:match("^firefox%-")
        or class == "org.mozilla.firefox"
    if not browser or not is_extension(window) then return end

    local id = window.stable_id
    if extension_popups[id] then return end
    extension_popups[id] = true

    if pending_windows[id] then
        finish_pending(window)
        return
    end

    -- Preserve an already-floating popup's position and size. Handle each
    -- window once, so later titles do not undo manual resizing or tiling.
    if window.floating then return end
    hl.dispatch(hl.dsp.window.float({ window = window, action = "enable" }))
    hl.dispatch(hl.dsp.window.resize({ window = window, x = 480, y = 600 }))
    hl.dispatch(hl.dsp.window.center({ window = window }))
end

hl.on("window.open", function(window)
    float_extension_popup(window)
    if window and pending_windows[window.stable_id] then
        hl.timer(function() finish_pending(window) end, { timeout = 300, type = "oneshot" })
    end
end)
hl.on("window.title", float_extension_popup)
hl.on("window.class", float_extension_popup)
hl.on("window.close", function(window)
    if window and window.stable_id then
        extension_popups[window.stable_id] = nil
        pending_windows[window.stable_id] = nil
    end
end)
hl.on("config.reloaded", function()
    for _, window in ipairs(hl.get_windows()) do
        -- Reload cancels old timers: release any interrupted staged window.
        for _, tag in ipairs(window.tags or {}) do
            if tag == pending_tag then
                pending_windows[window.stable_id] = true
                finish_pending(window)
                break
            end
        end
        float_extension_popup(window)
    end
end)

hl.config({
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },
})
