-- chapterpause.lua
--
-- Ain't Nobody Got Time for That
--
-- This script pauses chapters based on their title.

local categories = {
    prologue = "^Prologue/^Intro",
    opening = "^OP/ OP$/^Opening",
    ending = "^ED/ ED$/^Ending",
    preview = "Preview$"
}

local options = {
    enabled = true,
    pause_once = true,
    categories = "",
    pause = ""
}

mp.options = require "mp.options"

function matches(i, title)
    for category in string.gmatch(options.pause, " *([^;]*[^; ]) *") do
        if categories[category:lower()] then
            if string.find(category:lower(), "^idx%-") == nil then
                if title then
                    for pattern in string.gmatch(categories[category:lower()], "([^/]+)") do
                        if string.match(title, pattern) then
                            return true
                        end
                    end
                end
            else
                for pattern in string.gmatch(categories[category:lower()], "([^/]+)") do
                    if tonumber(pattern) == i then
                        return true
                    end
                end
            end
        end
    end
end

local paused = {}
local parsed = {}

function chapterpause(_, current)
    mp.options.read_options(options, "chapterpause")
    if not options.enabled then return end
    for category in string.gmatch(options.categories, "([^;]+)") do
        name, patterns = string.match(category, " *([^+>]*[^+> ]) *[+>](.*)")
        if name then
            categories[name:lower()] = patterns
        elseif not parsed[category] then
            mp.msg.warn("Improper category definition: " .. category)
        end
        parsed[category] = true
    end
    local chapters = mp.get_property_native("chapter-list")
    local pause = false
    for i, chapter in ipairs(chapters) do
        if (not options.pause_once or not paused[i]) and matches(i, chapter.title) then
            if i == current + 1 or pause == i - 1 then
                if pause then
                    paused[pause] = true
                end
                pause = i
            end
        elseif pause then
            mp.set_property("pause","yes")
            paused[pause] = true
            return
        end
    end
    if pause then
        if mp.get_property_native("playlist-count") == mp.get_property_native("playlist-pos-1") then
            return mp.set_property("pause","yes")
        end
        mp.commandv("pause")
    end
end

mp.observe_property("chapter", "number", chapterpause)
mp.register_event("file-loaded", function() paused = {} end)
