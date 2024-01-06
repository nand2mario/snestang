
import P65816::*;

// TODO: Micro code here should be compressed. There are lots of redundancy. 
// For example do something similar to ALUFlags for other fields.
// And lots of instructions do not have 8 entries.

module mcode(
   input       CLK,
   input       RST_N,
   input       EN,
   input [7:0] IR,
   input [3:0] STATE,
   output MCode_r   M
);

   logic [51:0] M_TAB [0:2047];
   initial begin
// 00 BRK
M_TAB[0]={3'b111, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['PC++']
M_TAB[1]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b110, 2'b10}; // ['PBR->[00:SP//]']
M_TAB[2]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b010, 2'b10}; // ['PCH->[00:SP//]']
M_TAB[3]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b010, 2'b10}; // ['PCL->[00:SP//]']
M_TAB[4]={3'b000, 3'b010, 2'b00, 3'b010, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b100, 2'b10}; // ['P->[00:SP//]']
M_TAB[5]={3'b000, 3'b100, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:VECT+0]->DR']
M_TAB[6]={3'b010, 3'b100, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b000, 3'b000, 2'b10, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:VECT+1]:DR->PC', '00->PBR', '1->I']
M_TAB[7]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 01 ORA (DP,X)
M_TAB[8]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[9]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[10]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[11]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[DX+0]->AAL']
M_TAB[12]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[DX+1]->AAH']
M_TAB[13]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[14]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[15]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 02 COP
M_TAB[16]={3'b111, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['PC++']
M_TAB[17]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b110, 2'b10}; // ['PBR->[00:SP//]']
M_TAB[18]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b010, 2'b10}; // ['PCH->[00:SP//]']
M_TAB[19]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b010, 2'b10}; // ['PCL->[00:SP//]']
M_TAB[20]={3'b000, 3'b010, 2'b00, 3'b010, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b100, 2'b10}; // ['P->[00:SP//]']
M_TAB[21]={3'b000, 3'b100, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:VECT+0]->DR']
M_TAB[22]={3'b010, 3'b100, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b000, 3'b000, 2'b10, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:VECT+1]:DR->PC', '00->PBR', '1->I']
M_TAB[23]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 03 ORA S
M_TAB[24]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[25]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[26]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[27]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[28]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[29]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[30]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[31]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 04 TSB DP
M_TAB[32]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[33]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[34]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[35]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[36]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01111, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[37]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[38]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
M_TAB[39]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 05 ORA DP
M_TAB[40]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[41]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[42]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[43]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[44]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[45]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[46]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[47]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 06 ASL DP
M_TAB[48]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[49]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[50]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[51]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[52]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01010, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[53]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[54]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
M_TAB[55]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 07 ORA [DP]
M_TAB[56]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[57]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[58]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[59]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[60]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB']
M_TAB[61]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[62]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[63]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 08 PHP
M_TAB[64]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[65]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b100, 2'b10}; // ['P->[00:SP//]']
M_TAB[66]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[67]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[68]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[69]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[70]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[71]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 09 ORA IMM
M_TAB[72]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])->AL', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[73]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)->A', 'PC++', 'Flags']
M_TAB[74]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[75]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[76]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[77]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[78]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[79]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 0A ASL A
M_TAB[80]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000010, 5'b01010, 2'b11, 3'b000, 2'b00}; // ['ALU(A)->A', 'Flags']
M_TAB[81]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[82]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[83]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[84]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[85]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[86]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[87]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 0B PHD
M_TAB[88]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[89]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b011000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['DH->[00:SP]', 'SP//']
M_TAB[90]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b011000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['DL->[00:SP]', 'SP//']
M_TAB[91]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[92]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[93]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[94]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[95]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 0C TSB ABS
M_TAB[96]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[97]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[98]={3'b110, 3'b001, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[DBR:AA+0]->TL']
M_TAB[99]={3'b000, 3'b001, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[DBR:AA+1]->TH']
M_TAB[100]={3'b110, 3'b001, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01111, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[101]={3'b000, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DBR:AA+1]']
M_TAB[102]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DBR:AA+0]']
M_TAB[103]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 0D ORA ABS
M_TAB[104]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[105]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[106]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[107]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[108]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[109]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[110]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[111]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 0E ASL ABS
M_TAB[112]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[113]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[114]={3'b110, 3'b001, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[DBR:AA+0]->TL']
M_TAB[115]={3'b000, 3'b001, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[DBR:AA+1]->TH']
M_TAB[116]={3'b110, 3'b001, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01010, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[117]={3'b000, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DBR:AA+1]']
M_TAB[118]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DBR:AA+0]']
M_TAB[119]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 0F ORA LONG
M_TAB[120]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[121]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[122]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++']
M_TAB[123]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[124]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[125]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[126]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[127]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 10 BPL
M_TAB[128]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DR', 'PC++']
M_TAB[129]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DR->PC']
M_TAB[130]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[131]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[132]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[133]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[134]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[135]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 11 ORA (DP),Y
M_TAB[136]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[137]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[138]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[139]={3'b001, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH','AAL+YL->AAL']
M_TAB[140]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[141]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[142]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[143]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 12 ORA (DP)
M_TAB[144]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[145]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[146]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[147]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[148]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[149]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[150]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[151]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 13 ORA (S),Y
M_TAB[152]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[153]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[154]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[155]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL']
M_TAB[156]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[157]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[158]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[159]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 14 TRB DP
M_TAB[160]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[161]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[162]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[163]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[164]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01110, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[165]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[166]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
M_TAB[167]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 15 ORA DP,X
M_TAB[168]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[169]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[170]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[171]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[172]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[173]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[174]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[175]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 16 ASL DP,X
M_TAB[176]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[177]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[178]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[179]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[180]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[181]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01010, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[182]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[183]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
// 17 ORA [DP],Y
M_TAB[184]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[185]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[186]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[187]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH','AAL+YL->AAL']
M_TAB[188]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b01, 8'b00000101, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB','AAH+YH+AALCarry->AAH']
M_TAB[189]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[190]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[191]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 18 CLC
M_TAB[192]={3'b010, 3'b000, 2'b00, 3'b100, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['Flags']
M_TAB[193]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[194]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[195]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[196]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[197]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[198]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[199]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 19 ORA ABS,Y
M_TAB[200]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'DBR->AB', 'PC++']
M_TAB[201]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL', 'PC++']
M_TAB[202]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[203]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[204]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[205]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[206]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[207]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 1A INC A
M_TAB[208]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000010, 5'b00011, 2'b11, 3'b000, 2'b00}; // ['ALU(A)->A', 'Flags']
M_TAB[209]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[210]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[211]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[212]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[213]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[214]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[215]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 1B TCS
M_TAB[216]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b100, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['A->S']
M_TAB[217]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[218]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[219]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[220]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[221]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[222]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[223]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 1C TRB ABS
M_TAB[224]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[225]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[226]={3'b110, 3'b001, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[DBR:AA+0]->TL']
M_TAB[227]={3'b000, 3'b001, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[DBR:AA+1]->TH']
M_TAB[228]={3'b110, 3'b001, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01110, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[229]={3'b000, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DBR:AA+1]']
M_TAB[230]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DBR:AA+0]']
M_TAB[231]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 1D ORA ABS,X
M_TAB[232]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'DBR->AB', 'PC++']
M_TAB[233]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL', 'PC++']
M_TAB[234]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[235]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[236]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[237]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[238]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[239]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 1E ASL ABS,X
M_TAB[240]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'DBR->AB', 'PC++']
M_TAB[241]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL', 'PC++']
M_TAB[242]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[243]={3'b110, 3'b101, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[AB:AA+0]->TL']
M_TAB[244]={3'b000, 3'b101, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[AB:AA+1]->TH']
M_TAB[245]={3'b110, 3'b101, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01010, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[246]={3'b000, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[AB:AA+1]']
M_TAB[247]={3'b010, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[AB:AA+0]']
// 1F ORA LONG,X
M_TAB[248]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[249]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL', 'PC++']
M_TAB[250]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000101, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'AAH+XH/YH+AALCarry->AAH', 'PC++']
M_TAB[251]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00100, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[252]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00100, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[253]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[254]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[255]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 20 JSR ABS
M_TAB[256]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL, 'PC++']
M_TAB[257]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH']
M_TAB[258]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[259]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b010, 2'b10}; // ['PCH->[00:SP]', 'SP//']
M_TAB[260]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b110, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b010, 2'b10}; // ['PCL->[00:SP]', 'SP//', 'AA->PC']
M_TAB[261]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[262]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[263]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 21 AND (DP,X)
M_TAB[264]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[265]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[266]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[267]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[268]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[269]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[270]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[271]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 22 JSR LONG
M_TAB[272]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[273]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[274]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b110, 2'b10}; // ['PBR->[00:SP]', 'SP//']
M_TAB[275]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[276]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b10, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->PBR']
M_TAB[277]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b010, 2'b10}; // ['PCH->[00:SP]', 'SP//']
M_TAB[278]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b110, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b010, 2'b10}; // ['PCL->[00:SP]', 'SP//', 'AA->PC']
M_TAB[279]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 23 AND S
M_TAB[280]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[281]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[282]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[283]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[284]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[285]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[286]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[287]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 24 BIT DP
M_TAB[288]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[289]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[290]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b01001, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])', '[00:DX+0]->DR', 'Flags']
M_TAB[291]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b01001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)', 'Flags']
M_TAB[292]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[293]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[294]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[295]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 25 AND DP
M_TAB[296]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[297]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[298]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[299]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[300]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[301]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[302]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[303]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 26 ROL DP
M_TAB[304]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[305]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[306]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[307]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[308]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01100, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[309]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[310]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
M_TAB[311]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 27 AND [DP]
M_TAB[312]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[313]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[314]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[315]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[316]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB']
M_TAB[317]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[318]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[319]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 28 PLP
M_TAB[320]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[321]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[322]={3'b010, 3'b010, 2'b00, 3'b011, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[SP]->P', 'Flags']
M_TAB[323]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[324]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[325]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[326]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[327]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 29 AND IMM
M_TAB[328]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])->AL', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[329]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)->A', 'PC++', 'Flags']
M_TAB[330]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[331]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[332]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[333]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[334]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[335]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 2A ROL A
M_TAB[336]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000010, 5'b01100, 2'b11, 3'b000, 2'b00}; // ['ALU(A)->A', 'Flags']
M_TAB[337]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[338]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[339]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[340]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[341]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[342]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[343]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 2B PLD
M_TAB[344]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[345]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[346]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:SP++]->DR']
M_TAB[347]={3'b010, 3'b010, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b01, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:SP]:DR)->D', 'Flags']
M_TAB[348]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[349]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[350]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[351]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 2C BIT ABS
M_TAB[352]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[353]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[354]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b01001, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])', '[DBR:AA+0]->DR']
M_TAB[355]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b01001, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)']
M_TAB[356]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[357]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[358]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[359]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 2D AND ABS
M_TAB[360]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[361]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[362]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR']
M_TAB[363]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A']
M_TAB[364]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[365]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[366]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[367]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 2E ROL ABS
M_TAB[368]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[369]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[370]={3'b110, 3'b001, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[DBR:AA+0]->TL']
M_TAB[371]={3'b000, 3'b001, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[DBR:AA+1]->TH']
M_TAB[372]={3'b110, 3'b001, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01100, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[373]={3'b000, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DBR:AA+1]']
M_TAB[374]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DBR:AA+0]']
M_TAB[375]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 2F AND LONG
M_TAB[376]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[377]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[378]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++']
M_TAB[379]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[380]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A, 'Flags'']
M_TAB[381]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[382]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[383]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 30 BMI
M_TAB[384]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DR', 'PC++']
M_TAB[385]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DR->PC']
M_TAB[386]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[387]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[388]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[389]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[390]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[391]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 31 AND (DP),Y
M_TAB[392]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[393]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[394]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[395]={3'b001, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL ']
M_TAB[396]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[397]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[398]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[399]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 32 AND (DP)
M_TAB[400]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[401]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[402]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[403]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[404]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[405]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[406]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[407]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 33 AND (S),Y
M_TAB[408]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DX', 'PC++']
M_TAB[409]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[410]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[411]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+Y->AAL']
M_TAB[412]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[413]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[414]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[415]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 34 BIT DP,X
M_TAB[416]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[417]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[418]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[419]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b01001, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]', '[00:DX+0]->DR', 'Flags']
M_TAB[420]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b01001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]', 'Flags']
M_TAB[421]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[422]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[423]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 35 AND DP,X
M_TAB[424]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[425]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[426]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[427]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[428]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[429]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[430]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[431]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 36 ROL DP,X
M_TAB[432]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[433]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[434]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[435]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[436]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[437]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01100, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[438]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[439]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
// 37 AND [DP],Y
M_TAB[440]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[441]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[442]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[443]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH,AAL+Y->AAL']
M_TAB[444]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b01, 8'b00000101, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB','AAH+YH+AALCarry->AAH']
M_TAB[445]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[446]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[447]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 38 SEC
M_TAB[448]={3'b010, 3'b000, 2'b00, 3'b100, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['Flags']
M_TAB[449]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[450]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[451]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[452]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[453]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[454]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[455]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 39 AND ABS,Y
M_TAB[456]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'DBR->AB', 'PC++']
M_TAB[457]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL', 'PC++']
M_TAB[458]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[459]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[460]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[461]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[462]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[463]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 3A DEC A
M_TAB[464]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000010, 5'b00010, 2'b11, 3'b000, 2'b00}; // ['ALU(A)->A', 'Flags']
M_TAB[465]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[466]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[467]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[468]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[469]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[470]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[471]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 3B TSC
M_TAB[472]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b101010, 5'b00001, 2'b11, 3'b000, 2'b00}; // ['ALU(SP)->A', 'Flags']
M_TAB[473]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[474]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[475]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[476]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[477]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[478]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[479]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 3C BIT ABS,X
M_TAB[480]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[481]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[482]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[483]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b01001, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[484]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b01001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])' 'Flags']
M_TAB[485]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[486]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[487]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 3D AND ABS,X
M_TAB[488]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'DBR->AB', 'PC++']
M_TAB[489]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL', 'PC++']
M_TAB[490]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[491]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[492]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[493]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[494]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[495]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 3E ROL ABS,X
M_TAB[496]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'DBR->AB', 'PC++']
M_TAB[497]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL', 'PC++']
M_TAB[498]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH'']
M_TAB[499]={3'b110, 3'b101, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[AB:AA+0]->TL']
M_TAB[500]={3'b000, 3'b101, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[AB:AA+1]->TH']
M_TAB[501]={3'b110, 3'b101, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01100, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[502]={3'b000, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[AB:AA+1]']
M_TAB[503]={3'b010, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[AB:AA+0]']
// 3F AND LONG,X
M_TAB[504]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[505]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL', 'PC++']
M_TAB[506]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000101, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'AAH+XH/YH+AALCarry->AAH', 'PC++']
M_TAB[507]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00101, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[508]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00101, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[509]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[510]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[511]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 40 RTI
M_TAB[512]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[513]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[514]={3'b000, 3'b010, 2'b00, 3'b011, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]->P', 'SP++']
M_TAB[515]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]->DR', 'SP++']
M_TAB[516]={3'b111, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]:DR->PC', 'SP++']
M_TAB[517]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b10, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]->PBR']
M_TAB[518]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[519]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 41 EOR (DP,X)
M_TAB[520]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[521]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[522]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[523]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[524]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[525]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[526]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[527]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 42 WDM
M_TAB[528]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['PC++']
M_TAB[529]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[530]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[531]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[532]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[533]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[534]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[535]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 43 EOR S
M_TAB[536]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[537]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[538]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[539]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[540]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[541]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[542]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[543]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 44 MVP
M_TAB[544]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b11, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DBR', 'PC++']
M_TAB[545]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b10, 8'b00000001, 3'b001, 3'b000, 3'b110, 2'b00, 6'b001010, 5'b00010, 2'b11, 3'b000, 2'b01}; // ['[PBR:PC]->ABR', 'PC++', 'X->AA', 'X-1->X']
M_TAB[546]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b11, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b010010, 5'b00010, 2'b11, 3'b000, 2'b10}; // ['[ABR:AA]->DR', 'Y->AA', 'Y-1->Y']
M_TAB[547]={3'b000, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b110, 2'b10}; // ['DR->[DBR:AA]']
M_TAB[548]={3'b000, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b111, 3'b000, 3'b101, 2'b00, 6'b000101, 5'b10000, 2'b11, 3'b000, 2'b00}; // ['ALU(A)->A', 'PC-3->PC']
M_TAB[549]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[550]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[551]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 45 EOR DP
M_TAB[552]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[553]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[554]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[555]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[556]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[557]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[558]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[559]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 46 LSR DP
M_TAB[560]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[561]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[562]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[563]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[564]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01011, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[565]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[566]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
M_TAB[567]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 47 EOR [DP]
M_TAB[568]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[569]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[570]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[571]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[572]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB']
M_TAB[573]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[574]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[575]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 48 PHA
M_TAB[576]={3'b110, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[577]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b001, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['AH->[00:SP]', 'SP//']
M_TAB[578]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b001, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['AL->[00:SP]', 'SP//']
M_TAB[579]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[580]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[581]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[582]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[583]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 49 EOR IMM
M_TAB[584]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])->AL', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[585]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)->A', 'PC++', 'Flags']
M_TAB[586]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[587]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[588]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[589]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[590]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[591]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 4A LSR A
M_TAB[592]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000010, 5'b01011, 2'b11, 3'b000, 2'b00}; // ['ALU(REG+1)->REG', 'Flags']
M_TAB[593]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[594]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[595]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[596]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[597]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[598]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[599]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 4B PHK
M_TAB[600]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[601]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b110000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['PBR->[00:SP]', 'SP//']
M_TAB[602]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[603]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[604]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[605]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[606]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[607]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 4C JMP ABS
M_TAB[608]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DR', 'PC++']
M_TAB[609]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]:DR->PC']
M_TAB[610]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[611]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[612]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[613]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[614]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[615]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 4D EOR ABS
M_TAB[616]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[617]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[618]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[619]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[620]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[621]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[622]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[623]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 4E LSR ABS
M_TAB[624]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[625]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[626]={3'b110, 3'b001, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[DBR:AA+0]->TL']
M_TAB[627]={3'b000, 3'b001, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[DBR:AA+1]->TH']
M_TAB[628]={3'b110, 3'b001, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01011, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[629]={3'b000, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DBR:AA+1]']
M_TAB[630]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DBR:AA+0]']
M_TAB[631]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 4F EOR LONG
M_TAB[632]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[633]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[634]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++']
M_TAB[635]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[636]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[637]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[638]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[639]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 50 BVC
M_TAB[640]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DL', 'PC++']
M_TAB[641]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DL->PC']
M_TAB[642]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['NOP']
M_TAB[643]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[644]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[645]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[646]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[647]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 51 EOR (DP),Y
M_TAB[648]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[649]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[650]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[651]={3'b001, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL ']
M_TAB[652]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[653]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[654]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[655]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 52 EOR (DP)
M_TAB[656]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[657]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[658]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // [00:DX+0]->AAL
M_TAB[659]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // [00:DX+1]->AAH
M_TAB[660]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[661]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[662]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[663]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 53 EOR (S),Y
M_TAB[664]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[665]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[666]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[667]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL ']
M_TAB[668]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[669]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[670]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[671]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 54 MVN
M_TAB[672]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b11, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DBR', 'PC++']
M_TAB[673]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b10, 8'b00000001, 3'b001, 3'b000, 3'b110, 2'b00, 6'b001010, 5'b00011, 2'b11, 3'b000, 2'b01}; // ['[PBR:PC]->ABR', 'PC++', 'X->AA', 'X+1->X']
M_TAB[674]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b11, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b010010, 5'b00011, 2'b11, 3'b000, 2'b10}; // ['[ABR:AA]->DR', 'Y->AA', 'Y+1->Y']
M_TAB[675]={3'b000, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b110, 2'b10}; // ['DR->[DBR:AA]']
M_TAB[676]={3'b000, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b111, 3'b000, 3'b101, 2'b00, 6'b000101, 5'b10000, 2'b11, 3'b000, 2'b00}; // ['ALU(A-1)->A','PC-3->PC']
M_TAB[677]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[678]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[679]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 55 EOR DP,X
M_TAB[680]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[681]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[682]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[683]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[684]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[685]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[686]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[687]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 56 LSR DP,X
M_TAB[688]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[689]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[690]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[691]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[692]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[693]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01011, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[694]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[695]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
// 57 EOR [DP],Y
M_TAB[696]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[697]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[698]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[699]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH,AAL+YL->AAL']
M_TAB[700]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b01, 8'b00000101, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB','AAH+YH+AALCarry->AAH']
M_TAB[701]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[702]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[703]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 58 CLI
M_TAB[704]={3'b010, 3'b000, 2'b00, 3'b100, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['[PBR:PC]->,ALU()->A', 'Flags', 'ALU()->X,Y', 'ALU()->A']
M_TAB[705]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[706]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[707]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[708]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[709]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[710]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[711]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 59 EOR ABS,Y
M_TAB[712]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[713]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[714]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[715]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[716]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[717]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[718]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[719]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 5A PHY
M_TAB[720]={3'b110, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[721]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b011, 2'b00, 6'b010000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['YH->[00:SP]', 'SP//']
M_TAB[722]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b011, 2'b00, 6'b010000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['YL->[00:SP]', 'SP//']
M_TAB[723]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[724]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[725]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[726]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[727]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 5B TCD
M_TAB[728]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b01, 6'b000010, 5'b00001, 2'b00, 3'b000, 2'b00}; // ['ALU(A)->D', 'Flags']
M_TAB[729]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[730]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[731]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[732]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[733]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[734]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[735]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 5C JMP LONG
M_TAB[736]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[737]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[738]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b110, 3'b000, 3'b000, 2'b10, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->PBR', 'AA->PC']
M_TAB[739]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[740]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[741]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[742]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[743]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 5D EOR ABS,X
M_TAB[744]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[745]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[746]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[747]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[748]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[749]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[750]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[751]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 5E LSR ABS,X
M_TAB[752]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[753]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[754]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[755]={3'b110, 3'b101, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[AB:AA+0]->TL']
M_TAB[756]={3'b000, 3'b101, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[AB:AA+1]->TH']
M_TAB[757]={3'b110, 3'b101, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01011, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[758]={3'b000, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[AB:AA+1]']
M_TAB[759]={3'b010, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[AB:AA+0]']
// 5F EOR LONG,X
M_TAB[760]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[761]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[762]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000101, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++', 'AAH+XH/YH+AALCarry->AAH']
M_TAB[763]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00110, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[764]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00110, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[765]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[766]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[767]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 60 RTS
M_TAB[768]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['']
M_TAB[769]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[770]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]->DR', 'SP++']
M_TAB[771]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]:DR->PC']
M_TAB[772]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC++']
M_TAB[773]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[774]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[775]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 61 ADC (DP,X)
M_TAB[776]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[777]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[778]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[779]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[780]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[781]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[782]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[783]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 62 PER
M_TAB[784]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->TL', 'PC++']
M_TAB[785]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->TH', 'PC++']
M_TAB[786]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01101100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+Offset->AA']
M_TAB[787]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b011, 2'b10}; // ['AAH->[00:SP]', 'SP//']
M_TAB[788]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b011, 2'b10}; // ['AAL->[00:SP]', 'SP//']
M_TAB[789]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[790]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[791]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 63 ADC S
M_TAB[792]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[793]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[794]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[795]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[796]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[797]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[798]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[799]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 64 STZ DP
M_TAB[800]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[801]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[802]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b111, 2'b10}; // ['0->[00:DX+0]']
M_TAB[803]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b111, 2'b10}; // ['0->[00:DX+1]']
M_TAB[804]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[805]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[806]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[807]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 65 ADC DP
M_TAB[808]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[809]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[810]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->A']
M_TAB[811]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->A']
M_TAB[812]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[813]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[814]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[815]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 66 ROR DP
M_TAB[816]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[817]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[818]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[819]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[820]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01101, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[821]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[822]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
M_TAB[823]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 67 ADC [DP]
M_TAB[824]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[825]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[826]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[827]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[828]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB']
M_TAB[829]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[830]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[831]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 68 PLA
M_TAB[832]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; //
M_TAB[833]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[834]={3'b100, 3'b010, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b010, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:SP])->REGL', 'SP++']
M_TAB[835]={3'b010, 3'b010, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:SP])->REGH', 'SP++']
M_TAB[836]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[837]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[838]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[839]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 69 ADC IMM
M_TAB[840]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])->AL', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[841]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)->A', 'PC++', 'Flags']
M_TAB[842]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[843]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[844]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[845]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[846]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[847]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 6A ROR A
M_TAB[848]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000010, 5'b01101, 2'b11, 3'b000, 2'b00}; // ['ALU(REG+1)->REG', 'Flags']
M_TAB[849]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[850]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[851]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[852]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[853]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[854]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[855]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 6B RTL
M_TAB[856]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['']
M_TAB[857]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[858]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]->DR', 'SP++']
M_TAB[859]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]:DR->PC', 'SP++']
M_TAB[860]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b10, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:SP]->PBR', 'PC++']
M_TAB[861]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[862]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[863]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 6C JMP (ABS)
M_TAB[864]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[865]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[866]={3'b000, 3'b110, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:AA+0]->DR']
M_TAB[867]={3'b010, 3'b110, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:AA+1]:DR->PC']
M_TAB[868]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[869]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[870]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[871]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 6D ADC ABS
M_TAB[872]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[873]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[874]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[875]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[876]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[877]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[878]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[879]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 6E ROR ABS
M_TAB[880]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[881]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[882]={3'b110, 3'b001, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[DBR:AA+0]->TL']
M_TAB[883]={3'b000, 3'b001, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[DBR:AA+1]->TH']
M_TAB[884]={3'b110, 3'b001, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01101, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[885]={3'b000, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DBR:AA+1]']
M_TAB[886]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DBR:AA+0]']
M_TAB[887]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 6F ADC LONG
M_TAB[888]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[889]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[890]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++']
M_TAB[891]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[892]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[893]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[894]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[895]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 70 BVS
M_TAB[896]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DR', 'PC++']
M_TAB[897]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DR->PC']
M_TAB[898]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[899]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[900]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[901]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[902]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[903]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 71 ADC (DP),Y
M_TAB[904]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[905]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[906]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[907]={3'b001, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL ']
M_TAB[908]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[909]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[910]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[911]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 72 ADC (DP)
M_TAB[912]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[913]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[914]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // [00:DX+0]->AAL
M_TAB[915]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // [00:DX+1]->AAH
M_TAB[916]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[917]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[918]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[919]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 73 ADC (S),Y
M_TAB[920]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[921]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[922]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[923]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL']
M_TAB[924]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[925]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[926]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[927]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 74 STZ DP,X
M_TAB[928]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[929]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[930]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[931]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b111, 2'b10}; // ['0->[00:DX+0]']
M_TAB[932]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b111, 2'b10}; // ['0->[00:DX+1]']
M_TAB[933]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[934]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[935]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 75 ADC DP,X
M_TAB[936]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[937]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[938]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[939]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[940]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[941]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[942]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[943]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 76 ROR DP,X
M_TAB[944]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[945]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[946]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[947]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[948]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[949]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01101, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[950]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[951]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
// 77 ADC [DP],Y
M_TAB[952]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[953]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[954]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[955]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL']
M_TAB[956]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b01, 8'b00000101, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB', 'AAH+YH+AALCarry->AAH']
M_TAB[957]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[958]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[959]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 78 SEI
M_TAB[960]={3'b010, 3'b000, 2'b00, 3'b100, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['[PBR:PC]->,ALU()->A', 'Flags', 'ALU()->X,Y', 'ALU()->A']
M_TAB[961]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[962]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[963]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[964]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[965]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[966]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[967]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 79 ADC ABS,Y
M_TAB[968]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[969]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[970]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[971]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[972]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[973]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[974]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[975]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 7A PLY
M_TAB[976]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[977]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[978]={3'b100, 3'b010, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b010, 3'b111, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:SP])->YL', 'SP++']
M_TAB[979]={3'b010, 3'b010, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:SP])->YH']
M_TAB[980]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[981]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[982]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[983]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 7B TDC
M_TAB[984]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b011010, 5'b00001, 2'b11, 3'b000, 2'b00}; // ['ALU(D)->A', 'Flags']
M_TAB[985]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[986]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[987]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[988]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[989]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[990]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[991]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 7C JMP (ABS,X)
M_TAB[992]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[993]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[994]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+Carry->AAH']
M_TAB[995]={3'b000, 3'b111, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:AA+0]->DR']
M_TAB[996]={3'b010, 3'b111, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:AA+1]:DR->PC']
M_TAB[997]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[998]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[999]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 7D ADC ABS,X
M_TAB[1000]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1001]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1002]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH'']
M_TAB[1003]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1004]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1005]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1006]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1007]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 7E ROR ABS,X
M_TAB[1008]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1009]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1010]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1011]={3'b110, 3'b101, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[AB:AA+0]->TL']
M_TAB[1012]={3'b000, 3'b101, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[AB:AA+1]->TH']
M_TAB[1013]={3'b110, 3'b101, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000100, 5'b01101, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[1014]={3'b000, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[AB:AA+1]']
M_TAB[1015]={3'b010, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[AB:AA+0]']
// 7F ADC LONG,X
M_TAB[1016]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1017]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1018]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000101, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++', 'AAH+XH/YH+AALCarry->AAH']
M_TAB[1019]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00111, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1020]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00111, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1021]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1022]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1023]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 80 BRA
M_TAB[1024]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DL', 'PC++']
M_TAB[1025]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DL->PC']
M_TAB[1026]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1027]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1028]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1029]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1030]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1031]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 81 STA (DP,X)
M_TAB[1032]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1033]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1034]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1035]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1036]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1037]={3'b100, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['A->[DBR:AA+0]']
M_TAB[1038]={3'b010, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['B->[DBR:AA+1]']
M_TAB[1039]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 82 BRL
M_TAB[1040]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DL', 'PC++']
M_TAB[1041]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01101100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]:DL->AA', 'PC++']
M_TAB[1042]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b011, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+Offset->PC']
M_TAB[1043]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1044]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1045]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1046]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1047]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 83 STA S
M_TAB[1048]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[1049]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[1050]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[00:DX+0]']
M_TAB[1051]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[00:DX+1]']
M_TAB[1052]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1053]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1054]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1055]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 84 STY DP
M_TAB[1056]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1057]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1058]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010010, 5'b00000, 2'b01, 3'b101, 2'b10}; // REGL->[00:DX+0]
M_TAB[1059]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010010, 5'b00000, 2'b10, 3'b101, 2'b10}; // REGH->[00:DX+1]
M_TAB[1060]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1061]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1062]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1063]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 85 STA DP
M_TAB[1064]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1065]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1066]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // REGL->[00:DX+0]
M_TAB[1067]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // REGH->[D00:X+1]
M_TAB[1068]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1069]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1070]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1071]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 86 STX DP
M_TAB[1072]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1073]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1074]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001010, 5'b00000, 2'b01, 3'b101, 2'b10}; // REGL->[00:DX+0]
M_TAB[1075]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001010, 5'b00000, 2'b10, 3'b101, 2'b10}; // REGH->[00:DX+1]
M_TAB[1076]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1077]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1078]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1079]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 87 STA [DP]
M_TAB[1080]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1081]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1082]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1083]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1084]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB']
M_TAB[1085]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[AB:AA+0]']
M_TAB[1086]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[AB:AA+1]']
M_TAB[1087]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 88 DEY
M_TAB[1088]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b010010, 5'b00010, 2'b11, 3'b000, 2'b00}; // ['ALU(Y)->Y', 'Flags']
M_TAB[1089]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1090]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1091]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1092]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1093]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1094]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1095]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 89 BIT IMM
M_TAB[1096]={3'b100, 3'b000, 2'b00, 3'b111, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b01001, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[1097]={3'b010, 3'b000, 2'b00, 3'b111, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b01001, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)', 'PC++', 'Flags']
M_TAB[1098]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1099]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1100]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1101]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1102]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1103]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 8A TXA
M_TAB[1104]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b001010, 5'b00000, 2'b11, 3'b000, 2'b00}; // ['ALU(X)->A', 'Flags']
M_TAB[1105]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1106]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1107]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1108]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1109]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1110]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1111]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 8B PHB
M_TAB[1112]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1113]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b111010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['DBR->[00:SP]', 'SP//']
M_TAB[1114]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1115]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1116]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1117]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1118]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1119]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 8C STY ABS
M_TAB[1120]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1121]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1122]={3'b100, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[DBR:AA+0]']
M_TAB[1123]={3'b010, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[DBR:AA+1]']
M_TAB[1124]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1125]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1126]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1127]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 8D STA ABS
M_TAB[1128]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1129]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1130]={3'b100, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[DBR:AA+0]']
M_TAB[1131]={3'b010, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[DBR:AA+1]']
M_TAB[1132]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1133]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1134]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1135]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 8E STX ABS
M_TAB[1136]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1137]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1138]={3'b100, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[DBR:AA+0]']
M_TAB[1139]={3'b010, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[DBR:AA+1]']
M_TAB[1140]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1141]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1142]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1143]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 8F STA LONG
M_TAB[1144]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1145]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1146]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++']
M_TAB[1147]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[AB:AA+0]']
M_TAB[1148]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[AB:AA+1]']
M_TAB[1149]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1150]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1151]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 90 BCC
M_TAB[1152]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DR', 'PC++']
M_TAB[1153]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DR->PC']
M_TAB[1154]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1155]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1156]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1157]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1158]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1159]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 91 STA (DP),Y
M_TAB[1160]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1161]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1162]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[1163]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL ']
M_TAB[1164]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[1165]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['A->[AB:AA+0]']
M_TAB[1166]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['B->[AB:AA+1]']
M_TAB[1167]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 92 STA (DP)
M_TAB[1168]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1169]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1170]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1171]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1172]={3'b100, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00100, 2'b01, 3'b101, 2'b10}; // ['A->[DBR:AA+0]']
M_TAB[1173]={3'b010, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['B->[DBR:AA+1]']
M_TAB[1174]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1175]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 93 STA (S),Y
M_TAB[1176]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[1177]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[1178]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[1179]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL']
M_TAB[1180]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[1181]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[AB:AA+0]']
M_TAB[1182]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[AB:AA+1]']
M_TAB[1183]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 94 STY DP,X
M_TAB[1184]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1185]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1186]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1187]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[00:DX+0]']
M_TAB[1188]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[00:DX+1]']
M_TAB[1189]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1190]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1191]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 95 STA DP,X
M_TAB[1192]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1193]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1194]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1195]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[00:DX+0]']
M_TAB[1196]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[00:DX+1]']
M_TAB[1197]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1198]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1199]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 96 STX DP,Y
M_TAB[1200]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1201]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1202]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Y->DX']
M_TAB[1203]={3'b100, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[00:DX+0]']
M_TAB[1204]={3'b010, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[00:DX+1]']
M_TAB[1205]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1206]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1207]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 97 STA [DP],Y
M_TAB[1208]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1209]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1210]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1211]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH,AAL+YL->AAL']
M_TAB[1212]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b01, 8'b00000101, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB','AAH+YH+AALCarry->AAH']
M_TAB[1213]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['REGL->[AB:AA+0]']
M_TAB[1214]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['REGH->[AB:AA+1]']
M_TAB[1215]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 98 TYA
M_TAB[1216]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b010010, 5'b00000, 2'b11, 3'b000, 2'b00}; // ['ALU(Y)->A', 'Flags']
M_TAB[1217]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1218]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1219]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1220]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1221]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1222]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1223]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 99 STA ABS,Y
M_TAB[1224]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1225]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1226]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1227]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['A->[AB:AA+0]']
M_TAB[1228]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['B->[AB:AA+1]']
M_TAB[1229]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1230]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1231]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 9A TXS
M_TAB[1232]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b101, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['X->S']
M_TAB[1233]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1234]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1235]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1236]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1237]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1238]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1239]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 9B TXY
M_TAB[1240]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b001010, 5'b00000, 2'b11, 3'b000, 2'b00}; // ['ALU(X)->Y', 'Flags']
M_TAB[1241]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1242]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1243]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1244]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1245]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1246]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1247]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 9C STZ ABS
M_TAB[1248]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1249]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1250]={3'b100, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b111, 2'b10}; // ALU(0)->[DBR:AA+0]
M_TAB[1251]={3'b010, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b111, 2'b10}; // ALU(0)->[DBR:AA+1]
M_TAB[1252]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1253]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1254]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1255]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 9D STA ABS,X
M_TAB[1256]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1257]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1258]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1259]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['A->[AB:AA+0]']
M_TAB[1260]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['B->[AB:AA+1]']
M_TAB[1261]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1262]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1263]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 9E STZ ABS,X
M_TAB[1264]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1265]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1266]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1267]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b111, 2'b10}; // ALU(0)->[AB:AA+0]
M_TAB[1268]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b111, 2'b10}; // ALU(0)->[AB:AA+1]
M_TAB[1269]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1270]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1271]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// 9F STA LONG,X
M_TAB[1272]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1273]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1274]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000101, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++', 'AAH+XH/YH+AALCarry->AAH']
M_TAB[1275]={3'b100, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['A->[AB:AA+0]']
M_TAB[1276]={3'b010, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['B->[AB:AA+1]']
M_TAB[1277]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1278]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1279]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
//A0 LDY IMM
M_TAB[1280]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b111, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])->YL', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[1281]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b111, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)->Y', 'PC++', 'Flags']
M_TAB[1282]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1283]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1284]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1285]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1286]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1287]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A1 LDA (DP,X)
M_TAB[1288]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1289]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1290]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1291]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1292]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1293]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1294]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[1295]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A2 LDX IMM
M_TAB[1296]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b110, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])->XL', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[1297]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b110, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)->X', 'PC++', 'Flags']
M_TAB[1298]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1299]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1300]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1301]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1302]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1303]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A3 LDA S
M_TAB[1304]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[1305]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1306]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[1307]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[1308]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1309]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1310]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1311]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A4 LDY DP
M_TAB[1312]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1313]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1314]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]->YL', '[00:DX+0]->DR', 'Flags']
M_TAB[1315]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]->Y', 'Flags']
M_TAB[1316]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1317]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1318]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1319]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A5 LDA DP
M_TAB[1320]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1321]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1322]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[1323]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[1324]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1325]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1326]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1327]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A6 LDX DP
M_TAB[1328]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1329]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1330]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]->XL', '[00:DX+0]->DR', 'Flags']
M_TAB[1331]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]->X', 'Flags']
M_TAB[1332]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1333]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1334]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1335]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A7 LDA [DP]
M_TAB[1336]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1337]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1338]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1339]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1340]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB']
M_TAB[1341]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1342]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1343]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A8 TAY
M_TAB[1344]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000010, 5'b00000, 2'b11, 3'b000, 2'b00}; // ['ALU(A)->Y', 'Flags']
M_TAB[1345]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1346]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1347]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1348]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1349]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1350]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1351]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// A9 LDA IMM
M_TAB[1352]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])->AL', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[1353]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)->A', 'PC++', 'Flags']
M_TAB[1354]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1355]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1356]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1357]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1358]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1359]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// AA TAX
M_TAB[1360]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000010, 5'b00000, 2'b11, 3'b000, 2'b00}; // ['ALU(A)->X', 'Flags']
M_TAB[1361]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1362]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1363]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1364]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1365]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1366]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1367]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// AB PLB
M_TAB[1368]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1369]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[1370]={3'b010, 3'b010, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b11, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['ALU([00:SP])->DBR']
M_TAB[1371]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1372]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1373]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1374]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1375]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// AC LDY ABS
M_TAB[1376]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1377]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1378]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->YL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1379]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->Y', 'Flags']
M_TAB[1380]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1381]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1382]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1383]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// AD LDA ABS
M_TAB[1384]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1385]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1386]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1387]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[1388]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1389]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1390]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1391]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// AE LDX ABS
M_TAB[1392]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1393]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1394]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->XL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1395]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->X', 'Flags']
M_TAB[1396]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1397]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1398]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1399]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// AF LDA LONG
M_TAB[1400]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1401]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1402]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++']
M_TAB[1403]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1404]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1405]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1406]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1407]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B0 BCS
M_TAB[1408]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DR', 'PC++']
M_TAB[1409]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DR->PC']
M_TAB[1410]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1411]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1412]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1413]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1414]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1415]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B1 LDA (DP),Y
M_TAB[1416]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1417]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1418]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[1419]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL ']
M_TAB[1420]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[1421]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1422]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1423]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B2 LDA (DP)
M_TAB[1424]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1425]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1426]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1427]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH ']
M_TAB[1428]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1429]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[1430]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1431]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B3 LDA (S),Y
M_TAB[1432]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[1433]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[1434]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[1435]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL']
M_TAB[1436]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[1437]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1438]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1439]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B4 LDY DP,X
M_TAB[1440]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1441]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1442]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // [DX+X->DX]
M_TAB[1443]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]->YL', '[00:DX+0]->DR', 'Flags']
M_TAB[1444]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]->Y', 'Flags']
M_TAB[1445]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1446]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1447]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B5 LDA DP,X
M_TAB[1448]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1449]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[1450]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1451]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[1452]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[1453]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1454]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1455]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B6 LDX DP,Y
M_TAB[1456]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1457]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[1458]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // [DX+Y->DX]
M_TAB[1459]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]->XL', '[00:DX+0]->DR', 'Flags']
M_TAB[1460]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]->X', 'Flags']
M_TAB[1461]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1462]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1463]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B7 LDA [DP],Y
M_TAB[1464]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1465]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1466]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1467]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH,AAL+YL->AAL']
M_TAB[1468]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b01, 8'b00000101, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB','AAH+YH+AALCarry->AAH']
M_TAB[1469]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1470]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1471]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B8 CLV
M_TAB[1472]={3'b010, 3'b000, 2'b00, 3'b100, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['[PC]->,ALU()->A', 'Flags', 'ALU()->X,Y', 'ALU()->A']
M_TAB[1473]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1474]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1475]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1476]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1477]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1478]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1479]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// B9 LDA ABS,Y
M_TAB[1480]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1481]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1482]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1483]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1484]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1485]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1486]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1487]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// BA TSX
M_TAB[1488]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b101010, 5'b00001, 2'b11, 3'b000, 2'b00}; // ['ALU(SP)->X', 'Flags']
M_TAB[1489]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1490]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1491]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1492]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1493]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1494]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1495]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// BB TYX
M_TAB[1496]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b010010, 5'b00000, 2'b11, 3'b000, 2'b00}; // ['ALU(Y)->X', 'Flags']
M_TAB[1497]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1498]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1499]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1500]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1501]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1502]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1503]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// BC LDY ABS,X
M_TAB[1504]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1505]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1506]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1507]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->YL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1508]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])->Y', 'Flags']
M_TAB[1509]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1510]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1511]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// BD LDA ABS,X
M_TAB[1512]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1513]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1514]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1515]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1516]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1517]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1518]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1519]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// BE LDX ABS,Y
M_TAB[1520]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1521]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1522]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1523]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->XL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1524]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])->X', 'Flags']
M_TAB[1525]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1526]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1527]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// BF LDA LONG,X
M_TAB[1528]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1529]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1530]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000101, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++', 'AAH+XH/YH+AALCarry->AAH']
M_TAB[1531]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1532]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1533]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1534]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1535]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C0 CPY IMM
M_TAB[1536]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b011, 2'b00, 6'b010000, 5'b10000, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[1537]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b011, 2'b00, 6'b010001, 5'b10000, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)', 'PC++', 'Flags']
M_TAB[1538]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1539]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1540]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1541]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1542]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1543]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C1 CMP (DP,X)
M_TAB[1544]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1545]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1546]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1547]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1548]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1549]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1550]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1551]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C2 REP
M_TAB[1552]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // [[PBR:PC]->DR', 'PC++']
M_TAB[1553]={3'b010, 3'b000, 2'b00, 3'b110, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['Flags']
M_TAB[1554]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1555]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1556]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1557]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1558]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1559]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C3 CMP S
M_TAB[1560]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[1561]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[1562]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]', '[00:DX+0]->DR', 'Flags']
M_TAB[1563]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]', 'Flags']
M_TAB[1564]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1565]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1566]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1567]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C4 CPY DP
M_TAB[1568]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1569]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1570]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]', '[00:DX+0]->DR', 'Flags']
M_TAB[1571]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]', 'Flags']
M_TAB[1572]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1573]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1574]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1575]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C5 CMP DP
M_TAB[1576]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1577]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1578]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]', '[00:DX+0]->DR', 'Flags']
M_TAB[1579]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]', 'Flags']
M_TAB[1580]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1581]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1582]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1583]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C6 DEC DP
M_TAB[1584]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1585]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1586]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[1587]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[1588]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100010, 5'b00010, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[1589]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[1590]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
M_TAB[1591]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C7 CMP [DP]
M_TAB[1592]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1593]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1594]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1595]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1596]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB']
M_TAB[1597]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1598]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1599]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C8 INY
M_TAB[1600]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b111, 2'b00, 6'b010010, 5'b00011, 2'b11, 3'b000, 2'b00}; // ['ALU(Y+1)->Y', 'Flags']
M_TAB[1601]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1602]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1603]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1604]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1605]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1606]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1607]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// C9 CMP IMM
M_TAB[1608]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[1609]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)', 'PC++', 'Flags']
M_TAB[1610]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1611]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1612]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1613]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1614]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1615]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// CA DEX
M_TAB[1616]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b001010, 5'b00010, 2'b11, 3'b000, 2'b00}; // ['ALU(X-1)->X', 'Flags']
M_TAB[1617]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1618]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1619]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1620]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1621]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1622]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1623]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// CB WAI
M_TAB[1624]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1625]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1626]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1627]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1628]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1629]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1630]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1631]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// CC CPY ABS
M_TAB[1632]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1633]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1634]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1635]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b011, 2'b00, 6'b010001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)', 'Flags']
M_TAB[1636]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1637]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1638]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1639]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// CD CMP ABS
M_TAB[1640]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1641]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1642]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1643]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)', 'Flags']
M_TAB[1644]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1645]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1646]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1647]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// CE DEC ABS
M_TAB[1648]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1649]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1650]={3'b110, 3'b001, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[DBR:AA+0]->TL']
M_TAB[1651]={3'b000, 3'b001, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[DBR:AA+1]->TH']
M_TAB[1652]={3'b110, 3'b001, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100010, 5'b00010, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[1653]={3'b000, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DBR:AA+1]']
M_TAB[1654]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DBR:AA+0]']
M_TAB[1655]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// CF CMP LONG
M_TAB[1656]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1657]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1658]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++']
M_TAB[1659]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1660]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1661]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1662]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1663]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D0 BNE
M_TAB[1664]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DR', 'PC++']
M_TAB[1665]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DR->PC']
M_TAB[1666]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1667]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1668]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1669]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1670]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1671]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D1 CMP (DP),Y
M_TAB[1672]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1673]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1674]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[1675]={3'b001, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL ']
M_TAB[1676]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[1677]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1678]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1679]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D2 CMP (DP)
M_TAB[1680]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1681]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1682]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1683]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1684]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1685]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)', 'Flags']
M_TAB[1686]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1687]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D3 CMP (S),Y
M_TAB[1688]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[1689]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[1690]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR+AAHCarry->AB']
M_TAB[1691]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL']
M_TAB[1692]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[1693]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1694]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1695]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D4 PEI
M_TAB[1696]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1697]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1698]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1699]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1700]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b011, 2'b10}; // ['AAH->[00:SP]', 'SP//']
M_TAB[1701]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b011, 2'b10}; // ['AAL->[00:SP]', 'SP//']
M_TAB[1702]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1703]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D5 CMP DP,X
M_TAB[1704]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1705]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[1706]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1707]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]', '[00:DX+0]->DR', 'Flags']
M_TAB[1708]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]', 'Flags']
M_TAB[1709]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1710]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1711]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D6 DEC DP,X
M_TAB[1712]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1713]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1714]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1715]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[1716]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[1717]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100010, 5'b00010, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[1718]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DX+1]']
M_TAB[1719]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DX+0]']
// D7 CMP [DP],Y
M_TAB[1720]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1721]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1722]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1723]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH,AAL+YL->AAL']
M_TAB[1724]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b01, 8'b00000101, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB','AAH+YH+AALCarry->AAH']
M_TAB[1725]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1726]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1727]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D8 CLD
M_TAB[1728]={3'b010, 3'b000, 2'b00, 3'b100, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['[PC]->,ALU()->A', 'Flags', 'ALU()->X,Y', 'ALU()->A']
M_TAB[1729]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1730]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1731]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1732]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1733]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1734]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1735]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// D9 CMP ABS,Y
M_TAB[1736]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1737]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1738]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1739]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1740]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1741]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1742]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1743]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// DA PHX
M_TAB[1744]={3'b110, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1745]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b010, 2'b00, 6'b001000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['XH->[00:SP]', 'SP//']
M_TAB[1746]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b010, 2'b00, 6'b001000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['XL->[00:SP]', 'SP//']
M_TAB[1747]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1748]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1749]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1750]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1751]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// DB STP
M_TAB[1752]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1753]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1754]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1755]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1756]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1757]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1758]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1759]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// DC JMP [ABS]
M_TAB[1760]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1761]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1762]={3'b000, 3'b110, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:AA+0]->DL']
M_TAB[1763]={3'b000, 3'b110, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:AA+1]:DL->PC']
M_TAB[1764]={3'b010, 3'b110, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b10, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:AA+2]->PBR']
M_TAB[1765]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1766]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1767]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// DD CMP ABS,X
M_TAB[1768]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1769]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1770]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1771]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1772]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1773]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1774]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1775]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// DE DEC ABS,X
M_TAB[1776]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1777]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1778]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1779]={3'b110, 3'b101, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[AB:AA+0]->TL']
M_TAB[1780]={3'b000, 3'b101, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[AB:AA+1]->TH']
M_TAB[1781]={3'b110, 3'b101, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100010, 5'b00010, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[1782]={3'b000, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[AB:AA+1]']
M_TAB[1783]={3'b010, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[AB:AA+0]']
// DF CMP LONG,X
M_TAB[1784]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1785]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1786]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000101, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++', 'AAH+XH/YH+AALCarry->AAH']
M_TAB[1787]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])', '[AB:AA+0]->DR', 'Flags']
M_TAB[1788]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1])', 'Flags']
M_TAB[1789]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1790]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1791]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E0 CPX IMM
M_TAB[1792]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b010, 2'b00, 6'b001000, 5'b10000, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[1793]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b010, 2'b00, 6'b001001, 5'b10000, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)', 'PC++', 'Flags']
M_TAB[1794]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1795]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1796]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1797]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1798]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1799]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E1 SBC (DP,X)
M_TAB[1800]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1801]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1802]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1803]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1804]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1805]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1806]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[1807]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E2 SEP
M_TAB[1808]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]-DR', 'PC++']
M_TAB[1809]={3'b010, 3'b000, 2'b00, 3'b110, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['Flags']
M_TAB[1810]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1811]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1812]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1813]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1814]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1815]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E3 SBC S
M_TAB[1816]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[1817]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[1818]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[1819]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[1820]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1821]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1822]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1823]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E4 CPX DP
M_TAB[1824]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1825]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1826]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0]', '[00:DX+0]->DR', 'Flags']
M_TAB[1827]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]', 'Flags']
M_TAB[1828]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1829]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1830]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1831]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E5 SBC DP
M_TAB[1832]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1833]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1834]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[1835]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[1836]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1837]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1838]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1839]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E6 INC DP
M_TAB[1840]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1841]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1842]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[1843]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[1844]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100010, 5'b00011, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[1845]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[1846]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
M_TAB[1847]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E7 SBC [DP]
M_TAB[1848]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1849]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1850]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1851]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1852]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB']
M_TAB[1853]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1854]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1855]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E8 INX
M_TAB[1856]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b001010, 5'b00011, 2'b11, 3'b000, 2'b00}; // ['ALU(REG+1)->REG', 'Flags']
M_TAB[1857]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1858]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1859]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1860]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1861]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1862]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1863]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// E9 SBC IMM
M_TAB[1864]={3'b100, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b01}; // ['ALU([PBR:PC])->AL', '[PBR:PC]->DR', 'PC++', 'Flags']
M_TAB[1865]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b01}; // ['ALU([PBR:PC]:DR)->A', 'PC++', 'Flags']
M_TAB[1866]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1867]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1868]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1869]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1870]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1871]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// EA NOP
M_TAB[1872]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1873]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1874]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1875]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1876]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1877]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1878]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1879]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// EB XBA
M_TAB[1880]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b00000, 2'b11, 3'b000, 2'b00}; // ['B:A->C']
M_TAB[1881]={3'b010, 3'b000, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b001, 2'b00, 6'b000010, 5'b00000, 2'b01, 3'b000, 2'b00}; // ['Flags']
M_TAB[1882]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1883]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1884]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1885]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1886]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1887]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// EC CPX ABS
M_TAB[1888]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1889]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1890]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001000, 5'b10000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1891]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b010, 2'b00, 6'b001001, 5'b10000, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)', 'Flags']
M_TAB[1892]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1893]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1894]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1895]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// ED SBC ABS
M_TAB[1896]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1897]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1898]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1899]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[1900]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1901]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1902]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1903]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// EE INC ABS
M_TAB[1904]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1905]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1906]={3'b110, 3'b001, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[DBR:AA+0]->TL']
M_TAB[1907]={3'b000, 3'b001, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[DBR:AA+1]->TH']
M_TAB[1908]={3'b110, 3'b001, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100010, 5'b00011, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[1909]={3'b000, 3'b001, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[DBR:AA+1]']
M_TAB[1910]={3'b010, 3'b001, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[DBR:AA+0]']
M_TAB[1911]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// EF SBC LONG
M_TAB[1912]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1913]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1914]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000001, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++']
M_TAB[1915]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1916]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1917]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1918]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1919]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F0 BEQ
M_TAB[1920]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->DR', 'PC++']
M_TAB[1921]={3'b011, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b100, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['PC+DR->PC']
M_TAB[1922]={3'b010, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // []
M_TAB[1923]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1924]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1925]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1926]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1927]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F1 SBC (DP),Y
M_TAB[1928]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1929]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1930]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[1931]={3'b001, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL ']
M_TAB[1932]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[1933]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1934]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1935]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F2 SBC (DP)
M_TAB[1936]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1937]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1938]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1939]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH']
M_TAB[1940]={3'b100, 3'b001, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([DBR:AA+0])->AL', '[DBR:AA+0]->DR', 'Flags']
M_TAB[1941]={3'b010, 3'b001, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([DBR:AA+1]:DR)->A', 'Flags']
M_TAB[1942]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1943]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F3 SBC (S),Y
M_TAB[1944]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110111, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['SPL+[PBR:PC]->DL', 'PC++']
M_TAB[1945]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SPH+Carry->DH']
M_TAB[1946]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL', 'DBR->AB']
M_TAB[1947]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH', 'AAL+YL->AAL']
M_TAB[1948]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+YH+AALCarry->AAH']
M_TAB[1949]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1950]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1951]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F4 PEA
M_TAB[1952]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[1953]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00001000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++']
M_TAB[1954]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b011, 2'b10}; // ['AAH->[00:SP]', 'SP//']
M_TAB[1955]={3'b010, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b011, 2'b10}; // ['AAL->[00:SP]', 'SP//']
M_TAB[1956]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1957]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1958]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1959]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F5 SBC DP,X
M_TAB[1960]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1961]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+Carry->DX']
M_TAB[1962]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1963]={3'b100, 3'b011, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:DX+0])->AL', '[00:DX+0]->DR', 'Flags']
M_TAB[1964]={3'b010, 3'b011, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([00:DX+1]:DR)->A', 'Flags']
M_TAB[1965]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1966]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1967]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F6 INC DP,X
M_TAB[1968]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1969]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1970]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10010000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DX+X->DX']
M_TAB[1971]={3'b110, 3'b011, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[00:DX+0]->TL']
M_TAB[1972]={3'b000, 3'b011, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[00:DX+1]->TH']
M_TAB[1973]={3'b110, 3'b011, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100010, 5'b00011, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[1974]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[00:DX+1]']
M_TAB[1975]={3'b010, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[00:DX+0]']
// F7 SBC [DP],Y
M_TAB[1976]={3'b101, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b10110100, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['DL+[PBR:PC]->DL', 'PC++']
M_TAB[1977]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00011000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['DH+Carry->DH']
M_TAB[1978]={3'b000, 3'b011, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+0]->AAL']
M_TAB[1979]={3'b000, 3'b011, 2'b01, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+1]->AAH,AAL+YL->AAL']
M_TAB[1980]={3'b000, 3'b011, 2'b10, 3'b000, 2'b00, 2'b01, 8'b00000101, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b10}; // ['[00:DX+2]->AB','AAH+YH+AALCarry->AAH']
M_TAB[1981]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1982]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1983]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F8 SED
M_TAB[1984]={3'b010, 3'b000, 2'b00, 3'b100, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['[PC]->,ALU()->A', 'Flags', 'ALU()->X,Y', 'ALU()->A']
M_TAB[1985]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1986]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1987]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1988]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1989]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1990]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1991]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// F9 SBC ABS,Y
M_TAB[1992]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[1993]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[1994]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b01, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[1995]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[1996]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[1997]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1998]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[1999]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// FA PLX
M_TAB[2000]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; //
M_TAB[2001]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b001, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['SP++']
M_TAB[2002]={3'b100, 3'b010, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b010, 3'b110, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['ALU([00:SP])->REGL', 'SP++']
M_TAB[2003]={3'b010, 3'b010, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b110, 2'b00, 6'b000001, 5'b00001, 2'b10, 3'b000, 2'b10}; // ['ALU([00:SP])->REGH']
M_TAB[2004]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2005]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2006]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2007]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// FB XCE
M_TAB[2008]={3'b010, 3'b000, 2'b00, 3'b101, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['[PC]->,ALU()->A', 'Flags', 'ALU()->X,Y', 'ALU()->A']
M_TAB[2009]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2010]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2011]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2012]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2013]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2014]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2015]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// FC JSR (ABS,X)
M_TAB[2016]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[2017]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b010, 2'b10}; // ['PCH->[00:SP]', 'SP//']
M_TAB[2018]={3'b000, 3'b010, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b011, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b010, 2'b10}; // ['PCL->[00:SP]', 'SP//']
M_TAB[2019]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'AAL+XL/YL->AAL']
M_TAB[2020]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+Carry->AAH']
M_TAB[2021]={3'b000, 3'b111, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:AA+0]->DR']
M_TAB[2022]={3'b010, 3'b111, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b010, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:AA+1]:DR->PC']
M_TAB[2023]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// FD SBC ABS,X
M_TAB[2024]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[2025]={3'b001, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[2026]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[2027]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[2028]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[2029]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2030]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2031]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
// FE INC ABS,X
M_TAB[2032]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000011, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++', 'DBR->AB']
M_TAB[2033]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[2034]={3'b000, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000100, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b00}; // ['AAH+XH/YH+AALCarry->AAH']
M_TAB[2035]={3'b110, 3'b101, 2'b00, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b01, 3'b000, 2'b10}; // ['[AB:AA+0]->TL']
M_TAB[2036]={3'b000, 3'b101, 2'b01, 3'b000, 2'b01, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b10, 3'b000, 2'b10}; // ['[AB:AA+1]->TH']
M_TAB[2037]={3'b110, 3'b101, 2'b01, 3'b001, 2'b10, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100010, 5'b00011, 2'b11, 3'b000, 2'b00}; // ['ALU(T)->T', 'Flags']
M_TAB[2038]={3'b000, 3'b101, 2'b01, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b10, 3'b101, 2'b10}; // ['TH->[AB:AA+1]']
M_TAB[2039]={3'b010, 3'b101, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b000, 2'b00, 6'b100000, 5'b00000, 2'b01, 3'b101, 2'b10}; // ['TL->[AB:AA+0]']
// FF SBC LONG,X
M_TAB[2040]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b01000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAL', 'PC++']
M_TAB[2041]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00101000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AAH', 'PC++', 'AAL+XL/YL->AAL']
M_TAB[2042]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000101, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b01}; // ['[PBR:PC]->AB', 'PC++', 'AAH+XH/YH+AALCarry->AAH']
M_TAB[2043]={3'b100, 3'b101, 2'b00, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000000, 5'b01000, 2'b01, 3'b000, 2'b10}; // ['ALU([AB:AA+0])->AL', '[AB:AA+0]->DR', 'Flags']
M_TAB[2044]={3'b010, 3'b101, 2'b01, 3'b001, 2'b00, 2'b00, 8'b00000000, 3'b000, 3'b000, 3'b101, 2'b00, 6'b000001, 5'b01000, 2'b10, 3'b000, 2'b10}; // ['ALU([AB:AA+1]:DR)->A', 'Flags']
M_TAB[2045]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 
M_TAB[2046]={3'bXXX, 3'bXXX, 2'bXX, 3'bXXX, 2'bXX, 2'bXX, 8'bXXXXXXXX, 3'bXXX, 3'bXXX, 3'bXXX, 2'bXX, 6'bXXXXXX, 5'bXXXXX, 2'bXX, 3'bXXX, 2'bXX}; 

// Special entry for STATE==0
M_TAB[2047]={3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b11}; 
   end

   MicroInst_r         MI;
   ALUCtrl_r        ALUFlags;
   
   always @* begin
      case (MI.ALUCtrl)
      5'd0: ALUFlags = {3'b100, 3'b100, 1'b0, 1'b0};    // firstOp, secondOp, fc, w16
      5'd1: ALUFlags = {3'b100, 3'b100, 1'b0, 1'b1};
      5'd2: ALUFlags = {3'b110, 3'b100, 1'b0, 1'b0};
      5'd3: ALUFlags = {3'b111, 3'b100, 1'b0, 1'b0};
      5'd4: ALUFlags = {3'b100, 3'b000, 1'b0, 1'b0};
      5'd5: ALUFlags = {3'b100, 3'b001, 1'b0, 1'b0};
      5'd6: ALUFlags = {3'b100, 3'b010, 1'b0, 1'b0};
      5'd7: ALUFlags = {3'b100, 3'b011, 1'b0, 1'b0};
      5'd8: ALUFlags = {3'b100, 3'b111, 1'b1, 1'b0};
      5'd9: ALUFlags = {3'b100, 3'b001, 1'b1, 1'b0};
      5'd10: ALUFlags = {3'b000, 3'b100, 1'b0, 1'b0};
      5'd11: ALUFlags = {3'b010, 3'b100, 1'b0, 1'b0};
      5'd12: ALUFlags = {3'b001, 3'b100, 1'b0, 1'b0};
      5'd13: ALUFlags = {3'b011, 3'b100, 1'b0, 1'b0};
      5'd14: ALUFlags = {3'b100, 3'b101, 1'b0, 1'b0};
      5'd15: ALUFlags = {3'b100, 3'b101, 1'b1, 1'b0};
      5'd16: ALUFlags = {3'b100, 3'b110, 1'b0, 1'b0};
      default: ALUFlags = 8'b0;
      endcase
   end

    // micro code format:
    // 111_000_00_000_00_00_00000000_001_000_000_00_000000_00000_00_000_00
    // stateCtrl  loadP     addrCtrl loadPC  regAXY busCtrl      byteSel
    //     addrBus    loadT              loadSP  loadDKB   ALUCtrl  outBus
    //         addrInc   muxCtrl                                        va
    always @(posedge CLK or negedge RST_N)
    begin
        reg [3:0] STATE2;
        if (~RST_N)
            // MI <= M_TAB[2047];
            MI <= {3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b11};
        else begin
            STATE2 = STATE - 4'd1;
            if (EN == 1'b1) begin
                // NOTE: the previous code causes LUT to explode
                // When STATE==0, returns M_TAB[2047] = {3'b000, 3'b000, 2'b00, 3'b000, 2'b00, 2'b00, 8'b00000000, 3'b001, 3'b000, 3'b000, 2'b00, 6'b000000, 5'b00000, 2'b00, 3'b000, 2'b11}
                MI <= M_TAB[STATE == 4'b0 ? 11'd2047 : {IR, STATE2[2:0]}];
            end
        end
   end
   assign M = {ALUFlags, MI.stateCtrl, MI.addrBus, MI.addrInc, MI.muxCtrl, MI.addrCtrl, MI.loadPC, MI.loadSP, 
               MI.regAXY, MI.loadP, MI.loadT, MI.loadDKB, MI.busCtrl, MI.byteSel, MI.outBus, MI.va};

endmodule
