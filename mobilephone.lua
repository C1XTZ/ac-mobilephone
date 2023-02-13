--made by XTZ, CheesyManiac
--i'd like to apologize in advance for any piece of code that mightve gotten mishandled and abused in the following lines

--ideas
--map view instead of chat
--broken screen on high gforce, 2 stages, one only glass cracks second one with a broken display

--im sure this does something 
ui.setAsynchronousImagesLoading(true)

--setting values
local SETTINGS = ac.storage {
    GLARE = false,
    GLOW = false,
    TRACKTIME = false,
    NOWPLAYING = true,
    SPACES = 5
}

--initial spacing
local SPACETABLE = {}
for i = 0, SETTINGS.SPACES do
    SPACETABLE[i] = ' '
end

--we do a minuscule amount of declaring. do i need all of this? probably not but i like the way it makes me feel
local DATA = {
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
        ['LOCAL'] = '',
        ['TRACK'] = '',
        ['DISPLAY'] = ''
    },
    ['NOWPLAYING'] = {
        ['ARTIST'] = '',
        ['TITLE'] = '',
        ['SCROLL'] = '',
        ['DISPLAY'] = '',
        ['LENGTH'] = 0,
        ['PSTR'] = '    PAUSE ll     ',
        ['isPAUSED'] = false,
        ['SPACES'] = table.concat(SPACETABLE),
        ['FUCK'] = false
    },
    ['CHAT'] = {
        ['SIZE'] = vec2(210, 240),
        ['FLAGS'] = bit.bor(ui.WindowFlags.NoDecoration,ui.WindowFlags.NoBackground, ui.WindowFlags.NoNavFocus)
    }
}

local CHATCOUNT = 0
local CHAT = {
}

--chat message event handler
ac.onChatMessage(function (message, senderCarIndex, senderSessionID)
    CHATCOUNT = CHATCOUNT + 1

--get message content and sender
    if ac.getDriverName(senderCarIndex) then
    CHAT[CHATCOUNT] = {message, ac.getDriverName(senderCarIndex)}
    else CHAT[CHATCOUNT] = {message, 'Server'} end

--only keep the 8 latest messages
    if table.getn(CHAT) > 8 then
    table.remove(CHAT,1)
    CHATCOUNT = table.getn(CHAT)
    end

end)

--update spacing
function UPDATESPACING()
    SPACETABLE = {}
    for i = 0, SETTINGS.SPACES do
        SPACETABLE[i] = ' '
    end
    DATA.NOWPLAYING.SPACES = table.concat(SPACETABLE)
    DATA.NOWPLAYING.FUCK = true
end

--set and update time
function UPDATETIME()
    if SETTINGS.TRACKTIME then
        DATA.TIME.TRACK = string.format("%02d",ac.getSim().timeHours)..":"..string.format("%02d",ac.getSim().timeMinutes)
        DATA.TIME.DISPLAY = DATA.TIME.TRACK
    else
        DATA.TIME.LOCAL = os.date("%H:%M")
        DATA.TIME.DISPLAY = DATA.TIME.LOCAL
    end
end

--set and update Song
function UPDATESONG()
    if ac.currentlyPlaying().isPlaying and SETTINGS.NOWPLAYING then
        if DATA.NOWPLAYING.ARTIST ~= ac.currentlyPlaying().artist or DATA.NOWPLAYING.TITLE ~= ac.currentlyPlaying().title or DATA.NOWPLAYING.isPAUSED or DATA.NOWPLAYING.FUCK then
            DATA.NOWPLAYING.isPAUSED = false
            DATA.NOWPLAYING.FUCK = false
            DATA.NOWPLAYING.ARTIST = ac.currentlyPlaying().artist
            DATA.NOWPLAYING.TITLE = ac.currentlyPlaying().title
            DATA.NOWPLAYING.SCROLL = DATA.NOWPLAYING.ARTIST .. ' - ' .. DATA.NOWPLAYING.TITLE .. DATA.NOWPLAYING.SPACES
            DATA.NOWPLAYING.LENGTH = string.len(DATA.NOWPLAYING.SCROLL)
        end
    elseif not ac.currentlyPlaying().isPlaying and not DATA.NOWPLAYING.isPAUSED and SETTINGS.NOWPLAYING then
        DATA.NOWPLAYING.isPAUSED = true
        DATA.NOWPLAYING.SCROLL = DATA.NOWPLAYING.PSTR
        DATA.NOWPLAYING.LENGTH = string.len(DATA.NOWPLAYING.PSTR)
    end
end

--update once for good measure
UPDATETIME()
UPDATESONG()

setInterval(function()
UPDATETIME()
UPDATESONG()
end, 2)

--scrolling text shenanigans, will currently always run and scroll the pause text even if its disabled
setInterval(function()
        local NLETTER = string.sub(DATA.NOWPLAYING.SCROLL, DATA.NOWPLAYING.LENGTH, DATA.NOWPLAYING.LENGTH)
        local NSTRING = string.sub(DATA.NOWPLAYING.SCROLL, 1, DATA.NOWPLAYING.LENGTH)
        local SCROLLTEXT = NLETTER .. NSTRING
        DATA.NOWPLAYING.SCROLL = SCROLLTEXT
        DATA.NOWPLAYING.DISPLAY = SCROLLTEXT
end, 0.5)

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
                UPDATESONG()
            end
            --change the spacing between the start and end of playing song names
            if SETTINGS.NOWPLAYING then
                SETTINGS.SPACES = ui.slider('##', SETTINGS.SPACES, 1,25, 'Spaces' .. ': %.0f')
                if string.len(DATA.NOWPLAYING.SPACES) ~= SETTINGS.SPACES then
                    UPDATESPACING()
                end
            end
            if ui.checkbox("Display Track Time", SETTINGS.TRACKTIME) then
                SETTINGS.TRACKTIME = not SETTINGS.TRACKTIME
                UPDATETIME()
            end
        end)
    end)
end

--probably not labled correctly, dont care for now
local VECX = vec2(DATA.PADDING.x, DATA.SIZE.y - DATA.SIZE.y - DATA.PADDING.y):scale(DATA.SCALE)
local VECY = vec2(DATA.SIZE.x + DATA.PADDING.x, DATA.SIZE.y - DATA.PADDING.y):scale(DATA.SCALE)

--main app window
function script.windowMain(dt)

--draw display image
    ui.drawImage(DATA.SRC.DISPLAY, VECX, VECY, true)

--draw song info if enabled
if SETTINGS.NOWPLAYING then
    ui.pushDWriteFont(DATA.SRC.FONT)
    ui.setCursor(vec2(92, 69))
    ui.dwriteText(DATA.NOWPLAYING.DISPLAY, 16, 0)
    ui.popDWriteFont()
end

--draw time text
    ui.pushDWriteFont(DATA.SRC.FONT)
    ui.setCursor(vec2(35, 69))
    ui.dwriteText(DATA.TIME.DISPLAY, 16, 0)
    ui.popDWriteFont()

--draw the chat text - text is above the glare image for some reason
    ui.setCursor(vec2(35, 95))    
    ui.childWindow("Chatbox", DATA.CHAT.SIZE, DATA.CHAT.FLAGS, function ()
        if CHATCOUNT > 0 then
            for i = 1, CHATCOUNT do
                ui.pushDWriteFont(DATA.SRC.FONT)
                ui.dwriteTextWrapped(CHAT[i][2]..":  "..CHAT[i][1], 16,0)
                ui.popDWriteFont()
                ui.setScrollHereY(1)
            end
        end
end)

--draw phone image
    ui.drawImage(DATA.SRC.PHONE, VECX, VECY, true)

--draw glare image if enabled
    if SETTINGS.GLARE then
        ui.drawImage(DATA.SRC.GLARE, VECX, VECY, true)
    end

--draw glow image if enabled
    if SETTINGS.GLOW then
        ui.drawImage(DATA.SRC.GLOW, VECX, VECY, true)
    end
end
