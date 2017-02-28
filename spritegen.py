#!/bin/python

# Quick&Dirty program to convert a monochrome PPM file to an encoding we can use with a 6502
# asm file. This will either output raw bytes, or ascii that can be dropped 
# into an ASM file before compilation. In non-raw mode, it will also generate
# an ascii art comment showing the bitmap of the sprite, add label tags as well
# delimiting each section of bytes using the format:
# .SPRITE_lo_<DIR or FILE>
#     ....
#  .SPRITE_hi_<DIR or FILE>
#
#
# Mike Clark - 2016
#
# Usage: ./spritegen.py <r=raw output>
import sys
import os
import binascii
from struct import *

def main(argv):
	out_file_ext = ".sdat"
	
	if (len(argv) < 2):
		print "Usage: " + argv[0] + " <input_filename or dir>"
		return 1
	
	if (os.path.isdir(argv[1])):
		files = [f for f in os.listdir(argv[1]) if os.path.isfile(os.path.join(argv[1], f))]
	else:
		files = [argv[1]]
		
	cnt = 0
	for fyle in files:
		#fylepath  = os.path.join(argv[1], fyle)
		infyle = os.path.join(argv[1], fyle)
		outfyle = os.path.join(argv[1], os.path.splitext(os.path.basename(infyle ))[0]) + out_file_ext
		outfyle_inverse = os.path.join(argv[1], "InV" + os.path.splitext(os.path.basename(infyle ))[0]) + out_file_ext
		print "Generating '" + str(outfyle) + "' and '" + str(outfyle_inverse) + "' from '" + str(infyle) + "'"
		
		output = []
		inv_output = []
		with open(infyle,"rb") as f:
			f.seek(12)
			ca = f.read()
			f.close()
		ba = bytearray(ca)
		byt = 0
		ascii_art = [';']
		ascii_art_inv = [';']
		for i in range(0,len(ba),3):
			if  (ba[i] == 0 and ba[i+1] == 0 and ba[i+2] == 0):
				byt += 1
				ascii_art.append('1')
				ascii_art_inv.append('0')
			else:
				ascii_art.append('0')
				ascii_art_inv.append('1')
				
			if ((i % (3*8)) == 21):
				#export the byte we have built up
				output.append(byt)
				ibyt = (~byt) & 0xFF
				inv_output.append(ibyt)
				print "BYTE: " + str(byt) + " : " + str(ibyt)
				#inv_output.append(~byt & 0xF) # we have to mask off the upper bits
				byt = 0
				ascii_art.append('\n')
				ascii_art_inv.append('\n')
				ascii_art.append(';')
				ascii_art_inv.append(';')
			byt = byt << 1

		# Write ascii dasm
		# we add a lable that includes the filename and a unique id on the end
		# indicating the order in which it was processed
		with open(outfyle ,"w") as f:
			with open(outfyle_inverse ,"w") as fi:
			
				
				f.write("".join(ascii_art) + "\n")
				fi.write("".join(ascii_art_inv) + "\n")
				f.write(".SPRITE_lo_" + fyle + "_" + str(cnt))
				fi.write(".SPRITE_lo_" + "InV" + fyle + "_" + str(cnt) )
				for i in range(0, len(output)):
					if ((i % 8) == 0):
						f.write("\n HEX")
						fi.write("\n HEX")
					f.write( " " + binascii.b2a_hex(bytearray([output[i]])))
					fi.write( " " + binascii.b2a_hex(bytearray([inv_output[i]])))
				f.write("\n.SPRITE_hi_" + fyle + "_" + str(cnt) + "\n")
				fi.write("\n.SPRITE_hi_" + "InV" + fyle + "_" + str(cnt) + "\n")
				f.close()
				fi.close()
		cnt += 1
	return 0

if __name__ == "__main__":
	main(sys.argv)
