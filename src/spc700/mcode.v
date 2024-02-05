// `include "spc700.vh"

import spc700::*;

module SPC700_MCode(
    input CLK,
    input RST_N,
    input EN,
    input [7:0] IR,
    input [3:0] STATE,
    output SpcMCode_r M
);

// 31 bits
// stateCtrl[2], addrBus[2], addrCtrl[6], regMode[5], regAXY[2], busCtrl[5], ALUCtrl[6], outBus[3]
// 		ALUCtrl expands to 10 bits
//		regMode expands to 10 bits (loadPC, loadSP, loadP, loadT)
// TODO: MIST SNES has 6-bit busCtrl
`include "mcode.vh"

SpcMicroInst_r MI;
SpcALUCtrl_r ALUFlags;
SpcRegCtrl_r R;

always @(posedge CLK) begin
    if (~RST_N)
        MI <= MCODE0[0]; // {2'b0, 2'b0, 6'b0, 5'b1, 2'b0, 5'b0, 6'b0, 3'b0};
    else if (EN) begin
		MI <= MCODE0[{IR, STATE[2:0]}];
		if (IR == 8'h9E && STATE[3])		// DIV
			MI <= MCODE0[{9'h1,STATE[1:0]}];
		else if (IR == 8'hCF && STATE[3])	// MUL
			MI <= MCODE0[3];
	end
end

always @* begin
	case (MI.ALUCtrl)
	//             fstOp   secOp chgVO chgHO intC chgCO
	0: ALUFlags =  {3'b110,4'b0011,1'b0,1'b0,1'b0,1'b0};// 000000 LOAD
	1: ALUFlags =  {3'b100,4'b1011,1'b0,1'b0,1'b1,1'b0};// 000001 DECW
	2: ALUFlags =  {3'b101,4'b1011,1'b0,1'b0,1'b0,1'b0};// 000010 DEC 
	3: ALUFlags =  {3'b101,4'b1001,1'b0,1'b0,1'b0,1'b0};// 000011 INC
	4: ALUFlags =  {3'b110,4'b0000,1'b0,1'b0,1'b0,1'b0};// 000100 OR
	5: ALUFlags =  {3'b110,4'b0001,1'b0,1'b0,1'b0,1'b0};// 000101 AND
	6: ALUFlags =  {3'b110,4'b0010,1'b0,1'b0,1'b0,1'b0};// 000110 EOR
	7: ALUFlags =  {3'b110,4'b1000,1'b1,1'b1,1'b0,1'b1};// 000111 ADC
	8: ALUFlags =  {3'b110,4'b1010,1'b1,1'b1,1'b0,1'b1};// 001000 SBC
	9: ALUFlags =  {3'b100,4'b1001,1'b0,1'b0,1'b1,1'b0};// 001001 INCW
	10: ALUFlags = {3'b000,4'b0011,1'b0,1'b0,1'b0,1'b1};// 001010 ASL
	11: ALUFlags = {3'b010,4'b0011,1'b0,1'b0,1'b0,1'b1};// 001011 LSR
	12: ALUFlags = {3'b001,4'b0011,1'b0,1'b0,1'b0,1'b1};// 001100 ROL
	13: ALUFlags = {3'b011,4'b0011,1'b0,1'b0,1'b0,1'b1};// 001101 ROR
	14: ALUFlags = {3'b110,4'b0100,1'b0,1'b0,1'b0,1'b0};// 001110 TCLR1
	15: ALUFlags = {3'b110,4'b0101,1'b0,1'b0,1'b0,1'b0};// 001111 TSET1
	16: ALUFlags = {3'b110,4'b1011,1'b0,1'b0,1'b1,1'b1};// 010000 CMPW
	17: ALUFlags = {3'b110,4'b1001,1'b0,1'b0,1'b0,1'b1};// 010001 ADD
	18: ALUFlags = {3'b110,4'b1001,1'b1,1'b1,1'b1,1'b1};// 010010 ADDW
	19: ALUFlags = {3'b110,4'b1011,1'b0,1'b0,1'b0,1'b1};// 010011 SUB/CMP
	20: ALUFlags = {3'b110,4'b1011,1'b1,1'b1,1'b1,1'b1};// 010100 SUBW
	21: ALUFlags = {3'b111,4'b0001,1'b0,1'b0,1'b0,1'b0};// 010101 CLR1
	22: ALUFlags = {3'b110,4'b0000,1'b0,1'b0,1'b0,1'b0};// 010110 SET1
	23: ALUFlags = {3'b110,4'b0001,1'b0,1'b0,1'b0,1'b0};// 010111 AND1
	24: ALUFlags = {3'b111,4'b0001,1'b0,1'b0,1'b0,1'b0};// 011000 NOT AND1
	25: ALUFlags = {3'b110,4'b0000,1'b0,1'b0,1'b0,1'b0};// 011001 OR1
	26: ALUFlags = {3'b111,4'b0000,1'b0,1'b0,1'b0,1'b0};// 011010 NOT OR1
	27: ALUFlags = {3'b110,4'b0010,1'b0,1'b0,1'b0,1'b0};// 011011 EOR1
	28: ALUFlags = {3'b101,4'b0010,1'b0,1'b0,1'b0,1'b0};// 011100 NOTC {C ^ 1}
	29: ALUFlags = {3'b110,4'b0110,1'b0,1'b0,1'b0,1'b0};// 011101 XCN
	30: ALUFlags = {3'b110,4'b1100,1'b0,1'b0,1'b0,1'b1};// 011110 DAA 
	31: ALUFlags = {3'b110,4'b1101,1'b0,1'b0,1'b0,1'b1};// 011111 DAS
	32: ALUFlags = {3'b110,4'b1110,1'b0,1'b0,1'b0,1'b0};// 100000 MUL 
	33: ALUFlags = {3'b110,4'b1111,1'b1,1'b1,1'b0,1'b0};// 100001 DIV
	default: ALUFlags = 11'b0;
	endcase
end

always @* begin
	case (MI.regMode)
	//      loadPC loadSP loadP loadT
	0: R = {3'b000,2'b00,3'b000,2'b00};//00000
	1: R = {3'b001,2'b00,3'b000,2'b00};//00001 PC++
	2: R = {3'b001,2'b00,3'b001,2'b00};//00010 PC++, Flags
	3: R = {3'b000,2'b00,3'b001,2'b00};//00011 Flags
	4: R = {3'b000,2'b11,3'b000,2'b00};//00100 X->SP
	5: R = {3'b001,2'b00,3'b000,2'b01};//00101 [PC]->T, PC++
	6: R = {3'b000,2'b00,3'b000,2'b01};//00110 []->T
	7: R = {3'b000,2'b00,3'b001,2'b10};//00111 ALU{}->T, Flags
	8: R = {3'b000,2'b00,3'b100,2'b00};//01000 CLR/SET
	9: R = {3'b011,2'b00,3'b000,2'b00};//01001 PC+DR->PC
	10: R = {3'b000,2'b00,3'b101,2'b00};//01010 C change
	11: R = {3'b000,2'b00,3'b000,2'b10};//01011 ALU{}->T
	12: R = {3'b010,2'b00,3'b000,2'b00};//01100 []:DR->PC
	13: R = {3'b000,2'b10,3'b000,2'b00};//01101 Reg->[SP], SP--
	14: R = {3'b100,2'b00,3'b000,2'b00};//01110 AX->PC
	15: R = {3'b000,2'b00,3'b010,2'b00};//01111 1->B
	16: R = {3'b000,2'b01,3'b000,2'b00};//10000 SP++
	17: R = {3'b000,2'b00,3'b011,2'b00};//10001 []->PSW
	18: R = {3'b101,2'b00,3'b000,2'b00};//10010 FF:AL->PC
	default: R = 10'b0;
	endcase
end

assign M = {ALUFlags, 
            MI.stateCtrl, 
            MI.addrBus, 
            MI.addrCtrl,
            R.loadPC,
            R.loadSP, 
            MI.regAXY, 
            R.loadP, 
            R.loadT,
            MI.busCtrl,
            MI.outBus};

endmodule