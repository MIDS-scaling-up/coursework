#!/usr/bin/python

import sys
import os


def do_simple_map(line):

	return line[0]
	

		

i=0
print "{\"docs\": ["
for line in sys.stdin:
	if i == 0:
		print line
	else:
		print "," + line
		
	i=i + 1

print "]}"	
	