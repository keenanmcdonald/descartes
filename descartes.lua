-- 
-- Descartes v1.1.0
-- an implementation of Make Noise Rene v2 for norns, grid, and crow
-- K2/3 Cycle through layers
-- crow inputs 1 and 2 accept gates for x and y layers respectively
-- crow outputs are assignable via edit menu
-- norns display indicates how 4x4 grids are mapped to various functions 

g = grid.connect()

local SNAKE_PATTERNS = {
  {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
  {1,2,3,4,8,7,6,5,9,10,11,12,16,15,14,13},
  {4,8,12,16,3,7,11,15,2,6,10,14,1,5,9,13},
  {1,5,9,13,14,10,6,2,3,7,11,15,16,12,8,4},
  {1,2,3,4,8,12,16,15,14,13,9,5,6,7,11,10},
  {13,14,15,16,12,8,4,3,2,1,5,9,10,11,7,6},
  {1,2,5,9,6,3,4,7,10,13,14,11,8,12,15,16},
  {1,6,11,16,15,10,5,2,7,12,8,3,9,14,13,4},
  {3,15,16,2,8,9,10,6,5,11,12,7,1,13,14,4},
  {1,8,11,15,5,2,9,12,13,6,3,10,16,14,7,4},
  {7,8,15,16,5,6,13,14,3,4,11,12,1,2,9,10},
  {7,15,8,16,5,13,6,14,3,11,4,12,1,9,2,10},
  {5,6,7,8,13,14,15,16,9,10,11,12,1,2,3,4},
  {2,10,9,1,4,12,11,3,6,14,13,5,8,16,15,7},
  {13,14,15,16,11,3,4,12,9,1,2,10,5,6,7,8},
  {9,13,12,16,3,7,2,6,11,15,10,14,1,5,4,8},
}
local NOTE_NAMES = {'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'}
local SLEW_TIME = 0.04
local LAYER_NAMES = {'X','Y','C'}
local editNote = 0

local quantOctave = {1, 1, 1}
local quantScale = {
  {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
  {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
  {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
}
local stepBase = {1, 1}
local step = {1, 1, 1}
local snake = {1, 1}
local displayLayer = 1
local cGateOpen = {false, false}

local midiVelParam = {"midiVelX", "midiVelY"}
local midiChanParam = {"midiChanX", "midiChanY"}

function initTable(size, value)
  t = {}
  for i=1,size do
    table.insert(t, value)
  end
  return t
end

function init()
  params:add_group("x layer",8)
  params:add{type = "option", id = "xClock", name = "clock source", options = {"crow input 1", "crow input 2", "internal clock"}, default = 1}
  params:add{type = "option", id = "xStep", name = "step", options = {"crow output 1", "crow output 2", "crow output 3", "crow output 4", "none"}, default=1}
  params:add{type = "option", id = "xGate", name = "gate", options = {"crow output 1", "crow output 2", "crow output 3", "crow output 4", "none"}, default=2}
  params:add{type = "number", id = "midiChanX", name = "midi channel", min = 1, max = 16, default = 1}
  params:add{type = "number", id = "midiVelX", name = "midi velocity", min = 1, max = 127, default = 100}
  params:add_separator("xClockDiv", "internal clock division")
  params:add{type = "number", id = "xClockNum", name = "numerator", min = 1, max = 8, default = 1}
  params:add{type = "number", id = "xClockDen", name = "denominator", min=1, max=16, default = 1}


  params:add_group("y layer",8)
  params:add{type = "option", id = "yClock", name = "clock", options = {"crow input 1", "crow input 2", "internal clock"}, default = 2}
  params:add{type = "option", id = "yStep", name = "step", options = {"crow output 1", "crow output 2", "crow output 3", "crow output 4", "none"}, default=3}
  params:add{type = "option", id = "yGate", name = "gate", options = {"crow output 1", "crow output 2", "crow output 3", "crow output 4", "none"}, default=4}
  params:add{type = "number", id = "midiChanY", name = "midi channel", min = 1, max = 16, default = 2}
  params:add{type = "number", id = "midiVelY", name = "midi velocity", min = 1, max = 127, default = 100}
  params:add_separator("yClockDiv", "internal clock division")
  params:add{type = "number", id = "yClockNum", name = "numerator", min = 1, max = 8, default = 1}
  params:add{type = "number", id = "yClockDen", name = "denominator", min=1, max=16, default = 1}


  params:add_group("c layer",4)
  params:add{type = "option", id = "cStep", name = "step", options = {"crow output 1", "crow output 2", "crow output 3", "crow output 4", "none"}, default=5}
  params:add{type = "option", id = "cGate", name = "gate", options = {"crow output 1", "crow output 2", "crow output 3", "crow output 4", "none"}, default=5}
  params:add{type = "number", id = "midiChanC", name = "midi channel", min = 1, max = 16, default = 3}
  params:add{type = "number", id = "midiVelC", name = "midi velocity", min = 1, max = 127, default = 100}
  
  quant = {
    initTable(12, true),
    initTable(12, true),
    initTable(12, true),
  }
  access = {
    initTable(16, true),
    initTable(16, true),
    initTable(16, true),
  }
  noteValue = {
    initTable(16, 0),
    initTable(16, 0),
    initTable(16, 0),
  }
  quantizedNotes = {
    initTable(16, 0),
    initTable(16, 0),
    initTable(16, 0),
  }
  gate = {
    initTable(16, true),
    initTable(16, true),
    initTable(16, true),
  }
  glide = {
    initTable(16, false),
    initTable(16, false),
    initTable(16, false),
  }
  
  -- make data directory
  if not util.file_exists(_path.data.."descartes/") then util.make_dir(_path.data.."descartes/") end
  
  loadData()
  midi_out = midi.connect(1)
  
  crow.input[1].change = function(rising)
    advance(1, rising)
  end
  crow.input[1].mode("change", 2.0, .25, "both")
  crow.input[2].change = function(rising)
    advance(2, rising)
  end
  crow.input[2].mode("change", 2.0, .25, "both")

  clock.run(stepXClock)
  -- clock.run(stepYClock)
  
  grid_redraw()
  redraw()
end

function stepXClock()
  print(params:get("xClock"), params:get("xClock") == 3)
  print(params:get("xClockDen")/(params:get("xClockNum")*2))
  while true do
    advance(1, true)
    clock.sync(params:get("xClockDen")/(params:get("xClockNum")*2))
    advance(1, false)
    clock.sync(params:get("xClockDen")/(params:get("xClockNum")*2))
  end
end

-- function stepYClock()
--   -- while true do
--   --   if (params:get("yClock") == 3) then
--   --     advance(2, true)
--   --   end
--   --   clock.sync(params:get("yClockDen")/(params:get("yClockNum")*2))
--   --   if (params:get("yClock") == 3) then
--   --     advance(2, false)
--   --   end
--   --   clock.sync(params:get("yClockDen")/(params:get("yClockNum")*2))
--   -- end
-- end


function advance(inputNum, rising)
  l = activeLayer
  if (inputNum == 1) then
    stepOut = params:get("xStep")
    gateOut = params:get("xGate")
  elseif (inputNum == 2) then
    stepOut = params:get("yStep")
    gateOut = params:get("yGate")
  end

  --TODO handle case where access is completely blank, prevent infinite loop
  
  -- C
  if rising then
    cRow = math.floor(step[3] / 4) -- 0,1,2, or 3
    cCol = ((step[3]) % 4)+1 -- 1,2,3,4

    -- C
    if (inputNum == 1) then
      -- if there are no accessible steps in the current row
      if (access[3][(cRow*4 % 16)+1] or access[3][(cRow*4 % 16)+2] or access[3][(cRow*4 % 16)+3] or access[3][(cRow*4 % 16)+4]) then
        step[3] = (step[3] % 4 + 1) + (math.floor((step[3]-1)/4)*4)
        while (not access[3][step[3]]) do
          step[3] = (step[3] % 4 + 1) + (math.floor((step[3]-1)/4)*4)
        end
      end
    elseif (inputNum == 2) then
      if (access[3][cCol] or access[3][cCol+4] or access[3][cCol+8] or access[3][cCol+12]) then
        step[3] = (step[3]+3) % 16 + 1
        while (not access[3][step[3]]) do
          step[3] = (step[3]+3) % 16 + 1
        end
      end
    end
    if params:get("cStep") < 5 then
      --glide
      if (glide[3][step[3]]) then
        crow.output[params:get("cStep")].slew = SLEW_TIME
      else
        crow.output[params:get("cStep")].slew = 0
      end
    
      --note
      crow.output[params:get("cStep")].volts=(quantizedNotes[3][step[3]]/12)
    end
    if params:get("cGate") < 5 then
      -- gate
      if (gate[3][step[3]]) then
        crow.output[params:get("cGate")].volts = 5
        cGateOpen[inputNum] = true
      end
    end
    midi_out:note_on(quantizedNotes[3][step[3]], params:get("midiVelC"), params:get("midiChanC"))
    
    -- X and Y
    stepBase[inputNum] = (stepBase[inputNum]) % 16 + 1
    step[inputNum] = SNAKE_PATTERNS[snake[inputNum]][stepBase[inputNum]]
    while (not access[inputNum][step[inputNum]]) do
      stepBase[inputNum] = (stepBase[inputNum]) % 16 + 1
      step[inputNum] = SNAKE_PATTERNS[snake[inputNum]][stepBase[inputNum]]
    end
    
    if stepOut < 5 then
      --glide
      if (glide[inputNum][step[inputNum]]) then
        crow.output[stepOut].slew = SLEW_TIME
      else
        crow.output[stepOut].slew = 0
      end
    
      --note
      crow.output[stepOut].volts=(quantizedNotes[inputNum][step[inputNum]]/12)
    end
    
    if gateOut < 5 then
      -- gate
      if (gate[inputNum][step[inputNum]]) then
        crow.output[gateOut].volts = 5
      end
    end
    midi_out:note_on(quantizedNotes[inputNum][step[inputNum]], params:get(midiVelParam[inputNum]), params:get(midiChanParam[inputNum]))
  else
    if gateOut < 5 then
      crow.output[gateOut].volts = 0
    end
    if params:get("cGate") < 5 then
      crow.output[params:get("cGate")].volts = 0
      cGateOpen[inputNum] = false
    end
    midi_out:note_off(quantizedNotes[inputNum][step[inputNum]], params:get(midiVelParam[inputNum]), params:get(midiChanParam[inputNum]))
  end
  grid_redraw()
  redraw()
end

function redraw()
  screen.clear()
  l = displayLayer

  -- containers
  screen.level(6)
  screen.rect(1,1,32,32)
  screen.rect(33,1,32,32)
  screen.rect(65,1,32,32)
  screen.rect(97,1,31,32)
  screen.rect(1,33,32,31)
  if (displayLayer ~= 3) then
    screen.rect(33,33,32,31)
  end
  screen.stroke()
  
  -- names
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  screen.move(4,7)
  screen.text('step')
  screen.move(36,7)
  screen.text('active')
  screen.move(68,7)
  screen.text('gate')
  screen.move(100,7)
  screen.text('glide')
  screen.move(4,39)
  screen.text('quant')
  screen.move(36,39)
  if (displayLayer ~= 3) then
    screen.text('snake')
    screen.stroke()
  end
  
  if editNote >= 1 then
    screen.font_size(8)
    screen.move(70,42)
    screen.text('edit')
    screen.font_size(16)
    screen.move(70,58)
    screen.text(NOTE_NAMES[(quantizedNotes[l][editNote] % 12) + 1])
    screen.text(math.floor(quantizedNotes[l][editNote] / 12) + 1)
  else
    screen.move(70,42)
    screen.text('note')
    screen.move(70,58)
    screen.font_size(16)
    screen.text(NOTE_NAMES[(quantizedNotes[l][step[l]] % 12) + 1])
    screen.text(math.floor(quantizedNotes[l][step[l]] / 12) + 1)
  end
  
  -- layer
  screen.move(104,60)
  screen.font_face(20)
  screen.font_size(26)
  screen.text(LAYER_NAMES[l])
  
  for x=0,3 do
    for y=0,3 do
      drawStep = toStep(x+1,y+1)
      screenLevel = drawStep == step[l] and 15 or 2
      screen.level(screenLevel)
      screen.rect(8+x*5,11+y*5,3,3)
      screen.stroke()
      
      screenLevel = access[l][drawStep] and 15 or 2
      screen.level(screenLevel)
      screen.rect(40+x*5,11+y*5,3,3)
      screen.stroke()
      
      screenLevel = gate[l][drawStep] and 15 or 2
      screen.level(screenLevel)
      screen.rect(72+x*5,11+y*5,3,3)
      screen.stroke()
      
      screenLevel = glide[l][drawStep] and 15 or 2
      screen.level(screenLevel)
      screen.rect(104+x*5,11+y*5,3,3)
      screen.stroke()
      
      if (drawStep == quantOctave[l]+12 or drawStep <= 12 and quant[l][drawStep]) then
        screenLevel = 15
      else
        screenLevel = 2
      end
      screen.level(screenLevel)
      screen.rect(8+x*5,43+y*5,3,3)
      screen.stroke()
      
      if (displayLayer ~= 3) then
        screenLevel = drawStep == snake[l] and 15 or 2
        screen.level(screenLevel)
        screen.rect(40+x*5,43+y*5,3,3)
        screen.stroke()
      end
    end
  end
  
  screen.stroke()
  screen.update()
  grid_redraw()
end

function grid_redraw()
  l = displayLayer

  g:all(0)
  
  -- notes
  for i=1,16 do
    x, y = toGrid(i)
    g:led(x, y, math.floor((quantizedNotes[l][i]/quantScale[l][#quantScale[l]])*8))
  end
  
  --active step
  x, y = toGrid(step[l])
  g:led(x, y, 12)

  
  --access
  for i=1,16 do
    if (access[l][i]) then
      brightness = 12
    else
      brightness = 2
    end
    x, y = toGrid(i, 4)
    g:led(x, y, brightness)
  end
  
  -- gate
  for i=1,16 do
    if (gate[l][i]) then
      brightness = 12
    else
      brightness = 2
    end
    x, y = toGrid(i, 8)
    g:led(x, y, brightness)
  end
  
  --glide
  for i=1,16 do
    if (glide[l][i]) then
      brightness = 12
    else
      brightness = 2
    end
    x, y = toGrid(i, 12)
    g:led(x, y, brightness)
  end

  -- quant
  for i=1,16 do
    if (i <= 12 and quant[l][i]) then
      brightness = 12
    else
      brightness = 2
    end
    x, y = toGrid(i, 0, 4)
    g:led(x,y,brightness)
  end
  g:led(quantOctave[l], 5, 15)

  --snake
  if (displayLayer~=3) then
    for i=1,16 do
      x,y=toGrid(i, 4, 4)
      g:led(x,y,2)
    end
    x,y = toGrid(snake[l], 4,4)
    g:led(x,y,12)
  end
  
  --layer
  if l==1 then
    g:led(13,5,12)
    g:led(14,6,12)
    g:led(15,7,12)
    g:led(16,8,12)
    g:led(16,5,12)
    g:led(15,6,12)
    g:led(14,7,12)
    g:led(13,8,12)
  elseif l==2 then
    g:led(13,5,12)
    g:led(14,6,12)
    g:led(16,5,12)
    g:led(15,6,12)
    g:led(14,7,12)
    g:led(14,8,12)
  elseif l == 3 then
    g:led(13,5,12)
    g:led(14,5,12)
    g:led(15,5,12)
    g:led(16,5,12)
    g:led(13,6,12)
    g:led(13,7,12)
    g:led(13,8,12)
    g:led(14,8,12)
    g:led(15,8,12)
    g:led(16,8,12)
  end

  g:refresh()
end

function toGrid(v, xOffset, yOffset)
  xOffset = xOffset or 0
  yOffset = yOffset or 0
  if (v <= 0) then
    return 0,0
  end
  x = ((v-1) % 4)+1+xOffset
  y = math.abs(4-math.floor((v-1)/4)) + yOffset
  return x, y
end

function toStep(x, y)
  number = (((math.abs(((math.floor(y / 4)+1)*4)-y)%4))*4)+(((x-1)%4)+1)
  return number
end

function getZone(x, y)
  if (x <= 4 and y <= 4) then
    return 'note'
  elseif (x >= 5 and x <= 8 and y <= 4) then
    return 'access'
  elseif (x >= 9 and x <= 12 and y <= 4) then
    return 'gate'
  elseif (x >= 12 and x<= 16 and y <= 4) then
    return 'glide'
  elseif (x <= 4 and y == 5) then
    return 'quantOctave'
  elseif (x <= 4 and y >= 6) then
    return 'quant'
  elseif (x>=5 and x<= 8 and y>=5) then
    return 'snake'
  end
end

function updateQuantScale(l)
  quantScale[l] = {}
  for i=1,quantOctave[l] do
    for j=1,#quant[l] do
      if (quant[l][j]) then
        table.insert(quantScale[l], (i-1)*12 + j-1)
      end
    end
    if (i == quantOctave[l] and quant[l][1]) then
      table.insert(quantScale[l], 12*i)
    end
  end
  updateQuantizedNotes(l)
end

function updateQuantizedNotes(l)
  quantizedNotes[l] = {}
  for i=1,#noteValue[l] do
    table.insert(quantizedNotes[l], quantizeValue(noteValue[l][i]))
  end
end

function quantizeValue(value)
  unQuantizedValue = quantScale[l][#quantScale[l]] * (value / 100)
  leastDiff = 100
  closestNote = nil
  --TODO: what if there are no notes in the xQuantizer?
  for j=1,#quantScale[l] do
    diff = math.abs(quantScale[l][j] - unQuantizedValue)
    if (diff < leastDiff) then
      leastDiff = diff
      closestNote = quantScale[l][j]
    end
  end
  return closestNote
end

function key(n,z)
  if n == 3 and z == 1 then
    displayLayer = displayLayer % 3 + 1
  elseif n == 2 and z == 1 then
    if (displayLayer-1 == 0) then
      displayLayer = 3
    else
      displayLayer = displayLayer-1
    end
  end
  saveData()
  grid_redraw()
  redraw()
end

function enc(n, d)
  l = displayLayer
  if (editNote >= 1) then
    noteValue[l][editNote] = util.clamp(noteValue[l][editNote]+d*2, 0, 100)
  end
  updateQuantizedNotes(l)
  grid_redraw()
  redraw()
end

function g.key(x,y,z)
  l = displayLayer
  if (z==1) then
    if (getZone(x,y) == 'note') then
      editNote = toStep(x,y)
    elseif (getZone(x,y) == 'access') then
      access[l][toStep(x,y)] = not access[l][toStep(x,y)]
    elseif(getZone(x,y) == 'gate') then
      gate[l][toStep(x,y)] = not gate[l][toStep(x,y)]
    elseif(getZone(x,y) == 'quantOctave') then
      quantOctave[l] = x
      updateQuantScale(l)
    elseif(getZone(x,y) == 'quant') then
      quant[l][toStep(x,y)] = not quant[l][toStep(x,y)]
      updateQuantScale(l)
    elseif(getZone(x,y) == 'glide') then
      glide[l][toStep(x,y)] = not glide[l][toStep(x,y)]
    elseif(getZone(x,y) == 'snake') then
      snake[l] = toStep(x,y)
    end
  else
    editNote = 0
  end
  saveData()
  grid_redraw()
  redraw()
end

function saveData()
  saveState = {}
  saveState['quantOctave'] = quantOctave
  saveState['quantScale'] =  quantScale
  saveState['quantizedNotes'] = quantizedNotes
  saveState['snake'] = snake
  saveState['quant'] = quant
  saveState['access']  = access
  saveState['noteValue'] = noteValue
  saveState['gate'] = gate
  saveState['glide'] = glide
  tab.save(saveState, _path.data.."descartes/".."descartes_state.txt")
  params:write(_path.data.."descartes/".."descartes_params.pset")
end

function loadData()
  saveState = tab.load(_path.data.."descartes/".."descartes_state.txt")
  if saveState ~= nil then
    quantOctave = saveState['quantOctave']
    quantScale = saveState['quantScale']
    quantizedNotes = saveState['quantizedNotes']
    snake = saveState['snake']
    quant =  saveState['quant']
    access = saveState['access']
    noteValue = saveState['noteValue']
    gate = saveState['gate']
    glide = saveState['glide']
  end
  params:read(_path.data.."descartes/".."descartes_params.pset")
  redraw()
  grid_redraw()
end