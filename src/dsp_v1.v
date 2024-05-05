
// This is the old (v1) dsp implementation that uses more LUT resources.

// Timing
// - DSP is active every 4 clk cycles
// - Every active DSP cycle increments SUBSTEP (0~3), then STEP (0~31)
// - SMP is active (SMP_EN) when SUBSTEP == 3

module DSP(
    input CLK,                  // mclk: ~21.5Mhz
    input RST_N,
    input ENABLE,
    input PAL,

    // SMP interface
    output SMP_EN,              // SMP is active on SUBSTEP 3
    input [15:0] SMP_A,
    input [7:0] SMP_DO,
    output reg [7:0] SMP_DI,
    input SMP_WE_N,
    output SMP_CE,

    // memmux interface
    output reg [15:0] RAM_A,
    input [7:0] RAM_Q,
    output reg [7:0] RAM_D,
    output RAM_WE_N,
    output RAM_OE_N,
    output RAM_CE_N,

    output reg [15:0] AUDIO_L,
    output reg [15:0] AUDIO_R,
    output reg SND_RDY,         // pulse when AUDIO_L and AUDIO_R is ready

    // debug
    input [7:0] DBG_REG,
    input [7:0] DBG_DAT_IN,
    output reg [7:0] DBG_DAT_OUT,
    input DBG_DAT_WR
);

`include "dsp.vh"

// set this to non-zero to mute voices corresponding to 1's
// e.g. 8'b1111_1110 will only play voice 0
localparam [7:0] MUTE_MASK = 8'b0;

reg RAM_WE; reg RAM_OE; reg RAM_CE;
wire [7:0] RAM_DI;
reg [7:0] RAM_DO;

reg [7:0] REGRAM[0:127] = '{128{8'b0}} /* synthesis syn_ramstyle = "distributed_ram" */;
reg [7:0] RI;               // register value from SMP
reg [6:0] REGN_RD, REGN_WR; // current register for read/write
wire [6:0] REGS_ADDR_WR, REGS_ADDR_RD;
wire [7:0] REGS_DI, REGS_DO;    // DI: value to write to register, DO: to read from reg
wire REGS_WE;               // 1: write to register

wire SMP_EN_INT;            // run SMP in this cycle when last_phase is 1
reg [4:0] STEP_CNT;
reg [1:0] SUBSTEP_CNT;
wire [4:0] STEP;            // 0-31
wire [1:0] SUBSTEP;         // 0-3
wire [2:0] BRR_VOICE;       // current active voice

reg [11:0] GCNT_BY1;
reg [11:0] GCNT_BY3, GCNT_BY5;

reg RST_FLG, MUTE_FLG, ECEN_FLG;
reg [7:0] WKON;             // Key-ON from register write
reg [7:0] TKON, TKOFF;      // Start/fade off the voice specified
reg [2:0] KON_CNT[0:7];     // After Key-ON, a voice goes through 5,4,3,2,1

reg [13:0] TPITCH;          // $x2/$x3: Pitch
reg [7:0] TSRCN;            // $x4: source/sample number (0-255)
reg [7:0] TADSR1, TADSR2;   // $x5/$x6: Per voice Attach-Decay-Sustain-Release control
reg [7:0] TENVX /*verilator public*/;            
                            // $x8: present ADSR/GAIN envelope value
reg [7:0] TOUTX;            // $x9: wave height multiplied by the ADSR/GAIN envelope value

reg [7:0] TDIR;             // $5D: DIR location: {TDIR, 8'b0}
reg [7:0] TNON;             // $3D: 1bit per voice: noise on
reg [7:0] TESA;             // $6D: global: echo waveform directory location
reg [7:0] TEON;             // $4D: 1bit per voice: echo on
reg [7:0] TPMON;            // $2D: 1bit per voice: pitch modulation ON
reg [7:0] ENDX, ENDX_BUF;   // $7C: 1bit per voice: BRR decoder has reached the block in sample

reg EVEN_SAMPLE;            // flip every 32-cycle loop at VS_ESA time
reg BRR_DECODE_EN;

shortint TOUT;
reg signed [14:0] NOISE;
reg [15:0] OUTL;
reg [15:0] OUTR;
reg [31:0] OUTPUT;
shortint MOUT[0:1];
shortint EOUT[0:1];

reg [15:0] TDIR_ADDR;           // dir address for current sample
reg [15:0] BRR_NEXT_ADDR;       // next sample address
reg [15:0] BRR_ADDR[0:7];       // sample address for each channel
reg [2:0] BRR_OFFS[0:7];
reg [15:0] TBRRDAT;             // sample data (a pair of bytes)
reg [7:0] TBRRHDR;              // sample header
reg signed [15:0] BRR_BUF[0:7][0:11] /* synthesis syn_ramstyle = "distributed_ram" */;

reg [14:0] ECHO_POS;
reg [14:0] ECHO_BUF[0:1][0:7];
reg [14:0] ECHO_LEN;
reg [6:0] ECHO_DATA_TEMP;
reg ECHO_WR_EN;
reg signed [15:0] ECHO_FIR[0:1];
reg signed [7:0] ECHO_FFC[0:7];
reg [2:0] FFC_CNT;

reg [1:0] ENV_MODE[0:7];        // envelope mode
reg signed [11:0] ENV[0:7];
reg [7:0] BENT_INC_MODE;
reg [15:0] INTERP_POS[0:7];     // interpolation position, [14:12]: BBRpos, [11:0]: GTBLpos

typedef logic [11:0] GCntMask_t [0:31];
localparam GCntMask_t GCNT_MASK = '{
    12'hFFF, 12'h7FF, 12'h7FF,
    12'h7FF, 12'h3FF, 12'h3FF,
    12'h3FF, 12'h1FF, 12'h1FF,
    12'h1FF, 12'h0FF, 12'h0FF,
    12'h0FF, 12'h07F, 12'h07F,
    12'h07F, 12'h03F, 12'h03F,
    12'h03F, 12'h01F, 12'h01F,
    12'h01F, 12'h00F, 12'h00F,
    12'h00F, 12'h007, 12'h007,
    12'h007, 12'h003, 12'h003,
             12'h001,
             12'h000 };

function logic GCOUNT_TRIGGER(logic [4:0] r);
    case (r)
    1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 30:
        return (GCNT_BY1 & GCNT_MASK[r]) == 12'b0;
    2, 5, 8, 11, 14, 17, 20, 23, 26, 29:
        return (GCNT_BY3 & GCNT_MASK[r]) == 12'b0;
    3, 6, 9, 12, 15, 18, 21, 24, 27:
        return (GCNT_BY5 & GCNT_MASK[r]) == 12'b0;
    31:
        return 1'b1;
    default:
        return 1'b0;
    endcase
endfunction

VoiceStep_r VS;
wire [3:0] RS;
BRRDecodeStep_r BDS;
IntStep_r INS;

//debug
reg [15:0] DBG_ADDR;
reg DBG_DAT_WRr;
reg [7:0] DBG_VMUTE = 8'b0;

wire CE;
wire CEGEN_RST_N = RST_N & ENABLE;

CEGen cegen (
  .CLK(CLK), .RST_N(CEGEN_RST_N),
//   .IN_CLK(2148540),
  .IN_CLK(2150540),
  .OUT_CLK(ACLK_FREQ),
  .CE(CE)
);

assign SMP_EN = SMP_EN_INT;
assign SMP_CE = CE;

always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      STEP_CNT <= 5'b0;
      SUBSTEP_CNT <= 2'b0;
    end else if (ENABLE && CE) begin
      SUBSTEP_CNT <= SUBSTEP_CNT + 1;
      if(SUBSTEP_CNT == 3) begin
        STEP_CNT <= STEP_CNT + 1;
      end
    end
end

assign SMP_EN_INT = SUBSTEP == 3 ? ENABLE : 1'b0;
assign STEP = STEP_CNT;
assign SUBSTEP = SUBSTEP_CNT;
assign REGS_ADDR_WR = ENABLE == 1'b0 ? DBG_REG[6:0] : REGN_WR;
assign REGS_ADDR_RD = ENABLE == 1'b0 ? DBG_REG[6:0] : REGN_RD;
assign REGS_DI = ENABLE == 1'b0 ? DBG_DAT_IN : SUBSTEP == 3 ? SMP_DO : 
                REGN_WR[3:0] == 4'h8 ? TENVX : 
                REGN_WR[3:0] == 4'h9 ? TOUTX : 
                SMP_DO;
assign REGS_WE = ENABLE == 1'b0 && DBG_REG[7] == 1'b0 ? DBG_DAT_WR : 
                SMP_WE_N == 1'b0 && SMP_A == 16'h00F3 && SUBSTEP == 3 ? 1'b1 :
                REGN_WR[3:1] == 3'b100 && SUBSTEP == 0 ? 1'b1 : 
                1'b0;
assign REGS_DO = REGRAM[REGS_ADDR_RD];

always @(posedge CLK) begin : register_access
    if(RST_N == 1'b0) begin
      REGRAM <= '{128{8'b0}};
    end else begin
      if(REGS_WE == 1'b1) begin
        REGRAM[REGS_ADDR_WR] <= REGS_DI;
        if (SUBSTEP == 2'd3 && ENABLE) begin
            // $display("DSP register [%x] <= %x", REGS_ADDR_WR, REGS_DI);
        end
      end
    end
end

always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      RI <= 8'b0;
    end else if (ENABLE && CE) begin
      if(SMP_EN_INT == 1'b1 && SMP_WE_N == 1'b0) begin
        if(SMP_A == 16'h00F2) begin
          RI <= SMP_DO;
        end
      end
    end
end

always @* begin
    if(SMP_A == 16'h00F2)
      SMP_DI = RI;
    else if(SMP_A == 16'h00F3) begin
      if(RI[6:0] == 7'b1111100) 
        //ENDX
        SMP_DI = ENDX;
      else 
        SMP_DI = REGS_DO;
    end else 
      SMP_DI = RAM_DI;
end

always @* begin : reg_read
    reg [7:0] REG;

    REG = RA_TBL[STEP][SUBSTEP];
    if(SUBSTEP == 3) 
      REGN_RD = RI[6:0];
    else if(REG[3:0] == 4'h6) 
      REGN_RD = {REG[6:1], ~TADSR1[7]};
    else 
      REGN_RD = REG[6:0];
    if(SUBSTEP == 3) 
      REGN_WR = RI[6:0];
    else
      REGN_WR = RA_TBL[STEP][SUBSTEP][6:0];
end

assign VS = VS_TBL[STEP][SUBSTEP];
assign RS = RS_TBL[STEP][SUBSTEP];
assign BRR_VOICE = BRR_VOICE_TBL[STEP];
assign BDS = BDS_TBL[STEP][SUBSTEP];
assign INS = IS_TBL[STEP][SUBSTEP];

reg [7:0] SMP_DO_buf;
reg [15:0] SMP_A_buf;
reg SMP_WE_N_buf;
always @(posedge CLK) begin
    SMP_DO_buf <= SMP_DO;
    SMP_A_buf <= SMP_A;
    SMP_WE_N_buf <= SMP_WE_N;
end

always @* begin : ram_addrgen
    reg [1:0] ADDR_INC;
    reg [31:0] LR;

    RAM_DO = 8'h00;
    ADDR_INC = 2'b0;        // remove latch
    LR = 0;                 // remove latch
    if(ENABLE == 1'b0) begin
      RAM_A = DBG_ADDR;
      RAM_DO = DBG_DAT_IN;
      RAM_WE = DBG_DAT_WR;
      RAM_OE = ~DBG_DAT_WR;
      if(DBG_REG == 8'h80) 
        RAM_CE = 1'b1;
      else 
        RAM_CE = 1'b0;
    end else begin
      case(RS)
      RS_SRCNL : begin      // 4: read directory entry low 8bit
        if(KON_CNT[BRR_VOICE] == 0) 
          ADDR_INC = 2'b10;
        else 
          ADDR_INC = 2'b00;
        RAM_A = TDIR_ADDR + 16'(ADDR_INC);
        RAM_WE = 1'b0;
        RAM_OE = 1'b1;
        RAM_CE = 1'b1;
      end

      RS_SRCNH : begin      // 5: read directory entry high 8bit
        if(KON_CNT[BRR_VOICE] == 0) 
          ADDR_INC = 2'b10;
        else 
          ADDR_INC = 2'b00;
        RAM_A = TDIR_ADDR + 16'(ADDR_INC) + 16'd1;
        RAM_WE = 1'b0;
        RAM_OE = 1'b1;
        RAM_CE = 1'b1;
      end

      RS_BRRH : begin       // 1: read BRR header
        RAM_A = BRR_ADDR[BRR_VOICE];
        RAM_WE = 1'b0;
        RAM_OE = 1'b1;
        RAM_CE = 1'b1;
      end

      RS_BRR1 : begin       // 2: read BRR block 1
        RAM_A = BRR_ADDR[BRR_VOICE] + 16'(BRR_OFFS[BRR_VOICE]) + 16'd1;
        RAM_WE = 1'b0;
        RAM_OE = 1'b1;
        RAM_CE = 1'b1;
      end

      RS_BRR2 : begin       // 3: read BRR block 2
        RAM_A = BRR_ADDR[BRR_VOICE] + 16'(BRR_OFFS[BRR_VOICE]) + 16'd2;
        RAM_WE = 1'b0;
        RAM_OE = 1'b1;
        RAM_CE = 1'b1;
      end

      RS_ECHORDL,RS_ECHORDH : begin // 6, 7
        if(STEP == 22) 
          ADDR_INC = 2'b00;
        else 
          ADDR_INC = 2'b10;
        if(RS == RS_ECHORDL) 
          RAM_A = {TESA,8'h00} + ECHO_POS + 16'(ADDR_INC);
        else 
          RAM_A = {TESA,8'h00} + ECHO_POS + 16'(ADDR_INC) + 16'd1;
        RAM_WE = 1'b0;
        RAM_OE = 1'b1;
        RAM_CE = 1'b1;
      end

      RS_ECHOWRL,RS_ECHOWRH : begin // 8, 9
        if(STEP == 29) begin
          ADDR_INC = 2'b00;
          LR = 0;
        end else begin
          ADDR_INC = 2'b10;
          LR = 1;
        end

        if(RS == RS_ECHOWRL) begin
          RAM_A = {TESA,8'h00} + ECHO_POS + 16'(ADDR_INC);
          RAM_DO = EOUT[LR][7:0];
        end else begin
          RAM_A = {TESA,8'h00} + ECHO_POS + 16'(ADDR_INC) + 16'd1;
          RAM_DO = EOUT[LR][15:8];
        end

        if(ECHO_WR_EN == 1'b1) begin
          RAM_CE = 1'b1;
          RAM_OE = 1'b0;
          RAM_WE = 1'b1;
        end else begin
          RAM_CE = 1'b0;
          RAM_OE = 1'b0;
          RAM_WE = 1'b0;
        end
      end

    // nand2mario: do memory operation in the first phase, so that read data is 
    // available to SMP in second(last) phase earlier (end of first phase), for better timing
      RS_SMP : begin            // $A
        RAM_A = SMP_A_buf;
        RAM_WE = ~SMP_WE_N_buf;
        RAM_OE = SMP_WE_N_buf;
        RAM_DO = SMP_DO_buf;        // buffered to satisfy timing checker  
        if (SMP_A_buf[15:4]== 12'h00F)
            RAM_CE = 0;
        else
            RAM_CE = 1;      
      end

      default : begin
        RAM_A = 16'b0;
        RAM_WE = 1'b0;
        RAM_OE = 1'b0;
        RAM_CE = 1'b0;
      end
      endcase
    end
end

always @(posedge CLK) begin : ram_process
    reg [31:0] LR;

    if(RST_N == 1'b0) begin
      BRR_NEXT_ADDR <= 16'b0;
      TBRRHDR <= 8'b0;
      TBRRDAT <= 16'b0;
      ECHO_BUF <= '{2{'{8{15'b0}}}};
      ECHO_DATA_TEMP <= 7'b0;
    end else if (ENABLE && CE) begin
      case(RS)
      RS_SRCNL : 
        BRR_NEXT_ADDR[7:0] <= RAM_DI;
      RS_SRCNH : 
        BRR_NEXT_ADDR[15:8] <= RAM_DI;
      RS_BRRH : 
        TBRRHDR <= RAM_DI;
      RS_BRR1 : 
        TBRRDAT[15:8] <= RAM_DI;
      RS_BRR2 : 
        TBRRDAT[7:0] <= RAM_DI;
      RS_ECHORDL,RS_ECHORDH : begin
        if(STEP == 22) 
          LR = 0;
        else 
          LR = 1;
        if(RS == RS_ECHORDL) 
          ECHO_DATA_TEMP <= RAM_DI[7:1];
        else begin
          ECHO_BUF[LR][0] <= ECHO_BUF[LR][1];
          ECHO_BUF[LR][1] <= ECHO_BUF[LR][2];
          ECHO_BUF[LR][2] <= ECHO_BUF[LR][3];
          ECHO_BUF[LR][3] <= ECHO_BUF[LR][4];
          ECHO_BUF[LR][4] <= ECHO_BUF[LR][5];
          ECHO_BUF[LR][5] <= ECHO_BUF[LR][6];
          ECHO_BUF[LR][6] <= ECHO_BUF[LR][7];
          ECHO_BUF[LR][7] <= {RAM_DI, ECHO_DATA_TEMP};
        end
      end
      RS_ECHOWRL,RS_ECHOWRH : begin
        if (STEP == 29)
          LR = 0;
        else
          LR = 1;
      end
      default : ;
      endcase
    end
end

assign RAM_D = RAM_DO;
assign RAM_DI = RAM_Q;

assign RAM_WE_N = ~RAM_WE;
assign RAM_OE_N = ~RAM_OE;
assign RAM_CE_N = ~RAM_CE;

always @(posedge CLK) begin : brr_decode
    logic [1:0] FILTER;
    logic [3:0] SCALE;
    logic signed [15:0] SOUT, P0, P1;
    logic signed [15:0] SR;
    logic signed [16:0] SF;
    logic signed [15:0] S;   // original sample -8 ~ 7

    if(RST_N == 1'b0) begin
      BRR_BUF <= '{8{'{12{16'b0}}}};
      // synthesis translate_off
    //   SF_DBG <= 17'b0;
      // synthesis translate_on
    end else if (ENABLE && CE) begin
      // https://snes.nesdev.org/wiki/BRR_samples
      if(BDS.S != BDS_IDLE && BRR_DECODE_EN == 1'b1) begin
        FILTER = TBRRHDR[3:2];
        SCALE = TBRRHDR[7:4];
        case (BDS.S)
        BDS_SMPL0:      // Each sample nibble is a signed 4-bit value in the range of -8 to +7. 
        	S = {{13{TBRRDAT[15]}}, TBRRDAT[14], TBRRDAT[13], TBRRDAT[12]};
        BDS_SMPL1:
          S = {{13{TBRRDAT[11]}}, TBRRDAT[10], TBRRDAT[9],  TBRRDAT[8]};
        BDS_SMPL2:
          S = {{13{TBRRDAT[7]}}, TBRRDAT[6], TBRRDAT[5], TBRRDAT[4]};
        BDS_SMPL3:
          S = {{13{TBRRDAT[3]}}, TBRRDAT[2], TBRRDAT[1], TBRRDAT[0]};
        default: ;
        endcase

        SR = (S << SCALE) >>> 1;
        // if SCALE <= 12 then
        //     SR := shift_right(signed(unsigned(S) sll to_integer(SCALE)),1);
        // else
        //     SR := signed(S and x"F800");
        // end if;

        // Filter application. This is Tricky.
        // - Easy to cause overflows
        // - Needs lots of () as shifting is lower-precedence than +/-
        P0 = BRR_BUF[BDS.V][11];
        P1 = BRR_BUF[BDS.V][10] >>> 1;
        case(FILTER)    
        2'b00 : 
          SF = 17'(SR);
        2'b01 : 
          // SR + P0*15/32
          // output += output[now-1] * 15/16
          SF = 17'(SR) + (17'(P0) >>> 1) - (17'(P0) >>> 5);
        2'b10 : 
          // SR + P0*61/64 - P1*15/16
          // output += output[now-1] * 61/32 - output[now-2] * 15/16;
          SF = 17'(SR)  
               + 17'(P0) - (17'(P0) >>> 6) - (17'(P0) >>> 5) 
               - 17'(P1) + (17'(P1) >>> 4);
        default : 
          // SR + P0*115/128 - P1*13/16
          // output += output[now-1] * 115/64 - output[now-2] * 13/16;
          SF = 17'(SR) 
               + 17'(P0) - (17'(P0) >>> 7) - (17'(P0) >>> 5) - (17'(P0) >>> 4)
               - 17'(P1) + (17'(P1) >>> 4) + (17'(P1) >>> 3);
        endcase

        // synthesis translate_off
        // SF_DBG <= SF;
        // synthesis translate_on
        SOUT = CLAMP16(SF << 1);
        BRR_BUF[BDS.V][0] <= BRR_BUF[BDS.V][1];
        BRR_BUF[BDS.V][1] <= BRR_BUF[BDS.V][2];
        BRR_BUF[BDS.V][2] <= BRR_BUF[BDS.V][3];
        BRR_BUF[BDS.V][3] <= BRR_BUF[BDS.V][4];
        BRR_BUF[BDS.V][4] <= BRR_BUF[BDS.V][5];
        BRR_BUF[BDS.V][5] <= BRR_BUF[BDS.V][6];
        BRR_BUF[BDS.V][6] <= BRR_BUF[BDS.V][7];
        BRR_BUF[BDS.V][7] <= BRR_BUF[BDS.V][8];
        BRR_BUF[BDS.V][8] <= BRR_BUF[BDS.V][9];
        BRR_BUF[BDS.V][9] <= BRR_BUF[BDS.V][10];
        BRR_BUF[BDS.V][10] <= BRR_BUF[BDS.V][11];
        BRR_BUF[BDS.V][11] <= SOUT;
      end
    end
end

always @(posedge CLK) begin : main_process
    logic signed [15:0] TEMP16, OUT_TEMP;
    logic signed [16:0] VOL_TEMP;
    logic [3:0] BB_POS;
    logic [15:0] NEW_INTERP_POS;
    reg [7:0] GTBL_POS;
    logic signed [12:0] ENV_TEMP, ENV_TEMP2;
    logic [4:0] ENV_RATE;
    logic [2:0] GAIN_MODE;
    logic [2:0] NEW_KON_CNT;
    logic [4:0] NOISE_RATE;
    logic signed [14:0] NEW_NOISE;
    logic signed [15:0] BRR0, BRR1, BRR2, BRR3;
    logic signed [11:0] GTBL0, GTBL1, GTBL2, GTBL3;

    if(RST_N == 1'b0) begin
      BRR_ADDR <= '{8{16'b0}};
      BRR_OFFS <= '{8{3'b0}};
      INTERP_POS <= '{8{16'b0}};
      TDIR <= 8'b0;
      TDIR_ADDR <= 16'b0;
      TADSR1 <= 8'b0;
      TADSR2 <= 8'b0;
      TSRCN <= 8'b0;
      TPITCH <= 14'b0;
      ENV <= '{8{12'b0}};
      ENV_MODE <= '{8{EM_RELEASE}};
      BENT_INC_MODE <= 8'b0;
      TOUT <= 16'b0;
      TKON <= 8'b0;
      TKOFF <= 8'b0;
      KON_CNT <= '{8{3'b0}};
      WKON <= 8'b0;
      RST_FLG <= 1'b1;
      MUTE_FLG <= 1'b1;
      ECEN_FLG <= 1'b1;
      EVEN_SAMPLE <= 1'b1;
      OUTL <= 16'b0;
      OUTR <= 16'b0;
      MOUT <= '{2{16'b0}};
      EOUT <= '{2{16'b0}};
      TESA <= 8'b0;
      TNON <= 8'b0;
      NOISE <= {1'b1, 14'b0};
      TEON <= 8'b0;
      ECHO_POS <= 15'b0;
      ECHO_LEN <= 15'b0;
      ECHO_FFC <= '{8{8'b0}};
      ECHO_FIR <= '{2{16'b0}};
      FFC_CNT <= 3'b0;
      ECHO_WR_EN <= 1'b0;
      ENDX <= 8'b0;
      ENDX_BUF <= 8'b0;
      TOUTX <= 8'b0;
      TENVX <= 8'b0;
      BRR_DECODE_EN <= 1'b0;
      // synthesis translate_off
    //   RATE_DBG <= 5'b0;
    //   ENV_DBG <= 13'b0;
    //   SAMPLE_CNT <= 24'b0;
      // synthesis translate_on
    end else if(ENABLE == 1'b0) begin
        if(DBG_DAT_WR == 1'b1 && DBG_REG[7] == 1'b0) begin
          if(DBG_REG[6:0] == 7'b1101100) begin          // 6C: FLG
            RST_FLG <= DBG_DAT_IN[7];
            MUTE_FLG <= DBG_DAT_IN[6];
            ECEN_FLG <= DBG_DAT_IN[5];
          end else if(DBG_REG[6:0] == 7'b1001100) begin // 4C: KON
            WKON <= DBG_DAT_IN & ~MUTE_MASK;
          end else if(DBG_REG[6:0] == 7'b1011101) begin // 5D: DIR
            TDIR <= DBG_DAT_IN;
          end else if(DBG_REG[6:0] == 7'b1101101) begin // 6D: ESA
            TESA <= DBG_DAT_IN;
          end
        end
    end else if (CE) begin 
        if(SMP_EN_INT == 1'b1 && SMP_A == 16'h00F3 && SMP_WE_N == 1'b0) begin
          if(RI[6:0] == 7'b1001100) begin           // $4C: KON
            WKON <= SMP_DO & ~MUTE_MASK;
            // $display("KON = %x", SMP_DO);
          end else if(RI[6:0] == 7'b1101100) begin  // $6C: FLG
            RST_FLG <= SMP_DO[7];
            MUTE_FLG <= SMP_DO[6];
            ECEN_FLG <= SMP_DO[5];
          end else if(RI[6:0] == 7'b1111100) begin  // $7C: ENDX
            ENDX_BUF <= 8'b0;
          end
        end

        case (INS.S)
        IS_ENV : begin      // STEP 1.2, 4.2, 7.2, 10.2, 13.2, 16.2, 19.2, 30.2
          NEW_KON_CNT = KON_CNT[INS.V] - 1;
          if (KON_CNT[INS.V] != 0) begin
            if(KON_CNT[INS.V] == 5) begin
              BRR_ADDR[INS.V] <= BRR_NEXT_ADDR;     // Set new BRR_ADDR
              BRR_OFFS[INS.V] <= 3'b0;
            end
            INTERP_POS[INS.V] <= 16'b0;
            if(NEW_KON_CNT[1:0] != 2'b00)           // KON_CNT = 4 3 2
              INTERP_POS[INS.V] <= 16'h4000;
            ENV[INS.V] <= 12'b0;
            TPITCH <= 14'b0;
          end else 
            if(TPMON[INS.V] == 1'b1)                // Set pitch modulation
              TPITCH <= signed'(TPITCH) + 14'(28'(14'(TOUT >> 5) * signed'(TPITCH)) >>> 10);

          if(RST_FLG == 1'b1 || (TBRRHDR[1:0] == 2'b01 && KON_CNT[INS.V] != 5)) begin
            ENV_MODE[INS.V] <= EM_RELEASE;
            ENV[INS.V] <= 12'b0;
          end

          if(EVEN_SAMPLE == 1'b1 && TKON[INS.V] == 1'b1) 
            KON_CNT[INS.V] <= 3'b101;               // Start KON process on even sample
          else if(KON_CNT[INS.V] != 0) 
            KON_CNT[INS.V] <= KON_CNT[INS.V] - 1;   // KON_CNT --
          if(EVEN_SAMPLE == 1'b1) begin
            if(TKON[INS.V] == 1'b1) 
              ENV_MODE[INS.V] <= EM_ATTACK;         // Start with ATTACK
            else if(TKOFF[INS.V] == 1'b1) 
              ENV_MODE[INS.V] <= EM_RELEASE;        // End with RELEASE
          end
        end

        // Main sound processing routine
        IS_ENV2 : begin     // STEP 1.3, 4.3, 7.3, 10.3, 13.3, 16.3, 19.3, 30.3
          BB_POS = 4'(INTERP_POS[INS.V][14:12]);
          GTBL_POS = INTERP_POS[INS.V][11:4];
          BRR0 = BRR_BUF[INS.V][BB_POS];            // 16bit signed
          BRR1 = BRR_BUF[INS.V][BB_POS + 1];
          BRR2 = BRR_BUF[INS.V][BB_POS + 2];
          BRR3 = BRR_BUF[INS.V][BB_POS + 3];
          GTBL0 = GTBL[{1'b0, ~GTBL_POS}];          // 12bit signed
          GTBL1 = GTBL[{1'b1, ~GTBL_POS}];
          GTBL2 = GTBL[{1'b1, GTBL_POS}];
          GTBL3 = GTBL[{1'b0, GTBL_POS}];
          // result is 28bit signed
          TEMP16 = CLAMP16(17'(28'(GTBL0 * BRR0 + GTBL1 * BRR1 +
                        GTBL2 * BRR2 + GTBL3 * BRR3) >>> 11));
          if(TNON[INS.V] == 1'b0) 
            OUT_TEMP = TEMP16 & 16'hFFFE;
          else 
            OUT_TEMP = {NOISE,1'b0};

          // env apply
          TOUT <= 16'(28'(OUT_TEMP * ENV[INS.V]) >>> 11) & 16'hFFFE;
          TENVX <= {1'b0, ENV[INS.V][10:4]};

          // envelope
          if(KON_CNT[INS.V] == 0) begin
            if(ENV_MODE[INS.V] == EM_RELEASE) begin
              ENV_TEMP = 13'(ENV[INS.V]) - 8;
              if(ENV_TEMP < 0) begin
                ENV_TEMP = 13'b0;
              end
              ENV_RATE = 5'b11111;
            end else begin
              if (TADSR1[7] == 1'b1) begin
                if (ENV_MODE[INS.V] == EM_DECAY || ENV_MODE[INS.V] == EM_SUSTAIN) begin
                  ENV_TEMP = 13'(ENV[INS.V]) - ((ENV[INS.V] - 1) >>> 8) - 1;
                  if(ENV_MODE[INS.V] == EM_DECAY) 
                    ENV_RATE = {1'b1, TADSR1[6:4], 1'b0};
                  else 
                    ENV_RATE = TADSR2[4:0];
                end else begin
                  ENV_RATE = {TADSR1[3:0], 1'b1};
                  if(ENV_RATE != 31) 
                    ENV_TEMP = 13'(ENV[INS.V]) + 13'h020;
                  else 
                    ENV_TEMP = 13'(ENV[INS.V]) + 13'h400;
                end
              end else begin
                GAIN_MODE = TADSR2[7:5];
                if(GAIN_MODE[2] == 1'b0) begin
                  ENV_TEMP = 13'({TADSR2[6:0], 4'b0000});
                  ENV_RATE = 5'b11111;
                end else begin
                  ENV_RATE = TADSR2[4:0];
                  if (GAIN_MODE[1:0] == 2'b00) 
                    ENV_TEMP = 13'(ENV[INS.V]) - 13'h020;
                  else if (GAIN_MODE[1:0] == 2'b01) 
                    ENV_TEMP = 13'(ENV[INS.V]) - ((ENV[INS.V] - 1) >>> 8) - 1;
                  else if (GAIN_MODE[1:0] == 2'b10) 
                    ENV_TEMP = 13'(ENV[INS.V]) + 13'h020;
                  else begin
                    if(BENT_INC_MODE[INS.V] == 1'b0) 
                      ENV_TEMP = 13'(ENV[INS.V]) + 13'h020;
                    else 
                      ENV_TEMP = 13'(ENV[INS.V]) + 13'h008;
                  end
                end
              end
              if (ENV_TEMP < 13'h600) 
                BENT_INC_MODE[INS.V] <= 1'b0;
              else 
                BENT_INC_MODE[INS.V] <= 1'b1;
              if (ENV_TEMP[10:8] == TADSR2[7:5] && ENV_MODE[INS.V] == EM_DECAY) 
                ENV_MODE[INS.V] <= EM_SUSTAIN;
            end

            if (ENV_TEMP[12:11] != 2'b00) begin
              if (ENV_TEMP < 0) 
                ENV_TEMP2 = 13'b0;
              else 
                ENV_TEMP2 = 13'b0_0111_1111_1111;
              if (ENV_MODE[INS.V] == EM_ATTACK) 
                ENV_MODE[INS.V] <= EM_DECAY;
            end else 
              ENV_TEMP2 = ENV_TEMP;

            if(GCOUNT_TRIGGER(ENV_RATE) == 1'b1) 
              ENV[INS.V] <= 12'(ENV_TEMP2);

            // synthesis translate_off
            // RATE_DBG <= ENV_RATE;
            // ENV_DBG <= ENV_TEMP2;
            // synthesis translate_on
          end else 
            ENV[INS.V] <= 12'b0;
        end
        default : ;
        endcase

        case(VS.S)        // pipeline to compute output from samples
        VS_ADSR1 : 
          TADSR1 <= REGS_DO;

        VS_PITCHL : 
          TPITCH[7:0] <= REGS_DO;

        VS_PITCHH : 
          TPITCH[13:8] <= REGS_DO[5:0];

        VS_ADSR2 : 
          TADSR2 <= REGS_DO;

        VS_SRCN : begin
          TSRCN <= REGS_DO;
          TDIR_ADDR <= 16'({TDIR, 8'h00}) + 16'({TSRCN, 2'b00});
        end

        VS_VOLL : begin
          VOL_TEMP = 17'(24'(TOUT * signed'(REGS_DO)) >>> 7);
        //   VOL_TEMP = 17'(24'(TOUT * REGS_DO) >>> 7);
          MOUT[0] <= CLAMP16(17'(MOUT[0]) + VOL_TEMP);
          if (TEON[VS.V] == 1'b1)
            EOUT[0] <= CLAMP16(17'(EOUT[0]) + VOL_TEMP);
          BRR_DECODE_EN <= 1'b0;
          if (INTERP_POS[VS.V][15:14] != 2'b00) begin
            // >= 4000
            BRR_DECODE_EN <= 1'b1;
            BRR_OFFS[VS.V] <= BRR_OFFS[VS.V] + 2;
            if(BRR_OFFS[VS.V] == 6) begin
              if(TBRRHDR[0] == 1'b1) begin      // end bit ON
                BRR_ADDR[VS.V] <= BRR_NEXT_ADDR;
                ENDX_BUF[VS.V] <= 1'b1;
              end else 
                BRR_ADDR[VS.V] <= BRR_ADDR[VS.V] + 9;
            end
          end
          NEW_INTERP_POS = (INTERP_POS[VS.V] & 16'h3FFF) + 16'(TPITCH);
          if(NEW_INTERP_POS[15] == 1'b0) 
            INTERP_POS[VS.V] <= NEW_INTERP_POS;
          else 
            INTERP_POS[VS.V] <= 16'h7FFF;
        end

        VS_VOLR : begin
          VOL_TEMP = 17'(24'(TOUT * signed'(REGS_DO)) >>> 7);
          MOUT[1] <= CLAMP16(17'(MOUT[1]) + VOL_TEMP);
          if(TEON[VS.V] == 1'b1) begin
            EOUT[1] <= CLAMP16(17'(EOUT[1]) + VOL_TEMP);
          end
          if(KON_CNT[VS.V] == 5) begin
            ENDX_BUF[VS.V] <= 1'b0;
          end
        end

        VS_MVOLL : 
          MOUT[0] <= shortint'(24'(MOUT[0] * signed'(REGS_DO)) >>> 7);

        VS_MVOLR : 
          MOUT[1] <= shortint'(24'(MOUT[1] * signed'(REGS_DO)) >>> 7);

        VS_EVOLL : begin
          if(MUTE_FLG == 1'b1) begin
            OUTL <= 16'b0;
          end
          else begin
            // VOL_OUT
            OUTL <= CLAMP16(17'(MOUT[0]) + 
                        17'(24'(ECHO_FIR[0] * signed'(REGS_DO)) >>> 7) );
          end
          MOUT[0] <= 16'b0;
        end

        VS_EVOLR : begin
          if(MUTE_FLG == 1'b1) begin
            OUTR <= 16'b0;
          end
          else begin
            // VOL_OUT
            OUTR <= CLAMP16( 17'(MOUT[1]) + 
                        17'(24'(ECHO_FIR[1] * signed'(REGS_DO)) >>> 7) );
          end
          MOUT[1] <= 16'b0;
          ECHO_FIR[0] <= 16'b0;
          ECHO_FIR[1] <= 16'b0;
          // synthesis translate_off
        //   SAMPLE_CNT <= SAMPLE_CNT + 1;
          // synthesis translate_on
        end

        VS_DIR : 
          TDIR <= REGS_DO;

        VS_KON : begin
          if(EVEN_SAMPLE == 1'b1) 
            WKON <= WKON & ~TKON;
        end

        VS_KOFF : begin
          if(EVEN_SAMPLE == 1'b1) begin
            TKON <= WKON;
            TKOFF <= REGS_DO | DBG_VMUTE;
          end
        end

        VS_PMON : 
          TPMON <= {REGS_DO[7:1], 1'b0};

        VS_NON : 
          TNON <= REGS_DO;

        VS_FLG : begin
          NOISE_RATE = REGS_DO[4:0];
          NEW_NOISE = {NOISE[0] ^ NOISE[1], 14'b00000000000000} | {1'b0, NOISE[14:1]};
          if (GCOUNT_TRIGGER(NOISE_RATE) == 1'b1) begin
            NOISE <= NEW_NOISE;
          end
          ECHO_WR_EN <=  ~ECEN_FLG;
          EOUT[0] <= 16'b0;
          EOUT[1] <= 16'b0;
        end
        VS_EON : 
          TEON <= REGS_DO;

        VS_ESA : begin
          TESA <= REGS_DO;
          EVEN_SAMPLE <=  ~EVEN_SAMPLE;
        end

        VS_EDL : begin
          if(ECHO_POS == 0) begin
            ECHO_LEN <= {REGS_DO[3:0], 11'b0};
          end
        end

        VS_FIR0, VS_FIR1, VS_FIR2, VS_FIR3,
        VS_FIR4, VS_FIR5, VS_FIR6, VS_FIR7 : 
          ECHO_FFC[VS.V] <= REGS_DO;

        VS_EFB : begin
          EOUT[0] <= CLAMP16(17'(EOUT[0]) + 17'(24'(ECHO_FIR[0] * signed'(REGS_DO)) >>> 7)) & 16'hFFFE;
          EOUT[1] <= CLAMP16(17'(EOUT[1]) + 17'(24'(ECHO_FIR[1] * signed'(REGS_DO)) >>> 7)) & 16'hFFFE;
        end

        VS_ENVX : 
          TOUTX <= TOUT[15:8];

        VS_OUTX : 
          ENDX <= ENDX_BUF;

        VS_ECHO : begin
          if (ECHO_POS + 4 >= ECHO_LEN) 
            ECHO_POS <= 15'b0;
          else 
            ECHO_POS <= ECHO_POS + 4;
        end
        default : ;
        endcase

        if((STEP == 24) || (STEP == 25)) begin
          ECHO_FIR[0] <= CLAMP16(17'(ECHO_FIR[0]) + 
                17'(23'(signed'(ECHO_BUF[0][FFC_CNT]) * ECHO_FFC[FFC_CNT]) >>> 6)); // and x"FFFE"
          ECHO_FIR[1] <= CLAMP16(17'(ECHO_FIR[1]) + 
                17'(23'(signed'(ECHO_BUF[1][FFC_CNT]) * ECHO_FFC[FFC_CNT]) >>> 6)); // and x"FFFE"
          FFC_CNT <= FFC_CNT + 1;
        end

    end
end

always @(posedge CLK) begin : gcount
    if(RST_N == 1'b0) begin
      GCNT_BY1 <= 12'b0;
      GCNT_BY3 <= 12'h004;
      GCNT_BY5 <= 12'h008;
    end else if (ENABLE && CE) begin
      if (ENABLE == 1'b1) begin
        if (STEP == 30 && SUBSTEP == 1) begin
          if (GCNT_BY3[1:0] == 2'b00) 
            GCNT_BY3[1:0] <= 2'b10;
          else 
            GCNT_BY3 <= GCNT_BY3 + 1;
          if (GCNT_BY5[2:0] == 3'b000) 
            GCNT_BY5[2:0] <= 3'b100;
          else 
            GCNT_BY5 <= GCNT_BY5 + 1;
          GCNT_BY1 <= GCNT_BY1 + 1;
        end
      end
    end
end

always @(posedge CLK) begin : output2audio
    if(RST_N == 1'b0) begin
        OUTPUT <= 32'b0;
        SND_RDY <= 1'b0;
        AUDIO_L <= 16'b0;
        AUDIO_R <= 16'b0;
    end else begin
        SND_RDY <= 1'b0;        // ensure pulse
        if (ENABLE && CE) begin
            if(SUBSTEP == 3) begin
                OUTPUT <= {OUTPUT[30:0], 1'b0};
                if (STEP == 31) begin
                    OUTPUT <= {OUTL, OUTR};
                    AUDIO_L <= OUTL;
                    AUDIO_R <= OUTR;
                    SND_RDY <= 1'b1;
                end
            end
        end        
    end
end

// assign LRCK =  ~STEP_CNT[4];
// assign BCK = SUBSTEP_CNT[1];
// assign SDAT = OUTPUT[31];

//debug
always @* begin
    if(DBG_REG[7] == 1'b0) 
      DBG_DAT_OUT = REGS_DO;
    else begin
      case(DBG_REG)
      8'h80 : 
        DBG_DAT_OUT = RAM_DI;
      8'h81 : 
        DBG_DAT_OUT = DBG_ADDR[7:0];
      8'h82 : 
        DBG_DAT_OUT = DBG_ADDR[15:8];
      default : 
        DBG_DAT_OUT = 8'h55;
      endcase
    end
  end

  always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      DBG_ADDR <= 16'b0;
      DBG_DAT_WRr <= 1'b0;
    end else begin
      DBG_DAT_WRr <= DBG_DAT_WR;
      if (DBG_DAT_WR == 1'b1 && DBG_DAT_WRr == 1'b0) begin
        case(DBG_REG)
        8'h81 : 
          DBG_ADDR[7:0] <= DBG_DAT_IN;
        8'h82 : 
          DBG_ADDR[15:8] <= DBG_DAT_IN;
        8'h83 : 
          DBG_VMUTE <= DBG_DAT_IN;
        default : ;
        endcase
      end
    end
end

endmodule
