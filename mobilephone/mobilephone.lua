--made by C1XTZ (xtz), CheesyManiac (che)

--xtz: im sure this does something
--che: you dont really need this since you're loading only a few images at the start
ui.setAsynchronousImagesLoading(true)

local SnakeGame = require('./src/snake_game')

--#region UTF8 HANDLING

--xtz: adding these so unicode characters like kanji dont break while scrolling
function utf8len(s)
    local len = 0
    local i = 1

    while i <= #s do
        len = len + 1
        local c = s:byte(i)
        if c >= 0xF0 then
            i = i + 4
        elseif c >= 0xE0 then
            i = i + 3
        elseif c >= 0xC0 then
            i = i + 2
        else
            i = i + 1
        end
    end

    return len
end

function utf8sub(s, i, j)
    j = j or -1
    local pos = 1
    local bytes = s:len()
    local len = 0

    local l = (i >= 0 and j >= 0) or utf8len(s)
    local startChar = (i >= 0) and i or l + i + 1
    local endChar = (j >= 0) and j or l + j + 1

    if startChar > endChar then return '' end

    local startByte, endByte = 1, bytes

    while pos <= bytes do
        len = len + 1

        if len == startChar then startByte = pos end
        pos = pos + (s:byte(pos) >= 0xF0 and 4 or
            s:byte(pos) >= 0xE0 and 3 or
            s:byte(pos) >= 0xC0 and 2 or 1)
        if len == endChar then
            endByte = pos - 1
            break
        end
    end

    return s:sub(startByte, endByte)
end

--#endregion

--#region APP SETTINGS

local settings = ac.storage {
    glare = true,
    glow = true,
    trackTime = false,
    badTime = false,
    nowPlaying = true,
    spaces = 5,
    scrollSpeed = 2,
    scrollDirection = 1,
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
    forceBottom = true,
    snakeHighscore = 0,
}

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
    final = '',
    period = '',
    interval = nil,
}

local nowPlaying = {
    artist = '',
    title = '',
    scroll = '',
    final = '',
    length = 0,
    pstr = '   PAUSED ll',
    lstr = '   LOADING',
    isPaused = false,
    isLoading = false,
    spaces = '',
    loadingDots = 0,
    loadingInterval = nil,
    scrollInterval = nil,
    updateInterval = nil
}

local notification = {
    sound = ui.MediaPlayer():setSource('./src/notif.mp3'):setAutoPlay(false):setLooping(false),
    allow = false
}

local car = {
    player = ac.getCar(0),
    playerName = ac.getDriverName(0),
    online = ac.getSim().isOnlineRace,
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

if settings.customColor then
    phone.displayColor:set(settings.displayColor)
    phone.txtColor:set(settings.txtColor)
end

--#endregion

--#region APP UPDATER

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

local function scanDirRecursive(directory)
    local function scan(dir, fileList)
        local files = io.scanDir(dir)
        for _, file in ipairs(files) do
            if file ~= '.' and file ~= '..' then
                local fullPath = dir .. '/' .. file
                local attributes = io.getAttributes(fullPath)
                if attributes.isDirectory then
                    scan(fullPath, fileList)
                else
                    table.insert(fileList, fullPath)
                end
            end
        end
    end

    local fileList = {}
    scan(directory, fileList)
    return fileList
end

function updateApplyUpdate(downloadUrl)
    web.get(downloadUrl, function(downloadErr, downloadResponse)
        if downloadErr then
            settings.updateStatus = 4
            error('Error downloading update: ' .. downloadErr)
            return
        end

        local updatedFiles = {}

        for _, file in ipairs(io.scanZip(downloadResponse.body)) do
            local content = io.loadFromZip(downloadResponse.body, file)
            if content then
                local filePath = file:match('(.*)')
                if filePath then
                    filePath = filePath:gsub(appName .. '/', '')
                    if filePath ~= mainFile then
                        if io.save(appFolder .. '/' .. filePath, content) then
                            print('Updating: ' .. filePath)
                            updatedFiles[filePath] = true
                        else
                            print('Failed to update: ' .. filePath)
                        end
                    end
                end
            end
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
                        break
                    end
                end
            end
        end

        local currentFiles = scanDirRecursive(appFolder)

        for _, file in ipairs(currentFiles) do
            local relativePath = file:sub(#appFolder + 2)
            if not updatedFiles[relativePath] then
                if io.deleteFile(file) then
                    print('Removing: ' .. relativePath)
                else
                    settings.updateStatus = 4
                    error('Failed to remove: ' .. file)
                end
            end
        end

        if mainFileContent then
            if io.save(appFolder .. '/' .. mainFile, mainFileContent) then
                print('Updating: ' .. mainFile)
                updatedFiles[mainFile] = true
            else
                settings.updateStatus = 4
                error('Failed to update: ' .. mainFile)
            end
        end

        settings.updateStatus = 1
        settings.updateAvailable = false
        settings.updateURL = ''
    end)
end

--#endregion

--#region APP FUNCTIONS

function updateChatMovement(dt)
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
end

function moveChatUp()
    if settings.chatMove then
        movement.timer = settings.chatTimer
        movement.up = true
    end
end

function playNotificationSound()
    if settings.enableSound and notification.allow and not notification.sound:playing() then
        notification.sound:play()
        notification.allow = false
    end
end

function sendAppMessage(message)
    table.insert(chat.messages, { message, '', '', os.time() })
    local msgIndex = #chat.messages
    local msgToUser = setTimeout(function()
        table.remove(chat.messages, msgIndex)
    end, 30)

    moveChatUp()
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
    local lowerMessage = message:lower()
    local lowerPlayerName = car.playerName:lower()

    if isPlayer then
        local hidePatterns = {
            '^RP: App not running$',
            '^PLP: running version',
            '^ACP: App not active$',
            '^D&O Racing APP:',
            '^DRIFT%%%-STRUCTION POINTS:',
            '^OSRW Race Admin Version:',
            '^RSRC Race Admin',
        }

        for _, pattern in ipairs(hidePatterns) do
            if message:match(pattern) then
                return true
            end
        end
    else
        local hidePatterns = {
            'kicked',
            'banned',
            'checksums',
            'teleported to pits',
        }

        for _, reason in ipairs(hidePatterns) do
            if lowerMessage:find(reason) then
                if lowerMessage:find(lowerPlayerName) then
                    notification.allow = true
                else
                    if lowerMessage:find('^you') or lowerMessage:find('^it is currently night') then
                        notification.allow = true
                    else
                        return true
                    end
                end
            end
        end
    end

    return false
end

function deleteOldestMessages()
    local currentTime = os.time()
    local index = 1
    while index <= #chat.messages do
        if #chat.messages > settings.chatKeepSize and
            currentTime - chat.messages[index][4] > (settings.chatOlderThan * 10) then
            table.remove(chat.messages, index)
        else
            index = index + 1
        end
    end
end

function to12hTime(timeString)
    local hour, minute = timeString:match('^(%d+):(%d+)$')
    hour, minute = tonumber(hour), tonumber(minute)
    time.period = 'AM'
    if hour >= 12 then
        time.period = 'PM'
        hour = hour % 12
        if hour == 0 then hour = 12 end
    end

    if hour < 10 then hour = '0' .. hour end
    return string.format('%s:%02d', hour, minute)
end

function updateTimeDisplay()
    local currentTime = settings.trackTime and (string.format('%02d', ac.getSim().timeHours) .. ':' .. string.format('%02d', ac.getSim().timeMinutes)) or os.date('%H:%M')
    time.final = settings.badTime and to12hTime(currentTime) or currentTime
end

function updateTimeInterval()
    updateTimeDisplay()

    if time.interval then
        clearInterval(time.interval)
        time.interval = nil
    end

    if settings.trackTime then
        time.interval = setInterval(updateTimeDisplay, 1)
    else
        time.interval = setInterval(updateTimeDisplay, 30)
    end
end

function updateSpacing()
    nowPlaying.spaces = string.rep(' ', settings.spaces)
    updateNowPlaying(true)
end

function updateLoadingAnimation()
    nowPlaying.loadingDots = (nowPlaying.loadingDots + 1) % 4
    nowPlaying.final = nowPlaying.lstr .. string.rep('.', nowPlaying.loadingDots)
end

function startLoadingAnimation()
    if not nowPlaying.loadingInterval then
        nowPlaying.isLoading = true
        nowPlaying.loadingInterval = setInterval(updateLoadingAnimation, 0.5, 'loadingAnim')
        updateLoadingAnimation()
    end
end

function stopLoadingAnimation()
    if nowPlaying.loadingInterval then
        clearInterval(nowPlaying.loadingInterval)
        nowPlaying.loadingInterval = nil
        nowPlaying.isLoading = false
    end
end

function splitTitle(title)
    local patterns = {
        '^(.-)%s*%- %s*(.+)$',
        '^(.-)%-([^%-]+)$',
    }

    for _, pattern in ipairs(patterns) do
        local artist, track = title:match(pattern)
        if artist and track then
            return artist:match('^%s*(.-)%s*$'), track:match('^%s*(.-)%s*$')
        end
    end

    return 'Unknown Artist', title
end

function updateNowPlaying(forced)
    local current = ac.currentlyPlaying()
    local artist = current.artist
    local title = current.title

    if (current.artist:lower() == 'unknown artist' or current.artist == '') and current.title ~= '' then
        artist, title = splitTitle(current.title)
    end

    if artist == '' and title == '' and not current.isPlaying then
        if nowPlaying.artist == '' or nowPlaying.title == '' then
            startLoadingAnimation()
        else
            stopLoadingAnimation()
            nowPlaying.final = nowPlaying.pstr
            nowPlaying.isPaused = true
        end
    else
        stopLoadingAnimation()
        nowPlaying.isPaused = false
        if artist ~= nowPlaying.artist or title ~= nowPlaying.title or forced then
            nowPlaying.artist = artist
            nowPlaying.title = title
            nowPlaying.scroll = (nowPlaying.artist ~= '' and nowPlaying.artist:lower() ~= 'unknown artist') and (nowPlaying.artist .. ' - ' .. nowPlaying.title .. nowPlaying.spaces) or (nowPlaying.title .. nowPlaying.spaces)
            if utf8len(nowPlaying.scroll) < 18 then nowPlaying.scroll = nowPlaying.scroll .. string.rep(' ', 18 - utf8len(nowPlaying.scroll)) end
            nowPlaying.length = utf8len(nowPlaying.scroll)
            nowPlaying.final = nowPlaying.scroll
        end
    end
end

function scrollText()
    if nowPlaying.isPaused or nowPlaying.isLoading then return end

    local firstLetter, restString

    if settings.scrollDirection == 0 then
        firstLetter = utf8sub(nowPlaying.scroll, 1, 1)
        restString = utf8sub(nowPlaying.scroll, 2)
        nowPlaying.scroll = restString .. firstLetter
    else
        firstLetter = utf8sub(nowPlaying.scroll, nowPlaying.length, nowPlaying.length)
        restString = utf8sub(nowPlaying.scroll, 1, nowPlaying.length - 1)
        nowPlaying.scroll = firstLetter .. restString
    end

    nowPlaying.final = nowPlaying.scroll
end

function startNowPlaying()
    updateSpacing()
    updateNowPlaying()

    if nowPlaying.updateInterval then
        clearInterval(nowPlaying.updateInterval)
        nowPlaying.updateInterval = nil
    end

    if nowPlaying.scrollInterval then
        clearInterval(nowPlaying.scrollInterval)
        nowPlaying.scrollInterval = nil
    end

    nowPlaying.updateInterval = setInterval(updateNowPlaying, 2, 'updateNP')
    nowPlaying.scrollInterval = setInterval(scrollText, 1 / settings.scrollSpeed, 'scrollText')
end

function stopNowPlaying()
    stopLoadingAnimation()

    if nowPlaying.updateInterval then
        clearInterval(nowPlaying.updateInterval)
        nowPlaying.updateInterval = nil
    end

    if nowPlaying.scrollInterval then
        clearInterval(nowPlaying.scrollInterval)
        nowPlaying.scrollInterval = nil
    end

    nowPlaying.final = ''
    nowPlaying.artist = ''
    nowPlaying.title = ''
    nowPlaying.isPaused = false
    nowPlaying.isLoading = false
end

function updateScrollInterval()
    if nowPlaying.scrollInterval then
        clearInterval(nowPlaying.scrollInterval)
        nowPlaying.scrollInterval = nil
    end

    nowPlaying.scrollInterval = setInterval(scrollText, 1 / settings.scrollSpeed, 'scrollText')
end

local appWindow = ac.accessAppWindow('IMGUI_LUA_Mobilephone_main')
local windowHeight, appBottom
function forceAppToBottom()
    if not appWindow:valid() then return end

    windowHeight = ac.getSim().windowHeight
    appBottom = windowHeight - appWindow:size().y

    if appWindow:position().y ~= appBottom and not ui.isMouseDragging(ui.MouseButton.Left, 0) then
        appWindow:move(vec2(appWindow:position().x, appBottom))
    end
end

--#endregion

--#region APP EVENTS

function onShowWindow()
    updateTimeInterval()
    if settings.nowPlaying then startNowPlaying() end
    if (settings.autoUpdate and doUpdate) or settings.updateAvailable then updateCheckVersion() end
end

ac.onChatMessage(function(message, senderCarIndex)
    local escapedMessage = message:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1')
    local isPlayer = senderCarIndex > -1
    local isFriend = isPlayer and checkIfFriend(senderCarIndex)
    local isMentioned = settings.notifSound and escapedMessage:lower():find('%f[%a_]' .. car.playerName:lower() .. '%f[%A_]')
    local hideMessage = false

    if isPlayer then
        hideMessage = matchMessage(isPlayer, escapedMessage) and settings.hideAnnoy
    else
        hideMessage = matchMessage(isPlayer, escapedMessage) and settings.hideKB
    end

    if not hideMessage and message:len() > 0 then
        deleteOldestMessages()
        table.insert(chat.messages, { message, isPlayer and ac.getDriverName(senderCarIndex) .. ': ' or '', isFriend and '* ' or '', os.time() })
        moveChatUp()

        if settings.enableSound and (isMentioned or settings.alwaysNotif) then notification.allow = true end

        if senderCarIndex == car.player.index then
            chat.scrollBool = true
            setTimeout(function() chat.scrollBool = false end, 0.1)
        end
    end
end)

if settings.joinNotif then
    local function connectionHandler(connectedCarIndex, action)
        local isFriend = checkIfFriend(connectedCarIndex)
        if settings.joinNotif and not settings.joinNotifFriends or isFriend then
            deleteOldestMessages()
            table.insert(chat.messages, { action .. ' the Server', ac.getDriverName(connectedCarIndex) .. ' ', isFriend and '* ' or '', os.time() })
            moveChatUp()

            if settings.enableSound and ((not settings.joinNotifSoundFriends or isFriend) or settings.alwaysNotif) then
                notification.allow = true
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

--#endregion

--#region APP SETTINGS WINDOW

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
            if ac.getPatchVersionCode() >= 3044 then
                if ui.checkbox('Force App to Bottom', settings.forceBottom) then settings.forceBottom = not settings.forceBottom end
            end

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
                updateTimeInterval()
            end

            if ui.checkbox('Use Track Time', settings.trackTime) then
                settings.trackTime = not settings.trackTime
                updateTimeInterval()
            end

            if ui.checkbox('Show Current Song', settings.nowPlaying) then
                settings.nowPlaying = not settings.nowPlaying
                if settings.nowPlaying then
                    startNowPlaying()
                else
                    stopNowPlaying()
                end
            end

            if settings.nowPlaying then
                ui.text('\t')
                ui.sameLine()
                local spacesChanged
                settings.spaces, spacesChanged = ui.slider('##Spaces', settings.spaces, 0, 25, 'Spaces: %.0f', true)
                if spacesChanged then
                    updateSpacing()
                end

                ui.text('\t')
                ui.sameLine()
                local speedChanged
                settings.scrollSpeed, speedChanged = ui.slider('##ScrollSpeed', settings.scrollSpeed, 0.1, 15, 'Scroll Speed: %.1f')
                if speedChanged then
                    updateScrollInterval()
                end

                ui.text('\t')
                ui.sameLine()
                local scrollDirStr = (settings.scrollDirection == 0) and 'Left' or 'Right'
                settings.scrollDirection = ui.slider('##ScrollDirection', settings.scrollDirection, 0, 1, 'Scroll Direction: ' .. scrollDirStr, true)
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

--#endregion

--#region APP MAIN WINDOW

local VecTR = vec2(app.padding.x, phone.size.y - phone.size.y - app.padding.y)
local VecBL = vec2(phone.size.x + app.padding.x, phone.size.y - app.padding.y)
function script.windowMain(dt)
    if ac.getPatchVersionCode() >= 3044 and settings.forceBottom then forceAppToBottom() end
    updateChatMovement(dt)

    local phoneHovered = ui.windowHovered(ui.HoveredFlags.ChildWindows)
    if (phoneHovered or chat.activeInput or SnakeGame.state ~= 'waiting') then moveChatUp() end

    if settings.notifSound or settings.joinNotifSound then
        if notification.sound:playing() and notification.sound:ended() then notification.sound:pause() end
        playNotificationSound()
    end

    ui.setCursor(vec2(0, 0 + movement.smooth))
    ui.childWindow('Display', app.size, flags.window, function()
        ui.drawImage(phone.src.display, VecTR, VecBL, phone.displayColor)

        if SnakeGame.state == 'waiting' then
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
        end
    end)

    if SnakeGame.state == 'waiting' then
        ui.setCursor(vec2(11, 73 + movement.smooth))
        ui.childWindow('Chatbox', chat.size, flags.window, function()
            if #chat.messages > 0 then
                for i = 1, #chat.messages do
                    if (i == #chat.messages and settings.chatBold) or chat.messages[i][1]:lower():find('%f[%a_]' .. car.playerName:lower() .. '%f[%A_]') then
                        ui.pushDWriteFont(phone.src.fontBold)
                    else
                        ui.pushDWriteFont(phone.src.font)
                    end

                    ui.dwriteTextWrapped(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatFontSize, phone.txtColor)
                    local dwriteSize = ui.measureDWriteText(chat.messages[i][3] .. chat.messages[i][2] .. chat.messages[i][1], settings.chatFontSize, 200)
                    ui.popDWriteFont()

                    local cursorPos = vec2(ui.getCursorX(), ui.getCursorY() - dwriteSize.y) - vec2(1, 3)
                    local senderUserName = chat.messages[i][2]

                    if senderUserName:endsWith(': ') then
                        senderUserName = senderUserName:sub(1, #senderUserName - 2)
                    elseif senderUserName:endsWith(' ') then
                        senderUserName = senderUserName:sub(1, #senderUserName - 1)
                    end

                    if phoneHovered and senderUserName ~= '' and senderUserName ~= car.playerName then
                        local messageHovered = {}
                        messageHovered[i] = ui.rectHovered(cursorPos, cursorPos + dwriteSize, true)
                        if messageHovered[i] and ui.mouseClicked(ui.MouseButton.Right) then
                            chat.mentioned = '@' .. senderUserName .. ' '
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

                --xtz: split x and z axis into 4 directions
                car.forces.left = math.max(-car.player.acceleration.x, 0)
                car.forces.right = math.max(car.player.acceleration.x, 0)
                car.forces.front = math.max(-car.player.acceleration.z, 0)
                car.forces.back = math.max(car.player.acceleration.z, 0)

                --xtz: add all the forces together and calculate the mean value then insert them into a table
                local totalForce = (car.forces.front + car.forces.back + car.forces.left + car.forces.right) / 2
                table.insert(car.forces.total, totalForce)
                local maxForce = math.max(unpack(car.forces.total))

                --xtz: set damage state if forces exceed the force values and reset damage duration if not already fading
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
    end

    ui.setCursor(vec2(16, 75 + movement.smooth))
    ui.childWindow('Easteregg', vec2(233, 310), function()
        SnakeGame.update(dt, settings.snakeHighscore, phone.txtColor)
        if SnakeGame.highScore > settings.snakeHighscore then settings.snakeHighscore = SnakeGame.highScore end
    end)

    if SnakeGame.state ~= 'waiting' then
        ui.setCursor(vec2(0, 0 + movement.smooth))
        ui.childWindow('EastereggScore', app.size, flags.window, function()
            if SnakeGame.state == 'gameover' then
                local goTxt = 'Game Over!\n' .. (SnakeGame.newHs and 'New Highscore: ' or 'Score: ') .. (SnakeGame.newHs and SnakeGame.snakeHighscore or SnakeGame.score)
                ui.pushDWriteFont(phone.src.fontNoEm)
                local goTxtSize = ui.measureDWriteText(goTxt, 17)
                ui.setCursor(vec2((ui.windowWidth() / 2) - (goTxtSize.x / 2), (ui.windowHeight() / 2) - (goTxtSize.y / 2)))
                ui.beginOutline()
                ui.dwriteTextAligned(goTxt, 17, 0, 0, goTxtSize, false, phone.txtColor)
                ui.endOutline(phone.displayColor, 1)
                ui.popDWriteFont()
            end

            local scoreTxt = string.format("%04d", SnakeGame.score)
            ui.pushDWriteFont(phone.src.fontNoEm)
            ui.setCursor(vec2(31, 53))
            ui.dwriteTextAligned(scoreTxt, 16, -1, 0, ui.measureDWriteText(scoreTxt, 16), false, phone.txtColor)
            ui.popDWriteFont()

            local hsTxt = string.format("%04d", SnakeGame.highScore)
            ui.pushDWriteFont(phone.src.fontNoEm)
            ui.setCursor(vec2(170, 53))
            ui.dwriteTextAligned('* ' .. hsTxt, 16, 1, 0, ui.measureDWriteText('* ' .. hsTxt, 16), false, phone.txtColor)
            ui.popDWriteFont()
        end)
    end

    ui.setCursor(vec2(0, 0 + movement.smooth))
    ui.childWindow('DisplayonTopImages', app.size, flags.window, function()
        if phoneHovered then
            if settings.nowPlaying then
                local nowPlayingHovered = ui.rectHovered(ui.getCursor() + vec2(64, 44), ui.getCursor() + vec2(220, 64))
                if nowPlayingHovered then
                    if ui.mouseClicked(ui.MouseButton.Right) and car.online then
                        ac.sendChatMessage('Currently listening to: ' .. nowPlaying.artist .. ' - ' .. nowPlaying.title)
                        chat.sendCd = true
                        setTimeout(function() chat.sendCd = false end, 1)
                    elseif ui.mouseClicked(ui.MouseButton.left) and not nowPlaying.isPaused then
                        settings.scrollDirection = 1 - settings.scrollDirection
                    end
                end
            end

            local timeHovered = ui.rectHovered(ui.getCursor() + vec2(6, 44), ui.getCursor() + vec2(64, 64))
            if timeHovered then
                if ui.mouseClicked(ui.MouseButton.Right) and car.online then
                    local timeString = settings.trackTime and 'Current track time: ' or 'Current local time: '
                    local timeValue = settings.badTime and (time.final .. ' ' .. time.period) or time.final
                    ac.sendChatMessage(timeString .. timeValue)
                    chat.sendCd = true
                    setTimeout(function() chat.sendCd = false end, 1)
                elseif ui.mouseClicked(ui.MouseButton.Left) then
                    settings.trackTime = not settings.trackTime
                    updateTimeInterval()
                end
            end
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
    if SnakeGame.state == 'waiting' then
        ui.setCursor(vec2(8, 347 + movement.smooth))
        ui.childWindow('Chatinput', vec2(323, 38), flags.window, function()
            local chatLabelString, chatInputString, chatInputChange, chatInputEnter = 'Type new message...', chat.mentioned .. '', _, _
            if not car.online then
                chatLabelString = 'Must be online to send message'
                chat.inputFlags = bit.bor(chat.inputFlags, ui.InputTextFlags.ReadOnly)
            end

            chatInputString, chatInputChange, chatInputEnter = ui.inputText(chatLabelString, chatInputString, chat.inputFlags)
            chat.activeInput = ui.itemActive()
            if chat.mentioned ~= '' and chatInputString ~= chat.mentioned then chat.mentioned = '' end
            --xtz: there is a cooldown on sending chat messages online
            if car.online and chatInputEnter and chatInputString and not chat.sendCd then
                ac.sendChatMessage(chatInputString)
                ui.setKeyboardFocusHere(-1)
                ui.clearInputCharacters()
                chat.mentioned = ''
                chat.sendCd = true
                --xtz: need to add this flag because otherwise the inputbox is emptied even tho clearInputCharacters is not called after pressing enter
                chat.inputFlags = bit.bor(chat.inputFlags, ui.InputTextFlags.RetainSelection)

                setTimeout(function()
                    chat.sendCd = false
                    chat.inputFlags = bit.band(chat.inputFlags, bit.bnot(ui.InputTextFlags.RetainSelection))
                end, 1)
            end
        end)
    end
end

--#endregion
