g = grid.connect()

local quantOctave = 1
local quant = {true, false, true, false, true, true, false, true, false, true, false, true}
local quantScale = {0, 2, 4, 5, 7, 9, 11, 12}
local noteNames = {'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'}
local metRunning = false
local stepBase = 1
local step = 1
local editNote = 0
local snakePatterns = {
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
local slewTime = 0.04
local snake = 1

function initTable(size, value)
  t = {}
  for i=1,size do
    table.insert(t, value)
  end
  return t
end

function init()
  params:add{type = "option", id = "clockSrc", name = "clock source", options = {"internal", "crow"}, default=1}
  access = initTable(16, true)
  noteValue = initTable(16, 0)
  quantizedNotes = initTable(16, 0)
  gate = initTable(16, true)
  glide = initTable(16, false)
  crow.input[1].change = advance
  crow.input[1].mode("change", 2.0, .25, "rising")
  redraw()
end

function advance()
  stepBase = (stepBase) % 16 + 1
  step = snakePatterns[snake][stepBase]
  while (not access[step]) do
    step = (step) % 16 + 1
  end
  --glide
  if (glide[step]) then
    crow.output[1].slew = slewTime
  else
    crow.output[1].slew = 0
  end
  --note
  crow.output[1].volts=(quantizedNotes[step]/12)
  --gate
  if (gate[step]) then
    norns.crow.events = {}
    crow.input[1].change = endGate
    crow.input[1].mode("change", 2.0, .25, "falling")
    crow.output[2].volts = 5
  end
  redraw()
end

function endGate()
  norns.crow.events = {}
  crow.output[2].volts = 0
  crow.input[1].change = advance
  crow.input[1].mode("change", 2.0, .25, "rising")
end

function redraw()
  screen.clear()
  if (editNote >= 1) then
    screen.font_face(3)
    screen.font_size(20)
    screen.move(30, 20)
    screen.text(editNote)
    screen.text(': ')
    screen.text(noteNames[(quantizedNotes[editNote] % 12) + 1])
    screen.text(math.floor(quantizedNotes[editNote] / 12) + 1)
  else
    screen.font_face(1)
    screen.font_size(8)
    screen.level(15)
    --step
    screen.rect(1,1,32,32)
    screen.move(2,6)
    screen.text('step')
    
    --note
    screen.rect(32,1,32,32)
    screen.move(34,6)
    screen.text('note')

    -- active
    screen.rect(64,1,32,32)
    screen.move(66,6)
    screen.text('active')
    
    -- gate
    screen.rect(96,1,32,32)
    screen.move(98,6)
    screen.text('gate')
    
    --quant
    screen.rect(1,32,32,32)
    screen.move(2,38)
    screen.text('quant')
    
    -- glide
    screen.rect(32,32,32,32)
    screen.move(34,38)
    screen.text('glide')
    
    --snake
    screen.rect(64,32,32,32)
    screen.move(66,38)
    screen.text('snake')
    
    screen.rect(96,32,32,32)

  end
  screen.stroke()
  screen.update()
  grid_redraw()
end

function grid_redraw()
  g:all(0)
  --active step
  x, y = toGrid(step)
  g:led(x, y, 15)
  -- notes
  for i=1,16 do
    x, y = toGrid(i, 4)
    g:led(x, y, math.floor((quantizedNotes[i]/quantScale[#quantScale])*15))
  end
  
  --access
  for i=1,16 do
    if (access[i]) then
      brightness = 15
    else
      brightness = 0
    end
    x, y = toGrid(i, 8)
    g:led(x, y, brightness)
  end
  
  -- gate
  for i=1,16 do
    if (gate[i]) then
      brightness = 15
    else
      brightness = 0
    end
    x, y = toGrid(i, 12)
    g:led(x, y, brightness)
  end
  
  -- quant
  g:led(quantOctave, 5, 15)
  for i=1,#quant do
    if (quant[i]) then
      brightness = 15
    else
      brightness = 0
    end
    x, y = toGrid(i, 0, 4)
    g:led(x,y,brightness)
  end
  
  --glide
  for i=1,16 do
    if (glide[i]) then
      brightness = 15
    else
      brightness = 0
    end
    x, y = toGrid(i, 4, 4)
    g:led(x, y, brightness)
  end
  
  --snake
  x,y = toGrid(snake, 8,4)
  g:led(x,y,15)

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
    return 'play'
  elseif (x >= 5 and x <= 8 and y <= 4) then
    return 'note'
  elseif (x >= 9 and x <= 12 and y <= 4) then
    return 'access'
  elseif (x >= 13 and x <= 16 and y <= 4) then
    return 'gate'
  elseif (x <= 4 and y == 5) then
    return 'quantOctave'
  elseif (x <= 4 and y >= 6) then
    return 'quant'
  elseif (x >= 5 and x<= 8 and y >= 5) then
    return 'glide'
  elseif (x>=9 and x<= 12 and y>=5) then
    return 'snake'
  end
end

function updateQuantScale()
  quantScale = {}
  for i=1,quantOctave do
    for j=1,#quant do
      if (quant[j]) then
        table.insert(quantScale, (i-1)*12 + j-1)
      end
    end
    if (i == quantOctave and quant[1]) then
      table.insert(quantScale, 12*i)
    end
  end
  updateQuantizedNotes()
end

function updateQuantizedNotes()
  quantizedNotes = {}
  for i=1,#noteValue do
    table.insert(quantizedNotes, quantizeValue(noteValue[i]))
  end
end

function quantizeValue(value)
  unquantizedValue = quantScale[#quantScale] * (value / 100)
  print(unquantizedValue)
  leastDiff = 100
  closestNote = nil
  --TODO: what if there are no notes in the quantizer?
  for j=1,#quantScale do
    diff = math.abs(quantScale[j] - unquantizedValue)
    if (diff < leastDiff) then
      leastDiff = diff
      closestNote = quantScale[j]
    end
  end
  return closestNote
end

function key(n,z)
  -- print("key: ", n,z)
  -- if (n == 2 and z == 1) then
  --   if (metRunning == false) then 
  --     met:start()
  --     metRunning = true
  --   else
  --     met:stop()
  --     metRunning = false
  --   end
  -- end
  -- redraw()
end

function enc(n, d)
  if (editNote >= 1) then
    noteValue[editNote] = util.clamp(noteValue[editNote]+d*2, 0, 100)
  end
  updateQuantizedNotes()
  redraw()
end

function g.key(x,y,z)
  if (z==1) then
    if (getZone(x,y) == 'note') then
      editNote = toStep(x,y)
    elseif (getZone(x,y) == 'access') then
      access[toStep(x,y)] = not access[toStep(x,y)]
    elseif(getZone(x,y) == 'gate') then
      gate[toStep(x,y)] = not gate[toStep(x,y)]
    elseif(getZone(x,y) == 'quantOctave') then
      quantOctave = x
      updateQuantScale()
    elseif(getZone(x,y) == 'quant') then
      quant[toStep(x,y)] = not quant[toStep(x,y)]
      updateQuantScale()
    elseif(getZone(x,y) == 'glide') then
      print('glide', x, y)
      glide[toStep(x,y)] = not glide[toStep(x,y)]
      printTable(glide)
    elseif(getZone(x,y) == 'snake') then
      snake = toStep(x,y)
    end
  else
    editNote = 0
  end
  redraw()
end

function printTable(t)
  print('table: ')
  for i=1,#t do
    print(i, t[i])
  end
end