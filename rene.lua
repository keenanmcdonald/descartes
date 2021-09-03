g = grid.connect()

local notes = {0,2,4,5,7,9,11,12,12,11,9,7,5,4,2,0}
local editNote = 0

function init()
  redraw()
  print('init')
end

function redraw()
  print('redraw')
  screen.clear()
  screen.font_face(25)
  screen.font_size(6)
  screen.move(30, 5)
  screen.text(editNote)
  screen.update()
  grid_redraw()
end

function grid_redraw()
  g:all(0)
  for x=1,16 do
    g:led((x % 4) + 1, math.floor(x/4)+1, notes[x])
  end
  g:refresh()
  print('redraw grid')
end

function g.key(x,y,z)
  if (x <= 4 and y <= 4 and z == 1) then
    editNote = ((y-1)*4)+x
  elseif z == 0 then
    editNote = 0
  end
  redraw()
end 