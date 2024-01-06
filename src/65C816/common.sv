package P65816;

// 52 bits
typedef struct packed {
  logic [2:0] stateCtrl;
  logic [2:0] addrBus;
  logic [1:0] addrInc;
  logic [2:0] loadP;
  logic [1:0] loadT;
  logic [1:0] muxCtrl;
  logic [7:0] addrCtrl;
  logic [2:0] loadPC;
  logic [2:0] loadSP;
  logic [2:0] regAXY;
  logic [1:0] loadDKB;
  logic [5:0] busCtrl;
  logic [4:0] ALUCtrl;
  logic [1:0] byteSel;
  logic [2:0] outBus;
  logic [1:0] va;
} MicroInst_r;

// 8 bits
typedef struct packed {
  logic [2:0] fstOp;
  logic [2:0] secOp;
  logic fc;
  logic w16;
} ALUCtrl_r;

// 55 bits
typedef struct packed {
  ALUCtrl_r ALU_CTRL;
  logic [2:0] STATE_CTRL;
  logic [2:0] ADDR_BUS;
  logic [1:0] ADDR_INC;
  logic [1:0] IND_CTRL;
  logic [7:0] ADDR_CTRL;
  logic [2:0] LOAD_PC;
  logic [2:0] LOAD_SP;
  logic [2:0] LOAD_AXY;
  logic [2:0] LOAD_P;
  logic [1:0] LOAD_T;
  logic [1:0] LOAD_DKB;
  logic [5:0] BUS_CTRL;
  logic [1:0] BYTE_SEL;
  logic [2:0] OUT_BUS;
  logic [1:0] VA;
} MCode_r;

endpackage