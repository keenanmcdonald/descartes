function bothGates(direction)
  print(direction)
  local name = direction and 'start' or 'end'
  local v = direction and 5 or 0
  print( name .. ' gate')
  crow.output[2].volts = v
end

crow.input[1].change = bothGates
crow.input[1].mode('change', 2.0, .25, 'both')
