--made by XTZ, CheesyManiac

--xtz: im sure this does something
--che: you dont really need this since you're loading only a few images at the start
ui.setAsynchronousImagesLoading(true)

--adding this so unicode characters like kanji dont break while scrolling
--xtz: had to add a -1 to nowplaying.length and a +1 to settings.spaces because otherwise the function complains about a nil value for j and im too lazy to fix this
require 'src.utf8'
function utf8.sub(s, i, j)
    i = utf8.offset(s, i)
    j = utf8.offset(s, j + 1) - 1
    return string.sub(s, i, j)
end

--setting values
local settings = ac.storage {
    glare = true,
    glow = true,
    tracktime = false,
    nowplaying = true,
    spaces = 5,
    scrollspeed = 2,
    damage = false,
    damageduration = 5,
    fadeduration = 3,
    crackforce = 15,
    breakforce = 30,
    chatmove = true,
    chattimer = 15,
    chatmovespeed = 4,
    chatfontsize = 16,
    chatbold = true,
    customcolor = false,
    colorR = 0.640,
    colorG = 1.000,
    colorB = 0.710,
    hideKB = true,
    hideAnnoy = true,
    notifsound = false,
    notifvol = 5,
    joinnotif = true,
    joinnotifsound = false,
    joinnotiffriends = true,
    joinnotifsoundfriends = false,
}

--initial spacing
local spacetable = {}
for i = 0, settings.spaces + 1 do
    spacetable[i] = ' '
end

--app data
local app = {
    ['size'] = vec2(265, 435),
    ['padding'] = vec2(10, -22),
    ['scale'] = 1,
}

--phone data
local phone = {
    ['src'] = {
        ['display'] = './src/img/display.png',
        ['phone'] = './src/img/phone.png',
        ['glare'] = './src/img/glare.png',
        ['glow'] = './src/img/glow.png',
        ['cracked'] = './src/img/cracked.png',
        ['destroyed'] = './src/img/destroyed.png',
        ['font'] = ui.DWriteFont('NOKIA CELLPHONE FC SMALL', './src'),
        ['fontBold'] = ui.DWriteFont('NOKIA CELLPHONE FC SMALL', './src'):weight(ui.DWriteFont.Weight.SemiBold),
    },
    ['size'] = vec2(245, 409),
    ['color'] = rgbm(0.64, 1.0, 0.71, 1),
}

local chat = {
    ['size'] = vec2(245, 294),
    ['messages'] = {},
    ['messagecount'] = 0,
    ['activeinput'] = false,
    ['inputfade'] = 0,
}

local movement = {
    ['maxdistance'] = 357,
    ['timer'] = settings.chattimer,
    ['down'] = true,
    ['up'] = false,
    ['distance'] = 0,
    ['smooth'] = 0,
}

local time = {
    ['player'] = '',
    ['track'] = '',
    ['final'] = '',
}

local nowplaying = {
    ['artist'] = '',
    ['title'] = '',
    ['scroll'] = '',
    ['final'] = '',
    ['length'] = 0,
    ['pstr'] = '     PAUSE ll',
    ['isPaused'] = false,
    ['spaces'] = table.concat(spacetable),
    ['FUCK'] = false,
}

local notification = {
    ['sound'] = ui.MediaPlayer():setSource('notif.mp3'):setVolume(0.01 * settings.notifvol):setAutoPlay(false):setLooping(false),
    ['allow'] = false,
}

--car data
local car = {
    ['player'] = ac.getCar(0),
    ['damage'] = {
        ['state'] = 0,
        ['duration'] = 0,
        ['fadetimer'] = settings.fadeduration,
        ['glow'] = 1,
    },
    ['forces'] = {
        ['left'] = 0,
        ['right'] = 0,
        ['front'] = 0,
        ['back'] = 0,
        ['total'] = {},
    },
}

--flags
local flags = {
    ['window'] = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs),
    ['color'] = bit.bor(ui.ColorPickerFlags.NoAlpha, ui.ColorPickerFlags.NoSidePreview, ui.ColorPickerFlags.NoDragDrop, ui.ColorPickerFlags.NoLabel, ui.ColorPickerFlags.DisplayRGB),
}

--emojis
local Emojis = {
    ["txt"] = { "%(angel%)", "%(angry%)", "%(anguish%)", "%(clown%)", "%(confused%)", "%(cool%)", "%(crying%)", "%(curious%)", "%(dead%)", "%(devil%)", "%(dislike%)", "%(dissapointed%)", "%(down%)", "%(flipped%)", "%(friendly%)", "%(ghost%)", "%(greedy%)", "%(grimacing%)", "%(grinning%)", "%(heart%)", "%(injury%)", "%(inlove%)", "%(joy%)", "%(kiss%)", "%(laughing%)", "%(like%)", "%(mad%)", "%(muted%)", "%(nerd%)", "%(neutral%)", "%(ninja%)", "%(poo%)", "%(puking%)", "%(sad%)", "%(scared%)", "%(shocked%)", "%(sick%)", "%(silent%)", "%(sleeping%)", "%(smiling%)", "%(sweating%)", "%(tired%)", "%(tongue%)", "%(up%)", "%(vomiting%)", "%(wink%)", "%(yeehaw%)", "%(yeehawnt%)" },
    ["uni"] = { "😇", "😤", "😫", "🤡", "😕", "😎", "😭", "🧐", "😵", "😈", "👎", "😓", "👇", "🙃", "😊", "👻", "🤑", "😬", "😀", "❤️", "🤕", "😍", "😂", "😘", "😆", "👍", "😡", "🤐", "🤓", "😐", "🤫", "💩", "🤢", "☹️", "😖", "😲", "😷", "🤐", "😴", "🙂", "😓", "😔", "😋", "☝️", "🤮", "😉", "🤠", "🤠" }
}

--use saved color instead if enabled
if settings.customcolor then
    phone.color = rgbm(settings.colorR, settings.colorG, settings.colorB, 1)
end

function checkIfFriend(carIndex)
    if ac.getPatchVersionCode() > 2144 then
        return ac.DriverTags(ac.getDriverName(carIndex)).friend
    else
        return ac.isTaggedAsFriend(ac.getDriverName(carIndex))
    end
end

--chat message event handler
ac.onChatMessage(function(message, senderCarIndex, senderSessionID)
    chat.messagecount = chat.messagecount + 1
    --emoji parsing
    for i = 1, table.getn(Emojis.txt) do
        if string.find(message, Emojis.txt[i]) then
            message = string.gsub(message, Emojis.txt[i], Emojis.uni[i])
        end
    end
    local hideMessage = false
    --check if the message came from a player or a server
    if senderCarIndex > -1 then
        --allow notification to play if enabled and player is mentioned
        if settings.notifsound and string.find(string.lower(message), '%f[%a_]' .. string.lower(ac.getDriverName(0)) .. '%f[%A_]') then notification.allow = true end
        --player messages just get sent
        chat.messages[chat.messagecount] = { message, ac.getDriverName(senderCarIndex) .. ': ', '' }
        --insert * if messsage sender is tagged as friend
        if checkIfFriend(senderCarIndex) then
            chat.messages[chat.messagecount][3] = '* '
        end
        --find and hide annoying app messages otherwise continue on
        if settings.hideAnnoy then
            local annoying = 'RP: PLP: ACP: D&O DRIFT-STRUCTION OSRW'
            for msg in string.gmatch(annoying, '%S+') do
                if string.find(string.lower(message), '^(' .. string.lower(msg) .. ')') then
                    hideMessage = true
                end
            end
        end
        --if message is not hidden and moving is enabled, start the countdown to move
        if not hideMessage then
            if settings.chatmove then
                movement.timer = settings.chattimer
                movement.up = true
            end
        else --remove message
            chat.messages[chat.messagecount] = nil
            chat.messagecount = chat.messagecount - 1
        end
    else
        --check message content for these keywords if hide kick/bans is enabled
        if settings.hideKB then
            local search = 'kicked banned checksums'
            for msg in string.gmatch(search, '%S+') do
                --hide the message if a keyword has been found in the message and doesnt contain 'you' so it doesnt hide server messages targeted at the player
                if string.find(string.lower(message), '(' .. string.lower(msg) .. ')') then
                    if not string.find(string.lower(message), '%f[%a_](you)%f[%A_]') then
                        hideMessage = true
                    else
                        --play notification sound when server message is targeted at the player
                        notification.allow = true
                    end
                end
            end
        end
        --send server message without a username if its not supposed to be hidden, otherwise remove it from the messagecount
        if not hideMessage then
            if settings.chatmove then
                movement.timer = settings.chattimer
                movement.up = true
            end
            chat.messages[chat.messagecount] = { message, '', '' }
        else
            chat.messages[chat.messagecount] = nil
            chat.messagecount = chat.messagecount - 1
        end
        --only keep the 25 latest messages
        if table.getn(chat.messages) > 25 then
            table.remove(chat.messages, 1)
            chat.messagecount = table.getn(chat.messages)
        end
    end
end)

--display join/leave messages
if settings.joinnotif then
    ac.onClientConnected(function(connectedCarIndex)
        chat.messagecount = chat.messagecount + 1
        chat.messages[chat.messagecount] = { 'joined the Server', ac.getDriverName(connectedCarIndex) .. ' ', '' }
        if settings.joinnotiffriends and not checkIfFriend(connectedCarIndex) then
            chat.messages[chat.messagecount] = nil
            chat.messagecount = chat.messagecount - 1
        else
            if checkIfFriend(connectedCarIndex) then
                chat.messages[chat.messagecount][3] = '* '

                if settings.joinnotifsound then
                    notification.allow = true
                end
            end
            if settings.chatmove then
                movement.timer = settings.chattimer
                movement.up = true
            end

            if settings.joinnotifsound and not settings.joinnotifsoundfriends then
                notification.allow = true
            end
        end
    end)

    ac.onClientDisconnected(function(connectedCarIndex)
        chat.messagecount = chat.messagecount + 1
        chat.messages[chat.messagecount] = { 'left the Server', ac.getDriverName(connectedCarIndex) .. ' ', '' }
        if settings.joinnotiffriends and not checkIfFriend(connectedCarIndex) then
            chat.messages[chat.messagecount] = nil
            chat.messagecount = chat.messagecount - 1
        else
            if checkIfFriend(connectedCarIndex) then
                chat.messages[chat.messagecount][3] = '* '

                if settings.joinnotifsound then
                    notification.allow = true
                end
            end
            if settings.chatmove then
                movement.timer = settings.chattimer
                movement.up = true
            end
            if settings.joinnotifsound and not settings.joinnotifsoundfriends then
                notification.allow = true
            end
        end
    end)
end

--scrolling text
local scrlintvl
function scrollText()
    scrlintvl = setInterval(function()
        local nletter = utf8.sub(nowplaying.scroll, nowplaying.length - 1, nowplaying.length - 1)
        local nstring = utf8.sub(nowplaying.scroll, 1, nowplaying.length - 1)
        local ntext = nletter .. nstring
        nowplaying.scroll = ntext
        nowplaying.final = ntext
    end, 1 / settings.scrollspeed, 'ST')
end

--update spacing
function UpdateSpacing()
    spacetable = {}
    for i = 0, settings.spaces + 1 do
        spacetable[i] = ' '
    end
    nowplaying.spaces = table.concat(spacetable)
    nowplaying.FUCK = true
end

--set and update song info
function UpdateSong()
    if ac.currentlyPlaying().isPlaying and settings.nowplaying then
        if nowplaying.artist ~= ac.currentlyPlaying().artist or nowplaying.title ~= ac.currentlyPlaying().title or nowplaying.isPaused or nowplaying.FUCK then
            if not scrlintvl then scrollText() end
            nowplaying.isPaused = false
            nowplaying.FUCK = false
            nowplaying.artist = ac.currentlyPlaying().artist
            nowplaying.title = ac.currentlyPlaying().title
            --tested a song without metadata tags on Groove Music and Dopamine, both set artist to Unknown Artist and used the filename (artist - songname.mp3) as the title
            --might not work the same on every single music player but this should cover most of them
            if string.lower(nowplaying.artist) == 'unknown artist' then
                nowplaying.scroll = nowplaying.title .. nowplaying.spaces
            else
                nowplaying.scroll = nowplaying.artist .. ' - ' .. nowplaying.title .. nowplaying.spaces
            end
            --adding some filler spaces since strings like 'ABC - DEF' are too short by themself so they would get cut by the scrolling before reaching the right edge
            if utf8.len(nowplaying.scroll) < 19 then
                local fillSpaces = {}
                for i = 0, 19 - utf8.len(nowplaying.scroll) do
                    fillSpaces[i] = ' '
                end
                nowplaying.scroll = nowplaying.scroll .. table.concat(fillSpaces)
            end
            nowplaying.length = utf8.len(nowplaying.scroll)
        end
    elseif not ac.currentlyPlaying().isPlaying and not nowplaying.isPaused and settings.nowplaying and nowplaying.artist ~= '' then
        if scrlintvl then
            clearInterval(scrlintvl)
            scrlintvl = nil
        end
        nowplaying.isPaused = true
        nowplaying.length = utf8.len(nowplaying.pstr)
        nowplaying.final = nowplaying.pstr
    end
end

--set and update time
function UpdateTime()
    if settings.tracktime then
        time.track = string.format('%02d', ac.getSim().timeHours) .. ':' .. string.format('%02d', ac.getSim().timeMinutes)
        time.final = time.track
    else
        time.player = os.date('%H:%M')
        time.final = time.player
    end
end

--update these every 2s, should be good enough
local updtintvl
function RunUpdate()
    updtintvl = setInterval(function()
        UpdateTime()
        if settings.nowplaying then UpdateSong() end
    end, 2, 'RU')
end

--(re)start intervals and show loading nowplaying until a song is actually playing and not paused
function onShowWindow()
    if settings.nowplaying then nowplaying.final = '     Loading...' end
    nowplaying.FUCK = true
    nowplaying.isPaused = false
    UpdateTime()
    RunUpdate()
end

function script.windowMainSettings(dt)
    ui.tabBar('TabBar', function()
        --display settings
        ui.tabItem('Display', function()
            --display and glow color
            if ui.checkbox('Custom Color', settings.customcolor) then
                settings.customcolor = not settings.customcolor
                --reset to default color if disabled
                if not settings.customcolor then
                    phone.color = rgbm(0.640, 1.000, 0.710, 1)
                end
            end
            --load saved colors if enabled and display colorpicker and save the new color
            if settings.customcolor then
                ui.text('\t')
                ui.sameLine()
                phone.color = rgbm(settings.colorR, settings.colorG, settings.colorB, 1)
                colorChange = ui.colorPicker('Display Color Picker', phone.color, flags.color)
                if colorChange then
                    settings.colorR, settings.colorG, settings.colorB = phone.color.r, phone.color.g, phone.color.b
                end
            end

            --display glare toggle
            if ui.checkbox('Screen Glare', settings.glare) then settings.glare = not settings.glare end

            --display glow toggle
            if ui.checkbox('Screen Glow', settings.glow) then settings.glow = not settings.glow end

            --nowplaying toggle
            if ui.checkbox('Show Current Song', settings.nowplaying) then
                settings.nowplaying = not settings.nowplaying
                if settings.nowplaying then
                    nowplaying.FUCK = true
                    UpdateSong()
                else
                    clearInterval(updtintvl)
                    clearInterval(scrlintvl)
                    updtintvl = nil
                    scrlintvl = nil
                    RunUpdate()
                end
            end

            --change the spacing between the start and end of playing song names
            if settings.nowplaying then
                ui.text('\t')
                ui.sameLine()
                settings.spaces = ui.slider('##Spaces', settings.spaces, 1, 25, 'Spaces: ' .. '%.0f')
                if string.len(nowplaying.spaces) ~= settings.spaces + 1 then
                    UpdateSpacing()
                end
                --change the speed at which the songtext scrolls across
                ui.text('\t')
                ui.sameLine()
                settings.scrollspeed, speedChange = ui.slider('##ScrollSpeed', settings.scrollspeed, 0, 15, 'Scroll Speed: ' .. '%.1f')
                if speedChange and not nowplaying.isPaused then
                    clearInterval(scrlintvl)
                    scrlintvl = nil
                    scrollText()
                end
            end

            --display tracktime
            if ui.checkbox('Use Track Time', settings.tracktime) then
                settings.tracktime = not settings.tracktime
                UpdateTime()
            end

            --display damage toggle
            if ui.checkbox('Screen Damage', settings.damage) then
                settings.damage = not settings.damage
                if not settings.damage then car.damage.glow = 1 end
            end

            --display duration and forces sliders
            if settings.damage then
                ui.text('\t')
                ui.sameLine()
                settings.damageduration, damageChange = ui.slider('##DamageDuration', settings.damageduration, 1, 60, 'Duration: ' .. '%.1f seconds')
                if damageChange then car.damage.duration = settings.damageduration end
                ui.text('\t')
                ui.sameLine()
                settings.fadeduration, fadeChange = ui.slider('##FadeDuration', settings.fadeduration, 1, 60, 'Fade out: ' .. '%.1f seconds')
                if fadeChange then car.damage.fadetimer = settings.fadeduration end
                ui.text('\t')
                ui.sameLine()
                settings.crackforce = ui.slider('##CrackForce', settings.crackforce, 5, 50, 'Crack Force: ' .. '%.0f')
                ui.text('\t')
                ui.sameLine()
                settings.breakforce = ui.slider('##BreakForce', settings.breakforce, 10, 100, 'Break Force: ' .. '%.0f')
            end
        end)

        --chat settings
        ui.tabItem('Chat', function()
            --chat fontsize
            ui.text('\t')
            ui.sameLine()
            settings.chatfontsize = ui.slider('##ChatFontSize', settings.chatfontsize, 6, 36, 'Chat Fontsize: ' .. '%.0f')

            if ui.checkbox('Show Join/Leave Messages', settings.joinnotif) then settings.joinnotif = not settings.joinnotif end
            if settings.joinnotif then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Friends Only', settings.joinnotiffriends) then settings.joinnotiffriends = not settings.joinnotiffriends end
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Play Notification Sound', settings.joinnotifsound) then settings.joinnotifsound = not settings.joinnotifsound end
                if settings.joinnotifsound then
                    ui.text('\t')
                    ui.sameLine()
                    ui.text('\t')
                    ui.sameLine()
                    if ui.checkbox('Only for Friends', settings.joinnotifsoundfriends) then settings.joinnotifsoundfriends = not settings.joinnotifsoundfriends end
                end
            end

            --notification sound when player is mentioned in a message
            if ui.checkbox('Play Notification Sound when Mentioned', settings.notifsound) then settings.notifsound = not settings.notifsound end
            if settings.notifsound or settings.joinnotifsound then
                ui.text('\t')
                ui.sameLine()
                settings.notifvol, volumeChange = ui.slider('##SoundVolume', settings.notifvol, 1, 100, 'Sound Volume: ' .. '%.0f' .. '%')
                if volumeChange then notification.sound:setVolume(0.01 * settings.notifvol):play() end
            end

            --make latest message bold
            if ui.checkbox('Highlight Latest Message', settings.chatbold) then settings.chatbold = not settings.chatbold end

            --kick ban hidding
            if ui.checkbox('Hide Kick and Ban Messages', settings.hideKB) then settings.hideKB = not settings.hideKB end

            --real penalty and pit lane penalty message hiding?
            if ui.checkbox('Hide Annoying App Messages', settings.hideAnnoy) then settings.hideAnnoy = not settings.hideAnnoy end

            --move phone down after chat inactivity
            if ui.checkbox('Chat Inactivity Minimizes Phone', settings.chatmove) then
                settings.chatmove = not settings.chatmove
                if settings.chatmove then
                    movement.up = false
                    movement.timer = settings.chattimer
                end
            end
            --inactivity and movespeed sliders
            if settings.chatmove then
                ui.text('\t')
                ui.sameLine()
                settings.chattimer, chatinactiveChange = ui.slider('##ChatTimer', settings.chattimer, 1, 120, 'Inactivity: ' .. '%.0f seconds')
                if chatinactiveChange then movement.timer = settings.chattimer end
                ui.text('\t')
                ui.sameLine()
                settings.chatmovespeed = ui.slider('##ChatMoveSpeed', settings.chatmovespeed, 1, 20, 'Speed: ' .. '%.0f')
            end
        end)
    end)
end

--image size vectors
local VecTR = vec2(app.padding.x, phone.size.y - phone.size.y - app.padding.y)
local VecBL = vec2(phone.size.x + app.padding.x, phone.size.y - app.padding.y)
function script.windowMain(dt)
    --move the phone up/down depending on chat activity
    if settings.chatmove then
        --countdown until moving phone
        if movement.timer > 0 and movement.distance == 0 then
            movement.timer = movement.timer - dt
            movement.down = true
        end
        --move the phone but now with smootherstep
        if movement.timer <= 0 and movement.down then
            movement.down = true
            movement.distance = math.floor(movement.distance + dt * 100 * settings.chatmovespeed)
            movement.smooth = math.floor(math.smootherstep(math.lerpInvSat(movement.distance, 0, movement.maxdistance)) * movement.maxdistance)
        elseif movement.timer > 0 and movement.up then
            movement.distance = math.floor(movement.distance - dt * 100 * settings.chatmovespeed)
            movement.smooth = math.floor(math.smootherstep(math.lerpInvSat(movement.distance, 0, movement.maxdistance)) * movement.maxdistance)
            --che: the entire thing doesnt work if I don't make it a new variable. I have idea why and I am far too tired to sit and work it out for another 2 hours
            --xtz: it seems to work, so im not touching it
        end
        --stop the phone from moving further if its in position
        if movement.distance > movement.maxdistance then
            movement.distance = movement.maxdistance
            movement.down = false
        elseif movement.distance < 0 then
            movement.distance = 0
            movement.up = false
            movement.timer = settings.chattimer
        end
        --if the settings gets disabled, set the phone to be placed correctly
    elseif not settings.chatmove and movement.distance ~= 0 then
        movement.distance = 0
        movement.smooth = 0
    end

    --set fade timer if mouse is not hovering over the app
    local phoneHovered = ui.rectHovered(0, app.size)
    if phoneHovered and settings.chatmove then
        movement.timer = settings.chattimer
        movement.up = true
    end
    if phoneHovered and movement.distance == 0 then
        chat.inputfade = 1
    elseif chat.inputfade > 0 then
        chat.inputfade = chat.inputfade - dt
    end

    --play notification sound when allowed to and enabled
    if settings.notifsound or settings.joinnotifsound then
        if notification.sound:playing() and notification.sound:ended() then notification.sound:pause() end
        if notification.allow and not notification.sound:playing() then
            notification.sound:play()
            notification.allow = false
        else
            --dont allow playing if the sound is already playing to prevent spam a little
            notification.allow = false
        end
    end

    --draw display
    ui.setCursor(vec2(0, 0 + movement.smooth))
    ui.childWindow('Display', app.size, flags.window, function()
        --draw display image
        ui.drawImage(phone.src.display, VecTR, VecBL, phone.color, true)
        --draw time
        ui.pushDWriteFont(phone.src.font)
        ui.setCursor(vec2(31, 54))
        ui.dwriteTextAligned(time.final, 16, -1, 0, vec2(60, 18), false, 0)
        ui.popDWriteFont()

        --draw song info if enabled
        if settings.nowplaying then
            ui.pushDWriteFont(phone.src.font)
            ui.setCursor(vec2(90, 54))
            ui.dwriteTextAligned(nowplaying.final, 16, -1, 0, vec2(146, 18), false, 0)
            ui.popDWriteFont()
        end
    end)

    --draw chat messages
    ui.setCursor(vec2(12, 72 + movement.smooth))
    ui.childWindow('Chatbox', chat.size, flags.window, function()
        if chat.messagecount > 0 then
            for i = 1, chat.messagecount do
                --make the latest message bold if enabled
                if i == chat.messagecount and settings.chatbold then
                    ui.pushDWriteFont(phone.src.fontBold)
                    ui.dwriteTextWrapped(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatfontsize, 0)
                    ui.popDWriteFont()
                    ui.setScrollHereY(1)
                    --make message bold if player is mentioned (@user or user)
                elseif string.find(string.lower(chat.messages[i][1]), '%f[%a_]' .. string.lower(ac.getDriverName(0)) .. '%f[%A_]') then
                    ui.pushDWriteFont(phone.src.fontBold)
                    ui.dwriteTextWrapped(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatfontsize, 0)
                    ui.popDWriteFont()
                    ui.setScrollHereY(1)
                else
                    ui.pushDWriteFont(phone.src.font)
                    ui.dwriteTextWrapped(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatfontsize, 0)
                    ui.popDWriteFont()
                    ui.setScrollHereY(1)
                end
            end
        end
    end)

    --break the phone screen on impacts if enabled
    if settings.damage then
        if car.player.collidedWith > -1 then
            --reset the table for new colisions if the screen is not fully damaged
            if car.damage.state < 2 then car.forces.total = {} end
            --split x and z axis into 4 directions
            if car.player.acceleration.x < 0 then car.forces.left = car.player.acceleration.x * -1 else car.forces.right = car.player.acceleration.x end
            if car.player.acceleration.z < 0 then car.forces.front = car.player.acceleration.z * -1 else car.forces.back = car.player.acceleration.z end
            --add all the forces together and calculate the mean value then insert them into a table, then get the largest force value in the table
            table.insert(car.forces.total, (car.forces.front + car.forces.back + car.forces.left + car.forces.right) / 2)
            local maxForce = math.max(unpack(car.forces.total))
            --set damage state if forces exeed the force values and reset damage duration if not already fading
            if maxForce > settings.breakforce then
                car.damage.state = 2
                if car.damage.duration > 0 and car.damage.fadetimer == settings.fadeduration then
                    car.damage.duration = settings.damageduration
                end
            elseif maxForce > settings.crackforce then
                car.damage.state = 1
                if car.damage.duration > 0 and car.damage.fadetimer == settings.fadeduration then
                    car.damage.duration = settings.damageduration
                end
            end
        end
        --display and fade timers
        if car.damage.state > 0 and car.damage.duration <= 0 and car.damage.fadetimer == settings.fadeduration then
            car.damage.duration = settings.damageduration
        elseif car.damage.duration > 0 then
            car.damage.duration = car.damage.duration - dt
        end
        if car.damage.duration <= 0 and car.damage.state > 0 then
            car.damage.fadetimer = car.damage.fadetimer - dt
        end
        if car.damage.fadetimer <= 0 and car.damage.state > 0 then
            car.damage.state = 0
            car.damage.fadetimer = settings.fadeduration
        end
        --display damage depending on state
        if car.damage.state > 0 and car.damage.fadetimer > 0 then
            ui.setCursor(vec2(0, 0 + movement.smooth))
            ui.childWindow('DisplayDamage', app.size, flags.window, function()
                if car.damage.state > 1 then
                    ui.drawImage(phone.src.destroyed, VecTR, VecBL, rgbm(1, 1, 1, ((100 / settings.fadeduration) / 100) * car.damage.fadetimer), true)
                end
                if car.damage.state > 0 then
                    ui.drawImage(phone.src.cracked, VecTR, VecBL, rgbm(1, 1, 1, ((100 / settings.fadeduration) / 100) * car.damage.fadetimer), true)
                end
            end)
        end
    end

    --draw images that need to be on top
    ui.setCursor(vec2(0, 0 + movement.smooth))
    ui.childWindow('DisplayonTopImages', app.size, flags.window, function()
        --draw phone image
        ui.drawImage(phone.src.phone, VecTR, VecBL, true)
        --draw glare image if enabled
        if settings.glare then
            ui.drawImage(phone.src.glare, VecTR, VecBL, true)
        end
        --draw glow image if enabled
        if settings.glow then
            if settings.damage and car.damage.state == 2 then
                car.damage.glow = math.lerpInvSat(((100 / settings.fadeduration) / 100) * car.damage.fadetimer, 1, 0)
            end
            ui.drawImage(phone.src.glow, VecTR, VecBL, rgbm(phone.color.r, phone.color.g, phone.color.b, car.damage.glow), true)
        end
    end)

    --chat input
    --xtz: not affected by glare/glow because childwindows dont have clickthrough so it cant be moved 'below', not important just a ocd thing
    ui.setCursor(vec2(8, 347))
    ui.childWindow('Chatinput', vec2(323, 38), flags.window, function()
        if phoneHovered and movement.distance == 0 and car.damage.state < 2 or chat.activeinput then
            --if enabled, stop the phone from moving down while hovering over the app or while textinput is active
            if settings.chatmove then
                movement.timer = settings.chattimer
                movement.up = true
            end
            local chatInputString, chatInputChange, chatInputEnter = ui.inputText('Type new message...', chatInputString, ui.InputTextFlags.Placeholder)
            chat.activeinput = ui.itemActive()
            if chatInputEnter then
                ac.sendChatMessage(chatInputString)
                ui.clearInputCharacters()
                ui.setKeyboardFocusHere(-1)
            end
        elseif chat.inputfade > 0 and car.damage.state < 2 then
            ui.drawRectFilled(vec2(20, 8), vec2(229, 30), rgbm(0.1, 0.1, 0.1, 0.66 * chat.inputfade), 0)
        end
    end)
end
