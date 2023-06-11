# descartes
Cartesian sequencer for norns, grid and crow. 

## Requirements
- norns
- grid

## Documentation
- Norns' screen indicates which parts of the grid correspond to which parameters of the sequencer.
- For access, gate, and glide, press keys on the grid to enable / disable behavior for a particular step.
- Hold a grid key in the step section and turn E2 to change the current note on that step.
- Go to params to map the various layers' cv and gate outputs to crows four outputs

## Changelog

### v1.2.0
- adjusted midi note values so that output midi note numbers match note name displayed
- added midi offset param in each layer

### v1.1.1
- fixed a bug in which norns would freeze if a user set turned off all access cells
- fixed a bug that prevented the y layer from working entirely
- fixed assignable inputs

### v1.1.0
- crow is no longer required!
- added midi output for all 3 channels, velocity and midi channel configurable in params
- added internal clocking, users can opt to use an internal clock for any layer rather than crow, users can set division of global clock
- added param groups
- fixed a bug in which x clocks weren't cycling correctly in the c layer
- fixed a bug in which the script may not have been loading due to an absence of save data
