--made by C1XTZ

--#region 'GLOBAL' GAME VARIABLES

local SnakeGame = {
  state = 'waiting',
  newHs = false,
  score = 0,
  highScore = 0
}

--#endregion

--#region GAME SETTINGS

local cellSize = 18
local elementColor = rgb.colors.black
local outlineThickness = math.floor(cellSize / 2)
local outlineHalfThickness = math.floor(outlineThickness / 2)
local movementInterval = 0.26
local offset = vec2(9, 0)
local initialSnakeLength = 3
local numCellsX, numCellsY

--#endregion

--#region GAME OBJECTS

local snake = {}
local food = vec2(0, 0)
local direction = vec2(1, 0)
local lastInput = vec2(1, 0)
local lastUpdateTime = 0
local gameOverTime = 0

--#endregion

--#region INPUT VARIABLES

-- I noticed that my gamepad also gets detected with ac.getJoystickDpadValue(), im not sure if this is the case for all gamepads or just certain ones so im leaving ac.isGamepadButtonPressed() in, just in case
local inputSequence = {}
local requiredKeyboardSequence = { ui.KeyIndex.Up, ui.KeyIndex.Up, ui.KeyIndex.Down, ui.KeyIndex.Down, ui.KeyIndex.Left, ui.KeyIndex.Right, ui.KeyIndex.Left, ui.KeyIndex.Right }
local requiredGamepadSequence = { ac.GamepadButton.DPadUp, ac.GamepadButton.DPadUp, ac.GamepadButton.DPadDown, ac.GamepadButton.DPadDown, ac.GamepadButton.DPadLeft, ac.GamepadButton.DPadRight, ac.GamepadButton.DPadLeft, ac.GamepadButton.DPadRight }
local requiredJoystickSequence = { 0, 0, 18000, 18000, 27000, 9000, 27000, 9000 }
local keyboardStates = {}
local gamepadStates = {}
local joystickState = -1

--#endregion

--#region GAME LOGIC FUNCTIONS

local function getGridDimensions()
  local availableSpace = ui.windowSize()
  local playAreaWidth = availableSpace.x - (2 * outlineThickness)
  local playAreaHeight = availableSpace.y - (2 * outlineThickness)
  local numCellsX = math.floor(playAreaWidth / cellSize)
  local numCellsY = math.floor(playAreaHeight / cellSize)
  return numCellsX, numCellsY
end

local function checkFoodPosition(x, y)
  for _, segment in ipairs(snake) do
    if segment.x == x and segment.y == y then
      return true
    end
  end
  return false
end

local function getFoodPosition()
  local x, y
  repeat
    x, y = math.random(1, numCellsX), math.random(1, numCellsY)
  until not checkFoodPosition(x, y)
  return vec2(x, y)
end

local function getRandomDirection()
  local directions = {
    vec2(1, 0),
    vec2(-1, 0),
    vec2(0, 1),
    vec2(0, -1)
  }
  return directions[math.random(1, 4)]
end

function resetGame()
  local startX = math.random(initialSnakeLength, numCellsX - initialSnakeLength)
  local startY = math.random(initialSnakeLength, numCellsY - initialSnakeLength)

  direction = getRandomDirection()
  lastInput = direction:clone()

  snake = {}
  for i = 0, initialSnakeLength - 1 do
    table.insert(snake, vec2(startX - i * direction.x, startY - i * direction.y))
  end

  food = getFoodPosition()
  SnakeGame.score = 0
  SnakeGame.state = 'playing'
  gameOverTime = 0
end

local function updateSnake()
  local newHead = direction:clone():add(snake[1])
  table.insert(snake, 1, newHead)

  if newHead.x < 1 or newHead.x > numCellsX or newHead.y < 1 or newHead.y > numCellsY then
    return false
  end

  for i = 2, #snake do
    if snake[i].x == newHead.x and snake[i].y == newHead.y then
      return false
    end
  end

  if newHead.x == food.x and newHead.y == food.y then
    food = getFoodPosition()
    SnakeGame.score = SnakeGame.score + 1

    local speedUp = false
    if SnakeGame.score % 3 == 0 and speedUp == false then
      speedUp = true
    end

    if speedUp then
      movementInterval = math.round(movementInterval * 0.9, 2)
      speedUp = false
    end
  else
    table.remove(snake)
  end

  return true
end

local directionMap = {
  [ui.KeyIndex.Left] = vec2(-1, 0),
  [ui.KeyIndex.Right] = vec2(1, 0),
  [ui.KeyIndex.Up] = vec2(0, -1),
  [ui.KeyIndex.Down] = vec2(0, 1),
  [ac.GamepadButton.DPadLeft] = vec2(-1, 0),
  [ac.GamepadButton.DPadRight] = vec2(1, 0),
  [ac.GamepadButton.DPadUp] = vec2(0, -1),
  [ac.GamepadButton.DPadDown] = vec2(0, 1)
}

--#endregion

--#region INPUT FUNCTIONS

local function isInputPressed(key)
  return ui.keyboardButtonPressed(key) or ac.isGamepadButtonPressed(0, key)
end

local function getJoystickInput(dt)
  local joystickValue = ac.getJoystickDpadValue(0, 0)
  local joystickInputStartTime = 0

  if joystickValue ~= joystickState then
    joystickState = joystickValue
    joystickInputStartTime = 0
    return joystickValue
  elseif joystickValue ~= -1 then
    joystickInputStartTime = joystickInputStartTime + dt
    if joystickInputStartTime >= 0.2 then
      joystickInputStartTime = 0
      return joystickValue
    end
  end

  return -1
end

local function updateDirection(dt)
  for key, dir in pairs(directionMap) do
    if isInputPressed(key) and not (dir.x == -direction.x and dir.y == -direction.y) then
      lastInput = dir
      break
    end
  end

  local joystickInput = getJoystickInput(dt)
  if joystickInput ~= -1 then
    local joystickDir
    if joystickInput == 0 then
      joystickDir = vec2(0, -1)
    elseif joystickInput == 9000 then
      joystickDir = vec2(1, 0)
    elseif joystickInput == 18000 then
      joystickDir = vec2(0, 1)
    elseif joystickInput == 27000 then
      joystickDir = vec2(-1, 0)
    end

    if joystickDir and not (joystickDir.x == -direction.x and joystickDir.y == -direction.y) then
      lastInput = joystickDir
    end
  end
end

local function areSequencesEqual(seq1, seq2)
  if #seq1 ~= #seq2 then return false end
  for i = 1, #seq1 do
    if seq1[i] ~= seq2[i] then return false end
  end
  return true
end

local function checkInputSequence(dt)
  local currentKeyboardStates = {}
  local currentGamepadStates = {}
  local currentJoystickState = getJoystickInput(dt)

  for _, key in ipairs(requiredKeyboardSequence) do
    currentKeyboardStates[key] = ui.keyboardButtonPressed(key)
  end
  for _, key in ipairs(requiredGamepadSequence) do
    currentGamepadStates[key] = ac.isGamepadButtonPressed(0, key)
  end

  local sequenceType = nil
  for _, key in ipairs(requiredKeyboardSequence) do
    if currentKeyboardStates[key] and not keyboardStates[key] then
      table.insert(inputSequence, key)
      keyboardStates[key] = true
      sequenceType = 'keyboard'
    elseif not currentKeyboardStates[key] then
      keyboardStates[key] = false
    end
  end

  for _, key in ipairs(requiredGamepadSequence) do
    if currentGamepadStates[key] and not gamepadStates[key] then
      table.insert(inputSequence, key)
      gamepadStates[key] = true
      sequenceType = 'gamepad'
    elseif not currentGamepadStates[key] then
      gamepadStates[key] = false
    end
  end

  if currentJoystickState ~= -1 then
    table.insert(inputSequence, currentJoystickState)
    sequenceType = 'joystick'
  end

  if #inputSequence > #requiredKeyboardSequence then
    table.remove(inputSequence, 1)
  end

  if #inputSequence == #requiredKeyboardSequence then
    if sequenceType == 'keyboard' and areSequencesEqual(inputSequence, requiredKeyboardSequence) then
      resetGame()
      inputSequence = {}
    elseif sequenceType == 'gamepad' and areSequencesEqual(inputSequence, requiredGamepadSequence) then
      resetGame()
      inputSequence = {}
    elseif sequenceType == 'joystick' and areSequencesEqual(inputSequence, requiredJoystickSequence) then
      resetGame()
      inputSequence = {}
    end
  end
end


--#endregion

--#region DRAW FUNCTIONS

local function drawRectAtGridPosition(pos, color)
  local topLeft = vec2((pos.x - 1) * cellSize + outlineThickness + offset.x, (pos.y - 1) * cellSize + outlineThickness + offset.y)
  local bottomRight = vec2(pos.x * cellSize + outlineThickness + offset.x, pos.y * cellSize + outlineThickness + offset.y)
  ui.drawRectFilled(topLeft, bottomRight, color, 0)
end

local function drawGrid()
  local topLeft = vec2(outlineThickness + offset.x, outlineThickness + offset.y)
  local bottomRight = vec2(numCellsX * cellSize + outlineThickness + offset.x, numCellsY * cellSize + outlineThickness + offset.y)

  local function drawOutline(start, finish)
    ui.drawSimpleLine(start, finish, elementColor, outlineThickness)
  end

  drawOutline(vec2(topLeft.x - outlineHalfThickness - 5, topLeft.y - outlineHalfThickness), vec2(bottomRight.x + outlineHalfThickness + 5, topLeft.y - outlineHalfThickness))
  drawOutline(vec2(topLeft.x - outlineHalfThickness, topLeft.y - outlineHalfThickness), vec2(topLeft.x - outlineHalfThickness, bottomRight.y + outlineHalfThickness))
  drawOutline(vec2(bottomRight.x + outlineHalfThickness, topLeft.y - outlineHalfThickness), vec2(bottomRight.x + outlineHalfThickness, bottomRight.y + outlineHalfThickness))
  drawOutline(vec2(topLeft.x - outlineHalfThickness - 5, bottomRight.y + outlineHalfThickness), vec2(bottomRight.x + outlineHalfThickness + 5, bottomRight.y + outlineHalfThickness))
end

local function drawSnake()
  for _, segment in ipairs(snake) do
    drawRectAtGridPosition(segment, elementColor)
  end
end

local function drawAppleAtGridPosition(pos, color)
  local cellTopLeft = vec2((pos.x - 1) * cellSize + outlineThickness + offset.x, (pos.y - 1) * cellSize + outlineThickness + offset.y)
  local smallCellSize = cellSize / 3

  local positions = {
    vec2(cellTopLeft.x + smallCellSize, cellTopLeft.y),
    vec2(cellTopLeft.x, cellTopLeft.y + smallCellSize),
    vec2(cellTopLeft.x + 2 * smallCellSize, cellTopLeft.y + smallCellSize),
    vec2(cellTopLeft.x + smallCellSize, cellTopLeft.y + 2 * smallCellSize)
  }

  for _, pos in ipairs(positions) do
    ui.drawRectFilled(pos, vec2(pos.x + smallCellSize, pos.y + smallCellSize), color, 0)
  end
end

local function drawFood()
  drawAppleAtGridPosition(food, elementColor)
end

--#endregion

--#region MAIN UPDATE FUNCTION

function SnakeGame.update(dt, highscore, color)
  if not numCellsX or not numCellsY then numCellsX, numCellsY = getGridDimensions() end
  if highscore > SnakeGame.highScore then SnakeGame.highScore = highscore end
  if color ~= elementColor then elementColor = color end

  if SnakeGame.state == 'playing' then
    updateDirection(dt)

    lastUpdateTime = lastUpdateTime + dt
    if lastUpdateTime >= movementInterval then
      direction = lastInput

      if not updateSnake() then
        SnakeGame.state = 'gameover'
      end
      lastUpdateTime = 0
    end
  elseif SnakeGame.state == 'gameover' then
    gameOverTime = gameOverTime + dt
    if SnakeGame.score > SnakeGame.highScore then
      SnakeGame.highScore = SnakeGame.score
      SnakeGame.newHs = true
    end
    if gameOverTime >= 5 then
      SnakeGame.state = 'waiting'
      gameOverTime = 0
    end
  elseif SnakeGame.state == 'waiting' then
    checkInputSequence(dt)
    if SnakeGame.newHs then SnakeGame.newHs = false end
  end

  if SnakeGame.state ~= 'waiting' then
    drawGrid()
    drawSnake()
    drawFood()
  end
end

--#endregion

return SnakeGame
