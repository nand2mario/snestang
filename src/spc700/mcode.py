#!/usr/bin/python3

# process mcode.txt to generate BRAM-driven mcode
# we compress a little by special-handling the only 2 instructions with more 
# than 8 mcodes (DIV 159 and MUL 207)
# - All entries 0-7 go into MCODE[]
# - The 1 extra for MUL and 4 extra mcodes for DIV go into MCODE[3] ~ MCODE[7].
#   These are unused by NOP.

import re

c = -1      # op code point
l = 0       # entry line number
v = 0       # num of valid entries in mcode
mcode1={}   # opcode -> [mcode]

# parse mcode.txt and print MCODE0
print("reg [30:0] MCODE0 [2048];")
print("initial begin")
with open('mcode.txt', 'r') as f:
    lines = f.readlines()
    for s in lines:
        ss = s.strip()
        if ss.startswith('//'):
            print(ss)
            l = 0
            c += 1
        else:
            # parse {2'b10,2'b01,6'b000000,5'b00000,2'b00,5'b01100,6'b000000,3'b001},// ['T->[AX]']
            # total 8 groups
            # print(ss)
            m = re.search(r'\d.b([\dX]+),\d.b([\dX]+),\d.b([\dX]+),\d.b([\dX]+),\d.b([\dX]+),\d.b([\dX]+),\d.b([\dX]+),\d.b([\dX]+)', ss)
            ss.replace('},', '};')
            if l < 8:
                print('MCODE0[{}]={}'.format(l+c*8, ss))
            elif m and m.group(1) != 'XX':
                if not c in mcode1:
                    mcode1[c] = []
                mcode1[c].append(ss)
            l += 1

# now print the extended MCODE1
print("end\n")
print("reg [30:0] MCODE1 [{}];".format(len(mcode1)))
start={}
c=0
for op in mcode1:
    start[op]=c
    c+=len(mcode1[op])
print("// start positions: ", end='')
for op in start:
    print("{}:{} ".format(op, start[op]), end='')
print("\ninitial begin")
c=0
for op in mcode1:
    for m in mcode1[op]:
        print("MCODE1[{}]={}".format(c, m))
        c += 1
print("end")


