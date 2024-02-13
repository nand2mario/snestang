package GSU_Package;

parameter FLAG_GO = 5;
parameter FLAG_R = 6;
parameter FLAG_IL = 10;
parameter FLAG_IH = 11;
parameter FLAG_IRQ = 15;

parameter NUM_MCODES = 25;

parameter [5:0]
    OP_NOP = 0, OP_STOP = 1, OP_CACHE = 2, OP_MOVE = 3, 
    OP_MOVES = 4, OP_IBT = 5, OP_IWT = 6, OP_GETB = 7,
    OP_GETBH = 8, OP_GETBL = 9, OP_GETBS = 10, OP_LDB = 11,
    OP_LDW = 12, OP_LM = 13, OP_LMS = 14, OP_STB = 15,
    OP_STW = 16, OP_SM = 17, OP_SMS = 18, OP_SBK = 19,
    OP_RAMB = 20, OP_ROMB = 21, OP_CMODE = 22, OP_COLOR = 23,
    OP_GETC = 24, OP_PLOT = 25, OP_RPIX = 26, OP_ADD = 27,
    OP_SUB = 28, OP_CMP = 29, OP_AND = 30, OP_OR = 31,
    OP_XOR = 32, OP_NOT = 33, OP_LSR = 34, OP_ASR = 35,
    OP_ROL = 36, OP_ROR = 37, OP_DIV2 = 38, OP_INC = 39,
    OP_DEC = 40, OP_SWAP = 41, OP_SEX = 42, OP_LOB = 43,
    OP_HIB = 44, OP_MERGE = 45, OP_MULT = 46, OP_UMULT = 47,
    OP_FMULT = 48, OP_LMULT = 49, OP_BRA = 50, OP_JMP = 51,
    OP_LJMP = 52, OP_LOOP = 53, OP_LINK = 54, OP_ALT1 = 55,
    OP_ALT2 = 56, OP_ALT3 = 57, OP_TO = 58, OP_WITH = 59,
    OP_FROM = 60;
typedef logic [5:0] Opcode_t;
typedef logic [$clog2(NUM_MCODES)-1:0] Mccode_t;

typedef struct packed {
    Opcode_t OP;
    Mccode_t MC;     
} Opcode_r;

typedef struct packed {
    Opcode_r OP;
    Opcode_r OP_ALT1;
    Opcode_r OP_ALT2;
    Opcode_r OP_ALT3;
} OpcodeAlt_r;

typedef struct packed {
    logic LAST_CYCLE;
    logic INCPC;
    logic FSET;         // 1: update ALU flags
    logic [2:0] DREG;   // [2] - dest reg 0 = Rd, 1 = Rn; [1] - MSB; [0] - LSB;
    logic ROMWAIT;
    logic RAMWAIT;
    logic [1:0] RAMLD;
    logic [2:0] RAMST;  // [2] - source reg 0 = Rs, 1 = Rn; [1] - MSB; [0] - LSB;
    logic [2:0] RAMADDR;// [2:0] 0 = none, 1 = RAMADDR.LSB = DATA, 2 = RAMADDR.MSB = DATA, 3 = RAMADDR = Rn, 4 = RAMADDR = DATA*2, 5 = RAMADDR no change 
} Microcode_r;

typedef Microcode_r MicrocodeTbl_t[NUM_MCODES][4];

parameter MicrocodeTbl_t MC_TBL = '{
	// 0 STOP
	'{{1'b1,1'b1,1'b0,3'b000,1'b1,1'b1,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 1 NOP
	'{{1'b1,1'b1,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 2 CACHE
	'{{1'b1,1'b1,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 3 BRA
	'{{1'b0,1'b1,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'b1,1'b1,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 4 MOVE
	'{{1'b1,1'b1,1'b0,3'b111,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 5 ALU
	'{{1'b1,1'b1,1'b1,3'b011,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 6 CMP
	'{{1'b1,1'b1,1'b1,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 7 IBT
	'{{1'b0,1'b1,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'b1,1'b1,1'b0,3'b111,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 8 IWT
	'{{1'b0,1'b1,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'b0,1'b1,1'b0,3'b101,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'b1,1'b1,1'b0,3'b110,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 9 LDB
	'{{1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b01,3'b000,3'b011},
	  {1'b1,1'b1,1'b0,3'b001,1'b0,1'b1,2'b01,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 10 LDW
	'{{1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b10,3'b000,3'b011},
	  {1'b1,1'b1,1'b0,3'b011,1'b0,1'b1,2'b10,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 11 GETB/GETC
	'{{1'b1,1'b1,1'b0,3'b011,1'b1,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 12 STB
	'{{1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b00,3'b001,3'b011},
	  {1'b1,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b001,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 13 STW
	'{{1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b00,3'b010,3'b011},
	  {1'b1,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b010,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 14 INC/DEC
	'{{1'b1,1'b1,1'b1,3'b111,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 15 SM
	'{{1'b0,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b000,3'b000},
	  {1'b0,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b000,3'b001},
	  {1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b00,3'b110,3'b010},
	  {1'b1,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b110,3'b000}},
	// 16 ROMB
	'{{1'b1,1'b1,1'b0,3'b000,1'b1,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 17 RAMB
	'{{1'b1,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 18 LM
	'{{1'b0,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b000,3'b000},
	  {1'b0,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b000,3'b001},
	  {1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b10,3'b000,3'b010},
	  {1'b1,1'b1,1'b0,3'b111,1'b0,1'b1,2'b10,3'b000,3'b000}},
	// 19 LMS
	'{{1'b0,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b000,3'b000},
	  {1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b10,3'b000,3'b100},
	  {1'b1,1'b1,1'b0,3'b111,1'b0,1'b1,2'b10,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 20 SMS
	'{{1'b0,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b000,3'b000},
	  {1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b00,3'b110,3'b100},
	  {1'b1,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b110,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 21 SBK
	'{{1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b00,3'b010,3'b101},
	  {1'b1,1'b1,1'b0,3'b000,1'b0,1'b1,2'b00,3'b010,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 22 RPIX
	'{{1'b0,1'b0,1'b0,3'b000,1'b0,1'b1,2'b00,3'b000,3'b000},
	  {1'b1,1'b1,1'b1,3'b001,1'b0,1'b1,2'b01,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 23 PLOT
	'{{1'b1,1'b1,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}},
	// 24 LMULT
	'{{1'b0,1'b0,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'b0,1'b0,1'b0,3'b000,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'b1,1'b1,1'b1,3'b011,1'b0,1'b0,2'b00,3'b000,3'b000},
	  {1'bX,1'bX,1'bX,3'bXXX,1'bX,1'bX,2'bXX,3'bXXX,3'bXXX}}
};

typedef OpcodeAlt_r OpcodeTbl_t[256];
parameter OpcodeTbl_t OP_TBL = '{
	'{'{OP_STOP,   0}, '{OP_STOP,    0}, '{OP_STOP,    0}, '{OP_STOP,    0}}, //STOP
	'{'{OP_NOP,    1}, '{OP_NOP,     1}, '{OP_NOP,     1}, '{OP_NOP,     1}}, //NOP
	'{'{OP_CACHE,  2}, '{OP_CACHE,   2}, '{OP_CACHE,   2}, '{OP_CACHE,   2}}, //CACHE
	'{'{OP_LSR,    5}, '{OP_LSR,     5}, '{OP_LSR,     5}, '{OP_LSR,     5}}, //LSR
	'{'{OP_ROL,    5}, '{OP_ROL,     5}, '{OP_ROL,     5}, '{OP_ROL,     5}}, //ROL
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BRA
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BGE
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BLT
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BNE
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BEQ
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BPL
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BMI
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BCC
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BCS
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BVC
	'{'{OP_BRA,    3}, '{OP_BRA,     3}, '{OP_BRA,     3}, '{OP_BRA,     3}}, //BVS
	//10
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R0 / MOVE R0,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R1 / MOVE R1,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R2 / MOVE R2,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R3 / MOVE R3,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R4 / MOVE R4,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R5 / MOVE R5,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R6 / MOVE R6,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R7 / MOVE R7,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R8 / MOVE R8,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R9 / MOVE R9,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R10 / MOVE R10,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R11 / MOVE R11,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R12 / MOVE R12,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R13 / MOVE R13,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R14 / MOVE R14,Rs
	'{'{OP_TO,     1}, '{OP_TO,      1}, '{OP_TO,      1}, '{OP_TO,      1}}, //TO R15 / MOVE R15,Rs
	//20
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R0
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R1
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R2
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R3
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R4
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R5
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R6
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R7
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R8
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R9
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R10
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R11
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R12
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R13
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R14
	'{'{OP_WITH,   1}, '{OP_WITH,    1}, '{OP_WITH,    1}, '{OP_WITH,    1}}, //WITH R15
	 //30
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R0)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R1)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R2)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R3)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R4)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R5)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R6)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R7)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R8)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R9)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R10)
	'{'{OP_STW,   13}, '{OP_STB,    12}, '{OP_STW,    13}, '{OP_STW,    13}}, //STB/STW (R11)
	'{'{OP_LOOP,   5}, '{OP_LOOP,    5}, '{OP_LOOP,    5}, '{OP_LOOP,    5}}, //LOOP
	'{'{OP_ALT1,   1}, '{OP_ALT1,    1}, '{OP_ALT1,    1}, '{OP_ALT1,    1}}, //ALT1
	'{'{OP_ALT2,   1}, '{OP_ALT2,    1}, '{OP_ALT2,    1}, '{OP_ALT2,    1}}, //ALT2
	'{'{OP_ALT3,   1}, '{OP_ALT3,    1}, '{OP_ALT3,    1}, '{OP_ALT3,    1}}, //ALT3
	//40
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R0)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R1)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R2)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R3)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R4)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R5)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R6)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R7)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R8)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R9)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R10)
	'{'{OP_LDW,   10}, '{OP_LDB,     9}, '{OP_LDW,    10}, '{OP_LDW,    10}}, //LDB/LDW (R11)
	'{'{OP_PLOT,  23}, '{OP_RPIX,   22}, '{OP_PLOT,   23}, '{OP_PLOT,   23}}, //PLOT / RPIX
	'{'{OP_SWAP,   5}, '{OP_SWAP,    5}, '{OP_SWAP,    5}, '{OP_SWAP,    5}}, //SWAP
	'{'{OP_COLOR,  1}, '{OP_CMODE,   1}, '{OP_COLOR,   1}, '{OP_COLOR,   1}}, //COLOR / CMODE
	'{'{OP_NOT,    5}, '{OP_NOT,     5}, '{OP_NOT,     5}, '{OP_NOT,     5}}, //NOT
	//50
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R0 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R1 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R2 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R3 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R4 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R5 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R6 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R7 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R8 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R6 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R10 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R11 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R12 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R13 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R14 
	'{'{OP_ADD,    5}, '{OP_ADD,     5}, '{OP_ADD,     5}, '{OP_ADD,     5}}, //ADD R15 
	//60
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R0 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R1 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R2 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R3 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R4 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R5 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R6 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R7 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R8 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R9 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R10 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R11 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R12 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R13 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R14 
	'{'{OP_SUB,    5}, '{OP_SUB,     5}, '{OP_SUB,     5}, '{OP_CMP,     6}}, //SUB/CMP R15 
	//70
	'{'{OP_MERGE,  5}, '{OP_MERGE,   5}, '{OP_MERGE,   5}, '{OP_MERGE,   5}}, //MERGE
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R1 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R2 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R3 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R4 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R5 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R6 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R7 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R8 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R9 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R10 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R11 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R12 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R13 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R14 
	'{'{OP_AND,    5}, '{OP_AND,     5}, '{OP_AND,     5}, '{OP_AND,     5}}, //AND R15 
	//80
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R0
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R1 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R2 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R3 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R4 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R5 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R6 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R7 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R8 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R9 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R10 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R11 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R12 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R13 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R14 
	'{'{OP_MULT,   5}, '{OP_UMULT,   5}, '{OP_MULT,    5}, '{OP_UMULT,   5}}, //MULT/UMULT R15 
	//90
	'{'{OP_SBK,   21}, '{OP_SBK,    21}, '{OP_SBK,    21}, '{OP_SBK,    21}}, //SBK
	'{'{OP_LINK,   1}, '{OP_LINK,    1}, '{OP_LINK,    1}, '{OP_LINK,    1}}, //LINK #1
	'{'{OP_LINK,   1}, '{OP_LINK,    1}, '{OP_LINK,    1}, '{OP_LINK,    1}}, //LINK #2 
	'{'{OP_LINK,   1}, '{OP_LINK,    1}, '{OP_LINK,    1}, '{OP_LINK,    1}}, //LINK #3 
	'{'{OP_LINK,   1}, '{OP_LINK,    1}, '{OP_LINK,    1}, '{OP_LINK,    1}}, //LINK #4 
	'{'{OP_SEX,    5}, '{OP_SEX,     5}, '{OP_SEX,     5}, '{OP_SEX,     5}}, //SEX
	'{'{OP_ASR,    5}, '{OP_DIV2,    5}, '{OP_ASR,     5}, '{OP_ASR,     5}}, //ASR / DIV2
	'{'{OP_ROR,    5}, '{OP_ROR,     5}, '{OP_ROR,     5}, '{OP_ROR,     5}}, //ROR
	'{'{OP_JMP,    1}, '{OP_LJMP,    1}, '{OP_JMP,     1}, '{OP_JMP,     1}}, //JMP R8 / LJMP R8 
	'{'{OP_JMP,    1}, '{OP_LJMP,    1}, '{OP_JMP,     1}, '{OP_JMP,     1}}, //JMP R9 / LJMP R9 
	'{'{OP_JMP,    1}, '{OP_LJMP,    1}, '{OP_JMP,     1}, '{OP_JMP,     1}}, //JMP R10 / LJMP R10 
	'{'{OP_JMP,    1}, '{OP_LJMP,    1}, '{OP_JMP,     1}, '{OP_JMP,     1}}, //JMP R11 / LJMP R11 
	'{'{OP_JMP,    1}, '{OP_LJMP,    1}, '{OP_JMP,     1}, '{OP_JMP,     1}}, //JMP R12 / LJMP R12 
	'{'{OP_JMP,    1}, '{OP_LJMP,    1}, '{OP_JMP,     1}, '{OP_JMP,     1}}, //JMP R13 / LJMP R13 
	'{'{OP_LOB,    5}, '{OP_LOB,     5}, '{OP_LOB,     5}, '{OP_LOB,     5}}, //LOB
	'{'{OP_FMULT, 24}, '{OP_LMULT,  24}, '{OP_FMULT,  24}, '{OP_FMULT,  24}}, //FMULT / LMULT
	//A0
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R0,#pp / LMS R0,(yy) / SMS (yy),R0
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R1,#pp / LMS R1,(yy) / SMS (yy),R1
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R2,#pp / LMS R2,(yy) / SMS (yy),R2
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R3,#pp / LMS R3,(yy) / SMS (yy),R3
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R4,#pp / LMS R4,(yy) / SMS (yy),R4
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R5,#pp / LMS R5,(yy) / SMS (yy),R5 
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R6,#pp / LMS R6,(yy) / SMS (yy),R6
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R7,#pp / LMS R7,(yy) / SMS (yy),R7
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R8,#pp / LMS R8,(yy) / SMS (yy),R8
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R9,#pp / LMS R9,(yy) / SMS (yy),R9
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R10,#pp / LMS R10,(yy) / SMS (yy),R10
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R11,#pp / LMS R11,(yy) / SMS (yy),R11
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R12,#pp / LMS R12,(yy) / SMS (yy),R12
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R13,#pp / LMS R13,(yy) / SMS (yy),R13
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R14,#pp / LMS R14,(yy) / SMS (yy),R14
	'{'{OP_IBT,    7}, '{OP_LMS,    19}, '{OP_SMS,    20}, '{OP_IBT,     7}}, //IBT R15,#pp / LMS R15,(yy) / SMS (yy),R15
	//B0
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R0 / MOVES Rd,R0
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R1 / MOVES Rd,R1
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R2 / MOVES Rd,R2
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R3 / MOVES Rd,R3
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R4 / MOVES Rd,R4
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R5 / MOVES Rd,R5
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R6 / MOVES Rd,R6
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R7 / MOVES Rd,R7
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R8 / MOVES Rd,R8
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R9 / MOVES Rd,R9
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R10 / MOVES Rd,R10
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R11 / MOVES Rd,R11
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R12 / MOVES Rd,R12
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R13 / MOVES Rd,R13
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R14 / MOVES Rd,R14
	'{'{OP_FROM,   1}, '{OP_FROM,    1}, '{OP_FROM,    1}, '{OP_FROM,    1}}, //FROM R15 / MOVES Rd,R15
	//C0
	'{'{OP_HIB,    5}, '{OP_HIB,     5}, '{OP_HIB,     5}, '{OP_HIB,     5}}, //HIB
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R1 / XOR R1
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R2 / XOR R2
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R3 / XOR R3
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R4 / XOR R4
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R5 / XOR R5
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R6 / XOR R6
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R7 / XOR R7
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R8 / XOR R8
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R9 / XOR R9
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R10 / XOR R10
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R11 / XOR R11
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R12 / XOR R12
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R13 / XOR R13
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R14 / XOR R14
	'{'{OP_OR,     5}, '{OP_XOR,     5}, '{OP_OR,      5}, '{OP_XOR,     5}}, //OR R15 / XOR R15
	//D0
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R0
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R1 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R2 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R3 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R4 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R5 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R6 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R7 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R8 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R9 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R10 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R11 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R12 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R13 
	'{'{OP_INC,   14}, '{OP_INC,    14}, '{OP_INC,    14}, '{OP_INC,    14}}, //INC R14 
	'{'{OP_GETC,  11}, '{OP_GETC,   11}, '{OP_RAMB,   17}, '{OP_ROMB,   16}}, //GETC / RAMB / ROMB
	//E 0
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R0
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R1 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R2 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R3 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R4 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R5 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R6 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R7 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R8 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R9 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R10 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R11 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R12 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R13 
	'{'{OP_DEC,   14}, '{OP_DEC,    14}, '{OP_DEC,    14}, '{OP_DEC,    14}}, //DEC R14 
	'{'{OP_GETB,  11}, '{OP_GETBH,  11}, '{OP_GETBL,  11}, '{OP_GETBS,  11}}, //GETB / GETBH / GETBL / GETBS
	//F0
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R0,#yyxx / LM R0,(hilo) / SM (hilo),R0
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R1,#yyxx / LM R1,(hilo) / SM (hilo),R1
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R2,#yyxx / LM R2,(hilo) / SM (hilo),R2
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R3,#yyxx / LM R3,(hilo) / SM (hilo),R3
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R4,#yyxx / LM R4,(hilo) / SM (hilo),R4
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R5,#yyxx / LM R5,(hilo) / SM (hilo),R5
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R6,#yyxx / LM R6,(hilo) / SM (hilo),R6
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R7,#yyxx / LM R7,(hilo) / SM (hilo),R7
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R8,#yyxx / LM R8,(hilo) / SM (hilo),R8
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R9,#yyxx / LM R9,(hilo) / SM (hilo),R9
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R10,#yyxx / LM R10,(hilo) / SM (hilo),R10
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R11,#yyxx / LM R11,(hilo) / SM (hilo),R11
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R12,#yyxx / LM R12,(hilo) / SM (hilo),R12
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R13,#yyxx / LM R13,(hilo) / SM (hilo),R13
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}, //IWT R14,#yyxx / LM R14,(hilo) / SM (hilo),R14
	'{'{OP_IWT,    8}, '{OP_LM,     18}, '{OP_SM,     15}, '{OP_IWT,     8}}  //IWT R15,#yyxx / LM R15,(hilo) / SM (hilo),R15
};

typedef logic [15:0] Reg_t [16];

// typedef logic [7:0] PixCacheData_t [8];
typedef struct {
    logic [8*8-1:0] DATA;		// 8 bytes
    logic [12:0] OFFSET;
    logic [7:0] VALID;
} PixCache_r;
typedef PixCache_r PixCaches_t[2];

parameter [2:0]
    ROMST_IDLE = 0, ROMST_FETCH = 1, ROMST_FETCH_DONE = 2, ROMST_CACHE = 3,
    ROMST_CACHE_DONE = 4, ROMST_CACHE_END = 5, ROMST_LOAD = 6;

parameter [3:0]
    RAMST_IDLE = 0, RAMST_FETCH = 1, RAMST_FETCH_DONE = 2, RAMST_CACHE = 3,
    RAMST_CACHE_DONE = 4, RAMST_CACHE_END = 5, RAMST_LOAD = 6, RAMST_SAVE = 7,
    RAMST_PCF = 8, RAMST_PCF_END = 9, RAMST_RPIX = 10;

parameter [0:0]
    MULTST_IDLE = 0, MULTST_EXEC = 1;

function logic [2:0] GetLastBPP(logic [1:0] md);
    logic [2:0] res;
    case (md)
    2'b00: res = 3'b001;
    2'b01: res = 3'b011;
    2'b11: res = 3'b111;
    default: res = 3'b011;
    endcase
    return res;
endfunction

function logic [16:0] GetCharOffset(logic [12:0] offs, logic [1:0] ht,
                                    logic [1:0] md, logic [2:0] bpp, logic [7:0] scbr);
    logic [9:0] temp;
    logic [16:0] temp2;
    logic [16:0] res;

    case (ht)
    2'b00: temp = {1'b0, offs[4:0], 4'b0} + {5'b0, offs[12:8]};
    2'b01: temp = {1'b0, offs[4:0], 4'b0} + {3'b0, offs[4:0], 2'b0};
    2'b10: temp = {1'b0, offs[4:0], 4'b0} + {2'b0, offs[4:0], 3'b0};
    default:  temp = {offs[12], offs[4], offs[11:8], offs[3:0]};
    endcase

    case (md)
    2'b00: temp2 = {3'b0, temp, 4'b0};
    2'b01: temp2 = {2'b0, temp, 5'b0};
    2'b10: temp2 = {1'b0, temp, 6'b0};
    default:  temp2 = {2'b0, temp, 5'b0};
    endcase

    res = temp2 + {scbr[6:0], 4'b0, bpp[2:1], offs[7:5], bpp[0]};
    return res;
endfunction

function logic [7:0] GetPCData(PixCache_r pc, logic [2:0] p);
    return {pc.DATA[{3'b111, p}], pc.DATA[{3'b110, p}], pc.DATA[{3'b101, p}], pc.DATA[{3'b100, p}],
            pc.DATA[{3'b011, p}], pc.DATA[{3'b010, p}], pc.DATA[{3'b001, p}], pc.DATA[{3'b000, p}]};
endfunction

endpackage