# The Divine Scientist
This was a game I created for a retrogames archeology course (Aycock).
The source is 6502 ASM which compiles to run on VIC-20 hardware or emulator.
This code is highly optimized, making use of self-modifying code, laying out data structures to minimize the instruction widths required to act on it, interlaying code and data (polygots), as well as many other subtle optimizations.

## Author
Mike Clark - 2016

## Intro
After a long day of work at the laboratory, you begin to bicycle home.
Suddenly you begin to feel a little strange...

## Game Screen

### Scores
The top row contains the current score.
The bottom row contains the hi score.

### Color Meters
You have two sets of two color meters below the current score,
and above the hi score.

### Playfield
The playfield consists of one row of non-interactive background of space and
stars, as well as 5 horizontal bands of color. The horizontal bands will
consist of filled (colored) and unfilled (black) tiles. (as well as other 
occupied tiles discussed below.)

## Playing

### Tiles
Stay on the (filled) color tiles to build up that color meter and points.
Black tiles (unfilled) decreases that color meter and points.

### Magenta Tiles
You will not gain any color meter.
You will lose from each color meter concurrently, if you occupy an unfilled 
(black) magenta tile.

### Monsters and Gold
Avoid monsters. Get the gold.
There are two types of monsters and two types of gold: small and large.
 Small reduces/increases points by 4.
 Large reduces/increases points by 4.
The large monster has fangs and the large gold looks like a lollipop.

### Temporal Mechanics
If all of your color meters are filled, press the space key to reverse time and
attempt to follow your past selves back to the start for an extra bonus!
If you fail to follow your past self, or you reach the start, time will move 
forward again.

You can unlock this power up to four times per level, with each reversal 
constricting time further while you travel backwards. If you successfully 
complete four backwards journeys to the start, who knows what might happen the 
next time your paint meter fills???

## Files
All source files and makefiles to build the project.
Also included are a sprite generator and packer used by the game engine.
Assets directory contains sprite images used in project.

## Features
- 3 byte XOR shift prng
- independant animation and sprite gen/packer for extensability
- runtime support for modulating the abstract game clock
- forwards and backwards tracers animation for the player sprite
- hi score
- made careful use of how we chose to lay down data to optimize code acting on 
it

## Future
- less difficult
- better sound
- music (maybe pushing the limit for space on a regular cart?)
- the part of the main loop that branches on the direction of play 
could be combined if we could generalize one more routine (see prog.s file)
- push more to ZP, but my concern was with space not speed.


## Known Issues
- prng not winding properly in certain edge case, leaves a 1 tile wide gap in 
the first (screen-width) column of the level. However, this is asthetic and does
not corrupt the level generator.


## Modifying Assets
See inline comments for spritegen.py and pack3.bsh

## Compiling and Running
$ make clean && make
Run compiled divine.prg in emulator (VICE).


