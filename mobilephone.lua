--made by XTZ, CheesyManiac
--i'd like to apologize in advance for any piece of code that mightve gotten mishandled and abused in the following lines

--todo
--broken screen on high gforce, 2 stages, one only glass cracks second one with a broken display, on high gforce toggle drawing the images then decay the opacity over time and at 0% opacity toggle off drawing and reset opacity for the next impact
--map view instead of chat option for singleplayer, zoom setting slider but other than just centered on the player, simple black triangles for player cars, kinda like comfy map but in pure black, since a outline glow is probably too much work use a grey for player cars so they dont blend in with the track or the other way around

--im sure this does something 
ui.setAsynchronousImagesLoading(true)

--adding this so unicode characters like kanji dont break while scrolling
--had to add a -1 to DATA.NOWPLAYING.LENGTH and a +1 to SETTINGS.SPACES because otherwise the function complains about a nil value for j, probably fine the way it is
require 'src.utf8'
function utf8.sub(s,i,j)
    i=utf8.offset(s,i)
    j=utf8.offset(s,j+1)-1
    return string.sub(s,i,j)
end

--setting values
local SETTINGS = ac.storage {
    GLARE = true,
    GLOW = true,
    TRACKTIME = false,
    NOWPLAYING = true,
    SPACES = 5
}

--initial spacing
local SPACETABLE = {}
for i = 0, SETTINGS.SPACES + 1 do
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
        ['PSTR'] = '     PAUSE ll',
        ['isPAUSED'] = false,
        ['SPACES'] = table.concat(SPACETABLE),
        ['FUCK'] = false
    },
    ['CHAT'] = {
        ['SIZE'] = vec2(235, 230),
        ['FLAGS'] = bit.bor(ui.WindowFlags.NoDecoration,ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs)
    }
}

--chat message event handler
local CHATCOUNT = 0
local CHAT = {
}

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

--scrolling text, current implementation breaks some Unicode characters (example: full width Kanji, Katakana, Hiragana)
local SCROLLINTVL
function SCROLLTEXT()
    SCROLLINTVL = setInterval(function()
            local NLETTER = utf8.sub(DATA.NOWPLAYING.SCROLL, DATA.NOWPLAYING.LENGTH-1, DATA.NOWPLAYING.LENGTH-1)
            local NSTRING = utf8.sub(DATA.NOWPLAYING.SCROLL, 1, DATA.NOWPLAYING.LENGTH-1)
            local SCROLLTEXT = NLETTER .. NSTRING
            DATA.NOWPLAYING.SCROLL = SCROLLTEXT
            DATA.NOWPLAYING.DISPLAY = SCROLLTEXT
    end, 0.5, 'ST')
end

--update spacing
function UPDATESPACING()
    SPACETABLE = {}
    for i = 0, SETTINGS.SPACES + 1 do
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

--set and update song info
function UPDATESONG()
    if ac.currentlyPlaying().isPlaying and SETTINGS.NOWPLAYING then
        if DATA.NOWPLAYING.ARTIST ~= ac.currentlyPlaying().artist or DATA.NOWPLAYING.TITLE ~= ac.currentlyPlaying().title or DATA.NOWPLAYING.isPAUSED or DATA.NOWPLAYING.FUCK then
            if not SCROLLINTVL then SCROLLTEXT() end
            DATA.NOWPLAYING.isPAUSED = false
            DATA.NOWPLAYING.FUCK = false
            DATA.NOWPLAYING.ARTIST = ac.currentlyPlaying().artist
            DATA.NOWPLAYING.TITLE = ac.currentlyPlaying().title
            DATA.NOWPLAYING.SCROLL = DATA.NOWPLAYING.ARTIST .. ' - ' .. DATA.NOWPLAYING.TITLE .. DATA.NOWPLAYING.SPACES
            DATA.NOWPLAYING.LENGTH = utf8.len(DATA.NOWPLAYING.SCROLL)
        end
    elseif not ac.currentlyPlaying().isPlaying and not DATA.NOWPLAYING.isPAUSED and SETTINGS.NOWPLAYING then
        if SCROLLINTVL then clearInterval(SCROLLINTVL) SCROLLINTVL = nil end
        DATA.NOWPLAYING.isPAUSED = true
        DATA.NOWPLAYING.LENGTH = utf8.len(DATA.NOWPLAYING.PSTR)
        DATA.NOWPLAYING.DISPLAY = DATA.NOWPLAYING.PSTR
    end
end

--update these every 2s, for realtime checking the time every 2s isnt nessary but with tracktime enabled and a high timeofdaymult a ingame minute could be really fast.
local UPDATEINTVL
function RUNUPDATE()
    UPDATEINTVL = setInterval(function()
        UPDATETIME()
        if SETTINGS.NOWPLAYING then UPDATESONG() end
    end, 2, 'RU')
end

--turn on/off invervals when app gets opened/closed
function onHideWindow()
    clearInterval(UPDATEINTVL)
    clearInterval(SCROLLINTVL)
    UPDATEINTVL = nil
    SCROLLINTVL = nil
end

--this works as intended when reloading the script while already ingame because csp has already started the AcTools.CurrentlyPlaying.exe, when just starting the game that exe might take longer than 2s to start for whatever reason, in those cases it will go from loading to paused. i hate it
function onShowWindow()
    if SETTINGS.NOWPLAYING then 
        DATA.NOWPLAYING.DISPLAY = '    Loading...'
    end
    DATA.NOWPLAYING.FUCK = true
    DATA.NOWPLAYING.isPAUSED = false
    UPDATETIME()
    RUNUPDATE()
end

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
                if SETTINGS.NOWPLAYING then
                    DATA.NOWPLAYING.FUCK = true
                    UPDATESONG()
                else
                    clearInterval(UPDATEINTVL)
                    clearInterval(SCROLLINTVL)
                    UPDATEINTVL = nil
                    SCROLLINTVL = nil
                    RUNUPDATE()
                end
            end
            --change the spacing between the start and end of playing song names
            if SETTINGS.NOWPLAYING then
                ui.text('\t')
                ui.sameLine()
                SETTINGS.SPACES = ui.slider('##', SETTINGS.SPACES, 1,25, 'Spaces' .. ': %.0f')
                if string.len(DATA.NOWPLAYING.SPACES) ~= SETTINGS.SPACES + 1 then
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

--image sizing that is probably not labled correctly, dont care for now
local VECX = vec2(DATA.PADDING.x, DATA.SIZE.y - DATA.SIZE.y - DATA.PADDING.y):scale(DATA.SCALE)
local VECY = vec2(DATA.SIZE.x + DATA.PADDING.x, DATA.SIZE.y - DATA.PADDING.y):scale(DATA.SCALE)

--main app window
local CHATFADETIMER = 0
local CHATINPUTACTIVE = false
function script.windowMain(dt)

    --set fade timer if mouse is not hovering over the app
    local PHONEHOVERED = ui.rectHovered(0, DATA.SIZE)
    if PHONEHOVERED then
        CHATFADETIMER = 1
    elseif CHATFADETIMER > 0 then
        CHATFADETIMER = CHATFADETIMER - dt
    end

    --draw display image
    ui.drawImage(DATA.SRC.DISPLAY, VECX, VECY, true)

    --draw song info if enabled
    if SETTINGS.NOWPLAYING then
        ui.pushDWriteFont(DATA.SRC.FONT)
        ui.setCursor(vec2(92, 72))
        ui.dwriteTextAligned(DATA.NOWPLAYING.DISPLAY, 16, -1, 0, vec2(142,18), false, 0)
        ui.popDWriteFont()
    end

    --draw time
    ui.pushDWriteFont(DATA.SRC.FONT)
    ui.setCursor(vec2(34, 72))
    ui.dwriteTextAligned(DATA.TIME.DISPLAY, 16, 0, 0, vec2(55,17), false, 0)
    ui.popDWriteFont()

    --draw chat messages
    ui.setCursor(vec2(20, 93))
    ui.childWindow("Chatbox", DATA.CHAT.SIZE, DATA.CHAT.FLAGS, function ()
        if CHATCOUNT > 0 then
            for i = 1, CHATCOUNT do
                ui.pushDWriteFont(DATA.SRC.FONT)
                ui.dwriteTextWrapped(CHAT[i][2]..":  "..CHAT[i][1], 16, 0)
                ui.popDWriteFont()
                ui.setScrollHereY(1)
            end
        end
    end)

    --draw glare and glow if enabled
    ui.setCursor(vec2(0, 0))
    ui.childWindow('onTopImages', vec2(300, 415), DATA.CHAT.FLAGS, function ()

        --draw glare image if enabled
        if SETTINGS.GLARE then
            ui.drawImage(DATA.SRC.GLARE, VECX, VECY, true)
        end

        --draw glow image if enabled
        if SETTINGS.GLOW then
            ui.drawImage(DATA.SRC.GLOW, VECX, VECY, true)
        end
    end)
    
    --chat input
    --not affected by glare/glow because childwindows dont have clickthrough so I cant move it "below", not important just a ocd thing
    ui.setCursor(vec2(18, 306))
    ui.childWindow('Chatinput', vec2(298, 32), DATA.CHAT.FLAGS, function ()
        if PHONEHOVERED or CHATINPUTACTIVE then
            local CHATINPUTSTRING, CHATINPUTCHANGE, CHATINPUTENTER = ui.inputText('Type new message...', CHATINPUTSTRING, ui.InputTextFlags.Placeholder)
            CHATINPUTACTIVE = ui.itemActive()
            if CHATINPUTENTER then 
                ac.sendChatMessage(CHATINPUTSTRING)
                CHATINPUTSTRING = ''
                ui.setKeyboardFocusHere(-1)
            end
        elseif CHATFADETIMER > 0 then
            ui.drawRectFilled(vec2(20,8), vec2(213, 30), rgbm(0.1,0.1,0.1,0.66*CHATFADETIMER), 2)
        end
    end)

--draw phone image
    ui.drawImage(DATA.SRC.PHONE, VECX, VECY, true)
end
