// `ifndef SPC700_H
// `define SPC700_H

package spc700;

typedef struct packed {
    logic [1:0] stateCtrl;
    logic [1:0] addrBus;
    logic [5:0] addrCtrl;
    logic [4:0] regMode;
    logic [1:0] regAXY;
    logic [4:0] busCtrl;
    logic [5:0] ALUCtrl;
    logic [2:0] outBus;
} SpcMicroInst_r;

typedef struct packed {
    logic [2:0] fstOp;
    logic [3:0] secOp;
    logic chgHO;
    logic intC;
    logic chgCO;
} SpcALUCtrl_r;

typedef struct packed {
    logic [2:0] loadPC;
    logic [1:0] loadSP;
    logic [2:0] loadP;
    logic [1:0] loadT;
} SpcRegCtrl_r;

typedef struct packed {
    SpcALUCtrl_r ALU_CTRL;
    logic [1:0] STATE_CTRL;
    logic [1:0] ADDR_BUS;
    logic [5:0] ADDR_CTRL;
    logic [2:0] LOAD_PC;
    logic [1:0] LOAD_SP;
    logic [1:0] LOAD_AXY;
    logic [2:0] LOAD_P;
    logic [1:0] LOAD_T;
    logic [4:0] BUS_CTRL;
    logic [2:0] OUT_BUS;
} SpcMCode_r;

endpackage

// `endif