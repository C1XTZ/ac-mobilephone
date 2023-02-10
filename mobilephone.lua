--made by XTZ
--i'd like to apologize in advance for any piece of code that mightve gotten mishandled and abused in the following lines

--todo:
--chat
--making the glare adaptive, maybe using the brightness value from CSP and apply that to the glare opacity


--im sure this does something 
ui.setAsynchronousImagesLoading(true)

--setting values
local SETTINGS = ac.storage {
    GLARE = false,
    GLOW = false,
    TRACKTIME = false,
    NOWPLAYING = true
}

--we do a minuscule amount of declaring. do i need this much? probably not but i like the way it makes me feel
local PHONEDATA = {
    ['SIZE'] = vec2(250, 400),
    ['PADDING'] = vec2(10, -22),
    ['SCALE'] = 1,
    ['SRC'] = {
        ['DISPLAY'] = './src/DISPLAY.png',
        ['PHONE'] = './src/PHONE.png',
        ['GLARE'] = './src/GLARE.png',
        ['GLOW'] = './src/GLOW.png',
        ['FONT'] = ui.DWriteFont('NOKIA CELLPHONE FC SMALL', './src')
    },
    ['TIME'] = {
        ['LOCAL'] = os.date("%H:%M"),
        ['TRACK'] = string.format("%02d",ac.getSim().timeHours)..":"..string.format("%02d",ac.getSim().timeMinutes),
        ['DISPLAY'] = ''
    },
    ['NOWPLAYING'] = {
        ['ARTIST'] = '',
        ['TITLE'] = '',
        ['SONG'] = '',
        ['LENGTH'] = 0
    }
}

--set time, update time once, then repeat ever 2s
function UPDATETIME()
    if SETTINGS.TRACKTIME then
        PHONEDATA.TIME.TRACK = string.format("%02d",ac.getSim().timeHours)..":"..string.format("%02d",ac.getSim().timeMinutes)
        PHONEDATA.TIME.DISPLAY = PHONEDATA.TIME.TRACK
    else
        PHONEDATA.TIME.LOCAL = os.date("%H:%M")
        PHONEDATA.TIME.DISPLAY = PHONEDATA.TIME.LOCAL
    end
end

UPDATETIME()

setInterval(function()
UPDATETIME()
end, 2)

--set currently playing if enabled, scrolling text shenanigans
setInterval(function()
    if ac.currentlyPlaying().isPlaying and SETTINGS.NOWPLAYING then
        if PHONEDATA.NOWPLAYING.ARTIST ~= ac.currentlyPlaying().artist or PHONEDATA.NOWPLAYING.TITLE ~= ac.currentlyPlaying().title then
            PHONEDATA.NOWPLAYING.ARTIST = ac.currentlyPlaying().artist
            PHONEDATA.NOWPLAYING.TITLE = ac.currentlyPlaying().title
            PHONEDATA.NOWPLAYING.SONG = PHONEDATA.NOWPLAYING.ARTIST .. ' - ' .. PHONEDATA.NOWPLAYING.TITLE .. '     '
            PHONEDATA.NOWPLAYING.LENGTH = string.len(PHONEDATA.NOWPLAYING.SONG)
            TOSCROLL = PHONEDATA.NOWPLAYING.SONG
            --todo: probably good idea to stop this interval if nowplaying gets turned off
            setInterval(function()
                local NLETTER = string.sub(TOSCROLL, PHONEDATA.NOWPLAYING.LENGTH, PHONEDATA.NOWPLAYING.LENGTH)
                local NSTRING = string.sub(TOSCROLL, 1, PHONEDATA.NOWPLAYING.LENGTH - 1)
                local SCROLLTEXT = NLETTER .. NSTRING
                TOSCROLL = SCROLLTEXT
                PHONEDATA.NOWPLAYING.SONG = SCROLLTEXT
                end, 0.5)
        end
    end
end, 2)

--settings window
function script.windowMainSettings(dt)
    ui.tabBar('TabBar', function()
        ui.tabItem('Settings', function()
            if ui.checkbox("Display Glare", SETTINGS.GLARE) then
                SETTINGS.GLARE = not SETTINGS.GLARE
            end
            if ui.checkbox("Display Glow", SETTINGS.GLOW) then
                SETTINGS.GLOW = not SETTINGS.GLOW
            end
            if ui.checkbox("Display Current Song", SETTINGS.NOWPLAYING) then
                SETTINGS.NOWPLAYING = not SETTINGS.NOWPLAYING
            end
            if ui.checkbox("Display Track Time", SETTINGS.TRACKTIME) then
                SETTINGS.TRACKTIME = not SETTINGS.TRACKTIME
                UPDATETIME() --not needed technically but looks more responsive
            end
        end)
    end)
end

--main app window
function script.windowMain(dt)
--draw display image
    ui.drawImage(PHONEDATA.SRC.DISPLAY, vec2(PHONEDATA.PADDING.x, PHONEDATA.SIZE.y - PHONEDATA.SIZE.y - PHONEDATA.PADDING.y - 2):scale(PHONEDATA.SCALE), vec2(PHONEDATA.SIZE.x + PHONEDATA.PADDING.x, PHONEDATA.SIZE.y - PHONEDATA.PADDING.y + 2):scale(PHONEDATA.SCALE), true)

--draw now playing song if enabled, or paused text if paused but enabled
    if ac.currentlyPlaying().isPlaying and SETTINGS.NOWPLAYING then
        ui.pushDWriteFont(PHONEDATA.SRC.FONT)
        ui.setCursor(vec2(92, 69))
        ui.dwriteText(PHONEDATA.NOWPLAYING.SONG, 16, 0)
        ui.popDWriteFont()
    elseif not ac.currentlyPlaying().isPaused and SETTINGS.NOWPLAYING then
        ui.pushDWriteFont(PHONEDATA.SRC.FONT)
        ui.setCursor(vec2(92, 69))
        ui.dwriteText('     PAUSE ll', 16, 0)
        ui.popDWriteFont()
    end

--draw time text
    ui.pushDWriteFont(PHONEDATA.SRC.FONT)
    ui.setCursor(vec2(35, 69))
    ui.dwriteText(PHONEDATA.TIME.DISPLAY, 16, 0)
    ui.popDWriteFont()

--draw phone image
    ui.drawImage(PHONEDATA.SRC.PHONE, vec2(PHONEDATA.PADDING.x, PHONEDATA.SIZE.y - PHONEDATA.SIZE.y - PHONEDATA.PADDING.y):scale(PHONEDATA.SCALE), vec2(PHONEDATA.SIZE.x + PHONEDATA.PADDING.x, PHONEDATA.SIZE.y - PHONEDATA.PADDING.y):scale(PHONEDATA.SCALE), true)

--draw glare image if enabled
    if SETTINGS.GLARE then
        ui.drawImage(PHONEDATA.SRC.GLARE, vec2(PHONEDATA.PADDING.x, PHONEDATA.SIZE.y - 1 - PHONEDATA.SIZE.y - 1 - PHONEDATA.PADDING.y):scale(PHONEDATA.SCALE), vec2(PHONEDATA.SIZE.x + PHONEDATA.PADDING.x, PHONEDATA.SIZE.y + 2 - PHONEDATA.PADDING.y + 1):scale(PHONEDATA.SCALE), true)
    end

--draw glow image if enabled
    if SETTINGS.GLOW then
        ui.drawImage(PHONEDATA.SRC.GLOW, vec2(PHONEDATA.PADDING.x, PHONEDATA.SIZE.y - PHONEDATA.SIZE.y - PHONEDATA.PADDING.y):scale(PHONEDATA.SCALE), vec2(PHONEDATA.SIZE.x + PHONEDATA.PADDING.x, PHONEDATA.SIZE.y - PHONEDATA.PADDING.y):scale(PHONEDATA.SCALE), true)
    end
end
