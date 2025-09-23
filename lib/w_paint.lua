------------------------------------------------------------------------------------------------------------------------
---  Widget Paint Functions
------------------------------------------------------------------------------------------------------------------------
---
---  wPaint library with functions for painting title, footer and center text in the widget:
---
---    init(parameters)
---    textCentered(text, fontSize, verticalAlign, shiftLine)
---    title(titleText, titleBGColor, titleTxColor)
---    footer(footerText, footerBGColor, footerTxColor)
---    widgetText(widgetText, fontSize)
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
--- Modul locals (constants, variables, ...)
------------------------------------------------------------------------------------------------------------------------

-- library structure
local wPaint = {
    titleHeight   = 0, -- height of title box
    footerHeight  = 0, -- height of footer box

    -- Vertical alignment constants for function wPaint.textCentered()
    FREE_ABOVE    = 3, -- pixel free space at above title and/or text
    FREE_BELOW    = 3, -- pixel free space below title and/or text
    LINE_TOP      = 1, -- align top
    LINE_CENTERED = 2, -- align middle (vertical centered)
    LINE_BOTTOM   = 3, -- align bottom

}                      -- library structure

--  required libraries
local helper = {} -- helper library

-- config parameters
local widget = { height = 0, width = 0 } -- widget size structure

-----------------------------------------------------------------------------------------------------------------------
--- Init with actual form and widget
function wPaint.init(parameters)
    widget.height       = parameters.widgetHeight
    widget.width        = parameters.widgetWidth
    wPaint.titleHeight  = 0
    wPaint.footerHeight = 0
end

---------------------------------------------------------------------------------------------------------------------
--- Paint text centered in the widget.
--- Parameters:
---   text         : text to draw (string)
---   fontSize     : font size (FONT_XS, FONT_S, FONT_L, FONT_STD, FONT_XL, FONT_XXL) - default: FONT_STD
---   verticalAlign: vertical alignment (LINE_ABOVE, LINE_CENTERED, LINE_BELOW) - default: LINE_CENTERED
---   shiftLine    : shift line (example: 0 = no shift, -1 = one line up, 0.5 = half line down) - default: 0
--------------------------------------------------------------------------------------------------------------------
function wPaint.textCentered(text, fontSize, verticalAlign, shiftLine)
    local textWidth, textHeight -- text width and height
    local textPosY              -- text y position

    if not helper.existText(text) then return end
    if not fontSize then fontSize = FONT_STD end
    if not verticalAlign then verticalAlign = wPaint.LINE_CENTERED end
    if not shiftLine then shiftLine = 0 end

    lcd.font(fontSize) -- set font size
    _, textHeight = lcd.getTextSize("")

    if verticalAlign == wPaint.LINE_TOP then        -- align top
        textPosY = wPaint.FREE_ABOVE + wPaint.titleHeight
    elseif verticalAlign == wPaint.LINE_BOTTOM then -- align bottom
        textPosY = (widget.height - textHeight - wPaint.FREE_BELOW)
    else                                            -- align centered (default)
        textPosY = wPaint.FREE_ABOVE +
            ((widget.height - wPaint.titleHeight - wPaint.FREE_ABOVE - wPaint.footerHeight) / 2 - textHeight / 2) +
            wPaint.titleHeight
    end

    textPosY = textPosY + (shiftLine * textHeight) -- shift line

    lcd.drawText((widget.width / 2), textPosY, text, TEXT_CENTERED)
end

--------------------------------------------------------------------------------------------------------------------
--- Paint title text.
function wPaint.title(titleText, titleBGColor, titleTxColor)
    local titleHeight

    -- reset title height
    wPaint.titleHeight = 0

    -- calculate title box height an draw box
    lcd.font(FONT_S)
    _, titleHeight = lcd.getTextSize("")
    titleHeight = wPaint.FREE_ABOVE + titleHeight + wPaint.FREE_BELOW

    lcd.color(titleBGColor)
    lcd.drawFilledRectangle(0, 0, widget.width, titleHeight)

    --- draw title text
    lcd.color(titleTxColor)
    wPaint.textCentered(titleText, FONT_S, wPaint.LINE_TOP, 0)

    wPaint.titleHeight = titleHeight
end

--------------------------------------------------------------------------------------------------------------------
--- Paint footer text.
function wPaint.footer(footerText, footerBGColor, footerTxColor)
    local footerHeight

    -- reset footer height
    wPaint.footerHeight = 0

    -- calculate footer box height an draw box
    lcd.font(FONT_XS)
    _, footerHeight = lcd.getTextSize("")
    footerHeight = footerHeight + wPaint.FREE_BELOW

    if footerBGColor ~= nil then
        footerHeight = wPaint.FREE_ABOVE + footerHeight
        lcd.color(footerBGColor)
        lcd.drawFilledRectangle(0, widget.height - footerHeight, widget.width, widget.height)
    end
    --- draw footer text
    lcd.color(footerTxColor)
    wPaint.textCentered(footerText, FONT_XS, wPaint.LINE_BOTTOM, 0)

    wPaint.footerHeight = footerHeight
end

--------------------------------------------------------------------------------------------------------------------
---  wPaint multiline widget text
function wPaint.widgetText(widgetText, fontSize)
    -- local debug = helper.Debug:new(0, "wPaint.widgetText")
    local lines = helper.splitLines(widgetText)
    local n = #lines
    lcd.font(fontSize)
    for i, line in ipairs(lines) do
        local offset = -n / 2 - 0.5 + i
        -- debug:info( string.format("offset: %.2f | line: %s", offset, line))
        wPaint.textCentered(line, fontSize, wPaint.LINE_CENTERED, offset)
    end
end

-----------------------------------------------------------------------------------------------------------------------
--- Library settings and export
return function(parameters)
    helper = parameters.wHelper

    return wPaint
end
