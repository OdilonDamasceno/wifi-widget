local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")
local widget = {}
local popup = {}

local function worker(args)
    local _halign = "right"

    local function make_text(text, forced_width, forced_height)
        return wibox.widget{
            markup= "<b>".. text .."</b>",
            forced_width = forced_width,
            forced_height = forced_height,
            widget = wibox.widget.textbox
        }
    end

    local ssids = wibox.widget {
        spacing = 5,
        layout  = wibox.layout.fixed.vertical
    }

    widget = wibox.widget{
        {
            image = "wifi_icon.png",
            widget = wibox.widget.imagebox
        },
        margins = 5,
        widget = wibox.container.margin
    }

    local white_circle = wibox.widget{
        image = "white_circle.png",
        widget = wibox.widget.imagebox
    }

    local white_buttom = wibox.widget{
        white_circle,
        halign = _halign,
        widget = wibox.container.place
    }

    local bg_blue = wibox.widget{
        bg = '#5f5fff',
        shape = gears.shape.rounded_bar,
        widget = wibox.widget.background
    }

    local buttom = wibox.widget{
        bg_blue,
        white_buttom,
        forced_height = 15,
        forced_width = 15,
        layout = wibox.layout.stack
    }

    local separator = wibox.widget{
        index = 0,
        orientation = "horizontal",
        forced_height = 1,
        opacity=0.1,
        widget = wibox.widget.separator
    }

    local row = wibox.widget{
        make_text("Wi-Fi"),
        buttom,
        forced_height = 23,
        widget = wibox.layout.ratio.horizontal
    }

    row:set_ratio(1,0.85)

    local wifi_widget = wibox.widget{
        row,
        separator,
        make_text("Preferred Networks"),
        ssids,
        spacing = 10,
        layout  = wibox.layout.fixed.vertical
    }

    local wifi = wibox.widget {
        wifi_widget,
        margins = 12,
        widget = wibox.container.margin
    }

    popup = awful.popup{
        ontop = true,
        visible = false,
        shape = gears.shape.rounded_rect,
        bg = "#1a1a1acf",
        minimum_width = 300,
        maximum_width = 300,
        minimum_height = 100,
        widget = wifi
    }

    awful.widget.watch([[ bash -c "nmcli -m multiline -f SSID device wifi | sed -e 's/  *//' | awk -F: '{print $2}'" ]], 3, function (widget,stdout)
        ssids.children = {}
        local j = 1
        local lock = {
            {
            image = "lock_icon.png",
            widget = wibox.widget.imagebox
            },
            margins = 6,
            widget = wibox.container.margin
        }

        local wifi_icon = {
            {
                image = "wifi_icon.png",
                widget = wibox.widget.imagebox
            },
            margins = 5,
            widget = wibox.container.margin
        }
        if stdout:len() > 0 then
            for str in string.gmatch(stdout, "([^".."\n".."]+)") do
                if string.match(str, "%-%-") == nil then

                    local _row = wibox.widget{
                        {
                            wifi_icon,
                            make_text(str),
                            lock,
                            visible = true,
                            forced_height = 15,
                            widget= wibox.layout.align.horizontal
                        },
                        forced_height = 20,
                        widget = wibox.container.background,
                    }

                    ssids.children[j] = _row
                    _row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus .. "5a")  end)
                    _row:connect_signal("mouse::leave", function(c) c:set_bg("#00000000") end)
                    _row:connect_signal("button::press", function (c)
                        awful.spawn.with_shell(terminal .. " -d 50 1 -e nmcli --ask device wifi connect '" .. str .. "'" )
                    end)

                    j = j + 1
                end
            end
        else
            ssids.children[1] = make_text("Your Wi-Fi is disabled")
        end
    end, wifi_widget)

    local function change_buttom(side,color)
        _halign = side
        bg_blue:set_bg(color)
        white_buttom:set_halign(side)
    end

    awful.widget.watch("nmcli radio wifi",1, function (widget,stdout)
        if stdout:find("enabled") then
            change_buttom("right", '#5f5fff')
        else
            change_buttom("left","#b5b5b5")
        end
    end, white_buttom)

    widget:connect_signal("button::press", function (c)
        if popup.visible then
            popup.visible = not popup.visible
        else
            popup:move_next_to(mouse.current_widget_geometry)
        end
    end)

    white_buttom:connect_signal("button::press", function (c)
        if _halign == "right" then
            change_buttom("left","#b5b5b5")
            awful.spawn.with_shell("nmcli radio wifi off")
        else
            change_buttom("right", '#5f5fff')
            awful.spawn.with_shell("nmcli radio wifi on")
        end
    end)

    return widget
end

return setmetatable(widget, { __call = function(_, ...)
    return worker(...)
end })
