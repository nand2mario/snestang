#!/usr/bin/python3

# process mcode.txt to generate BRAM-driven mcode

import re

mi0=open('mcode_65c816_0.bin', 'w')
mi1=open('mcode_65c816_1.bin', 'w')
c = 0       # op code point
l = 0       # entry line number
last_l = 0
lmax = 0
cmax = 0

with open('mcode.txt', 'r') as f:
    lines = f.readlines()
    for s in lines:
        ss = s.strip()
        if ss.startswith('//'):
            print(l, end=', ')
            if (l-last_l > lmax):
                lmax = l-last_l
                cmax = c
            last_l = l
            if c % 8 == 7:
                print()
            c += 1
        else:
            # parse M_TAB[0]={3'b111, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['PC++']
            # print(ss)
            m = re.search(r'\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+),\s*\d.b([\dX]+)', ss)
            if m and m.group(1) != 'XXX':
                mi0.write('{}{}{}{}{}{}{}{}{}{}{}\n'.format(m.group(1), m.group(2), m.group(3), m.group(4),
                                                     m.group(5), m.group(6), m.group(7), m.group(8),
                                                     m.group(9), m.group(10), m.group(11)))
                mi1.write('{}{}{}{}{}\n'.format(m.group(12), m.group(13), m.group(14), m.group(15), m.group(16)))
                l += 1

mi0.close()
mi1.close()

print('\nmax_length={} @ {}'.format(lmax, cmax))