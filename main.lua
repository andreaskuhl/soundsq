------------------------------------------------------------------------------------------------------------------------
---                 SOUNDSQ | Sound Sequenzer - Widget für FrSky Ethos 1.6
---
---  FrSky Ethos widget for playing sequential voice announcements (sounds files).
---
---  Documentation: file://./readme.md
---
---  Development Environment: Ethos X20S Simulator Version 1.6.3
---  Test Environment:        FrSky Tandem X20 | Ethos 1.6.3 EU
---
---  Author: Andreas Kuhl (https://github.com/andreaskuhl)
---  License: GPL 3.0
---
---  Basic history:
---    Idea by Hannes Mössler
---    v0.1.0 Benno Jurisch (basic development) -> Play sound files in sequence
---    v0.2.0 Andreas Kuhl (further development) -> Prefix (filter) for multiple use with different sound sequences
---
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Modul locals (constants & variables)
------------------------------------------------------------------------------------------------------------------------

--- Application control and information
local WIDGET_VERSION          = "1.1.0"                                 -- version information
local WIDGET_KEY              = "SOUNDSQ"                               -- unique widget key (max. 7 characters)
local WIDGET_AUTOR            = "Andreas Kuhl (github.com/andreaskuhl)" -- author information
local DEBUG_MODE              = false                                    -- true: show debug information, false: release mode
local widgetCounter           = 0                                       -- counter for widget instances (0 = no instance)

--- Libraries
local wHelper                 = {} -- widget helper library
local wPaint                  = {} -- widget paint library
local wConfig                 = {} -- widget config library
local wStorage                = {} -- widget storage library

--- Translation
local STR                     = assert(loadfile("i18n/i18n.lua"))().translate -- load i18n and get translate function
local WIDGET_NAME_MAP         = assert(loadfile("i18n/w_name.lua"))()         -- load widget name map
local currentLocale           = system.getLocale()                            -- current system language

--- User interface
local FONT_SIZES              = {
    FONT_XS, FONT_S, FONT_STD, FONT_L, FONT_XL, FONT_XXL }                       -- global font IDs (1-5)
local FONT_SIZE_SELECTION     = {
    { "XS", 1 }, { "S", 2 }, { "M", 3 }, { "L", 4 }, { "XL", 5 }, { "XXL", 6 } } -- list for config listbox

--- widget defaults
local FONT_SIZE_INDEX_DEFAULT = 4                      -- font size index default
local BG_COLOR_TITLE_DEFAULT  = lcd.RGB(40, 40, 40)    -- title background  -> dark gray
local TX_COLOR_TITLE_DEFAULT  = COLOR_WHITE            -- title text        -> white
local BG_COLOR_WIDGET_DEFAULT = COLOR_BLACK            -- widget background -> black
local TX_COLOR_ACTUAL_DEFAULT = lcd.RGB(0, 128, 0)     -- "Actual"" text    -> dark green
local TX_COLOR_NEXT_DEFAULT   = COLOR_GREEN            -- "Next" text       -> green
local TX_COLOR_FOOTER_DEFAULT = lcd.RGB(176, 176, 176) -- footer text       -> light gray

------------------------------------------------------------------------------------------------------------------------
--- Local Helper functions
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Load and init Libraries.
local function initLibraries()
    -- load libraries with dependencies
    wHelper = dofile("lib/w_helper.lua")({ widgetVersion = WIDGET_VERSION, widgetKey = WIDGET_KEY, debugMode = DEBUG_MODE })
    wPaint = dofile("lib/w_paint.lua")({ wHelper = wHelper })
    wConfig = dofile("lib/w_config.lua")({ wHelper = wHelper })
    wStorage = dofile("lib/w_storage.lua")({ wHelper = wHelper })

    wHelper.Debug:new(0, "initLibraries"):info("libraries loaded")
end

------------------------------------------------------------------------------------------------------------------------
-- Check if the system language has changed and reload i18n if necessary.
local function updateLanguage(widget)
    local localeNow = system.getLocale()
    if localeNow ~= currentLocale then -- Language has changed, reload i18n
        wHelper.Debug:new(widget.no, "updateLanguage")
            :info("Language changed from " .. currentLocale .. " to " .. localeNow)
        STR = assert(loadfile("i18n/i18n.lua"))().translate
        currentLocale = localeNow
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Read sound files with the given prefix from the sounds directory and return a sorted list.
local function readSoundFiles(widget)
    local debug = wHelper.Debug:new(widget.no, "readSoundFiles")
    local fileMask = string.lower("^" .. widget.prefix .. ".*%.wav$")
    local files = system.listFiles("sounds/")

    table.sort(files, function(a, b) return a < b end)
    for i = #files, 1, -1 do
        if not (files[i]:lower():match(fileMask)) then
            table.remove(files, i)
        end
    end

    widget.soundFiles = files
    widget.soundCounter = 1 -- reset sound counter
    debug:info("found " .. #widget.soundFiles .. " sound files with prefix '" .. widget.prefix .. "'")
end

------------------------------------------------------------------------------------------------------------------------
--- Widget handler
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Handler to get the widget name in the current system language.
local function name() -- Widget name (ASCII) - only for name() Handler
    wHelper.Debug:new(0, "name"):info()
    local lang = system.getLocale and system.getLocale() or "en"
    return WIDGET_NAME_MAP[lang] or WIDGET_NAME_MAP["en"]
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to create a new widget instance with default values.
local function create()
    widgetCounter = widgetCounter + 1
    wHelper.Debug:new(widgetCounter, "create"):info()

    --- Create widget data structure with default values.r
    return {
        -- widget variables
        no                  = widgetCounter, -- widget instance number
        width               = nil,           -- widget height
        height              = nil,           -- widget width
        soundCounter        = 1,             -- index for next sound file
        soundFiles          = {},            -- list of sound files
        playPressed         = false,         -- true: play button pressed (false: released)
        prevPressed         = false,         -- true: previous button pressed (false: released)
        resetPressed        = false,         -- true: reset button pressed (false: released)

        -- config fields
        sourcePlay          = nil,                     -- source for play next sound file
        sourcePrev          = nil,                     -- source for go to previous sound file
        sourceReset         = nil,                     -- source for reset to first sound file
        prefix              = "",                      -- prefix for sound files (e.g. "A_" for A_1.wav, A_2.wav, ...)

        widgetFontSizeIndex = FONT_SIZE_INDEX_DEFAULT, -- index of font size
        widgetBgColor       = BG_COLOR_WIDGET_DEFAULT, -- widget background color
        actualShow          = true,                    -- actual show switch
        actualNextShow      = true,                    -- actual/next show switch
        actualTxColor       = TX_COLOR_ACTUAL_DEFAULT, -- actual text color
        nextTxColor         = TX_COLOR_NEXT_DEFAULT,   -- next text color
        reducedSortChars    = 3,                       -- reduce sort number of characters in file name for title

        footerShow          = true,                    -- footer show switch
        footerTxColor       = TX_COLOR_FOOTER_DEFAULT, -- widget text color

        titleShow           = true,                    -- title show switch
        titleColorUse       = true,                    -- title color switch
        titleBgColor        = BG_COLOR_TITLE_DEFAULT,  -- title background color
        titleTxColor        = TX_COLOR_TITLE_DEFAULT,  -- title text color
    }
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to wake up the widget (check for source value changes and initiating redrawing if necessary).
local function wakeup(widget)
    local debug = wHelper.Debug:new(widget.no, "wakeup")
    if not wHelper.existSource(widget.sourcePlay) or #widget.soundFiles == 0 then
        -- debug:warning("wakeup aborted - sourcePlay not defined or no sound files found")
        return
    end

    -- check sourceReset
    if wHelper.existSource(widget.sourceReset) then
        if widget.sourceReset:value() >= 0 then
            widget.resetPressed = true
        elseif widget.resetPressed == true and widget.sourceReset:value() < 0 then
            widget.resetPressed = false
            widget.soundCounter = 1
            lcd.invalidate()
        end
    end

    -- check sourcePrev (previous)
    if wHelper.existSource(widget.sourcePrev) then
        if widget.sourcePrev:value() >= 0 then
            widget.prevPressed = true
        elseif widget.prevPressed == true and widget.sourcePrev:value() < 0 then
            widget.prevPressed = false
            if widget.soundCounter > 1 then
                widget.soundCounter = widget.soundCounter - 1
                lcd.invalidate()
            end
        end
    end

    -- check sourcePlay
    if wHelper.existSource(widget.sourcePlay) then
        if widget.sourcePlay:value() >= 0 then
            widget.playPressed = true
        elseif widget.playPressed == true and widget.sourcePlay:value() < 0 then
            widget.playPressed = false
            system.playFile("sounds/" .. widget.soundFiles[widget.soundCounter])
            if widget.soundCounter < #widget.soundFiles then
                widget.soundCounter = widget.soundCounter + 1
            else
                widget.soundCounter = 1
            end
            lcd.invalidate()
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to paint (draw) the widget.
local function paint(widget)
    --------------------------------------------------------------------------------------------------------------------
    --- Paint title text.
    local function paintTitle()
        -- wHelper.Debug:new(widget.no, "paintTitle"):info()
        local titleText = STR("TitleText")
        local titleBgColor = widget.widgetBgColor
        local titleTXColor = widget.widgetTxColor

        if widget.titleShow ~= true then return end -- title disabled

        -- title background and title text color
        if widget.titleColorUse then
            titleBgColor = widget.titleBgColor
            titleTXColor = widget.titleTxColor
        end

        -- combine title text and prefix (if given)
        if wHelper.existText(widget.prefix) then
            titleText = titleText .. " - " .. widget.prefix
        end

        titleText = titleText .. " (" .. widget.soundCounter .. "/" .. #widget.soundFiles .. ")"

        wPaint.title(titleText, titleBgColor, titleTXColor)
    end
    --------------------------------------------------------------------------------------------------------------------
    --- Paint footer text.
    local function paintFooter()
        -- wHelper.Debug:new(widget.no, "paintFooter"):info()

        if not widget.footerShow then return end

        -- paint footer with widget background color
        local separator = "   " -- separator between the footer in the footer
        local footerText = STR("Play") .. wHelper.getSourceName(widget.sourcePlay)

        if wHelper.existSource(widget.sourcePrev) then
            footerText = footerText .. separator .. STR("Prev") .. wHelper.getSourceName(widget.sourcePrev)
        end

        if wHelper.existSource(widget.sourceReset) then
            footerText = footerText .. separator .. STR("Reset") .. wHelper.getSourceName(widget.sourceReset)
        end

        wPaint.footer(footerText, nil, widget.footerTxColor)
    end

    --------------------------------------------------------------------------------------------------------------------
    ---  paint widget text
    local function paintWidgetText()
        -- local debug = wHelper.Debug:new(widget.no, "paintWidgetText"):info()
        local nextLineShift = 0

        if widget.actualShow then
            local actualText = ""
            local actualFontSizeIndex = widget.widgetFontSizeIndex - 1
            if actualFontSizeIndex < 1 then actualFontSizeIndex = 1 end
            nextLineShift = 0.5
            lcd.color(widget.actualTxColor)
            if widget.soundCounter > 1 then
                actualText = widget.soundFiles[widget.soundCounter - 1]
                actualText = string.sub(actualText, #widget.prefix + widget.reducedSortChars + 1, #actualText - 4)
                if widget.actualNextShow then
                    wPaint.widgetText(STR("Actual"), FONT_SIZES[actualFontSizeIndex], TEXT_LEFT, wPaint.LINE_MIDDLE, -0.5)
                    wPaint.widgetText(actualText, FONT_SIZES[actualFontSizeIndex], TEXT_RIGHT, wPaint.LINE_MIDDLE, -0.5)
                else
                    wPaint.widgetText(actualText, FONT_SIZES[actualFontSizeIndex], TEXT_CENTERED, wPaint.LINE_MIDDLE,
                        -0.5)
                end
            end
        end

        local nextText = widget.soundFiles[widget.soundCounter]
        lcd.color(widget.nextTxColor)
        nextText = string.sub(nextText, #widget.prefix + widget.reducedSortChars + 1, #nextText - 4)
        if widget.actualNextShow then
            wPaint.widgetText(STR("Next"), FONT_SIZES[widget.widgetFontSizeIndex], TEXT_LEFT, wPaint.LINE_MIDDLE,
                nextLineShift)
            wPaint.widgetText(nextText, FONT_SIZES[widget.widgetFontSizeIndex], TEXT_RIGHT, wPaint.LINE_MIDDLE,
                nextLineShift)
        else
            wPaint.widgetText(nextText, FONT_SIZES[widget.widgetFontSizeIndex], TEXT_CENTERED, wPaint.LINE_MIDDLE,
                nextLineShift)
        end
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint background, set text color and paint state text (or debug information in debug mode).
    local function paintWidget()
        wHelper.Debug:new(widget.no, "paintWidget"):info()
        assert(wHelper.existSource(widget.sourcePlay))

        --- paint background and preset text color
        lcd.color(widget.widgetBgColor)
        lcd.drawFilledRectangle(0, 0, widget.width, widget.height)

        --- paint title and footer
        paintTitle()
        paintFooter()
        paintWidgetText()
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint source missed (no valid source selected) in red on black background.
    local function paintSourceMissed()
        local debug = wHelper.Debug:new(widget.no, "paintSourceMissed")
        local errorText = ""
        lcd.color(COLOR_BLACK)
        lcd.drawFilledRectangle(0, 0, widget.width, widget.height)

        --- paint title
        paintTitle()

        -- fehlende Schalter
        if not wHelper.existSource(widget.sourcePlay) then
            errorText = STR("NoSourcePlay")
            debug:warning("sourcePlay not defined")
        end
        if #widget.soundFiles == 0 then
            errorText = wHelper.addLine(errorText, STR("NoSoundFile"))
            debug:warning("no sound files found with prefix '" .. widget.prefix .. "'")
        end

        -- paint "Source missed" text
        lcd.color(COLOR_RED)
        wPaint.widgetText(errorText, FONT_S)
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint main
    wHelper.Debug:new(widget.no, "paint"):info()

    updateLanguage(widget)
    widget.width, widget.height = lcd.getWindowSize() -- set the actual widget size (always if the layout has been changed)
    wPaint.init({ widgetHeight = widget.height, widgetWidth = widget.width })

    if not wHelper.existSource(widget.sourcePlay) or #widget.soundFiles == 0 then
        paintSourceMissed()
    else
        paintWidget()
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to configure the widget (show configuration form).
local function configure(widget)
    wHelper.Debug:new(widget.no, "configure"):info()
    updateLanguage(widget) -- check if system language has changed
    wConfig.init({ form = form, widget = widget, STR = STR })

    -- source
    wConfig.addSourceField("sourcePlay")
    wConfig.addSourceField("sourcePrev")
    wConfig.addSourceField("sourceReset")
    wConfig.addTextField("prefix")

    -- widget
    wConfig.startPanel("Widget")
    wConfig.addChoiceField("widgetFontSizeIndex", FONT_SIZE_SELECTION)
    wConfig.addColorField("widgetBgColor")
    wConfig.addBooleanField("actualShow")
    wConfig.addBooleanField("actualNextShow")
    wConfig.addColorField("actualTxColor")
    wConfig.addColorField("nextTxColor")
    wConfig.addNumberField("reducedSortChars", 0, 20)
    wConfig.endPanel()

    -- title
    wConfig.startPanel("Title")
    wConfig.addBooleanField("titleShow")
    wConfig.addBooleanField("titleColorUse")
    wConfig.addColorField("titleBgColor")
    wConfig.addColorField("titleTxColor")
    wConfig.endPanel()

    -- footer
    wConfig.startPanel("Footer")
    wConfig.addBooleanField("footerShow")
    wConfig.addColorField("footerTxColor")
    wConfig.endPanel()

    -- widget Info
    wConfig.startPanel("Info")
    wConfig.addStaticText("Widget", STR("WidgetName"))
    wConfig.addStaticText("Version", WIDGET_VERSION)
    wConfig.addStaticText("Author", WIDGET_AUTOR)
    wConfig.endPanel()
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to write (save) the widget configuration.
local function write(widget)
    local debug = wHelper.Debug:new(widget.no, "write")
    wStorage.init({ storage = storage, widget = widget })

    -- write widget version number for user data format
    local versionNumber = wHelper.versionStringToNumber(WIDGET_VERSION)
    debug:info(string.format("store version %s (%d)", WIDGET_VERSION, versionNumber))
    storage.write("Version", versionNumber)

    -- source
    wStorage.write("sourcePlay")
    wStorage.write("sourcePrev")
    wStorage.write("sourceReset")
    wStorage.write("prefix")

    -- widget
    wStorage.write("widgetFontSizeIndex")
    wStorage.write("widgetBgColor")
    wStorage.write("actualShow")
    wStorage.write("actualNextShow")
    wStorage.write("actualTxColor")
    wStorage.write("nextTxColor")
    wStorage.write("reducedSortChars")

    -- footer
    wStorage.write("footerShow")
    wStorage.write("footerTxColor")

    -- title
    wStorage.write("titleShow")
    wStorage.write("titleColorUse")
    wStorage.write("titleBgColor")
    wStorage.write("titleTxColor")

    readSoundFiles(widget)

    debug:info("widget data write successfully")
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to read (load) the widget configuration.
local function read(widget)
    local debug = wHelper.Debug:new(widget.no, "read"):info()
    wStorage.init({ storage = storage, widget = widget })

    -- check first field Version number
    local versionNumber = storage.read("Version") or 100 -- v0.1.0
    if not wHelper.isValidVersion(versionNumber) then return end

    if versionNumber < 10000 then -- before v1.0.0
        widget.sourcePlay = storage.read("source") or nil
        widget.sourceReset = storage.read("reset") or nil
        widget.prefix = storage.read("prefix") or ""
    else
        -- source
        wStorage.read("sourcePlay")
        wStorage.read("sourcePrev")
        wStorage.read("sourceReset")
        wStorage.read("prefix")

        --  widget
        wStorage.read("widgetFontSizeIndex")
        wStorage.read("widgetBgColor")
        if versionNumber >= 10100 then -- v1.1.0 or later
            wStorage.read("actualShow")
            wStorage.read("actualNextShow")
            wStorage.read("actualTxColor")
            wStorage.read("nextTxColor")
            wStorage.read("reducedSortChars")
        else
            wStorage.read("widgetTxColor")
        end

        -- footer
        if versionNumber >= 10100 then -- v1.1.0 or later
            wStorage.read("footerShow")
        end
        wStorage.read("footerTxColor")

        -- title
        wStorage.read("titleShow")
        wStorage.read("titleColorUse")
        wStorage.read("titleBgColor")
        wStorage.read("titleTxColor")
    end

    readSoundFiles(widget)

    debug:info("widget data read successfully")
end

------------------------------------------------------------------------------------------------------------------------
--- Initialize the widget (register it in the system).
local function init()
    wHelper.Debug:new(0, "init")
    system.registerWidget({
        key = WIDGET_KEY,
        name = name,
        wakeup = wakeup,
        create = create,
        paint = paint,
        configure = configure,
        read = read,
        write = write,
        title = false
    })
end

------------------------------------------------------------------------------------------------------------------------
--- Module main
------------------------------------------------------------------------------------------------------------------------

warn("@on")
initLibraries()

return { init = init }
