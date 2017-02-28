#!/bin/sh
# Makefile to create program cartridge that can be loaded by VICE vic-20 emulator

.PHONY:all
all: divine.prg

divine.prg:prog.s block.dat
	dasm $< -v4 -o$@

block.dat:sprite.lst 
	./pack3.bsh $<

.PHONY:sprites
sprites:
	./spritegen.py assets

.PHONY:clean
clean:
	rm -f divine.prg 
