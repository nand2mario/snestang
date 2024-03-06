
import GSU_Package::*;

module GSU(
    input CLK,
    
    input RST_N,
    input ENABLE,
    input CLKREF,       // for sdram access sync
    
    input [23:0] ADDR,
    input [7:0] DI,
    output reg [7:0] DO,
    input RD_N,
    input WR_N,

    input SYSCLKF_CE,
    input SYSCLKR_CE,
    
    input TURBO,
    output IRQ_N,
    
    output [20:0] ROM_A,
    input [7:0] ROM_DI,
    output reg ROM_RD_N,
    
    output [16:0] RAM_A,
    input [7:0] RAM_DI,
    output [7:0] RAM_DO,
    output RAM_WE_N,
    output RAM_CE_N
    
    // output DBG_IN_CACHE,
    //  output Microcode_r DBG_MC;      //for MISTer sdram
    // output [15:0] DBG_GO_CNT
);

// CPU Registers
reg [15:0] R[0:15];
reg [15:0] CBR;
reg [7:0] PBR;
reg [7:0] ROMBR;
reg [7:0] RAMBR;
wire [15:0] ROMADDR;
reg [15:0] RAMADDR;
reg [7:0] ROMDR;
reg [15:0] RAMDR;
reg [7:0] BRAMR;
reg [7:0] SCBR;
reg MS0;
reg IRQ_OFF;
reg CLS;
reg [3:0] DREG;
reg [3:0] SREG;
reg FLAG_B;
reg FLAG_ALT1;
reg FLAG_ALT2;
reg FLAG_GO;
reg FLAG_R;
reg FLAG_IRQ;
reg FLAG_Z;
reg FLAG_CY;
reg FLAG_S;
reg FLAG_OV;
reg [7:0] COLR;
reg POR_TRANS;
reg POR_DITH;
reg POR_HN;
reg POR_FH;
reg POR_OBJ;
reg [1:0] SCMR_MD;
reg [1:0] SCMR_HT;
reg RON;
reg RAN;

// CPU opcode logic
OpcodeAlt_r OPS;
Opcode_r OP;
Microcode_r MC;
reg [7:0] OPCODE;
reg [7:0] OPDATA;
wire [3:0] OP_N;
reg [1:0] STATE;  

//CPU Core
reg EN;
reg GO;
wire CPU_EN;
reg CLK_CE;
wire SPEED;
reg [15:0] ALUR;
reg [15:0] MULR;
reg ALUZ;
reg ALUS;
reg ALUOV;
reg ALUCY;
reg [7:0] REG_LSB;
wire [3:0] DST_REG;
wire R14_CHANGE;
reg [2:0] ROMST;
reg [3:0] RAMST;
reg ROM_FETCH_EN;
reg RAM_FETCH_EN;
wire CACHE_FETCH_EN;
reg ROM_CACHE_EN;
reg RAM_CACHE_EN;
reg ROM_LOAD_PEND;
reg ROM_FETCH_PEND;
reg ROM_LOAD_WAIT;
reg ROM_FETCH_WAIT;
reg ROM_CACHE_WAIT;
reg RAM_LOAD_PEND;
reg RAM_SAVE_PEND;
reg RAM_PCF_PEND;
reg RAM_RPIX_PEND;
reg RAM_FETCH_PEND;
reg RAM_LOAD_WAIT;
reg RAM_SAVE_WAIT;
reg RAM_PCF_WAIT;
reg RAM_FETCH_WAIT;
reg RAM_CACHE_WAIT;
reg RAM_PCF_FULL;
reg [2:0] ROM_ACCESS_CNT;
reg [2:0] RAM_ACCESS_CNT;
wire CODE_IN_ROM;
wire CODE_IN_RAM;
reg [7:0] ROM_BUF;
reg RAM_BYTES;
reg RAM_WORD;
reg [15:0] RAM_LOAD_BUF;
reg [7:0] RAM_BUF;

reg MULTST;
reg [2:0] MULT_ACCESS_CNT;
reg MULT_WAIT;  

//CPU Code Cache
reg [31:0] CACHE_VALID;
wire [15:0] CACHE_POS;
reg [8:0] CACHE_DST_ADDR;
reg [23:0] CACHE_SRC_ADDR;
reg CACHE_RUN;
wire IN_CACHE;
wire VAL_CACHE;
wire [8:0] BRAM_CACHE_ADDR_A;
wire [8:0] BRAM_CACHE_ADDR_B;
wire [7:0] BRAM_CACHE_DI_A;
wire [7:0] BRAM_CACHE_DI_B;
reg [7:0] BRAM_CACHE_Q_A;
reg [7:0] BRAM_CACHE_Q_B;
wire BRAM_CACHE_WE_A;
wire BRAM_CACHE_WE_B;  

//CPU Pixel Cache
PixCaches_t PIX_CACHE;
wire [16:0] PCF_RAM_A;
wire [16:0] RPIX_RAM_A;
reg [7:0] PCF_RD_DATA;
wire [7:0] PCF_WR_DATA;
reg [7:0] RPIX_DATA;
reg PCF_RW;
reg PCF_WO;
wire PC0_FULL;
wire PC0_EMPTY;
wire [7:0] PC_X;
wire [7:0] PC_Y;
wire PC0_OFFS_HIT;
reg [2:0] BPP_CNT;
reg PLOT_EXEC;  

//MMIO
reg MMIO_SEL;
reg MMIO_CACHE_SEL;
reg MMIO_REG_SEL;
reg ROM_SEL;
reg SRAM_SEL;
wire MMIO_WR;
wire MMIO_RD;
wire MMIO_CACHE_WR;
wire MMIO_REG_WR;
reg GSU_MEM_ACCESS;
wire GSU_ROM_ACCESS;
wire GSU_RAM_ACCESS;
wire [15:0] SFR;
reg [16:0] SNES_RAM_A;
wire [23:0] INT_ROM_A;
wire [8:0] SNES_CACHE_ADDR;  
//reg GSU_ROM_RD;
reg [1:0] ROM_RD_CNT;
reg [15:0] GO_CNT;

//IO Ports
always @(ADDR) begin
    MMIO_CACHE_SEL <= 1'b0;
    MMIO_SEL <= 1'b0;
    MMIO_REG_SEL <= 1'b0;
    ROM_SEL <= 1'b0;
    SRAM_SEL <= 1'b0;
    SNES_RAM_A <= ADDR[16:0];
    if (ADDR[22] == 1'b0) begin
        if (ADDR[15:12] == 4'h3) begin
            if (ADDR[11:8] == 4'h0) begin
                if (ADDR[7:5] == 3'b000)                //00-3F:3000-301F, 80-BF:3000-301F
                    MMIO_REG_SEL <= 1'b1;
                else                                    //00-3F:3030-30FF, 80-BF:3030-30FF
                    MMIO_SEL <= 1'b1;
            end else if (ADDR[11:8] == 4'h1 || ADDR[11:8] == 4'h2)     //00-3F:3100-32FF, 80-BF:3100-32FF
                MMIO_CACHE_SEL <= 1'b1;
        end else if (ADDR[15:13] == 3'b011) begin       //00-3F:6000-7FFF, 80-BF:6000-7FFF
            SRAM_SEL <= 1'b1;
            SNES_RAM_A <= {4'b0000,ADDR[12:0]};
        end else if (ADDR[15]) begin
            ROM_SEL <= 1'b1;
        end
    end else begin
        if (ADDR[21] == 1'b0)                           //40-5F:0000-FFFF, C0-DF:0000-FFFF
            ROM_SEL <= 1'b1;
        else if (ADDR[23:17] == {4'h7,3'b000})          //70-71:0000-FFFF
            SRAM_SEL <= 1'b1;
    end
end

assign MMIO_CACHE_WR = MMIO_CACHE_SEL & SYSCLKF_CE &  ~WR_N;
assign MMIO_WR = MMIO_SEL & SYSCLKF_CE &  ~WR_N;
assign MMIO_RD = MMIO_SEL & SYSCLKF_CE &  ~RD_N;
assign MMIO_REG_WR = MMIO_REG_SEL & SYSCLKF_CE &  ~WR_N;

always @(posedge CLK) begin
    if (~RST_N) begin
        GO <= 1'b0;
        BRAMR <= {8{1'b0}};
        PBR <= {8{1'b0}};
        FLAG_GO <= 1'b0;
        FLAG_IRQ <= 1'b0;
        MS0 <= 1'b0;
        IRQ_OFF <= 1'b0;
        SCBR <= {8{1'b0}};
        CLS <= 1'b0;
        SCMR_MD <= {2{1'b0}};
        SCMR_HT <= {2{1'b0}};
        RAN <= 1'b0;
        RON <= 1'b0;
        GSU_MEM_ACCESS <= 1'b0;

        GO_CNT <= {16{1'b0}};
    end else begin
        if (ENABLE) begin
            if (MMIO_WR) begin
                if (ADDR[7:0] == 8'h30) begin           //SFR LSB
                    GO <= DI[5];
                    GSU_MEM_ACCESS <= DI[5];
                end else if (ADDR[7:0] == 8'h38)        //SCBR
                    SCBR <= DI;
                else if (ADDR[7:0] == 8'h3A) begin      //SCMR
                    SCMR_MD <= DI[1:0];
                    SCMR_HT <= {DI[5],DI[2]};
                    RAN <= DI[3];
                    RON <= DI[4];
                end
            end else if (MMIO_RD && ADDR[7:0] == 8'h31) //SFR MSB
                FLAG_IRQ <= 1'b0;

            if (~EN) begin
                if (MMIO_REG_WR && ADDR[4:0] == 5'b11111) begin
                    GO <= 1'b1;
                    GSU_MEM_ACCESS <= 1'b1;
                end else if (MMIO_WR) begin
                    case (ADDR[7:0])
                    8'h33 : BRAMR <= DI;    // 3033
                    8'h34 : PBR <= DI;      // 3034
                    8'h37 : begin           // 3037
                        MS0 <= DI[5];
                        IRQ_OFF <= DI[7];
                    end
                    // 8'h38:  SCBR <= DI;    // 3038
                    8'h39 : CLS <= DI[0];   // 3039
                    default : ;
                    endcase
                end
            end else begin
                if (CPU_EN) begin
                    if (OP.OP == OP_STOP) begin
                        FLAG_GO <= 1'b0;
                        FLAG_IRQ <= 1'b1;
                        if (SYSCLKF_CE) begin
                        GSU_MEM_ACCESS <= 1'b0;
                        end
                    end else if (OP.OP == OP_LJMP) begin
                        PBR <= R[OP_N][7:0];
                    end
                end
            end 
            
            if (ENABLE && CLK_CE) begin
                if (GO) begin
                    FLAG_GO <= 1'b1;
                    GO <= 1'b0;
                    GO_CNT <= GO_CNT + 1;
                end
            end

            if (SYSCLKF_CE && ~FLAG_GO && GSU_MEM_ACCESS) 
                GSU_MEM_ACCESS <= 1'b0;
        end
    end
end

assign GSU_ROM_ACCESS = GSU_MEM_ACCESS & RON;
assign GSU_RAM_ACCESS = GSU_MEM_ACCESS & RAN;

assign SFR = {FLAG_IRQ, 1'b0, 1'b0, FLAG_B, 1'b0, 1'b0,
              FLAG_ALT2, FLAG_ALT1, 1'b0, FLAG_R, FLAG_GO,
              FLAG_OV, FLAG_S, FLAG_CY, FLAG_Z, 1'b0};

always @* begin
    DO = 8'h00;
    if (ROM_SEL) begin
        if (GSU_ROM_ACCESS == 1'b0) 
            DO = ROM_DI;
        else  if (ADDR[0]) 
            DO = 8'h01;
        else if (ADDR[3:0] == 4'hE) 
            DO = 8'h0C;
        else if (ADDR[3:0] == 4'hA) 
            DO = 8'h08;
        else if (ADDR[3:0] == 4'h4) 
            DO = 8'h04;
        else 
            DO = 8'h00;
    end else if (MMIO_REG_SEL) begin
        if (ADDR[0] == 1'b0) 
            DO = R[ADDR[4:1]][7:0];
        else 
            DO = R[ADDR[4:1]][15:8];
    end else if (MMIO_SEL) begin
        case (ADDR[7:0])
        8'h30 : DO = SFR[7:0];     // 3030 SFR
        8'h31 : DO = SFR[15:8];    // 3031 SFR
        8'h33 : DO = BRAMR;        // 3033 BRAMR
        8'h34 : DO = PBR;          // 3034 PBR
        8'h36 : DO = ROMBR;        // 3036 ROMBR
        8'h3B : DO = 8'h04;        // 303B VCR
        8'h3C : DO = RAMBR;        // 303C RAMBR
        8'h3E : DO = CBR[7:0];     // 303E CBR
        8'h3F : DO = CBR[15:8];    // 303F CBR
        default : ;
        endcase
    end else if (MMIO_CACHE_SEL) 
      DO = BRAM_CACHE_Q_B;
    else if (SRAM_SEL) 
      DO = RAM_DI;
end

assign IRQ_N =  ~FLAG_IRQ | IRQ_OFF;

//CPU Core
assign CODE_IN_ROM = PBR <= 8'h5F ? 1'b1 : 1'b0;
assign CODE_IN_RAM = PBR[7:1] == 7'b0111000 ? 1'b1 : 1'b0;
assign IN_CACHE = CACHE_POS[15:9] == 7'b0000000 ? 1'b1 : 1'b0;
assign VAL_CACHE = CACHE_VALID[CACHE_POS[8:4]];

assign SPEED = CLS;

reg CLKREF_r;
always @(posedge CLK) begin
    CLKREF_r <= CLKREF;
    if (~RST_N) begin
        CLK_CE <= 1'b0;
    end else begin
        if (ENABLE) 
            CLK_CE <= (CLKREF && ~CLKREF_r ? 1'b1 : ~CLK_CE) | SPEED | TURBO;
    end
end

// GSU uses both positive and negative edges because of high frequency (10.7Mhz) 
// of original design
always @(negedge CLK) begin
    EN <= ENABLE & FLAG_GO & CLK_CE;
end

assign CPU_EN = EN &  ~ROM_LOAD_WAIT &  ~ROM_FETCH_WAIT &  ~ROM_CACHE_WAIT &  
                ~RAM_LOAD_WAIT &  ~RAM_SAVE_WAIT &  ~RAM_FETCH_WAIT &  
                ~RAM_CACHE_WAIT &  ~RAM_PCF_WAIT &  ~MULT_WAIT;

always @(posedge CLK) begin
    if (~RST_N) begin
        OPCODE <= 8'h01;
        OPDATA <= {8{1'b0}};
    end else begin
        if (CPU_EN) begin
            if (OP.OP == OP_STOP)
                OPCODE <= 8'h01;
            else if (IN_CACHE) begin
                if (MC.LAST_CYCLE) 
                    OPCODE <= BRAM_CACHE_Q_A;
                else 
                    OPDATA <= BRAM_CACHE_Q_A;
            end else if (ROM_FETCH_EN) begin
                if (MC.LAST_CYCLE) 
                    OPCODE <= /* ROM_BUF */ ROM_DI;  
                else 
                    OPDATA <= /* ROM_BUF */ ROM_DI;
            end else if (RAM_FETCH_EN) begin
                if (MC.LAST_CYCLE) 
                    OPCODE <= RAM_DI; //RAM_BUF;
                else 
                    OPDATA <= RAM_DI; // RAM_BUF;
            end
        end
    end
end

//CPU Code cache
assign CACHE_POS = (R[15]) - (CBR);
assign SNES_CACHE_ADDR = { ~ADDR[8],ADDR[7:0]};

always @(posedge CLK) begin
    if (~RST_N) begin
        CACHE_RUN <= 1'b0;
        CACHE_VALID <= {32{1'b0}};
        CACHE_DST_ADDR <= {9{1'b0}};
        CACHE_SRC_ADDR <= {24{1'b0}};
        CBR <= {16{1'b0}};
    end else begin
        if (ENABLE) begin 
            if (MMIO_WR && ADDR[7:0] == 8'h30) begin    //SFR
                
                if (FLAG_GO && DI[5] == 1'b0) begin
                    CBR <= {16{1'b0}};
                    CACHE_VALID <= {32{1'b0}};
                end
            end

            if (~EN) begin
                if (MMIO_WR && ADDR[7:0] == 8'h34)      //PBR
                    CACHE_VALID <= {32{1'b0}};
                else if (MMIO_CACHE_WR && ADDR[3:0] == 4'hF) 
                    CACHE_VALID[SNES_CACHE_ADDR[8:4]] <= 1'b1;
            end else begin
                if (IN_CACHE && ~VAL_CACHE && ~CACHE_RUN) begin
                    CACHE_RUN <= 1'b1;
                    CACHE_DST_ADDR <= {CACHE_POS[8:4],4'h0};
                    CACHE_SRC_ADDR <= {PBR, 16'h0000} + 24'({CBR[15:4] + CACHE_POS[15:4], 4'h0});
                end

                if (CPU_EN) begin
                    if ((OP.OP == OP_CACHE && CBR[15:4] != R[15][15:4])) begin
                        CBR <= {R[15][15:4],4'h0};
                        CACHE_VALID <= {32{1'b0}};
                    end else if (OP.OP == OP_LJMP) begin
                        CBR <= {R[SREG][15:4],4'h0};
                        CACHE_VALID <= {32{1'b0}};
                    end
                end else if (CACHE_RUN) begin
                    if (ROM_CACHE_EN || RAM_CACHE_EN) begin
                        CACHE_SRC_ADDR <= (CACHE_SRC_ADDR) + 1;
                        CACHE_DST_ADDR <= CACHE_DST_ADDR + 1;
                        if (CACHE_DST_ADDR[3:0] == 15) begin
                            CACHE_VALID[CACHE_DST_ADDR[8:4]] <= 1'b1;
                            CACHE_RUN <= 1'b0;
                        end
                    end
                end
            end
        end
    end
end

  // XXX  512-byte dual-port ram as cache
  // CACHE : entity work.dpram_difclk generic map(9, 8, 9, 8)
  // port map(
  // 	clock0		=> not CLK,
  // 	address_a	=> BRAM_CACHE_ADDR_A,
  // 	data_a		=> BRAM_CACHE_DI_A,
  // 	wren_a		=> BRAM_CACHE_WE_A,
  // 	q_a			=> BRAM_CACHE_Q_A,
  // 	clock1		=> CLK,
  // 	address_b	=> BRAM_CACHE_ADDR_B,
  // 	data_b		=> BRAM_CACHE_DI_B,
  // 	wren_b		=> BRAM_CACHE_WE_B,
  // 	q_b			=> BRAM_CACHE_Q_B
  // );
reg [7:0] cache [512];

always @(negedge CLK) begin
    if (BRAM_CACHE_WE_A)
        cache[BRAM_CACHE_ADDR_A] <= BRAM_CACHE_DI_A;
    else
        BRAM_CACHE_Q_A <= cache[BRAM_CACHE_ADDR_A];
end

always @(posedge CLK) begin
    if (BRAM_CACHE_WE_B)
        cache[BRAM_CACHE_ADDR_B] <= BRAM_CACHE_DI_B;
    else
        BRAM_CACHE_Q_B <= cache[BRAM_CACHE_ADDR_B];
end

assign BRAM_CACHE_ADDR_A = CACHE_POS[8:0];
assign BRAM_CACHE_DI_A = 8'h00;
assign BRAM_CACHE_WE_A = 1'b0;

assign BRAM_CACHE_ADDR_B = FLAG_GO ? CACHE_DST_ADDR : SNES_CACHE_ADDR;
assign BRAM_CACHE_DI_B = FLAG_GO && CODE_IN_ROM ? /* ROM_BUF */ ROM_DI : 
                         FLAG_GO && CODE_IN_RAM ? /* RAM_BUF */ RAM_DI : 
                         DI;
assign BRAM_CACHE_WE_B = FLAG_GO ? ROM_CACHE_EN | RAM_CACHE_EN : MMIO_CACHE_WR;

//CPU Opcode logic
assign OPS = OP_TBL[OPCODE];
assign OP = FLAG_B && OPS.OP.OP == OP_FROM ? '{OP_MOVES, 5} :
            FLAG_B && OPS.OP.OP == OP_TO ? '{OP_MOVE,  4} :
            FLAG_ALT1 && FLAG_ALT2 ? OPS.OP_ALT3 :
            ~FLAG_ALT1 && FLAG_ALT2 ? OPS.OP_ALT2 :
            FLAG_ALT1 && ~FLAG_ALT2 ? OPS.OP_ALT1 :
            OPS.OP;
assign MC = MC_TBL[OP.MC][STATE];

always @(posedge CLK) begin
    if (~RST_N) 
        STATE <= 0; 
    else begin
        if (CPU_EN) begin
            if (MC.LAST_CYCLE == 1'b0) 
                STATE <= STATE + 1;
        else 
            STATE <= 0;
        end
    end
end

assign OP_N = OPCODE[3:0];
assign DST_REG = MC.DREG[2] == 1'b0 ? DREG : OP_N;
always @(posedge CLK) begin
    if (~RST_N) begin
        FLAG_B <= 1'b0;
        FLAG_ALT1 <= 1'b0;
        FLAG_ALT2 <= 1'b0;
        DREG <= 0;
        SREG <= 0;
    end else begin
        if (CPU_EN) begin   
            if (OP.OP == OP_TO) 
                DREG <= OP_N;
            else if (OP.OP == OP_FROM) 
                SREG <= OP_N;
            else if (OP.OP == OP_WITH) begin
                FLAG_B <= 1'b1;
                DREG <= OP_N;
                SREG <= OP_N;
            end else if (OP.OP == OP_ALT1) 
                FLAG_ALT1 <= 1'b1;
            else if (OP.OP == OP_ALT2) 
                FLAG_ALT2 <= 1'b1;
            else if (OP.OP == OP_ALT3) begin
                FLAG_ALT1 <= 1'b1;
                FLAG_ALT2 <= 1'b1;
            end else if (OP.OP != OP_BRA && MC.LAST_CYCLE) begin
                FLAG_B <= 1'b0;
                FLAG_ALT1 <= 1'b0;
                FLAG_ALT2 <= 1'b0;
                DREG <= 0;
                SREG <= 0;
            end
        end
    end
end

//ALU
always @* begin
    reg [15:0] A, B;
    reg [16:0] TEMP;
    reg [31:0] MUL_TEMP;

    A = R[SREG];
    TEMP = {17{1'bX}};
    MUL_TEMP = {32{1'bX}};
    if (FLAG_ALT2 && (OP.OP == OP_ADD || OP.OP == OP_SUB || OP.OP == OP_AND || OP.OP == OP_MULT 
        || OP.OP == OP_UMULT || OP.OP == OP_OR || OP.OP == OP_XOR)) 
        B = {12'h000,OP_N};
    else 
        B = R[OP_N];
    ALUR = 0;
    MULR = 0;
    ALUOV = FLAG_OV;
    ALUCY = FLAG_CY;
    if (OP.OP == OP_SWAP) 
        ALUR = {A[7:0],A[15:8]};
    else if (OP.OP == OP_NOT) 
        ALUR =  ~A;
    else if (OP.OP == OP_ADD) begin
        TEMP = {1'b0, A} + {1'b0, B} + {16'b0, FLAG_ALT1 & FLAG_CY};
        ALUR = TEMP[15:0];
        ALUOV = (A[15] ^ TEMP[15]) & (B[15] ^ TEMP[15]);
        ALUCY = TEMP[16];
    end else if (OP.OP == OP_SUB) begin
        TEMP = {1'b0, A} - {1'b0, B} - {16'b0, FLAG_ALT1 & ~FLAG_CY};
        ALUR = TEMP[15:0];
        ALUOV = (A[15] ^ B[15]) & (A[15] ^ TEMP[15]);
        ALUCY =  ~TEMP[16];
    end else if (OP.OP == OP_CMP) begin
        TEMP = ({1'b0, A}) - ({1'b0, B});
        ALUR = TEMP[15:0];
        ALUOV = (A[15] ^ B[15]) & (A[15] ^ TEMP[15]);
        ALUCY =  ~TEMP[16];
    end else if (OP.OP == OP_LSR) begin
        ALUR = {1'b0,A[15:1]};
        ALUCY = A[0];
    end else if (OP.OP == OP_ASR || OP.OP == OP_DIV2) begin
        if (OP.OP == OP_DIV2 && A == 16'hFFFF) 
            ALUR = 0;
        else 
            ALUR = {A[15], A[15:1]};
        ALUCY = A[0];
    end else if (OP.OP == OP_ROL) begin
        ALUR = {A[14:0], FLAG_CY};
        ALUCY = A[15];
    end else if (OP.OP == OP_ROR) begin
        ALUR = {FLAG_CY, A[15:1]};
        ALUCY = A[0];
    end else if (OP.OP == OP_AND) 
        ALUR = A & (B ^ {16{FLAG_ALT1}});
    else if (OP.OP == OP_OR) 
        ALUR = A | B;
    else if (OP.OP == OP_XOR) 
        ALUR = A ^ B;
    else if (OP.OP == OP_INC) 
        ALUR = B + 1;
    else if (OP.OP == OP_DEC || OP.OP == OP_LOOP) 
        ALUR = B - 1;
    else if (OP.OP == OP_MULT) 
        ALUR = A[7:0] * B[7:0];
    else if (OP.OP == OP_UMULT) 
        ALUR = A[7:0] * B[7:0];
    else if (OP.OP == OP_FMULT || OP.OP == OP_LMULT) begin
        MUL_TEMP = A * R[6];
        ALUR = MUL_TEMP[31:16];
        MULR = MUL_TEMP[15:0];
        ALUCY = MUL_TEMP[15];
    end else if (OP.OP == OP_SEX) 
        ALUR = {{8{A[7]}}, A[7:0]};
    else if (OP.OP == OP_MERGE) begin
        ALUR = {R[7][15:8], R[8][15:8]};
        ALUCY = R[7][15] | R[7][14] | R[7][13] | R[8][15] | R[8][14] | R[8][13];
        ALUOV = R[7][15] | R[7][14] | R[8][15] | R[8][14];
    end else if (OP.OP == OP_LOB) 
        ALUR = {8'h00,A[7:0]};
    else if (OP.OP == OP_HIB)
        ALUR = {8'h00,A[15:8]};
    else if (OP.OP == OP_MOVES) begin
        ALUR = B;
        ALUOV = B[7];
    end else if (OP.OP == OP_RPIX) 
          ALUR = {8'h00,RPIX_DATA};

    if (OP.OP == OP_MERGE) 
        ALUZ = R[7][15] | R[7][14] | R[7][13] | R[7][12] | R[8][15] 
                | R[8][14] | R[8][13] | R[8][12];
    else if (ALUR == 16'h0000) 
        ALUZ = 1'b1;
    else 
        ALUZ = 1'b0;

    if (OP.OP == OP_MERGE) 
        ALUS = R[7][15] | R[8][15];
    else if (OP.OP == OP_LOB || OP.OP == OP_HIB) 
        ALUS = ALUR[7];
    else 
        ALUS = ALUR[15];
end

always @(posedge CLK) begin
    if (~RST_N) begin
        FLAG_Z <= 1'b0;
        FLAG_S <= 1'b0;
        FLAG_CY <= 1'b0;
        FLAG_OV <= 1'b0;
    end else begin
        if (CPU_EN && MC.FSET) begin
            FLAG_Z <= ALUZ;
            FLAG_S <= ALUS;
            FLAG_CY <= ALUCY;
            FLAG_OV <= ALUOV;
        end else if (MMIO_WR && ADDR[7:0] == 8'h30) begin   //SFR LSB
            FLAG_Z <= DI[1];
            FLAG_S <= DI[3];
            FLAG_CY <= DI[2];
            FLAG_OV <= DI[4];
        end
    end
end

//Registers
always @(posedge CLK) begin : P4
    reg COND;

    if (~RST_N) begin
//        R <= {16'{16'b0}};
        RAMBR <= 0;
        ROMBR <= 0;
        REG_LSB <= 0;
    end else begin
        if (~EN) begin
            if (MMIO_REG_WR) begin
                if (~ADDR[0]) 
                    REG_LSB <= DI;
                else 
                    R[ADDR[4:1]] <= {DI,REG_LSB};
            end
        end else if (CPU_EN) begin
            if (MC.INCPC) 
                R[15] <= (R[15]) + 1;
            
            if (OP.OP == OP_LMULT && MC.DREG[1:0] != 2'b00 && MC.FSET) 
                R[4] <= MULR;

            if (OP.OP == OP_BRA) begin
                case (OP_N)
                4'h5 : COND = 1'b1;                 //BRA
                4'h6 : COND =  ~(FLAG_S ^ FLAG_OV); //BGE
                4'h7 : COND = FLAG_S ^ FLAG_OV;     //BLT
                4'h8 : COND =  ~FLAG_Z;             //BNE
                4'h9 : COND = FLAG_Z;               //BEQ
                4'hA : COND =  ~FLAG_S;             //BPL
                4'hB : COND = FLAG_S;               //BMI
                4'hC : COND =  ~FLAG_CY;            //BCC
                4'hD : COND = FLAG_CY;              //BCS
                4'hE :  COND =  ~FLAG_OV;           //BVC
                4'hF : COND = FLAG_OV;              //BVS
                default : COND = 1'b0;
                endcase
                if (STATE == 1 && COND) 
                    R[15] <= R[15] + { {8{OPDATA[7]}}, OPDATA};
            end else if (OP.OP == OP_JMP) 
                R[15] <= R[OP_N];
            else if (OP.OP == OP_LJMP) 
                R[15] <= R[SREG];
            else if (OP.OP == OP_LOOP) begin
                R[12] <= ALUR;  
                if (ALUZ == 1'b0) 
                    R[15] <= R[13];
            end else if (OP.OP == OP_LINK) 
                R[11] <= R[15] + 16'(OP_N);
            else if (OP.OP == OP_PLOT) 
                R[1] <= R[1] + 1;
            else if (OP.OP == OP_RAMB) 
                RAMBR <= R[SREG][7:0] & 8'h01;
            else if (OP.OP == OP_ROMB) 
                ROMBR <= R[SREG][7:0] & 8'h7F;
            else if (MC.DREG[1:0] != 2'b00) begin
                if (MC.FSET) 
                    R[DST_REG] <= ALUR;
                else begin
                    case (OP.OP)
                    OP_LDB,OP_LDW,OP_LM,OP_LMS : begin
                        if (MC.RAMLD != 2'b00) 
                            R[DST_REG] <= RAM_LOAD_BUF;
                    end
                    OP_GETB : 
                        R[DST_REG] <= {8'h00,ROMDR};
                    OP_GETBL : 
                        R[DST_REG] <= {R[SREG][15:8],ROMDR};
                    OP_GETBH : 
                        R[DST_REG] <= {ROMDR,R[SREG][7:0]};
                    OP_GETBS : 
                        R[DST_REG] <= {{8{ROMDR[7]}}, ROMDR};
                    OP_MOVE : 
                        R[DST_REG] <= R[SREG];
                    OP_IBT : 
                        R[DST_REG] <= {{8{OPDATA[7]}}, OPDATA};
                    OP_IWT : begin
                        if (MC.DREG[0]) 
                            REG_LSB <= OPDATA;
                        else if (MC.DREG[1]) 
                            R[DST_REG] <= {OPDATA,REG_LSB};
                    end
                    OP_INC,OP_DEC : 
                        R[DST_REG] <= ALUR;
                    default : ;
                    endcase
                end
            end
        end
    end
end

reg LMULT;

// Falling edge
always @(negedge CLK) begin 
    if (~RST_N) begin
        MULT_WAIT <= 1'b0;
    end else if (EN) begin
        if (CPU_EN) begin
            if ((OP.OP == OP_MULT || OP.OP == OP_UMULT) && MC.LAST_CYCLE) begin
                MULT_WAIT <=  ~(MS0 | TURBO);
                LMULT = 1'b0;
            end
            else if ((OP.OP == OP_FMULT || OP.OP == OP_LMULT) && MC.LAST_CYCLE) begin
                MULT_WAIT <=  ~(TURBO);
                LMULT = 1'b1;
            end
            end
            if (MULTST == MULTST_EXEC && MULT_ACCESS_CNT == 0) begin
            MULT_WAIT <= 1'b0;
        end
    end
end

// Rising edge
always @(posedge CLK) begin
    if (~RST_N) begin
        MULT_ACCESS_CNT <= 3'b010;
        MULTST <= MULTST_IDLE;
    end else if (EN) begin
        case (MULTST)
        MULTST_IDLE : begin
            if (MULT_WAIT) begin
                if (LMULT) begin
                    if (MS0 == 1'b0) 
                        MULT_ACCESS_CNT <= 3'b100;
                    else 
                        MULT_ACCESS_CNT <= 3'b000;
                end else 
                    MULT_ACCESS_CNT <= 3'b000;
                MULTST <= MULTST_EXEC;
            end
        end
        MULTST_EXEC : begin
            MULT_ACCESS_CNT <= MULT_ACCESS_CNT - 1;
            if (MULT_ACCESS_CNT == 0) 
                MULTST <= MULTST_IDLE;
        end
        default : ;
        endcase
    end
end

//Memory buses
//ROM
assign R14_CHANGE = DST_REG == 14 && (MC.DREG[1] || MC.DREG[0]) && MC.LAST_CYCLE ? 1'b1 : 1'b0;
reg ROM_LOAD_START;
reg ROM_FETCH_START;
reg ROM_LOAD_END;
reg ROM_FETCH_END;
reg R14_CHANGE_LATCH;
reg [2:0] ROM_CYCLES;

always @(negedge CLK) begin
    if (~RST_N) begin
        ROM_LOAD_PEND <= 1'b0;
        ROM_LOAD_WAIT <= 1'b0;
        ROM_FETCH_PEND <= 1'b0;
        ROM_FETCH_WAIT <= 1'b0;
        ROM_CACHE_WAIT <= 1'b0;
        ROM_FETCH_EN <= 1'b0;
        ROM_CACHE_EN <= 1'b0;
    end else begin
        if (GO) begin
            ROM_FETCH_WAIT <= 1'b0;
            ROM_CACHE_WAIT <= 1'b0;
            if (~IN_CACHE && CODE_IN_ROM) begin
                ROM_FETCH_PEND <= 1'b1;
                ROM_FETCH_WAIT <= 1'b1;
            end else if (IN_CACHE && ~VAL_CACHE && CODE_IN_ROM) 
                ROM_CACHE_WAIT <= 1'b1;
            ROM_FETCH_EN <= 1'b0;
            ROM_CACHE_EN <= 1'b0;
        end

        if (EN) begin
            if (ROM_LOAD_START) 
                ROM_LOAD_PEND <= 1'b0;
            if (CPU_EN && R14_CHANGE_LATCH) 
                ROM_LOAD_PEND <= 1'b1;
            if (ROM_LOAD_END && ROM_LOAD_WAIT) 
                ROM_LOAD_WAIT <= 1'b0;
            if ((R14_CHANGE || MC.ROMWAIT) && (R14_CHANGE_LATCH || ROMST == ROMST_LOAD) && ROM_LOAD_WAIT == 1'b0) 
                ROM_LOAD_WAIT <= 1'b1;
            if (CPU_EN) 
                ROM_FETCH_EN <= 1'b0;
            if (ROM_FETCH_START) 
                ROM_FETCH_PEND <= 1'b0;
            if (ROM_FETCH_END) begin
                ROM_FETCH_WAIT <= 1'b0;
                ROM_FETCH_EN <= 1'b1;
            end
            if (CPU_EN && MC.INCPC && IN_CACHE == 1'b0 && CODE_IN_ROM) begin
                ROM_FETCH_PEND <= 1'b1;
                ROM_FETCH_WAIT <= 1'b1;
            end

            ROM_CACHE_EN <= 1'b0;
            if (ROMST == ROMST_CACHE_DONE) 
                ROM_CACHE_EN <= 1'b1;
            if (ROMST == ROMST_CACHE_END) 
                ROM_CACHE_WAIT <= 1'b0;
            if (IN_CACHE && VAL_CACHE == 1'b0 && CODE_IN_ROM) 
                ROM_CACHE_WAIT <= 1'b1;
        end
    end
end

always @(posedge CLK) begin
    if (~RST_N) begin
        ROMDR <= {8{1'b0}};
        ROM_ACCESS_CNT <= 3'b010;
        ROM_LOAD_START <= 1'b0;
        ROM_FETCH_START <= 1'b0;
        ROM_LOAD_END <= 1'b0;        
        R14_CHANGE_LATCH <= 1'b0;
        ROMST <= ROMST_IDLE;
        FLAG_R <= 1'b0;
    end else begin
        if (GO == 1'b1) begin
            ROM_LOAD_START <= 1'b0;
            ROM_FETCH_START <= 1'b0;
            ROM_LOAD_END <= 1'b0;
            ROM_FETCH_END <= 1'b0;
        end
      //			GSU_ROM_RD <= '0';
        if (EN) begin
            if (TURBO) 
                ROM_CYCLES <= 3'b010;
            else if (SPEED == 1'b0) 
                ROM_CYCLES <= 3'b001;
            else 
                ROM_CYCLES <= 3'b011;

            R14_CHANGE_LATCH <= 1'b0;
            if (CPU_EN && R14_CHANGE) 
                R14_CHANGE_LATCH <= 1'b1;

            ROM_LOAD_START <= 1'b0;
            ROM_FETCH_START <= 1'b0;
            ROM_LOAD_END <= 1'b0;
            ROM_FETCH_END <= 1'b0;

            case (ROMST)
            ROMST_IDLE : 
                if (ROM_LOAD_PEND) begin
                    FLAG_R <= 1'b1;
                    ROM_ACCESS_CNT <= ROM_CYCLES + 2;
                    ROM_LOAD_START <= 1'b1;
                    ROMST <= ROMST_LOAD;
                    // GSU_ROM_RD <= '1';
                end else if (ROM_FETCH_PEND) begin
                    ROM_ACCESS_CNT <= ROM_CYCLES - 1;
                    ROM_FETCH_START <= 1'b1;
                    ROMST <= ROMST_FETCH;
                    // GSU_ROM_RD <= '1';
                end else if (IN_CACHE && VAL_CACHE == 1'b0 && CODE_IN_ROM) begin
                    ROM_ACCESS_CNT <= ROM_CYCLES;
                    ROMST <= ROMST_CACHE;
                    // GSU_ROM_RD <= '1';
                end

            ROMST_LOAD : 
                if (RON) begin
                    ROM_ACCESS_CNT <= ROM_ACCESS_CNT - 1;
                    if (ROM_ACCESS_CNT == 0) begin
                    ROMDR <= ROM_DI;
                    FLAG_R <= 1'b0;
                    ROM_LOAD_END <= 1'b1;
                    ROMST <= ROMST_IDLE;
                    end
                end else 
                    ROM_ACCESS_CNT <= ROM_CYCLES + 1;
            
            ROMST_FETCH : 
                if (RON) begin
                    ROM_ACCESS_CNT <= ROM_ACCESS_CNT - 1;
                    if (ROM_ACCESS_CNT == 0) begin
                    ROM_BUF <= ROM_DI;
                    ROM_FETCH_END <= 1'b1;
                    ROMST <= ROMST_FETCH_DONE;
                    end
                end else 
                    ROM_ACCESS_CNT <= ROM_CYCLES;

            ROMST_FETCH_DONE : 
                ROMST <= ROMST_IDLE;

            ROMST_CACHE : 
                if (RON) begin
                    ROM_ACCESS_CNT <= ROM_ACCESS_CNT - 1;
                    if (ROM_ACCESS_CNT == 3'd0) begin
                        ROM_BUF <= ROM_DI;
                        ROMST <= ROMST_CACHE_DONE;
                    end
                end else 
                    ROM_ACCESS_CNT <= ROM_CYCLES;

            ROMST_CACHE_DONE : 
                if (CACHE_DST_ADDR[3:0] != 15) begin
                    // GSU_ROM_RD <= '1';
                    ROM_ACCESS_CNT <= ROM_CYCLES;
                    ROMST <= ROMST_CACHE;
                end else 
                    ROMST <= ROMST_CACHE_END;

            ROMST_CACHE_END : 
                ROMST <= ROMST_IDLE;

            default : ;
            endcase
        end
    end
end

always @(posedge CLK) begin
    if (~RST_N) begin
        ROM_RD_N <= 1'b1;
        ROM_RD_CNT <= 0;
    end else begin
        ROM_RD_N <= 1'b1;
        if (GSU_ROM_ACCESS == 1'b0) begin
            if (SYSCLKR_CE || SYSCLKF_CE) begin
                ROM_RD_N <= 1'b0;
                ROM_RD_CNT <= 0;
            end
        end else begin
            ROM_RD_CNT <= ROM_RD_CNT + 1;
            if (ROM_RD_CNT == 1) begin
                ROM_RD_CNT <= 0;
                ROM_RD_N <= 1'b0;
            end
        end
    end
end

assign INT_ROM_A =  ~GSU_ROM_ACCESS ? ADDR : 
                    ROMST == ROMST_CACHE ? CACHE_SRC_ADDR : 
                    ROMST == ROMST_LOAD ? {ROMBR,R[14]} : 
                    {PBR,R[15]};

assign ROM_A = INT_ROM_A[22] ? INT_ROM_A[20:0] : {INT_ROM_A[21:16],INT_ROM_A[14:0]};

//RAM
//Pixel cashe
assign PC_X = R[1][7:0];
assign PC_Y = R[2][7:0];
assign PC0_FULL = PIX_CACHE[0].VALID == 8'hFF;
assign PC0_EMPTY = PIX_CACHE[0].VALID == 8'h00;
assign PC0_OFFS_HIT = PIX_CACHE[0].OFFSET == {PC_Y, PC_X[7:3]};

always @(POR_TRANS, SCMR_MD, POR_FH, COLR) begin
    PLOT_EXEC <= 1'b0;
    if (POR_TRANS) 
        PLOT_EXEC <= 1'b1;
    else if (~SCMR_MD[1]) begin
        if ((COLR[3:0] != 4'b0000 && SCMR_MD[0]) || (COLR[1:0] != 2'b00 && ~SCMR_MD[0])) 
            PLOT_EXEC <= 1'b1;
    end else begin
        if ((COLR[7:0] != 8'b00000000 && ~POR_FH) || (COLR[3:0] != 4'b0000 && POR_FH)) 
            PLOT_EXEC <= 1'b1;
    end
end

reg RAM_SAVE_START;
reg RAM_LOAD_START;
reg RAM_PCF_START;
reg RAM_RPIX_START;
reg RAM_FETCH_START;
reg RAM_SAVE_END;
reg RAM_LOAD_END;
reg RAM_PCF_END;
reg RAM_FETCH_END;
reg RAM_CACHE_END;
reg RAM_LOAD_WORD;
reg RAM_STORE_WORD;
reg RAM_PCF_EXEC;
reg RAM_RPIX_EXEC;

always @(negedge CLK) begin : P1

    if (~RST_N) begin
        RAM_LOAD_PEND <= 1'b0;
        RAM_SAVE_PEND <= 1'b0;
        RAM_PCF_PEND <= 1'b0;
        RAM_RPIX_PEND <= 1'b0;
        RAM_FETCH_PEND <= 1'b0;
        RAM_LOAD_WAIT <= 1'b0;
        RAM_SAVE_WAIT <= 1'b0;
        RAM_PCF_WAIT <= 1'b0;
        RAM_FETCH_WAIT <= 1'b0;
        RAM_CACHE_WAIT <= 1'b0;

//        PIX_CACHE[0] <= '{8'{8'b0}, 13'b0, 8'b0};
//        PIX_CACHE[1] <= '{8'{8'b0}, 13'b0, 8'b0};
    end else begin
        if (GO) begin
            RAM_FETCH_WAIT <= 1'b0;
            RAM_CACHE_WAIT <= 1'b0;
            if (~IN_CACHE && CODE_IN_RAM) begin
                RAM_FETCH_PEND <= 1'b1;
                RAM_FETCH_WAIT <= 1'b1;
            end else if (IN_CACHE && ~VAL_CACHE && CODE_IN_RAM) 
                RAM_CACHE_WAIT <= 1'b1;
            RAM_FETCH_EN <= 1'b0;
            RAM_CACHE_EN <= 1'b0;
        end

        if (EN) begin
            if (RAM_SAVE_START) 
                RAM_SAVE_PEND <= 1'b0;
            else if (RAM_LOAD_START) 
                RAM_LOAD_PEND <= 1'b0;
            else if (RAM_PCF_START) 
                RAM_PCF_PEND <= 1'b0;
            else if (RAM_RPIX_START) 
                RAM_RPIX_PEND <= 1'b0;

            if (CPU_EN) begin
                if ((OP.OP == OP_LDB || OP.OP == OP_LDW || OP.OP == OP_LM || OP.OP == OP_LMS) && MC.LAST_CYCLE) begin
                    RAM_LOAD_PEND <= 1'b1;
                    RAM_LOAD_WAIT <= 1'b1;
                end else if ((OP.OP == OP_STB || OP.OP == OP_STW || OP.OP == OP_SM 
                        || OP.OP == OP_SMS || OP.OP == OP_SBK) && MC.LAST_CYCLE) begin
                    RAM_SAVE_PEND <= 1'b1;
                end else if (OP.OP == OP_RPIX && MC.LAST_CYCLE) begin
                    RAM_PCF_FULL <= 1'b0;
                    RAM_PCF_PEND <= 1'b1;
                    RAM_PCF_WAIT <= 1'b1;
                    RAM_RPIX_PEND <= 1'b1;
                end
            end

            if (MC.RAMWAIT && (RAM_SAVE_PEND || RAMST == RAMST_SAVE) && RAM_SAVE_WAIT == 1'b0) 
                RAM_SAVE_WAIT <= 1'b1;
            else if ((OP.OP == OP_STOP || (OP.OP == OP_RPIX && STATE == 0)) 
                    && (RAM_PCF_PEND || RAM_PCF_EXEC) && RAM_PCF_WAIT == 1'b0) 
                RAM_PCF_WAIT <= 1'b1;

            if ((PC0_OFFS_HIT == 1'b0 && PC0_EMPTY == 1'b0) || PC0_FULL) begin
                RAM_PCF_PEND <= 1'b1;
                if (RAM_PCF_EXEC) 
                    RAM_PCF_WAIT <= 1'b1;
                RAM_PCF_FULL <= PC0_FULL;
            end

            if (RAM_LOAD_END) 
                RAM_LOAD_WAIT <= 1'b0;
            if (RAM_SAVE_END) 
                RAM_SAVE_WAIT <= 1'b0;
            if (RAM_PCF_END) 
                RAM_PCF_WAIT <= 1'b0;

            if (CPU_EN) 
                RAM_FETCH_EN <= 1'b0;
            if (RAM_FETCH_START) 
                RAM_FETCH_PEND <= 1'b0;
            if (RAM_FETCH_END) begin
                RAM_FETCH_WAIT <= 1'b0;
                RAM_FETCH_EN <= 1'b1;
            end
            if (CPU_EN && MC.INCPC && ~IN_CACHE && CODE_IN_RAM) begin
                RAM_FETCH_PEND <= 1'b1;
                RAM_FETCH_WAIT <= 1'b1;
            end

            RAM_CACHE_EN <= 1'b0;
            if (RAM_CACHE_END) 
                RAM_CACHE_EN <= 1'b1;
            else if (RAMST == RAMST_CACHE_END) 
                RAM_CACHE_WAIT <= 1'b0;
            if (IN_CACHE && VAL_CACHE == 1'b0 && CODE_IN_RAM) 
                RAM_CACHE_WAIT <= 1'b1;
        end
    end
end

always @(posedge CLK) begin
    reg [2:0] RAM_CYCLES;
    reg [7:0] NEW_COLOR;
    reg [7:0] COL_DITH;
    reg RAM_STORE_WORD_t, RAM_LOAD_WORD_t;

    RAM_STORE_WORD_t = RAM_STORE_WORD;
    RAM_LOAD_WORD_t = RAM_LOAD_WORD;

    if (~RST_N) begin
        RAM_WORD <= 1'b0;
        RAM_BYTES <= 1'b0;

        RAMADDR <= {16{1'b0}};
        RAMDR <= {16{1'b0}};
        RAM_SAVE_START = 1'b0;
        RAM_LOAD_START = 1'b0;
        RAM_PCF_START = 1'b0;
        RAM_RPIX_START = 1'b0;
        RAM_FETCH_START = 1'b0;
        RAM_SAVE_END = 1'b0;
        RAM_LOAD_END = 1'b0;
        RAM_PCF_END = 1'b0;
        RAM_PCF_EXEC = 1'b0;
        RAM_RPIX_EXEC = 1'b0;

        COLR <= {8{1'b0}};
        POR_TRANS <= 1'b0;
        POR_DITH <= 1'b0;
        POR_HN <= 1'b0;
        POR_FH <= 1'b0;
        POR_OBJ <= 1'b0;
        RAMST <= RAMST_IDLE;
        RAM_ACCESS_CNT <= 3'b001;
        PCF_RW <= 1'b0;
        PCF_RD_DATA <= 0;
        RPIX_DATA <= 0;
        BPP_CNT <= 0;
    end else begin
        if (GO) begin
            RAM_SAVE_START = 1'b0;
            RAM_LOAD_START = 1'b0;
            RAM_PCF_START = 1'b0;
            RAM_RPIX_START = 1'b0;
            RAM_FETCH_START = 1'b0;
            RAM_SAVE_END = 1'b0;
            RAM_LOAD_END = 1'b0;
            RAM_PCF_END = 1'b0;
            RAM_FETCH_END = 1'b0;
            RAM_CACHE_END = 1'b0;
        end

        if (EN) begin
            if (TURBO) 
                RAM_CYCLES = 3'b001;
            // else if (SPEED) 
            else if (~SPEED)                 // nand2mario: when clock speed is slow (SPEED=0), RAM latency is only one cycle
                RAM_CYCLES = 3'b001;            
            else 
                RAM_CYCLES = 3'b011;

            if (((~PC0_OFFS_HIT && ~PC0_EMPTY) || PC0_FULL) && ~RAM_PCF_WAIT) begin
                PIX_CACHE[1] <= PIX_CACHE[0];
                PIX_CACHE[0].OFFSET <= {PC_Y, PC_X[7:3]};
                PIX_CACHE[0].VALID <= 0;
            end

            if (CPU_EN) begin
                if (MC.RAMADDR != 3'b000) begin
                    if (MC.RAMADDR == 3'b001) 
                        RAMADDR[7:0] <= OPDATA;
                    else if (MC.RAMADDR == 3'b010) 
                        RAMADDR[15:8] <= OPDATA;
                    else if (MC.RAMADDR == 3'b011) 
                        RAMADDR <= R[OP_N];
                    else if (MC.RAMADDR == 3'b100) 
                        RAMADDR <= {7'b0, OPDATA, 1'b0};

                    if (MC.RAMST[1:0] != 2'b00) begin
                        if (MC.RAMST[2] == 1'b0) 
                            RAMDR <= R[SREG];
                        else 
                            RAMDR <= R[OP_N];
                    end
                    RAM_LOAD_WORD_t = MC.RAMLD[1];
                    RAM_STORE_WORD_t = MC.RAMST[1];
                end else if (OP.OP == OP_CMODE) begin
                    POR_TRANS <= R[SREG][0];
                    POR_DITH <= R[SREG][1];
                    POR_HN <= R[SREG][2];
                    POR_FH <= R[SREG][3];
                    POR_OBJ <= R[SREG][4];
                end else if (OP.OP == OP_COLOR || OP.OP == OP_GETC) begin
                    if (OP.OP == OP_GETC) 
                        NEW_COLOR = ROMDR;
                    else 
                        NEW_COLOR = R[SREG][7:0];
                    if (POR_HN) 
                        COLR[3:0] <= NEW_COLOR[7:4];
                    else 
                        COLR[3:0] <= NEW_COLOR[3:0];
                    if (~POR_FH) 
                        COLR[7:4] <= NEW_COLOR[7:4];
                end else if (OP.OP == OP_PLOT) begin
                    reg [5:0] not_pc_x;
                    if (POR_DITH && SCMR_MD != 2'b11) begin
                        if ((R[1][0] ^ R[2][0])) 
                            COL_DITH = {4'b0000,COLR[7:4]};
                        else 
                            COL_DITH = {4'b0000,COLR[3:0]};
                    end else 
                        COL_DITH = COLR;
                    not_pc_x = {~PC_X[2:0], 3'b0};      // array slicing
                    PIX_CACHE[0].DATA[not_pc_x +: 8] <= COL_DITH;
                    PIX_CACHE[0].OFFSET <= {PC_Y, PC_X[7:3]};
                    PIX_CACHE[0].VALID[~PC_X[2:0]] <= PLOT_EXEC;
                end else if (OP.OP == OP_RPIX && STATE == 0) begin
                    PIX_CACHE[1] <= PIX_CACHE[0];
                    PIX_CACHE[0].OFFSET <= {PC_Y, PC_X[7:3]};
                    PIX_CACHE[0].VALID <= 0;
                end
            end

            RAM_SAVE_START = 1'b0;
            RAM_LOAD_START = 1'b0;
            RAM_PCF_START = 1'b0;
            RAM_RPIX_START = 1'b0;
            RAM_FETCH_START = 1'b0;
            RAM_SAVE_END = 1'b0;
            RAM_LOAD_END = 1'b0;
            RAM_PCF_END = 1'b0;
            RAM_FETCH_END = 1'b0;
            RAM_CACHE_END = 1'b0;
            case (RAMST)
            RAMST_IDLE : begin
                if (RAM_SAVE_PEND) begin
                    RAM_WORD <= RAM_STORE_WORD_t;
                    RAM_BYTES <= 1'b0;
                    RAM_ACCESS_CNT <= RAM_CYCLES;
                    RAM_SAVE_START = 1'b1;
                    RAMST <= RAMST_SAVE;
                end else if (RAM_LOAD_PEND) begin
                    RAM_WORD <= RAM_LOAD_WORD_t;
                    RAM_BYTES <= 1'b0;
                    RAM_LOAD_BUF <= 0;
                    RAM_ACCESS_CNT <= RAM_CYCLES;
                    RAM_LOAD_START = 1'b1;
                    RAMST <= RAMST_LOAD;
                end else if (IN_CACHE && ~VAL_CACHE && CODE_IN_RAM) begin
                    RAM_ACCESS_CNT <= RAM_CYCLES;
                    RAMST <= RAMST_CACHE;
                end else if (RAM_PCF_EXEC) begin
                    RAM_ACCESS_CNT <= RAM_CYCLES;
                    RAMST <= RAMST_PCF;
                end else if (RAM_RPIX_EXEC) begin
                    RAM_ACCESS_CNT <= RAM_CYCLES;
                    RAMST <= RAMST_RPIX;
                end else if (RAM_PCF_PEND) begin
                    RAM_ACCESS_CNT <= RAM_CYCLES;
                    RAM_PCF_START = 1'b1;
                    RAM_PCF_EXEC = 1'b1;
                    PCF_RW <= RAM_PCF_FULL;
                    PCF_WO <= RAM_PCF_FULL;
                    RPIX_DATA <= 0;
                    RAMST <= RAMST_PCF;
                end else if (RAM_RPIX_PEND) begin
                    RAM_RPIX_START = 1'b1;
                    RAM_RPIX_EXEC = 1'b1;
                    RAM_ACCESS_CNT <= RAM_CYCLES;
                    RAMST <= RAMST_RPIX;
                end else if (RAM_FETCH_PEND) begin
                    RAM_ACCESS_CNT <= RAM_CYCLES - 1;
                    RAM_FETCH_START = 1'b1;
                    RAMST <= RAMST_FETCH;
                end
            end

            RAMST_LOAD : begin
                if (RAN) begin
                    RAM_ACCESS_CNT <= RAM_ACCESS_CNT - 1;
                    if (RAM_ACCESS_CNT == 0) begin
                        RAM_ACCESS_CNT <= RAM_CYCLES;
                        RAM_BYTES <= 1'b1;
                        if (~RAM_BYTES) 
                            RAM_LOAD_BUF[7:0] <= RAM_DI;
                        else 
                            RAM_LOAD_BUF[15:8] <= RAM_DI;
                        if (RAM_BYTES == RAM_WORD) begin
                            RAM_LOAD_END = 1'b1;
                            RAMST <= RAMST_IDLE;
                        end
                    end
                end else 
                    RAM_ACCESS_CNT <= RAM_CYCLES;
            end

            RAMST_SAVE : begin
                if (RAN) begin
                    RAM_ACCESS_CNT <= RAM_ACCESS_CNT - 1;
                    if (RAM_ACCESS_CNT == 0) begin
                        RAM_ACCESS_CNT <= RAM_CYCLES;
                        RAM_BYTES <= 1'b1;
                        if (RAM_BYTES == RAM_WORD) begin
                            RAM_SAVE_END = 1'b1;
                            RAMST <= RAMST_IDLE;
                        end
                    end
                end else 
                    RAM_ACCESS_CNT <= RAM_CYCLES;
            end

            RAMST_PCF : begin
                if (RAN) begin
                    RAM_ACCESS_CNT <= RAM_ACCESS_CNT - 1;
                    if (RAM_ACCESS_CNT == 0) begin
                        PCF_RW <= ~PCF_RW | PCF_WO;
                        RAMST <= RAMST_IDLE;
                        if (~PCF_RW && ~PCF_WO) 
                            PCF_RD_DATA <= RAM_DI;
                        else begin
                            BPP_CNT <= BPP_CNT + 1;
                            if (BPP_CNT == GetLastBPP(SCMR_MD)) begin
                                BPP_CNT <= {3{1'b0}};
                                PIX_CACHE[1].VALID <= 0;
                                RAMST <= RAMST_PCF_END;
                            end
                        end
                    end
                end else 
                    RAM_ACCESS_CNT <= RAM_CYCLES;
            end
            
            RAMST_PCF_END : begin
                RAM_PCF_EXEC = 1'b0;
                if (~RAM_RPIX_PEND) 
                    RAM_PCF_END = 1'b1;
                RAMST <= RAMST_IDLE;
            end

            RAMST_RPIX : begin
                if (RAN) begin
                    RAM_ACCESS_CNT <= RAM_ACCESS_CNT - 1;
                    if (RAM_ACCESS_CNT == 0) begin
                        RPIX_DATA[BPP_CNT] <= RAM_DI[~PC_X[2:0]];
                        BPP_CNT <= BPP_CNT + 1;
                        if (BPP_CNT == GetLastBPP(SCMR_MD)) begin
                            BPP_CNT <= 0;
                            RAM_RPIX_EXEC = 1'b0;
                            RAM_PCF_END = 1'b1;
                        end
                        RAMST <= RAMST_IDLE;
                    end
                end else 
                    RAM_ACCESS_CNT <= RAM_CYCLES;
            end

            RAMST_FETCH : begin
                if (RAN) begin
                    RAM_ACCESS_CNT <= RAM_ACCESS_CNT - 1;
                    if (RAM_ACCESS_CNT == 0) begin
                        RAM_BUF <= RAM_DI;
                        RAM_FETCH_END = 1'b1;
                        RAMST <= RAMST_FETCH_DONE;
                    end
                end else 
                    RAM_ACCESS_CNT <= RAM_CYCLES;
            end

            RAMST_FETCH_DONE : 
                RAMST <= RAMST_IDLE;

            RAMST_CACHE : begin
                if (RAN) begin
                    RAM_ACCESS_CNT <= RAM_ACCESS_CNT - 1;
                    if (RAM_ACCESS_CNT == 0) begin
                        RAM_BUF <= RAM_DI;
                        RAM_CACHE_END = 1'b1;
                        RAMST <= RAMST_CACHE_DONE;
                    end
                end else 
                    RAM_ACCESS_CNT <= RAM_CYCLES;
            end

            RAMST_CACHE_DONE : begin
                if (CACHE_DST_ADDR[3:0] != 15) begin
                    RAM_ACCESS_CNT <= RAM_CYCLES;
                    RAMST <= RAMST_CACHE;
                end else 
                    RAMST <= RAMST_CACHE_END;
            end

            RAMST_CACHE_END : 
                RAMST <= RAMST_IDLE;

            default : ;
            endcase
        end
    end

    RAM_STORE_WORD <= RAM_STORE_WORD_t;
    RAM_LOAD_WORD <= RAM_LOAD_WORD_t;
end

assign PCF_WR_DATA = (PCF_RD_DATA & ~PIX_CACHE[1].VALID) | (GetPCData(PIX_CACHE[1], BPP_CNT) & PIX_CACHE[1].VALID);
assign PCF_RAM_A = GetCharOffset(PIX_CACHE[1].OFFSET, (SCMR_HT | {POR_OBJ, POR_OBJ}), SCMR_MD, BPP_CNT, SCBR);
assign RPIX_RAM_A = GetCharOffset({PC_Y, PC_X[7:3]}, (SCMR_HT | {POR_OBJ,POR_OBJ}), SCMR_MD, BPP_CNT, SCBR); 

assign RAM_A = ~GSU_RAM_ACCESS ? SNES_RAM_A : 
                RAMST == RAMST_CACHE ? CACHE_SRC_ADDR[16:0] : 
                (RAMST == RAMST_LOAD || RAMST == RAMST_SAVE) ? {RAMBR[0],RAMADDR[15:1],RAMADDR[0] ^ RAM_BYTES} : 
                RAMST == RAMST_PCF ? PCF_RAM_A : 
                RAMST == RAMST_RPIX ? RPIX_RAM_A : 
                {PBR[0],R[15]};

assign RAM_DO = ~GSU_RAM_ACCESS ? DI : 
                RAMST == RAMST_SAVE && RAM_BYTES == 1'b0 && GSU_RAM_ACCESS ? RAMDR[7:0] : 
                RAMST == RAMST_SAVE && RAM_BYTES && GSU_RAM_ACCESS ? RAMDR[15:8] : 
                RAMST == RAMST_PCF && GSU_RAM_ACCESS ? PCF_WR_DATA : 
                DI;

assign RAM_WE_N = ~ENABLE ? 1'b1 : 
                ~GSU_RAM_ACCESS ? WR_N : 
                RAMST == RAMST_SAVE && RAM_ACCESS_CNT == 0 && GSU_RAM_ACCESS ? 1'b0 : 
                RAMST == RAMST_PCF && RAM_ACCESS_CNT == 0 && GSU_RAM_ACCESS ?  ~PCF_RW : 
                1'b1;

assign RAM_CE_N = ~ENABLE ? 1'b0 : 
                ~GSU_RAM_ACCESS ?  ~SRAM_SEL : 
                (RAMST == RAMST_LOAD || RAMST == RAMST_SAVE || RAMST == RAMST_PCF 
                   || RAMST == RAMST_RPIX || RAMST == RAMST_CACHE || RAMST == RAMST_FETCH) 
                   && GSU_RAM_ACCESS ? 1'b0 : 
                1'b1;

// assign DBG_IN_CACHE = IN_CACHE;
// assign DBG_MC = MC;
// assign DBG_GO_CNT = GO_CNT;

endmodule
