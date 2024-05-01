--made by C1XTZ (xtz), CheesyManiac (che)

--xtz: im sure this does something
--che: you dont really need this since you're loading only a few images at the start
ui.setAsynchronousImagesLoading(true)

--xtz: adding this so unicode characters like kanji dont break while scrolling
--xtz: had to add a -1 to nowplaying.length and a +1 to settings.spaces because otherwise the function complains about a nil value for j and im too lazy to fix this
require 'src.utf8'
function utf8.sub(s, i, j)
    i = utf8.offset(s, i)
    j = utf8.offset(s, j + 1) - 1
    return string.sub(s, i, j)
end

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
    chatbold = false,
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
    txtColorR = 0,
    txtColorB = 0,
    txtColorG = 0,
    alwaysnotif = false,
    enableSound = true,
    lastCheck = 0,
    autoUpdate = false,
    updateInterval = 7,
    updateStatus = 0,
    updateAvailable = false,
    updateURL = '',
    chatpurge = false,
    chatkeepsize = 50,
    chatolderthan = 15,
    scrollspeed = 2,
}

local spacetable = {}
for i = 0, settings.spaces + 1 do
    spacetable[i] = ' '
end

local app = {
    size = vec2(265, 435),
    padding = vec2(10, -22),
    scale = 1
}

local phone = {
    src = {
        display = './src/img/display.png',
        phone = './src/img/phone.png',
        glare = './src/img/glare.png',
        glow = './src/img/glow.png',
        cracked = './src/img/cracked.png',
        destroyed = './src/img/destroyed.png',
        font = ui.DWriteFont('NOKIA CELLPHONE FC SMALL', './src'),
        fontNoEm = ui.DWriteFont('NOKIA CELLPHONE FC SMALL', './src'),
        fontBold = ui.DWriteFont('NOKIA CELLPHONE FC SMALL', './src'):weight(ui.DWriteFont.Weight.SemiBold),
    },
    size = vec2(245, 409),
    color = rgbm(0.64, 1.0, 0.71, 1),
    txtColor = rgbm(0, 0, 0, 1),
}

local chat = {
    size = vec2(245, 282),
    messages = {},
    activeinput = false,
    sendcd = false,
    inputflags = bit.bor(ui.InputTextFlags.Placeholder)
}

local movement = {
    maxdistance = 357,
    timer = settings.chattimer,
    down = true,
    up = false,
    distance = 0,
    smooth = 0
}

local time = {
    player = '',
    track = '',
    final = ''
}

local nowplaying = {
    artist = '',
    title = '',
    scroll = '',
    final = '',
    length = 0,
    pstr = '    PAUSE ll',
    isPaused = false,
    spaces = table.concat(spacetable),
    FUCK = false
}

local notification = {
    sound = ui.MediaPlayer():setSource('notif.mp3'):setAutoPlay(false):setLooping(false),
    allow = false
}

local car = {
    player = ac.getCar(0),
    damage = {
        state = 0,
        duration = 0,
        fadetimer = settings.fadeduration,
        glow = 1
    },
    forces = {
        left = 0,
        right = 0,
        front = 0,
        back = 0,
        total = {}
    },
}

local flags = {
    window = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs),
    color = bit.bor(ui.ColorPickerFlags.NoAlpha, ui.ColorPickerFlags.NoSidePreview, ui.ColorPickerFlags.NoDragDrop, ui.ColorPickerFlags.NoLabel, ui.ColorPickerFlags.DisplayRGB)
}

local updateStatusTable = {
    [0] = 'C1XTZ: You shouldnt be reading this',
    [1] = 'Updated: App successfully updated',
    [2] = 'No Change: Latest version was already installed',
    [3] = 'No Change: A newer version was already installed',
    [4] = 'Error: Something went wrong, aborted update',
    [5] = 'Update Available to Download and Install'
}
local updateStatusColor = {
    [0] = rgbm.colors.white,
    [1] = rgbm.colors.lime,
    [2] = rgbm.colors.white,
    [3] = rgbm.colors.white,
    [4] = rgbm.colors.red,
    [5] = rgbm.colors.lime
}

function setNotifiVolume()
    notification.sound:setVolume(0.01 * settings.notifvol)
end

setNotifiVolume()

local appFolder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/mobilephone/'
local manifest = ac.INIConfig.load(appFolder .. '/manifest.ini', ac.INIFormat.Extended)
local appVersion = manifest:get('ABOUT', 'VERSION', 0.01)
local releaseURL = 'https://api.github.com/repos/C1XTZ/ac-mobilephone/releases/latest'
local doUpdate = (os.time() - settings.lastCheck) / 86400 > settings.updateInterval
local mainFile = 'mobilephone.lua'
--xtz: The ingame updater idea was taken from tuttertep's comfy map app and rewritten to work with my github releases instead of pulling from the entire repository
function updateCheckVersion(manual)
    settings.lastCheck = os.time()

    web.get(releaseURL, function(err, response)
        if err then
            settings.updateStatus = 4
            error(err)
            return
        end

        local latestRelease = JSON.parse(response.body)
        if not (latestRelease.tag_name and latestRelease.tag_name:match('^v%d%d?%.%d%d?$')) then
            error('URL unavailable or no Version recognized, aborted update')
            settings.updateStatus = 4
            return
        end
        local version = tonumber(latestRelease.tag_name:sub(2))

        if appVersion > version then
            settings.updateStatus = 3
            return
        elseif appVersion == version then
            settings.updateStatus = 2
            return
        else
            local downloadUrl
            for _, asset in ipairs(latestRelease.assets) do
                if asset.name == 'mobilephone.zip' then
                    downloadUrl = asset.browser_download_url
                    break
                end
            end

            if not downloadUrl then
                error('No matching asset found, aborted update')
                settings.updateStatus = 4
                return
            end

            if manual then
                updateApplyUpdate(downloadUrl)
            else
                sendAppMessage('UPDATE AVAILABLE IN THE SETTINGS!')
                settings.updateAvailable = true
                settings.updateURL = downloadUrl
                settings.updateStatus = 5
            end
        end
    end)
end

function updateApplyUpdate(downloadUrl)
    web.get(downloadUrl, function(downloadErr, downloadResponse)
        if downloadErr then
            settings.updateStatus = 4
            error(downloadErr)
            return
        end

        local mainFileContent
        for _, file in ipairs(io.scanZip(downloadResponse.body)) do
            local content = io.loadFromZip(downloadResponse.body, file)
            if content then
                local filePath = file:match('(.*)')
                if filePath then
                    filePath = filePath:gsub('mobilephone/', '')
                    if filePath == mainFile then
                        mainFileContent = content
                    else
                        if io.save(appFolder .. filePath, content) then print('Updating: ' .. file) end
                    end
                end
            end
        end

        if mainFileContent then
            if io.save(appFolder .. mainFile, mainFileContent) then print('Updating: ' .. mainFile) end
        end

        settings.updateStatus = 1
        settings.updateAvailable = false
        settings.updateURL = ''
    end)
end

function sendAppMessage(message)
    table.insert(chat.messages, { message, '', '', os.time() })
    local msgIndex = #chat.messages
    local msgtoUser = setTimeout(function()
        table.remove(chat.messages, msgIndex)
    end, 30)

    if settings.chatmove then
        movement.timer = settings.chattimer
        movement.up = true
    end
end

if ac.getPatchVersionCode() < 2651 then
    sendAppMessage('YOU ARE USING A VERSION OF CSP OLDER THAN 0.2.0!\nIF YOU RUN INTO ANY ISSUES WITH THE APP UPDATE YOUR CSP!')
    function checkIfFriend(carIndex)
        return ac.isTaggedAsFriend(ac.getDriverName(carIndex))
    end
else
    function checkIfFriend(carIndex)
        return ac.DriverTags(ac.getDriverName(carIndex)).friend
    end

    phone.src.fontNoEm = phone.src.fontNoEm:allowEmoji(false)
end

function matchMessage(isPlayer, message)
    if isPlayer then
        local hidePatterns = {
            '^RP: App not running$',
            '^PLP: running version',
            '^ACP: App not active$',
            '^D&O Racing APP:',
            '^DRIFT%%%-STRUCTION POINTS:',
            '^OSRW Race Admin Version:',
        }

        for _, pattern in ipairs(hidePatterns) do
            if string.match(message, pattern) then
                return true
            end
        end
    else
        local hidePatterns = {
            'kicked',
            'banned',
            'checksums',
        }

        for _, reason in ipairs(hidePatterns) do
            if string.find(string.lower(message), '(' .. string.lower(reason) .. ')') then
                if string.find(string.lower(message), '%f[%a_](you)%f[%A_]') then
                    notification.allow = true
                else
                    return true
                end
            end
        end
    end

    return false
end

function isMessageOld(message)
    local messageTime = message[4]
    return os.time() - messageTime > (settings.chatolderthan * 60)
end

ac.onChatMessage(function(message, senderCarIndex)
    local escapedMessage = string.gsub(message, '([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1')
    local isPlayer = senderCarIndex > -1
    local isFriend = isPlayer and checkIfFriend(senderCarIndex)
    local isMentioned = settings.notifsound and string.find(string.lower(escapedMessage), '%f[%a_]' .. string.lower(ac.getDriverName(0)) .. '%f[%A_]')
    local hideMessage = false

    if isPlayer then
        hideMessage = matchMessage(isPlayer, escapedMessage) and settings.hideAnnoy
    else
        hideMessage = matchMessage(isPlayer, escapedMessage) and settings.hideKB
    end

    if not hideMessage and message:len() > 0 then
        table.insert(chat.messages, { message, isPlayer and ac.getDriverName(senderCarIndex) .. ': ' or '', isFriend and '* ' or '', os.time() })
        if settings.chatmove then
            movement.timer = settings.chattimer
            movement.up = true
        end

        if isMentioned or settings.alwaysnotif then notification.allow = true end
    end
end)

if settings.joinnotif then
    local function connectionHandler(connectedCarIndex, action)
        local isFriend = checkIfFriend(connectedCarIndex)
        if settings.joinnotiffriends and not isFriend then return end

        table.insert(chat.messages, { action .. ' the Server', ac.getDriverName(connectedCarIndex) .. ' ', isFriend and '* ' or '', os.time() })

        if isFriend or (settings.joinnotifsound and not settings.joinnotifsoundfriends) then
            notification.allow = true
        end

        if settings.chatmove then
            movement.timer = settings.chattimer
            movement.up = true
        end
    end

    ac.onClientConnected(function(connectedCarIndex)
        connectionHandler(connectedCarIndex, 'joined')
    end)

    ac.onClientDisconnected(function(connectedCarIndex)
        connectionHandler(connectedCarIndex, 'left')
    end)
end

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

function UpdateSpacing()
    spacetable = {}
    for i = 0, settings.spaces + 1 do
        spacetable[i] = ' '
    end
    nowplaying.spaces = table.concat(spacetable)
    nowplaying.FUCK = true
end

function UpdateSong()
    if settings.nowplaying then nowplaying.final = '   LOADING...' end
    local currentSong = ac.currentlyPlaying()
    if currentSong.isPlaying and settings.nowplaying then
        local artistChanged = nowplaying.artist ~= currentSong.artist
        local titleChanged = nowplaying.title ~= currentSong.title

        if artistChanged or titleChanged or nowplaying.isPaused or nowplaying.FUCK then
            if not scrlintvl then scrollText() end
            nowplaying.isPaused = false
            nowplaying.FUCK = false
            nowplaying.artist = currentSong.artist
            nowplaying.title = currentSong.title

            local isUnknownArtist = string.lower(nowplaying.artist) == 'unknown artist'
            nowplaying.scroll = isUnknownArtist and (nowplaying.title .. nowplaying.spaces) or (nowplaying.artist .. ' - ' .. nowplaying.title .. nowplaying.spaces)

            if utf8.len(nowplaying.scroll) < 19 then
                nowplaying.scroll = nowplaying.scroll .. string.rep(' ', 19 - utf8.len(nowplaying.scroll))
            end

            nowplaying.length = utf8.len(nowplaying.scroll)
        end
    elseif not currentSong.isPlaying and not nowplaying.isPaused and settings.nowplaying and nowplaying.artist ~= '' then
        if scrlintvl then
            clearInterval(scrlintvl)
            scrlintvl = nil
        end

        nowplaying.isPaused = true
        nowplaying.length = utf8.len(nowplaying.pstr)
        nowplaying.final = nowplaying.pstr
    end
end

function UpdateTime()
    if settings.tracktime then
        time.track = string.format('%02d', ac.getSim().timeHours) .. ':' .. string.format('%02d', ac.getSim().timeMinutes)
        time.final = time.track
    else
        time.player = os.date('%H:%M')
        time.final = time.player
    end
end

local updtintvl
function RunUpdate()
    updtintvl = setInterval(function()
        UpdateTime()
        if settings.nowplaying then UpdateSong() end
    end, 2, 'RU')
end

function onShowWindow()
    if settings.nowplaying then nowplaying.final = '   LOADING...' end
    nowplaying.FUCK = true
    nowplaying.isPaused = false
    UpdateTime()
    RunUpdate()

    if settings.autoUpdate and doUpdate then
        updateCheckVersion()
    end

    if settings.updateAvailable then
        sendAppMessage('UPDATE AVAILABLE IN THE SETTINGS!')
    end
end

if settings.customcolor then
    phone.color = rgbm(settings.colorR, settings.colorG, settings.colorB, 1)
    phone.txtColor = rgbm(settings.txtColorR, settings.txtColorG, settings.txtColorB, 1)
end

function script.windowMainSettings(dt)
    ui.tabBar('TabBar', function()
        if ac.getPatchVersionCode() < 2651 then
            ui.textColored('You are using a version of CSP older than 0.2.0!\nIf anything breaks update to the latest version\n ', rgbm.colors.red)
        end
        ui.tabItem('Update', function()
            ui.text('Currrently running version ' .. appVersion)
            if ui.checkbox('Automatically Check for Updates', settings.autoUpdate) then
                settings.autoUpdate = not settings.autoUpdate
                if settings.autoUpdate then updateCheckVersion() end
            end
            if settings.autoUpdate then
                ui.text('\t')
                ui.sameLine()
                settings.updateInterval = ui.slider('##UpdateInterval', settings.updateInterval, 1, 60, 'Check for Update every ' .. '%.0f days')
            end
            if ui.button('Get Update') then
                if settings.updateAvailable then
                    updateApplyUpdate(settings.updateURL)
                else
                    updateCheckVersion(true)
                end
            end
            if settings.updateStatus > 0 then
                ui.textColored(updateStatusTable[settings.updateStatus], updateStatusColor[settings.updateStatus])

                local diff = os.time() - settings.lastCheck
                if diff > 600 then settings.updateStatus = 0 end
                local units = { 'seconds', 'minutes', 'hours', 'days' }
                local values = { 1, 60, 3600, 86400 }

                local i = #values
                while i > 1 and diff < values[i] do
                    i = i - 1
                end

                local timeAgo = math.floor(diff / values[i])
                ui.text('Last checked ' .. timeAgo .. ' ' .. units[i] .. ' ago')
            end
        end)
        ui.tabItem('Display', function()
            if ui.checkbox('Custom Color', settings.customcolor) then
                settings.customcolor = not settings.customcolor
                --reset to default color if disabled
                if not settings.customcolor then
                    phone.color = rgbm(0.640, 1.000, 0.710, 1)
                    phone.txtColor = rgbm(0, 0, 0, 1)
                end
            end

            if settings.customcolor then
                ui.text('\t')
                ui.sameLine()
                ui.text('Display Color Picker')
                ui.text('\t')
                ui.sameLine()
                phone.color = rgbm(settings.colorR, settings.colorG, settings.colorB, 1)
                colorChange = ui.colorPicker('Display Color Picker', phone.color, flags.color)
                if colorChange then
                    settings.colorR, settings.colorG, settings.colorB = phone.color.r, phone.color.g, phone.color.b
                end
                ui.text('\t')
                ui.sameLine()
                ui.text('Text Color Picker')
                ui.text('\t')
                ui.sameLine()
                phone.txtColor = rgbm(settings.txtColorR, settings.txtColorG, settings.txtColorB, 1)
                colorChange = ui.colorPicker('Text Color Picker', phone.txtColor, flags.color)
                if colorChange then
                    settings.txtColorR, settings.txtColorG, settings.txtColorB = phone.txtColor.r, phone.txtColor.g, phone.txtColor.b
                end
            end

            if ui.checkbox('Screen Glare', settings.glare) then settings.glare = not settings.glare end

            if ui.checkbox('Screen Glow', settings.glow) then settings.glow = not settings.glow end

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

            if settings.nowplaying then
                ui.text('\t')
                ui.sameLine()
                settings.spaces = ui.slider('##Spaces', settings.spaces, 1, 25, 'Spaces: ' .. '%.0f')
                if string.len(nowplaying.spaces) ~= settings.spaces + 1 then
                    UpdateSpacing()
                end

                ui.text('\t')
                ui.sameLine()
                settings.scrollspeed, speedChange = ui.slider('##ScrollSpeed', settings.scrollspeed, 0, 15, 'Scroll Speed: ' .. '%.1f')
                if speedChange and not nowplaying.isPaused then
                    clearInterval(scrlintvl)
                    scrlintvl = nil
                    scrollText()
                end
            end

            if ui.checkbox('Use Track Time', settings.tracktime) then
                settings.tracktime = not settings.tracktime
                UpdateTime()
            end

            if ui.checkbox('Screen Damage', settings.damage) then
                settings.damage = not settings.damage
                if not settings.damage then car.damage.glow = 1 end
            end

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

        ui.tabItem('Chat', function()
            ui.text('\t')
            ui.sameLine()
            settings.chatfontsize = ui.slider('##ChatFontSize', settings.chatfontsize, 6, 36, 'Chat Fontsize: ' .. '%.0f')
            ui.text('\t')
            ui.sameLine()
            settings.scrollspeed = ui.slider('##ChatScrollSpeed', settings.scrollspeed, 1, 10, 'Chat Scroll Speed: ' .. '%.0f')
            if ui.checkbox('Chat History Settings', settings.chatpurge) then settings.chatpurge = not settings.chatpurge end
            if settings.chatpurge then
                ui.text('\t')
                ui.sameLine()
                settings.chatkeepsize = ui.slider('##ChatKeepSize', settings.chatkeepsize, 10, 500, 'Always keep %.0f Messages')
                ui.text('\t')
                ui.sameLine()
                settings.chatolderthan = ui.slider('##ChatOlderThan', settings.chatolderthan, 1, 60, 'Remove excess if older than %.0f min')
            end
            if ui.checkbox('Show Join/Leave Messages', settings.joinnotif) then settings.joinnotif = not settings.joinnotif end
            if settings.joinnotif then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Friends Only', settings.joinnotiffriends) then settings.joinnotiffriends = not settings.joinnotiffriends end
            end

            if ui.checkbox('Highlight Latest Message', settings.chatbold) then settings.chatbold = not settings.chatbold end

            if ui.checkbox('Hide Kick and Ban Messages', settings.hideKB) then settings.hideKB = not settings.hideKB end

            if ui.checkbox('Hide Annoying App Messages', settings.hideAnnoy) then settings.hideAnnoy = not settings.hideAnnoy end

            if ui.checkbox('Chat Inactivity Minimizes Phone', settings.chatmove) then
                settings.chatmove = not settings.chatmove
                if settings.chatmove then
                    movement.up = false
                    movement.timer = settings.chattimer
                end
            end

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

        ui.tabItem('Sound', function()
            if ui.checkbox('Enable Sound Notifications', settings.enableSound) then settings.enableSound = not settings.enableSound end
            if settings.enableSound then
                ui.text('\t')
                ui.sameLine()
                settings.notifvol, volumeChange = ui.slider('##SoundVolume', settings.notifvol, 1, 100, 'Sound Volume: ' .. '%.0f' .. '%')
                if volumeChange then setNotifiVolume() end
                ui.sameLine()
                if ui.button('Play') then
                    notification.sound:play()
                end

                if ui.checkbox('Play Notification Sound for Join/Leave Messages', settings.joinnotifsound) then settings.joinnotifsound = not settings.joinnotifsound end
                if settings.joinnotifsound then
                    ui.text('\t')
                    ui.sameLine()
                    if ui.checkbox('Only Play for Friends', settings.joinnotifsoundfriends) then settings.joinnotifsoundfriends = not settings.joinnotifsoundfriends end
                end

                if ui.checkbox('Play Notification Sound for all Messages', settings.alwaysnotif) then settings.alwaysnotif = not settings.alwaysnotif end

                if not settings.alwaysnotif then
                    if ui.checkbox('Play Notification Sound when Mentioned', settings.notifsound) then settings.notifsound = not settings.notifsound end
                end
            end
        end)
    end)
end

local VecTR = vec2(app.padding.x, phone.size.y - phone.size.y - app.padding.y)
local VecBL = vec2(phone.size.x + app.padding.x, phone.size.y - app.padding.y)
function script.windowMain(dt)
    if settings.chatmove then
        if movement.timer > 0 and movement.distance == 0 then
            movement.timer = movement.timer - dt
            movement.down = true
        end

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

        if movement.distance > movement.maxdistance then
            movement.distance = movement.maxdistance
            movement.down = false
        elseif movement.distance < 0 then
            movement.distance = 0
            movement.up = false
            movement.timer = settings.chattimer
        end
    elseif not settings.chatmove and movement.distance ~= 0 then
        movement.distance = 0
        movement.smooth = 0
    end

    local phoneHovered = ui.rectHovered(0, app.size)
    if settings.chatmove and (phoneHovered or chat.activeinput) then
        movement.timer = settings.chattimer
        movement.up = true
    end

    if settings.notifsound or settings.joinnotifsound then
        if notification.sound:playing() and notification.sound:ended() then notification.sound:pause() end
        if settings.enableSound and (notification.allow and not notification.sound:playing()) then
            notification.sound:play()
            notification.allow = false
        else
            notification.allow = false
        end
    end

    ui.setCursor(vec2(0, 0 + movement.smooth))
    ui.childWindow('Display', app.size, flags.window, function()
        ui.drawImage(phone.src.display, VecTR, VecBL, phone.color)

        ui.pushDWriteFont(phone.src.fontNoEm)
        ui.setCursor(vec2(31, 54))
        ui.dwriteTextAligned(time.final, 16, -1, 0, vec2(60, 18), false, phone.txtColor)
        ui.popDWriteFont()

        if settings.nowplaying then
            ui.pushDWriteFont(phone.src.fontNoEm)
            ui.setCursor(vec2(90, 54))
            ui.dwriteTextAligned(nowplaying.final, 16, -1, 0, vec2(146, 18), false, phone.txtColor)
            ui.popDWriteFont()
        end
    end)

    ui.setCursor(vec2(11, 73 + movement.smooth))
    ui.childWindow('Chatbox', chat.size, flags.window, function()
        if #chat.messages > 0 then
            if #chat.messages > settings.chatkeepsize and isMessageOld(chat.messages[1]) then
                table.remove(chat.messages, 1)
            end

            for i = 1, #chat.messages do
                if i == #chat.messages and settings.chatbold then
                    ui.pushDWriteFont(phone.src.fontBold)
                    ui.dwriteTextWrapped(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatfontsize, phone.txtColor)
                    ui.popDWriteFont()
                elseif string.find(string.lower(chat.messages[i][1]), '%f[%a_]' .. string.lower(ac.getDriverName(0)) .. '%f[%A_]') then
                    ui.pushDWriteFont(phone.src.fontBold)
                    ui.dwriteTextWrapped(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatfontsize, phone.txtColor)
                    ui.popDWriteFont()
                else
                    ui.pushDWriteFont(phone.src.font)
                    ui.dwriteTextWrapped(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatfontsize, phone.txtColor)
                    ui.popDWriteFont()
                end
                if not phoneHovered then ui.setScrollHereY(1) end
            end
        end

        if phoneHovered and ui.mouseWheel() ~= 0 then
            local mouseWheel = (ui.mouseWheel() * -1) * (settings.scrollspeed * 10)
            ui.setScrollY(mouseWheel, true, true)
        end
    end)

    if settings.damage then
        if car.player.collidedWith > -1 then
            if car.damage.state < 2 then
                car.forces.total = {}
            end

            --split x and z axis into 4 directions
            car.forces.left = math.max(-car.player.acceleration.x, 0)
            car.forces.right = math.max(car.player.acceleration.x, 0)
            car.forces.front = math.max(-car.player.acceleration.z, 0)
            car.forces.back = math.max(car.player.acceleration.z, 0)

            --add all the forces together and calculate the mean value then insert them into a table
            local totalForce = (car.forces.front + car.forces.back + car.forces.left + car.forces.right) / 2
            table.insert(car.forces.total, totalForce)

            local maxForce = math.max(unpack(car.forces.total))

            --set damage state if forces exceed the force values and reset damage duration if not already fading
            if maxForce > settings.breakforce or maxForce > settings.crackforce then
                car.damage.state = maxForce > settings.breakforce and 2 or 1
                if car.damage.duration > 0 and car.damage.fadetimer == settings.fadeduration then
                    car.damage.duration = settings.damageduration
                end
            end
        end

        if car.damage.state > 0 then
            if car.damage.duration <= 0 and car.damage.fadetimer == settings.fadeduration then
                car.damage.duration = settings.damageduration
            elseif car.damage.duration > 0 then
                car.damage.duration = car.damage.duration - dt
            end

            if car.damage.duration <= 0 then
                car.damage.fadetimer = car.damage.fadetimer - dt
            end

            if car.damage.fadetimer <= 0 then
                car.damage.state = 0
                car.damage.fadetimer = settings.fadeduration
            end
        end

        if car.damage.state > 0 and car.damage.fadetimer > 0 then
            ui.setCursor(vec2(0, 0 + movement.smooth))
            ui.childWindow('DisplayDamage', app.size, flags.window, function()
                local damageAlpha = ((100 / settings.fadeduration) / 100) * car.damage.fadetimer

                if car.damage.state > 1 then
                    ui.drawImage(phone.src.destroyed, VecTR, VecBL, rgbm(1, 1, 1, damageAlpha))
                end

                if car.damage.state > 0 then
                    ui.drawImage(phone.src.cracked, VecTR, VecBL, rgbm(1, 1, 1, damageAlpha))
                end
            end)
        end
    end

    ui.setCursor(vec2(0, 0 + movement.smooth))
    ui.childWindow('DisplayonTopImages', app.size, flags.window, function()
        ui.drawImage(phone.src.phone, VecTR, VecBL)

        if settings.glare then
            ui.drawImage(phone.src.glare, VecTR, VecBL)
        end

        if settings.glow then
            if settings.damage and car.damage.state == 2 then
                car.damage.glow = math.lerpInvSat(((100 / settings.fadeduration) / 100) * car.damage.fadetimer, 1, 0)
            end

            ui.drawImage(phone.src.glow, VecTR, VecBL, rgbm(phone.color.r, phone.color.g, phone.color.b, car.damage.glow))
        end
    end)

    --xtz: not affected by glare/glow because childwindows dont have clickthrough so it cant be moved 'below', not important just a ocd thing
    ui.setCursor(vec2(8, 347 + movement.smooth))
    ui.childWindow('Chatinput', vec2(323, 38), flags.window, function()
        local chatInputString, chatInputChange, chatInputEnter = ui.inputText('Type new message...', chatInputString, chat.inputflags)
        chat.activeinput = ui.itemActive()

        --there is a cooldown on sending chat messages online
        if chatInputEnter and chatInputString and not chat.sendcd then
            ac.sendChatMessage(chatInputString)
            ui.setKeyboardFocusHere(-1)
            ui.clearInputCharacters()

            chat.sendcd = true
            --need to add this flag because otherwise the inputbox is emptied even tho clearInputCharacters is not called after pressing enter
            chat.inputflags = bit.bor(ui.InputTextFlags.Placeholder, ui.InputTextFlags.RetainSelection)

            setTimeout(function()
                chat.sendcd = false
                chat.inputflags = bit.bor(ui.InputTextFlags.Placeholder)
            end, 1)
        end
    end)
end
