--made by C1XTZ (xtz), CheesyManiac (che)

--xtz: im sure this does something
--che: you dont really need this since you're loading only a few images at the start
ui.setAsynchronousImagesLoading(true)

--xtz: adding this so unicode characters like kanji dont break while scrolling
--xtz: had to add a -1 to nowPlaying.length and a +1 to settings.spaces because otherwise the function complains about a nil value for j and im too lazy to fix this
require 'src.utf8'
function utf8.sub(s, i, j)
    i = utf8.offset(s, i)
    j = utf8.offset(s, j + 1) - 1
    return string.sub(s, i, j)
end

local settings = ac.storage {
    glare = true,
    glow = true,
    trackTime = false,
    badTime = false,
    nowPlaying = true,
    spaces = 5,
    scrollSpeed = 2,
    damage = false,
    damageDuration = 5,
    fadeDuration = 3,
    crackForce = 15,
    breakForce = 30,
    chatMove = true,
    chatTimer = 15,
    chatMoveSpeed = 4,
    chatFontSize = 16,
    chatBold = false,
    customColor = false,
    displayColor = rgb(0.64, 1, 0.71),
    hideKB = true,
    hideAnnoy = true,
    notifSound = false,
    notifVolume = 5,
    joinNotif = true,
    joinNotifSound = false,
    joinNotifFriends = true,
    joinNotifSoundFriends = false,
    txtColor = rgb(0),
    alwaysNotif = false,
    enableSound = true,
    lastCheck = 0,
    autoUpdate = false,
    updateInterval = 7,
    updateStatus = 0,
    updateAvailable = false,
    updateURL = '',
    chatPurge = false,
    chatKeepSize = 50,
    chatOlderThan = 15,
    chatScrollSpeed = 2,
}

local spaceTable = {}
for i = 0, settings.spaces + 1 do
    spaceTable[i] = ' '
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
    displayColor = rgb(0.64, 1.0, 0.71),
    defaultDisplayColor = rgb(0.64, 1.0, 0.71),
    txtColor = rgb(0),
}

local chat = {
    size = vec2(245, 282),
    messages = {},
    activeInput = false,
    sendCd = false,
    scrollBool = false,
    inputFlags = bit.bor(ui.InputTextFlags.Placeholder),
    mentioned = '',
}

local movement = {
    maxDistance = 357,
    timer = settings.chatTimer,
    down = true,
    up = false,
    distance = 0,
    smooth = 0
}

local time = {
    player = '',
    track = '',
    final = '',
}

local nowPlaying = {
    artist = '',
    title = '',
    scroll = '',
    final = '',
    length = 0,
    pstr = '    PAUSE ll',
    isPaused = false,
    spaces = table.concat(spaceTable),
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
        fadeTimer = settings.fadeDuration,
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
    color = bit.bor(ui.ColorPickerFlags.NoAlpha, ui.ColorPickerFlags.NoSidePreview, ui.ColorPickerFlags.NoDragDrop, ui.ColorPickerFlags.NoLabel, ui.ColorPickerFlags.DisplayRGB, ui.ColorPickerFlags.NoSmallPreview)
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
    notification.sound:setVolume(0.01 * settings.notifVolume)
end

setNotifiVolume()

local appName = 'mobilephone'
local appFolder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/' .. appName .. '/'
local manifest = ac.INIConfig.load(appFolder .. '/manifest.ini', ac.INIFormat.Extended)
local appVersion = manifest:get('ABOUT', 'VERSION', 0.01)
local releaseURL = 'https://api.github.com/repos/C1XTZ/ac-mobilephone/releases/latest'
local doUpdate = (os.time() - settings.lastCheck) / 86400 > settings.updateInterval
local mainFile, assetFile = appName .. '.lua', appName .. '.zip'
--xtz: The ingame updater idea was taken from tuttertep's comfy map app and rewritten to work with my github releases instead of pulling from the entire repository
--xtz: JSON.parse returns a different json on 0.2.0 for some reason, ill do this for now, might bump recommended version to 0.2.1
function handle2651(latestRelease)
    local tagName, releaseAssets, getDownloadUrl
    if ac.getPatchVersionCode() <= 2651 then
        tagName = latestRelease.author.tag_name
        releaseAssets = latestRelease.author.assets
        getDownloadUrl = function(asset) return asset.uploader.browser_download_url end
    else
        tagName = latestRelease.tag_name
        releaseAssets = latestRelease.assets
        getDownloadUrl = function(asset) return asset.browser_download_url end
    end
    return tagName, releaseAssets, getDownloadUrl
end

function updateCheckVersion(manual)
    settings.lastCheck = os.time()

    web.get(releaseURL, function(err, response)
        if err then
            settings.updateStatus = 4
            error(err)
            return
        end

        local latestRelease = JSON.parse(response.body)
        local tagName, releaseAssets, getDownloadUrl = handle2651(latestRelease)

        if not (tagName and tagName:match('^v%d%d?%.%d%d?$')) then
            settings.updateStatus = 4
            error('URL unavailable or no Version recognized, aborted update')
            return
        end
        local version = tonumber(tagName:sub(2))

        if appVersion > version then
            settings.updateStatus = 3
            settings.updateAvailable = false
            return
        elseif appVersion == version then
            settings.updateStatus = 2
            settings.updateAvailable = false
            return
        else
            local downloadUrl
            for _, asset in ipairs(releaseAssets) do
                if asset.name == assetFile then
                    downloadUrl = getDownloadUrl(asset)
                    break
                end
            end

            if not downloadUrl then
                settings.updateStatus = 4
                error('No matching asset found, aborted update')
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
                    filePath = filePath:gsub(appName .. '/', '')
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
    local msgToUser = setTimeout(function()
        table.remove(chat.messages, msgIndex)
    end, 30)

    if settings.chatMove then
        movement.timer = settings.chatTimer
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

function convertTime(timeString)
    local hour, minute = string.match(timeString, "^(%d+):(%d+)$")
    hour, minute = tonumber(hour), tonumber(minute)
    if hour >= 12 then
        hour = hour % 12
        if hour == 0 then hour = 12 end
    end

    if hour < 10 then hour = "0" .. hour end
    return string.format("%s:%02d", hour, minute)
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
    return os.time() - messageTime > (settings.chatOlderThan * 60)
end

ac.onChatMessage(function(message, senderCarIndex)
    local escapedMessage = string.gsub(message, '([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1')
    local isPlayer = senderCarIndex > -1
    local isFriend = isPlayer and checkIfFriend(senderCarIndex)
    local isMentioned = settings.notifSound and string.find(string.lower(escapedMessage), '%f[%a_]' .. string.lower(ac.getDriverName(0)) .. '%f[%A_]')
    local hideMessage = false

    if isPlayer then
        hideMessage = matchMessage(isPlayer, escapedMessage) and settings.hideAnnoy
    else
        hideMessage = matchMessage(isPlayer, escapedMessage) and settings.hideKB
    end

    if not hideMessage and message:len() > 0 then
        table.insert(chat.messages, { message, isPlayer and ac.getDriverName(senderCarIndex) .. ': ' or '', isFriend and '* ' or '', os.time() })

        if settings.chatMove then
            movement.timer = settings.chatTimer
            movement.up = true
        end

        if settings.enableSound and (isMentioned or settings.alwaysNotif) then notification.allow = true end

        if senderCarIndex == car.player.index then
            chat.scrollBool = true
            setTimeout(function()
                chat.scrollBool = false
            end, 0.1)
        end
    end
end)

if settings.joinNotif then
    local function connectionHandler(connectedCarIndex, action)
        local isFriend = checkIfFriend(connectedCarIndex)
        if settings.joinNotifFriends and not isFriend then
            return
        else
            table.insert(chat.messages, { action .. ' the Server', ac.getDriverName(connectedCarIndex) .. ' ', isFriend and '* ' or '', os.time() })

            if settings.enableSound and ((not settings.joinNotifSoundFriends or isFriend) or settings.alwaysNotif) then
                notification.allow = true
            end

            if settings.chatMove then
                movement.timer = settings.chatTimer
                movement.up = true
            end
        end
    end

    ac.onClientConnected(function(connectedCarIndex)
        connectionHandler(connectedCarIndex, 'joined')
    end)

    ac.onClientDisconnected(function(connectedCarIndex)
        connectionHandler(connectedCarIndex, 'left')
    end)
end

local scrollInterval
function scrollText()
    scrollInterval = setInterval(function()
        local nLetter = utf8.sub(nowPlaying.scroll, nowPlaying.length - 1, nowPlaying.length - 1)
        local nString = utf8.sub(nowPlaying.scroll, 1, nowPlaying.length - 1)
        local nText = nLetter .. nString
        nowPlaying.scroll = nText
        nowPlaying.final = nText
    end, 1 / settings.scrollSpeed, 'ST')
end

function updateSpacing()
    spaceTable = {}
    for i = 0, settings.spaces + 1 do
        spaceTable[i] = ' '
    end
    nowPlaying.spaces = table.concat(spaceTable)
    nowPlaying.FUCK = true
end

function updateSong()
    if settings.nowPlaying and ac.currentlyPlaying().artist == nil then nowPlaying.final = '   LOADING...' end
    local currentSong = ac.currentlyPlaying()
    if currentSong.isPlaying and settings.nowPlaying then
        local artistChanged = nowPlaying.artist ~= currentSong.artist
        local titleChanged = nowPlaying.title ~= currentSong.title

        if artistChanged or titleChanged or nowPlaying.isPaused or nowPlaying.FUCK then
            if not scrollInterval then scrollText() end
            nowPlaying.isPaused = false
            nowPlaying.FUCK = false
            nowPlaying.artist = currentSong.artist
            nowPlaying.title = currentSong.title

            local isUnknownArtist = string.lower(nowPlaying.artist) == 'unknown artist'
            nowPlaying.scroll = isUnknownArtist and (nowPlaying.title .. nowPlaying.spaces) or (nowPlaying.artist .. ' - ' .. nowPlaying.title .. nowPlaying.spaces)

            if utf8.len(nowPlaying.scroll) < 19 then nowPlaying.scroll = nowPlaying.scroll .. string.rep(' ', 19 - utf8.len(nowPlaying.scroll)) end

            nowPlaying.length = utf8.len(nowPlaying.scroll)
        end
    elseif not currentSong.isPlaying and not nowPlaying.isPaused and settings.nowPlaying and nowPlaying.artist ~= '' then
        if scrollInterval then
            clearInterval(scrollInterval)
            scrollInterval = nil
        end

        nowPlaying.length = utf8.len(nowPlaying.pstr)
        nowPlaying.final = nowPlaying.pstr
        nowPlaying.isPaused = true
    end
end

function updateTime()
    time.track = string.format('%02d', ac.getSim().timeHours) .. ':' .. string.format('%02d', ac.getSim().timeMinutes)
    time.player = os.date('%H:%M')

    if settings.trackTime then time.final = time.track else time.final = time.player end

    if settings.badTime then time.final = convertTime(time.final) end
end

local updateInterval
function runUpdate()
    updateInterval = setInterval(function()
        updateTime()
        if settings.nowPlaying then updateSong() end
    end, 2, 'RU')
end

function onShowWindow()
    if settings.nowPlaying then nowPlaying.final = '   LOADING...' end
    nowPlaying.FUCK = true
    nowPlaying.isPaused = false
    updateTime()
    runUpdate()

    if (settings.autoUpdate and doUpdate) or settings.updateAvailable then updateCheckVersion() end
end

if settings.customColor then
    phone.displayColor:set(settings.displayColor)
    phone.txtColor:set(settings.txtColor)
end

function script.windowMainSettings(dt)
    ui.tabBar('TabBar', function()
        if ac.getPatchVersionCode() < 2651 then
            ui.textColored('You are using a version of CSP older than 0.2.0!\nIf anything breaks update to the latest version\n ', rgbm.colors.red)
            ui.newLine(-25)
        end

        if ac.getPatchVersionCode() >= 2651 then
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

                local updateButtonText = settings.updateAvailable and 'Install Update' or 'Check for Update'
                if ui.button(updateButtonText) then updateCheckVersion(settings.updateAvailable) end

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
        end

        ui.tabItem('Display', function()
            if ui.checkbox('Custom Color', settings.customColor) then
                settings.customColor = not settings.customColor

                if not settings.customColor then
                    phone.displayColor = phone.defaultDisplayColor:clone()
                    phone.txtColor = rgb(0)
                else
                    phone.displayColor = settings.displayColor
                    phone.txtColor = settings.txtColor
                end
            end

            if settings.customColor then
                ui.text('\t')
                ui.sameLine()
                ui.text('Display Color')

                ui.sameLine()
                ui.setCursorX(276)
                ui.text('Text Color')

                ui.text('\t')
                ui.sameLine()
                local displayColorChange = ui.colorPicker('Display Color Picker', phone.displayColor, flags.color)
                if displayColorChange then settings.displayColor = phone.displayColor end

                ui.sameLine()
                local txtColorChange = ui.colorPicker('Text Color Picker', phone.txtColor, flags.color)
                if txtColorChange then settings.txtColor = phone.txtColor end

                ui.text('\t')
                ui.sameLine()
                if ui.button('Reset Display Color') then
                    phone.displayColor = phone.defaultDisplayColor:clone()
                    settings.displayColor = phone.defaultDisplayColor:clone()
                end

                ui.sameLine()
                ui.setCursorX(276)
                if ui.button('Reset Text Color') then
                    phone.txtColor = rgb(0)
                    settings.txtColor = rgb(0)
                end
            end

            if ui.checkbox('Screen Glare', settings.glare) then settings.glare = not settings.glare end

            if ui.checkbox('Screen Glow', settings.glow) then settings.glow = not settings.glow end

            if ui.checkbox('Use 12h Clock', settings.badTime) then
                settings.badTime = not settings.badTime
                updateTime()
            end

            if ui.checkbox('Use Track Time', settings.trackTime) then
                settings.trackTime = not settings.trackTime
                updateTime()
            end

            if ui.checkbox('Show Current Song', settings.nowPlaying) then
                settings.nowPlaying = not settings.nowPlaying
                if settings.nowPlaying then
                    nowPlaying.FUCK = true
                    updateSong()
                else
                    clearInterval(updateInterval)
                    clearInterval(scrollInterval)
                    updateInterval = nil
                    scrollInterval = nil
                    runUpdate()
                end
            end

            if settings.nowPlaying then
                ui.text('\t')
                ui.sameLine()
                settings.spaces = ui.slider('##Spaces', settings.spaces, 1, 25, 'Spaces: ' .. '%.0f')
                if string.len(nowPlaying.spaces) ~= settings.spaces + 1 then updateSpacing() end

                ui.text('\t')
                ui.sameLine()
                settings.scrollSpeed, speedChange = ui.slider('##ScrollSpeed', settings.scrollSpeed, 0, 15, 'Scroll Speed: ' .. '%.1f')
                if speedChange and not nowPlaying.isPaused then
                    clearInterval(scrollInterval)
                    scrollInterval = nil
                    scrollText()
                end
            end

            if ui.checkbox('Screen Damage', settings.damage) then
                settings.damage = not settings.damage
                if not settings.damage then car.damage.glow = 1 end
            end

            if settings.damage then
                ui.text('\t')
                ui.sameLine()
                settings.damageDuration, damageChange = ui.slider('##DamageDuration', settings.damageDuration, 1, 60, 'Duration: ' .. '%.1f seconds')
                if damageChange then car.damage.duration = settings.damageDuration end

                ui.text('\t')
                ui.sameLine()
                settings.fadeDuration, fadeChange = ui.slider('##FadeDuration', settings.fadeDuration, 1, 60, 'Fade out: ' .. '%.1f seconds')
                if fadeChange then car.damage.fadeTimer = settings.fadeDuration end

                ui.text('\t')
                ui.sameLine()
                settings.crackForce = ui.slider('##CrackForce', settings.crackForce, 5, 50, 'Crack Force: ' .. '%.0f')

                ui.text('\t')
                ui.sameLine()
                settings.breakForce = ui.slider('##BreakForce', settings.breakForce, 10, 100, 'Break Force: ' .. '%.0f')
            end
        end)

        ui.tabItem('Chat', function()
            ui.text('\t')
            ui.sameLine()
            settings.chatFontSize = ui.slider('##ChatFontSize', settings.chatFontSize, 6, 36, 'Chat Fontsize: ' .. '%.0f')

            ui.text('\t')
            ui.sameLine()
            settings.chatScrollSpeed = ui.slider('##ChatScrollSpeed', settings.chatScrollSpeed, 1, 10, 'Chat Scroll Speed: ' .. '%.0f')

            if ui.checkbox('Chat History Settings', settings.chatPurge) then settings.chatPurge = not settings.chatPurge end
            if settings.chatPurge then
                ui.text('\t')
                ui.sameLine()
                settings.chatKeepSize = ui.slider('##ChatKeepSize', settings.chatKeepSize, 10, 500, 'Always keep %.0f Messages')

                ui.text('\t')
                ui.sameLine()
                settings.chatOlderThan = ui.slider('##ChatOlderThan', settings.chatOlderThan, 1, 60, 'Remove excess if older than %.0f min')
            end

            if ui.checkbox('Show Join/Leave Messages', settings.joinNotif) then settings.joinNotif = not settings.joinNotif end
            if settings.joinNotif then
                ui.text('\t')
                ui.sameLine()
                if ui.checkbox('Friends Only', settings.joinNotifFriends) then settings.joinNotifFriends = not settings.joinNotifFriends end
            end

            if ui.checkbox('Highlight Latest Message', settings.chatBold) then settings.chatBold = not settings.chatBold end

            if ui.checkbox('Hide Kick and Ban Messages', settings.hideKB) then settings.hideKB = not settings.hideKB end

            if ui.checkbox('Hide Annoying App Messages', settings.hideAnnoy) then settings.hideAnnoy = not settings.hideAnnoy end

            if ui.checkbox('Chat Inactivity Minimizes Phone', settings.chatMove) then
                settings.chatMove = not settings.chatMove

                if settings.chatMove then
                    movement.up = false
                    movement.timer = settings.chatTimer
                end
            end

            if settings.chatMove then
                ui.text('\t')
                ui.sameLine()
                settings.chatTimer, chatinactiveChange = ui.slider('##ChatTimer', settings.chatTimer, 1, 120, 'Inactivity: ' .. '%.0f seconds')
                if chatinactiveChange then movement.timer = settings.chatTimer end

                ui.text('\t')
                ui.sameLine()
                settings.chatMoveSpeed = ui.slider('##ChatMoveSpeed', settings.chatMoveSpeed, 1, 20, 'Speed: ' .. '%.0f')
            end
        end)

        ui.tabItem('Sound', function()
            if ui.checkbox('Enable Sound Notifications', settings.enableSound) then settings.enableSound = not settings.enableSound end
            if settings.enableSound then
                ui.text('\t')
                ui.sameLine()
                settings.notifVolume, volumeChange = ui.slider('##SoundVolume', settings.notifVolume, 1, 100, 'Sound Volume: ' .. '%.0f' .. '%')
                if volumeChange then setNotifiVolume() end

                ui.sameLine()
                if ui.button('Play') then notification.sound:play() end

                if ui.checkbox('Play Notification Sound for all Messages', settings.alwaysNotif) then settings.alwaysNotif = not settings.alwaysNotif end

                if not settings.alwaysNotif then
                    if ui.checkbox('Play Notification Sound for Join/Leave Messages', settings.joinNotifSound) then settings.joinNotifSound = not settings.joinNotifSound end
                    if settings.joinNotifSound then
                        ui.text('\t')
                        ui.sameLine()
                        if ui.checkbox('Only Play for Friends', settings.joinNotifSoundFriends) then settings.joinNotifSoundFriends = not settings.joinNotifSoundFriends end
                    end

                    if ui.checkbox('Play Notification Sound when Mentioned', settings.notifSound) then settings.notifSound = not settings.notifSound end
                end
            end
        end)
    end)
end

local VecTR = vec2(app.padding.x, phone.size.y - phone.size.y - app.padding.y)
local VecBL = vec2(phone.size.x + app.padding.x, phone.size.y - app.padding.y)
function script.windowMain(dt)
    if settings.chatMove then
        if movement.timer > 0 and movement.distance == 0 then
            movement.timer = movement.timer - dt
            movement.down = true
        end

        if movement.timer <= 0 and movement.down then
            movement.down = true
            movement.distance = math.floor(movement.distance + dt * 100 * settings.chatMoveSpeed)
            movement.smooth = math.floor(math.smootherstep(math.lerpInvSat(movement.distance, 0, movement.maxDistance)) * movement.maxDistance)
        elseif movement.timer > 0 and movement.up then
            movement.distance = math.floor(movement.distance - dt * 100 * settings.chatMoveSpeed)
            movement.smooth = math.floor(math.smootherstep(math.lerpInvSat(movement.distance, 0, movement.maxDistance)) * movement.maxDistance)
            --che: the entire thing doesnt work if I don't make it a new variable. I have idea why and I am far too tired to sit and work it out for another 2 hours
            --xtz: it seems to work, so im not touching it
        end

        if movement.distance > movement.maxDistance then
            movement.distance = movement.maxDistance
            movement.down = false
        elseif movement.distance < 0 then
            movement.distance = 0
            movement.up = false
            movement.timer = settings.chatTimer
        end
    elseif not settings.chatMove and movement.distance ~= 0 then
        movement.distance = 0
        movement.smooth = 0
    end

    local phoneHovered = ui.rectHovered(0, app.size)
    if settings.chatMove and (phoneHovered or chat.activeInput) then
        movement.timer = settings.chatTimer
        movement.up = true
    end

    if settings.notifSound or settings.joinNotifSound then
        if notification.sound:playing() and notification.sound:ended() then notification.sound:pause() end
        if settings.enableSound and (notification.allow and not notification.sound:playing()) then
            notification.sound:play()
            notification.allow = false
        end
    end

    ui.setCursor(vec2(0, 0 + movement.smooth))
    ui.childWindow('Display', app.size, flags.window, function()
        ui.drawImage(phone.src.display, VecTR, VecBL, phone.displayColor)
        ui.pushDWriteFont(phone.src.fontNoEm)
        ui.setCursor(vec2(31, 52))
        ui.dwriteTextAligned(time.final, 16, -1, 0, ui.measureDWriteText(time.final, 16), false, phone.txtColor)
        ui.popDWriteFont()

        if settings.nowPlaying then
            ui.setCursor(vec2(91, 54))
            ui.pushDWriteFont(phone.src.fontNoEm)
            ui.dwriteTextAligned(nowPlaying.final, 16, -1, 0, vec2(146, 18), false, phone.txtColor)
            ui.popDWriteFont()
        end
    end)
    ui.setCursor(vec2(11, 73 + movement.smooth))
    ui.childWindow('Chatbox', chat.size, flags.window, function()
        if #chat.messages > 0 then
            if #chat.messages > settings.chatKeepSize and isMessageOld(chat.messages[1]) then table.remove(chat.messages, 1) end

            for i = 1, #chat.messages do
                if (i == #chat.messages and settings.chatBold) or string.find(string.lower(chat.messages[i][1]), '%f[%a_]' .. string.lower(ac.getDriverName(0)) .. '%f[%A_]') then
                    ui.pushDWriteFont(phone.src.fontBold)
                else
                    ui.pushDWriteFont(phone.src.font)
                end

                ui.dwriteTextWrapped(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatFontSize, phone.txtColor)

                local dwriteSize = ui.measureDWriteText(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatFontSize, 200)
                ui.popDWriteFont()

                local cursorPos = vec2(ui.getCursorX(), ui.getCursorY() - dwriteSize.y) - vec2(1, 3)
                local senderUserName = chat.messages[i][2]:sub(1, -3)

                if chat.messages[i][2] ~= '' and senderUserName ~= ac.getDriverName(0) then
                    local messageHovered = {}
                    messageHovered[i] = ui.rectHovered(cursorPos, cursorPos + dwriteSize, true)
                    if messageHovered[i] and ui.mouseClicked(1) then
                        chat.mentioned = '@' .. senderUserName .. ", "
                    end
                end

                if not phoneHovered or chat.scrollBool then ui.setScrollHereY(1) end
            end
        end

        if phoneHovered and ui.mouseWheel() ~= 0 then
            local mouseWheel = (ui.mouseWheel() * -1) * (settings.chatScrollSpeed * 10)
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
            if maxForce > settings.breakForce or maxForce > settings.crackForce then
                car.damage.state = maxForce > settings.breakForce and 2 or 1
                if car.damage.duration > 0 and car.damage.fadeTimer == settings.fadeDuration then
                    car.damage.duration = settings.damageDuration
                end
            end
        end

        if car.damage.state > 0 then
            if car.damage.duration <= 0 and car.damage.fadeTimer == settings.fadeDuration then
                car.damage.duration = settings.damageDuration
            elseif car.damage.duration > 0 then
                car.damage.duration = car.damage.duration - dt
            end

            if car.damage.duration <= 0 then
                car.damage.fadeTimer = car.damage.fadeTimer - dt
            end

            if car.damage.fadeTimer <= 0 then
                car.damage.state = 0
                car.damage.fadeTimer = settings.fadeDuration
            end
        end

        if car.damage.state > 0 and car.damage.fadeTimer > 0 then
            ui.setCursor(vec2(0, 0 + movement.smooth))
            ui.childWindow('DisplayDamage', app.size, flags.window, function()
                local damageAlpha = ((100 / settings.fadeDuration) / 100) * car.damage.fadeTimer

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
        if settings.nowPlaying then
            local nowPlayingHovered = ui.rectHovered(ui.getCursor() + vec2(64, 44), ui.getCursor() + vec2(220, 64))
            if nowPlayingHovered and ui.mouseClicked(1) then
                ac.sendChatMessage('Currently listening to: ' .. nowPlaying.artist .. ' - ' .. nowPlaying.title)
                chat.sendCd = true
                setTimeout(function()
                    chat.sendCd = false
                end, 1)
            end
        end

        local timeHovered = ui.rectHovered(ui.getCursor() + vec2(6, 44), ui.getCursor() + vec2(64, 64))
        if timeHovered and ui.mouseClicked(1) then
            if settings.trackTime then
                ac.sendChatMessage('Current track time: ' .. time.track)
            else
                ac.sendChatMessage('Current local time: ' .. time.player)
            end

            chat.sendCd = true
            setTimeout(function()
                chat.sendCd = false
            end, 1)
        end

        ui.drawImage(phone.src.phone, VecTR, VecBL)

        if settings.glare then
            ui.drawImage(phone.src.glare, VecTR, VecBL)
        end

        if settings.glow then
            if settings.damage and car.damage.state == 2 then
                car.damage.glow = math.lerpInvSat(((100 / settings.fadeDuration) / 100) * car.damage.fadeTimer, 1, 0)
            end

            ui.drawImage(phone.src.glow, VecTR, VecBL, phone.displayColor:rgbm(car.damage.glow))
        end
    end)

    --xtz: not affected by glare/glow because childwindows dont have clickthrough so it cant be moved 'below', not important just a ocd thing
    ui.setCursor(vec2(8, 347 + movement.smooth))
    ui.childWindow('Chatinput', vec2(323, 38), flags.window, function()
        local chatInputString, chatInputChange, chatInputEnter = '', _, _
        chatInputString = chat.mentioned .. chatInputString
        chatInputString, chatInputChange, chatInputEnter = ui.inputText('Type new message', chatInputString, chat.inputFlags)

        chat.activeInput = ui.itemActive()
        if chat.mentioned ~= '' and chatInputString ~= chat.mentioned then chat.mentioned = '' end

        --there is a cooldown on sending chat messages online
        if chatInputEnter and chatInputString and not chat.sendCd then
            ac.sendChatMessage(chatInputString)
            ui.setKeyboardFocusHere(-1)
            ui.clearInputCharacters()
            chat.mentioned = ''
            chat.sendCd = true
            --need to add this flag because otherwise the inputbox is emptied even tho clearInputCharacters is not called after pressing enter
            chat.inputFlags = bit.bor(ui.InputTextFlags.Placeholder, ui.InputTextFlags.RetainSelection)

            setTimeout(function()
                chat.sendCd = false
                chat.inputFlags = bit.bor(ui.InputTextFlags.Placeholder)
            end, 1)
        end
    end)
end
