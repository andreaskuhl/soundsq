------------------------------------------------------------------------------------------------------------------------
---  Widget Config Functions
------------------------------------------------------------------------------------------------------------------------
---
---  wConfig library with functions for widget configuration:
---
---    init(parameters)
---    addSourceField(key)
---    addChoiceField(key, list)
---    addBooleanField(key)
---    addTextField(key)
---    addColorField(key)
---    addStaticText(title, text)
---    return function(parameters)
---
---  Version:                 1.1.0
---  Development Environment: Ethos X20S Simulator Version 1.6.3
---  Test Environment:        FrSky Tandem X20 | Ethos 1.6.3 EU
---
---  Author: Andreas Kuhl (https://github.com/andreaskuhl)
---  License: GPL 3.0
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Modul locals (constants, variables, ..)
------------------------------------------------------------------------------------------------------------------------

-- library structure
local wConfig = {}

-- parameters
local form    = {} -- form structure, for add... functions
local widget  = {} -- widget  structure
local STR     = {} -- i18n function

--  required libraries
local wHelper = {} -- helper library

-- config parameters
local CFL     = {} -- capitalize first letter function

-- local variables
local line    = {} -- form line

function wConfig.existWidgetKey(functionName, key)
    if widget[key] ~= nil then return true end
    wHelper.Debug:new({ widgetNo = widget.no, widgetFunction = functionName, debugInit = false }):error(
        "Widget key '" ..
        key .. "' not found!")
    return false
end

-----------------------------------------------------------------------------------------------------------------------
--- Init with actual form and widget
function wConfig.init(parameters)
    form = parameters.form
    widget = parameters.widget
    STR = parameters.STR
end

------------------------------------------------------------------------------------------------------------------------
--- Add source field
function wConfig.addSourceField(key)
    -- if not wConfig.existWidgetKey("addSourceField", key) then return end
    line = form.addLine(STR(CFL(key)))
    form.addSourceField(line, nil, function() return widget[key] end, function(value) widget[key] = value end)
end

------------------------------------------------------------------------------------------------------------------------
--- Add choice field
function wConfig.addChoiceField(key, list)
    if not wConfig.existWidgetKey("addChoiceField", key) then return end
    line = form.addLine(STR(CFL(key)))
    form.addChoiceField(line, nil, list, function() return widget[key] end, function(value) widget[key] = value end)
end

------------------------------------------------------------------------------------------------------------------------
--- Add boolean field
function wConfig.addBooleanField(key)
    if not wConfig.existWidgetKey("addBooleanField", key) then return end
    line = form.addLine(STR(CFL(key)))
    form.addBooleanField(line, nil, function() return widget[key] end, function(value) widget[key] = value end)
end

------------------------------------------------------------------------------------------------------------------------
--- Add text field
function wConfig.addTextField(key)
    if not wConfig.existWidgetKey("addTextField", key) then return end
    line = form.addLine(STR(CFL(key)))
    form.addTextField(line, nil, function() return widget[key] end, function(value) widget[key] = value end)
end

------------------------------------------------------------------------------------------------------------------------
--- Add color field
function wConfig.addColorField(key)
    if not wConfig.existWidgetKey("addColorField", key) then return end
    line = form.addLine(STR(CFL(key)))
    form.addColorField(line, nil, function() return widget[key] end, function(value) widget[key] = value end)
end

------------------------------------------------------------------------------------------------------------------------
--- Add static text output.
function wConfig.addStaticText(title, text)
    line = form.addLine(STR(title))
    form.addStaticText(line, nil, text)
end

-----------------------------------------------------------------------------------------------------------------------
--- Library settings and export
return function(parameters)
    wHelper = parameters.wHelper
    CFL = wHelper.capitalizeFirstLetter

    return wConfig
end
