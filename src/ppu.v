
// nand2mario: ∂ppu2.v is the new version of SPPU translated from PPU.vhd in MIST SNES core
// 2023.12

module SPPU(
    input wire RST_N,
    input wire CLK,         // master clock 21 Mhz
    // input CLK,        // half frequency of CLK
    input ENABLE,
    input DIS_SHORTLINE,

    input [7:0] PA,
    input PARD_N,
    input PAWR_N,
    input [7:0] DI /* synthesis syn_keep=1 */,
    output [7:0] DO,

    input SYSCLK_CE,

    output [15:0] VRAM_ADDRA,
    output [15:0] VRAM_ADDRB,
    input [7:0] VRAM_DAI,
    input [7:0] VRAM_DBI,
    output [7:0] VRAM_DAO,
    output [7:0] VRAM_DBO,
    output VRAM_WRA_N,
    output VRAM_WRB_N,
    output VRAM_RD_N,

    input EXTLATCH,

    input PAL,
    input BLEND,

    output HIGH_RES,
    output DOTCLK,

    output reg HBLANK,  
    output reg VBLANK,

    output reg [14:0] COLOR_OUT,
    output [8:0] X_OUT,
    output [8:0] Y_OUT,
    output reg HDE,       // COLOR_OUT is valid when HDE==1 && VDE==1
    output reg VDE,
    output V224,

    output FIELD_OUT,
    output INTERLACE,
    output reg HSYNC,
    output reg VSYNC,
    output reg FRAME_OUT,

    input [4:0] BG_EN
);

// types and functions
`include "ppu_defines.vh"

reg DOT_CLK = 1'b0;
reg DOT_CLKF_CE;        // 1 on first cycle
reg DOT_CLKR_CE;        // 1 on last cycle

reg [2:0] CLK_CNT = 0;
reg [7:0] MDR1, MDR2;   // Data output register for PPU1/PPU2
reg [7:0] D_OUT;

reg PARD_Nr;

// Registers
reg FORCE_BLANK;        // Forced Blanking (0=Normal, 1=Screen Black)
reg [3:0] MB;           // Master Brightness (0=Screen Black, or N=1..15: Brightness*(N+1)/16)
reg [2:0] OBJADDR;      // Base Address for OBJ Tiles 000h..0FFh  (8K-word steps) (16K-byte steps)
reg [1:0] OBJNAME;      // Gap between OBJ 0FFh and 100h (0=None) (4K-word steps) (8K-byte steps)
reg [2:0] OBJSIZE;      // 0=8x8,16x16, 1=8x8,32x32, 2=8x8,64x64, 3=16x16,32x32, 4=16x16,64x64, 5=32x32,64x64
reg [8:0] OAMADD;       // OAM address
reg OAM_PRIO;           // OAM Priority Rotation  (0=OBJ #0, 1=OBJ #N) (OBJ with highest priority)
reg [7:0] TM;           // Main Screen Designation 
reg [7:0] TS;           // Sub Screen Designation 
reg BGINTERLACE;        // V-Scanning: 1=interlace 
reg OBJINTERLACE;       // OBJ V-Direction Display
reg OVERSCAN;           // 0=224 lines, 1=239 lines
reg PSEUDOHIRES;        // Horizontal Pseudo 512 Mode (shift subscreen half to the left)
reg M7EXTBG;            // M7 EXTBG Mode (Screen expand)
reg [2:0] BG_MODE;      // Background mode
reg BG3PRIO;            // BG3 Priority in Mode 1 (0=Normal, 1=High)
reg [3:0] BG_SIZE;      // [0]: BG1 tile size (0=8x8, 1=16x16), [1]: BG1 tile size ...
reg [3:0] BG_MOSAIC_EN; // 0: BG1 Mosaic Enable, 1: BG2, 2: BG3, 3: BG4
reg [3:0] MOSAIC_SIZE;  // Mosaic Size        (0=Smallest/1x1, 0Fh=Largest/16x16)
BgScAddr_t BG_SC_ADDR;  // SC Base Address in VRAM (in 1K-word steps, aka 2K-byte steps)
BgScSize_t BG_SC_SIZE;  // SC Size (0=One-Screen, 1=V-Mirror, 2=H-Mirror, 3=Four-Screen)
BgTileAddr_t BG_NBA;    // BGx Tile Base Address (in 4K-word steps)
reg [8:0] CGADD;        // Palette CGRAM Address
reg VMAIN_ADDRINC;      // Increment VRAM Address after accessing High/Low byte (0=Low, 1=High)
reg [1:0] VMAIN_ADDRTRANS;  // Address Translation    (0..3 = 0bit/None, 8bit, 9bit, 10bit)
reg [15:0] VMADD;       // VRAM Address

BgScroll_t BG_HOFS;     // BGx Horizontal Scroll (X)
BgScroll_t BG_VOFS;     // BGx Vertical Scroll (X)

reg [7:0] M7SEL;        // [0]=H-Flip, [1]=V-Flip, [7:6]=Screen Over
reg [15:0] M7A, M7B, M7C, M7D;  // M7 rotaiton/scaling parameters
reg [12:0] M7HOFS, M7VOFS;  // BG1 horizontal/vertical scroll
reg [12:0] M7X, M7Y;    // Rotation/Scaling Center Coordinate X/Y (W) 

reg [7:0] WH0, WH1;     // Window 1 Left/Right Position
reg [7:0] WH2, WH3;     // Window 2 Left/Right Position
reg [7:0] W12SEL, W34SEL, WOBJSEL, WBGLOG, WOBJLOG; // Window parameters
reg [7:0] TMW;          // Disable layer within the window area (main screen)
                        // [0]=disable BG1 ... [3]=disable BG4, [4]=disable OBJ 
reg [7:0] TSW;          // Disable layer within the window area (sub screen)
reg [7:0] CGWSEL;       // Color Math Control A: [0]=Direct Color
reg [7:0] CGADSUB;      // Color Math Control B
reg [14:0] SUBCOLBD;

reg [8:0] OPHCT, OPVCT; // 
reg OPHCT_latch, OPVCT_latch;
reg EXTLATCHr, F_LATCH;

reg [7:0] CGRAM_Lsb, BGOFS_latch, M7_latch;
reg [2:0] BGHOFS_latch;
reg [7:0] OAM_latch;
reg [15:0] VRAMDATA_Prefetch;
reg [7:0] VMADD_INC;        // Address Increment Step (0..3 = Increment Word-Address by 1,32,128,128)
reg OBJ_TIME_OFL, OBJ_RANGE_OFL;

reg BG_FORCE_BLANK;
wire [15:0] VMADD_TRANS;
wire VRAM1_WRITE, VRAM2_WRITE;
wire VRAM_ADDR_INC;

reg OAM_ADDR_REQ, OAM_PRIO_REQ;
reg VRAMPRERD_REQ;
reg [1:0] VRAMRD_CNT;

// HV COUNTERS
reg [8:0] H_CNT, V_CNT;
reg FIELD;

reg [8:0] LAST_VIS_LINE, LAST_LINE, LAST_DOT;
reg IN_HBL, IN_VBL;

// BACKGROUND
reg [15:0] BG_VRAM_ADDRA, BG_VRAM_ADDRB;
reg BG_FETCH, M7_FETCH;
reg SPR_GET_PIXEL, BG_GET_PIXEL;
reg BG_MATH, BG_OUT;
reg [7:0] GET_PIXEL_X, WINDOW_X, OUT_X, OUT_Y;
reg [3:0] BG_MOSAIC_X, BG_MOSAIC_Y;
BgFetch_r BF;
reg [15:0] BG3_OPT_DATA0;
reg [15:0] BG3_OPT_DATA1;
BgData_t BG_DATA;
BgTileInfo_t BG_TILE_INFO;

logic [7:0] BG_TILES_PLANES[0:1][0:11];
logic [3:0] BG_TILES_ATR[0:1][0:3];

reg [11:0] BG1_PIX_DATA;
reg [7:0] BG2_PIX_DATA;
reg [5:0] BG3_PIX_DATA, BG4_PIX_DATA;
reg [7:0] M7_PIX_DATA;

reg [23:0] MPY;       // Multiplication Result
reg [7:0] M7_SCREEN_X;
reg [23:0] M7_TEMP_X, M7_TEMP_Y;
reg [7:0] M7_TILE_N;
reg [2:0] M7_TILE_ROW, M7_TILE_COL;
reg M7_TILE_OUTSIDE;

// OBJ
wire [15:0] OAM_D;
wire [31:0] OAM_Q;
wire [15:0] OAMIO_Q;
wire [7:0] OAM_ADDR_A;
wire [6:0] OAM_ADDR_B;
wire OAM_WE;
reg [7:0] HOAM_Q;
wire [4:0] HOAM_ADDR;
wire HOAM_WE;
wire HOAM_X8;
wire HOAM_S;

reg [9:0] OAM_ADDR;
RangeOam_t OAM_RANGE;
reg [6:0] OAM_PRIO_INDEX;
reg [6:0] OAM_TIME_INDEX;
reg [5:0] RANGE_CNT;
reg [5:0] TILES_OAM_CNT;
reg [2:0] TILES_CNT;

reg OBJ_RANGE, OBJ_TIME, OBJ_FETCH;
reg OBJ_RANGE_DONE, OBJ_TIME_DONE;

reg [3:0] OBJ_TILE_COL, OBJ_TILE_ROW;
reg [2:0] OBJ_TILE_LINE;
reg [14:0] OBJ_TILE_GAP;
reg OBJ_TILE_HFLIP;
reg [2:0] OBJ_TILE_PAL;
reg [1:0] OBJ_TILE_PRIO;
reg [8:0] OBJ_TILE_X;

reg [8:0] SPR_PIX_DATA;             // {SPR_TILE_PRIO, SPR_TILE_PAL, PIX_DATA}
reg [8:0] SPR_PIX_DATA_BUF;
reg [7:0] SPR_PIXEL_X;
wire [15:0] OBJ_VRAM_ADDR;

reg [31:0] SPR_TILE_DATA;
reg [15:0] SPR_TILE_DATA_TEMP;
reg [8:0] SPR_TILE_X;
reg [2:0] SPR_TILE_PAL;
reg [1:0] SPR_TILE_PRIO;
reg OBJ_TIME_SAVE;

reg [8:0] SPR_PIX_D;
reg [8:0] SPR_PIX_Q;
reg [7:0] SPR_PIX_ADDR_A;
reg SPR_PIX_WE_A, SPR_PIX_WE_B;
reg [2:0] SPR_PIX_CNT;

// CRAM
wire [14:0] CGRAM_Q;
wire [14:0] CGRAM_D; 
wire CGRAM_WE;
reg [7:0] CGRAM_FETCH_ADDR;
reg [7:0] CGRAM_ADDR;
reg CGRAM_ADDR_INC;
reg [7:0] CGRAM_ADDR_CLR;

// Color Math
reg [14:0] PREV_COLOR;
reg SUB_BD;
reg [4:0] MAIN_R, MAIN_G, MAIN_B;   // Main screen color
reg [4:0] SUB_R, SUB_G, SUB_B;      // Sub screen color
reg [4:0] SUB_MATH_R, SUB_MATH_G, SUB_MATH_B;      // Sub screen color
reg [14:0] SUBCOL;      // BGR: Color Math Sub Screen Backdrop Color
wire HIRES;

///////////////////////////////////////////////////////////////////////////////
// 1 - IO and BASICS
///////////////////////////////////////////////////////////////////////////////

/*
mclk    /1\__/2\__/3\__/4\__/5\__/6\__/7\__/8\__/9\__/0\__/
DOT_CLK /         \_4-cycle_/         \______6-cycle______/
IO_CLK  _____/    \____/    \_
*/

always @(posedge CLK) begin : clock_gen
    reg [2:0] DOT_CYCLES;
    if (~RST_N) begin
        CLK_CNT <= 0;
        DOT_CLK <= 1'b0;
        DOT_CLKR_CE <= 0;
        DOT_CLKF_CE <= 0;
    end else begin
        if (~ENABLE)
            DOT_CYCLES = 4;
        else if (V_CNT == 240 && ~BGINTERLACE && FIELD && ~PAL && ~DIS_SHORTLINE)
            DOT_CYCLES = 4;
        else if (H_CNT == 323 && H_CNT == 327)
            DOT_CYCLES = 6;
        else
            DOT_CYCLES = 4;

        DOT_CLKR_CE <= 0;
        DOT_CLKF_CE <= 0;
        CLK_CNT <= CLK_CNT + 1;
        if (CLK_CNT == 1) begin
            DOT_CLK <= 0;
        end else if (CLK_CNT == DOT_CYCLES - 1) begin
            CLK_CNT <= 0;
            DOT_CLK <= 1;
        end

        if (CLK_CNT == 0)
            DOT_CLKF_CE <= 1;     
        if (CLK_CNT == DOT_CYCLES-1-1)
            DOT_CLKR_CE <= 1;
    end
end

// Dual-port CGRAM
ppucgram cgram (
  .clock(CLK), 
  .address_a(CGRAM_ADDR), .data_a(CGRAM_D), .wren_a(CGRAM_WE), .q_a(CGRAM_Q),
  .address_b(CGRAM_ADDR_CLR), .data_b({CGRAM_ADDR_CLR[6:0], CGRAM_ADDR_CLR}), .wren_b(~RST_N), .q_b()
);

always @(posedge CLK) CGRAM_ADDR_CLR <= CGRAM_ADDR_CLR + 1;

assign CGRAM_ADDR = (BG_MATH && ~FORCE_BLANK) ? CGRAM_FETCH_ADDR :
                   CGADD[8:1];
assign CGRAM_D = {DI[6:0], CGRAM_Lsb};
assign CGRAM_WE = (CGADD[0] && ~PAWR_N && PA == 8'h22 && SYSCLK_CE) ? 1 : 0;

// always @(negedge RST_N, negedge IO_CLK) begin : register_access
always @(posedge CLK) begin : register_access
    if (~RST_N) begin
        FORCE_BLANK <= 1'b1;
        MB <= 4'b0;
        OBJADDR <= 3'b0;
        OBJNAME <= 2'b0;
        OBJSIZE <= 3'b0;
        OAMADD <= 9'b0;
        TM <= 8'b0;
        TS <= 8'b0;
        BGINTERLACE <= 1'b0;
        OBJINTERLACE <= 1'b0;
        OVERSCAN <= 1'b0;
        PSEUDOHIRES <= 1'b0;
        M7EXTBG <= 1'b0;
        BG_MODE <= 3'b0;
        BG3PRIO <= 1'b0;
        BG_SIZE <= 4'b0;
        BG_MOSAIC_EN <= 4'b0;
        MOSAIC_SIZE <= 4'b0;
        BG_SC_ADDR <= '{4{6'b0}};
        BG_SC_SIZE <= '{4{2'b0}};
        BG_NBA <= '{4{4'b0}};
        CGADD <= 9'b0;
        VMAIN_ADDRINC <= 1'b0;
        VMAIN_ADDRTRANS <= 2'b0;
        VMADD <= 16'b0;
        BG_HOFS <= '{4{10'b0}};
        BG_VOFS <= '{4{10'b0}};
        M7SEL <= 8'b0;
        M7A <= 16'b0;
        M7B <= 16'b0;
        M7C <= 16'b0;
        M7D <= 16'b0;
        M7HOFS <= 13'b0;
        M7VOFS <= 13'b0;
        M7X <= 13'b0;
        M7Y <= 13'b0;
        WH0 <= 8'b0;
        WH1 <= 8'b0;
        WH2 <= 8'b0;
        WH3 <= 8'b0;
        W12SEL <= 8'b0;
        W34SEL <= 8'b0;
        WOBJSEL <= 8'b0;
        WBGLOG <= 8'b0;
        WOBJLOG <= 8'b0;
        TMW <= 8'b0;
        TSW <= 8'b0;
        CGWSEL <= 8'b0;
        CGADSUB <= 8'b0;
        OPHCT <= 9'b0;
        OPVCT <= 9'b0;
        SUBCOLBD <= 15'b0;

        VRAMDATA_Prefetch <= 16'b0;
        VMADD_INC <= 8'h01;
        VRAMPRERD_REQ <= 0;
        VRAMRD_CNT <= 0;

        OPHCT_latch <= 0;
        OPVCT_latch <= 0;
        F_LATCH <= 1'b0;
        M7_latch <= 8'b0;
        BGOFS_latch <= 8'b0;
        BGHOFS_latch <= 3'b0;
        EXTLATCHr <= 1;
        PARD_Nr <= 1;

        OAM_ADDR <= 10'b0;
        OAM_PRIO <= 1'b0;
        OAM_latch <= 8'b0;
        OAM_PRIO_INDEX <= 0;
        OAM_ADDR_REQ <= 0;
        OAM_PRIO_REQ <= 0;
        CGRAM_Lsb <= 8'b0;

    end else if (ENABLE)/* if (IO_CLK)*/ begin
        if (OAM_ADDR_REQ && DOT_CLKR_CE) begin
            OAM_ADDR <= {OAMADD, 1'b0};
            OAM_PRIO_INDEX <= OAMADD[7:1];
            OAM_ADDR_REQ <= 0;
        end
        if (OAM_PRIO_REQ && DOT_CLKR_CE) begin
            OAM_PRIO_INDEX <= OAM_ADDR[8:2];
            OAM_PRIO_REQ <= 0;
        end

        if (H_CNT == LAST_DOT && (V_CNT < LAST_VIS_LINE || V_CNT == LAST_LINE) 
            && ~FORCE_BLANK && DOT_CLKR_CE) begin
            if (~OAM_PRIO)
                OAM_ADDR <= 0;
            else
                OAM_ADDR <= {1'b0, OAM_PRIO_INDEX, 2'b0};
        end

        if (OBJ_RANGE && ~FORCE_BLANK && H_CNT[0] && DOT_CLKR_CE)
            OAM_ADDR <= OAM_ADDR + 4;
        
        if (OBJ_TIME && ~H_CNT[0] && ~FORCE_BLANK && DOT_CLKR_CE)
            OAM_ADDR <= {1'b0, OAM_TIME_INDEX, 2'b0};
        
        if (VRAMPRERD_REQ) begin
            if (VRAMRD_CNT == 3) begin
                if (FORCE_BLANK || IN_VBL) 
                    VRAMDATA_Prefetch <= {VRAM_DBI, VRAM_DAI};
                else
                    VRAMDATA_Prefetch <= 0;
                VRAMPRERD_REQ <= 0;
            end
            VRAMRD_CNT <= VRAMRD_CNT + 1;
        end

        if (~PAWR_N && SYSCLK_CE) begin
            case (PA)
            8'h00 : begin       //INIDISP     Display Control 1
                FORCE_BLANK <= DI[7];
                MB <= DI[3:0];
                if (FORCE_BLANK && V_CNT == LAST_VIS_LINE + 1)
                    OAM_ADDR_REQ <= 1;
            end
            8'h01 : begin       //OBSEL       Object Size and Object Base 
                OBJADDR <= DI[2:0];
                OBJNAME <= DI[4:3];
                OBJSIZE <= DI[7:5];
            end
            8'h02 : begin       //OAMADDL     OAM Address (lower 8bit)
                OAMADD[7:0] <= DI;
                OAM_ADDR_REQ <= 1;
            end
            8'h03 : begin       //OAMADDH     OAM Address (upper 1bit) and Priority Rotation
                OAMADD[8] <= DI[0];
                OAM_PRIO <= DI[7];
                OAM_ADDR_REQ <= 1; 
            end
            8'h04 : begin       //OAMDI       OAM Data Write (write-twice)
                if (~OAM_ADDR[0]) 
                    OAM_latch <= DI;
                OAM_ADDR <= OAM_ADDR + 1;
                OAM_PRIO_REQ <= 1;
            end
            8'h05 : begin       //BGMODE      BG Mode and BG Character Size 
                BG_MODE <= DI[2:0];
                BG3PRIO <= DI[3];
                BG_SIZE <= DI[7:4];
            end
            8'h06 : begin       //MOSAIC      Mosaic Size and Mosaic Enable
                BG_MOSAIC_EN <= DI[3:0];
                MOSAIC_SIZE <= DI[7:4];
            end
            8'h07 : begin       //BG1SC       BG1 Screen Base and Screen Size 
                BG_SC_SIZE[BG1] <= DI[1:0];
                BG_SC_ADDR[BG1] <= DI[7:2];
            end
            8'h08 : begin       //BG2SC       BG2 Screen Base and Screen Size 
                BG_SC_SIZE[BG2] <= DI[1:0];
                BG_SC_ADDR[BG2] <= DI[7:2];
            end
            8'h09 : begin       //BG3SC       BG3 Screen Base and Screen Size 
                BG_SC_SIZE[BG3] <= DI[1:0];
                BG_SC_ADDR[BG3] <= DI[7:2];
            end
            8'h0A : begin       //BG4SC       BG4 Screen Base and Screen Size 
                BG_SC_SIZE[BG4] <= DI[1:0];
                BG_SC_ADDR[BG4] <= DI[7:2];
            end
            8'h0B : begin       //BG12NBA     BG Character Data Area Designation
                BG_NBA[BG1] <= DI[3:0];
                BG_NBA[BG2] <= DI[7:4];
            end
            8'h0C : begin       //BG34NBA     BG Character Data Area Designation
                BG_NBA[BG3] <= DI[3:0];
                BG_NBA[BG4] <= DI[7:4];
            end
            8'h0D : begin       //BG1HOFS     BG1 Horizontal Scroll (X) (write-twice) / M7HOFS
                BGOFS_latch <= DI;
                BGHOFS_latch <= DI[2:0];
                BG_HOFS[BG1] <= {DI[1:0],BGOFS_latch[7:3],BGHOFS_latch};
                M7_latch <= DI;
                M7HOFS <= {DI[4:0],M7_latch};
            end
            8'h0E : begin       //BG1VOFS     BG1 Vertical Scroll (Y)   (write-twice) / M7VOFS
                BGOFS_latch <= DI;
                BG_VOFS[BG1] <= {DI[1:0],BGOFS_latch};
                M7_latch <= DI;
                M7VOFS <= {DI[4:0],M7_latch};
            end
            8'h0F : begin       //BG2HOFS     BG2 Horizontal Scroll (X) (write-twice)
                BGOFS_latch <= DI;
                BGHOFS_latch <= DI[2:0];
                BG_HOFS[BG2] <= {DI[1:0],BGOFS_latch[7:3],BGHOFS_latch};
            end
            8'h10 : begin       //BG2VOFS     BG2 Vertical Scroll (Y)   (write-twice)
                BGOFS_latch <= DI;
                BG_VOFS[BG2] <= {DI[1:0],BGOFS_latch};
            end
            8'h11 : begin       //BG3HOFS     BG3 Horizontal Scroll (X) (write-twice)
                BGOFS_latch <= DI;
                BGHOFS_latch <= DI[2:0];
                BG_HOFS[BG3] <= {DI[1:0],BGOFS_latch[7:3],BGHOFS_latch};
            end
            8'h12 : begin       //BG3VOFS     BG3 Vertical Scroll (Y)   (write-twice)
                BGOFS_latch <= DI;
                BG_VOFS[BG3] <= {DI[1:0],BGOFS_latch};
            end
            8'h13 : begin       //BG4HOFS     BG4 Horizontal Scroll (X) (write-twice)
                BGOFS_latch <= DI;
                BGHOFS_latch <= DI[2:0];
                BG_HOFS[BG4] <= {DI[1:0],BGOFS_latch[7:3],BGHOFS_latch};
            end
            8'h14 : begin       //BG4VOFS     BG4 Vertical Scroll (Y)   (write-twice)
                BGOFS_latch <= DI;
                BG_VOFS[BG4] <= {DI[1:0],BGOFS_latch};
            end
            8'h15 : begin       //VMAIN       VRAM Address Increment Mode 
                VMAIN_ADDRINC <= DI[7];
                VMAIN_ADDRTRANS <= DI[3:2];
                case (DI[1:0])
                2'b00 : 
                    VMADD_INC <= 8'h01;
                2'b01 : 
                    VMADD_INC <= 8'h20;
                default : 
                    VMADD_INC <= 8'h80;
                endcase
            end
            8'h16 : begin       //VMADDL      VRAM Address (lower 8bit)
                VMADD[7:0] <= DI;
                VRAMPRERD_REQ <= 1;
            end
            8'h17 : begin       //VMADDH      VRAM Address (upper 8bit)  
                VMADD[15:8] <= DI;
                VRAMPRERD_REQ <= 1;
            end
            8'h18:              // VMDIL       VRAM Data Write (lower 8bit)  
                if (~VMAIN_ADDRINC)
                    VMADD <= VMADD + 16'(VMADD_INC);
            8'h19:              // VMDIH       VRAM Data Write (upper 8bit)
                if (VMAIN_ADDRINC)
                    VMADD <= VMADD + 16'(VMADD_INC);
            8'h1A : begin       //M7SEL       Rotation/Scaling Mode Settings
                M7SEL <= DI;
            end
            8'h1B : begin       //M7A         Rotation/Scaling Parameter A & Maths 16bit operand(FFh)(w2)
                M7_latch <= DI;
                M7A <= {DI,M7_latch};
            end
            8'h1C : begin       //M7B         Rotation/Scaling Parameter B & Maths 8bit operand (FFh)(w2)
                M7_latch <= DI;
                M7B <= {DI,M7_latch};
            end
            8'h1D : begin       //M7C         Rotation/Scaling Parameter C         (write-twice)
                M7_latch <= DI;
                M7C <= {DI,M7_latch};
            end
            8'h1E : begin       //M7D         Rotation/Scaling Parameter D         (write-twice)
                M7_latch <= DI;
                M7D <= {DI,M7_latch};
            end
            8'h1F : begin       //M7X         Rotation/Scaling Center Coordinate X (write-twice)
                M7_latch <= DI;
                M7X <= {DI[4:0],M7_latch};
            end
            8'h20 : begin       //M7Y         Rotation/Scaling Center Coordinate Y (write-twice)
                M7_latch <= DI;
                M7Y <= {DI[4:0],M7_latch};
            end
            8'h21 :             //CGADD       Palette CGRAM Address 
                CGADD <= {DI,1'b0};
            8'h22 : begin       //CGDI        Palette CGRAM Data Write             (write-twice)
                if (CGADD[0] == 1'b0) 
                    CGRAM_Lsb <= DI;
                CGADD <= CGADD + 1;
            end
            8'h23 : begin       //W12SEL      Window BG1/BG2 Mask Settings 
                W12SEL <= DI;
            end
            8'h24 :             //W34SEL      Window BG3/BG4 Mask Settings
                W34SEL <= DI;
            8'h25 :             //WOBJSEL     Window OBJ/MATH Mask Settings 
                WOBJSEL <= DI;
            8'h26 :             //WH0         Window 1 Left Position (X1)
                WH0 <= DI;
            8'h27 :             //WH1         Window 1 Right Position (X2)
                WH1 <= DI;
            8'h28 :             //WH2         Window 2 Left Position (X1)  
                WH2 <= DI;
            8'h29 :             //WH3         Window 2 Right Position (X2)  
                WH3 <= DI;
            8'h2A :             //WBGLOG      Window 1/2 Mask Logic (BG1-BG4)
                WBGLOG <= DI;
            8'h2B :             //WOBJLOG     Window 1/2 Mask Logic (OBJ/MATH)
                WOBJLOG <= DI;
            8'h2C :             //TM          Main Screen Designation 
                TM <= DI;
            8'h2D :             //TS          Sub Screen Designation 
            
                TS <= DI;
            8'h2E :             //TMW         Window Area Main Screen Disable 
            
                TMW <= DI;
            8'h2F :             //TSW         Window Area Sub Screen Disable 
            
                TSW <= DI;
            8'h30 :             //CGWSEL      Color Math Control Register A       
                CGWSEL <= DI;
            8'h31 :             //CGADSUB     Color Math Control Register B
                CGADSUB <= DI;  
            8'h32 : begin       //COLDATA     Color Math Sub Screen Backdrop Color
                if (DI[7])     // apply blue
                    SUBCOLBD[14:10] <= DI[4:0];
                if (DI[6])     // apply green
                    SUBCOLBD[9:5] <= DI[4:0];
                if (DI[5])     // apply red
                    SUBCOLBD[4:0] <= DI[4:0];
            end
            8'h33 : begin       //SETINI      Display Control 2
                BGINTERLACE <= DI[0];
                OBJINTERLACE <= DI[1];
                OVERSCAN <= DI[2];
                PSEUDOHIRES <= DI[3];
                //Always out H512
                M7EXTBG <= DI[6];
            end
            default : ;
            endcase
        end else if (~PARD_N && SYSCLK_CE) begin
            case (PA)
            8'h38 : begin       //RDOAM
                OAM_ADDR <= OAM_ADDR + 10'd1;
                OAM_PRIO_REQ <= 1;
            end
            8'h3B :             //RDCGRAM
                CGADD <= CGADD + 9'd1;
            8'h39 : begin       //RDVRAML
                if (VMAIN_ADDRINC == 1'b0) begin
                    VMADD <= VMADD + {8'b0, VMADD_INC};
                    if (FORCE_BLANK || IN_VBL) 
                        VRAMDATA_Prefetch <= {VRAM_DBI,VRAM_DAI};
                    else 
                        VRAMDATA_Prefetch <= 16'b0;
                end
            end
            8'h3A : begin       //RDVRAMH
                if (VMAIN_ADDRINC) begin
                    VMADD <= VMADD + {8'b0, VMADD_INC};
                    if (FORCE_BLANK || IN_VBL) 
                        VRAMDATA_Prefetch <= {VRAM_DBI, VRAM_DAI};
                    else 
                        VRAMDATA_Prefetch <= 16'b0;
                end
            end
            8'h3C :             //OPHCT
                OPHCT_latch <=  ~OPHCT_latch;
            8'h3D :             //OPVCT
                OPVCT_latch <=  ~OPVCT_latch;
            8'h3F : begin       //STAT78
                OPHCT_latch <= 1'b0;
                OPVCT_latch <= 1'b0;
                if (EXTLATCH) 
                    F_LATCH <= 1'b0;
            end
            default : ;
            endcase
        end

        if ((H_CNT == LAST_DOT && V_CNT == LAST_VIS_LINE && ~FORCE_BLANK && DOT_CLKR_CE)) begin
            OAM_ADDR <= {OAMADD,1'b0};
            OAM_PRIO_INDEX <= OAMADD[7:1];
        end 
        
        EXTLATCHr <= EXTLATCH;
        PARD_Nr <= PARD_N;

        if (~EXTLATCH && EXTLATCHr || ~PARD_N && PARD_Nr && PA == 8'h37) begin  // SLHV
            OPHCT <= H_CNT;
            OPVCT <= V_CNT;
            F_LATCH <= 1;
        end
    end
end

always @(posedge CLK) begin
    if (~RST_N) begin
        MDR1 <= 8'b1111_1111;
        MDR2 <= 8'b1111_1111;
    end else if (~PARD_N && SYSCLK_CE) begin
        if (PA == 8'h34 || PA == 8'h35 || PA == 8'h36 || PA == 8'h38 || 
            PA == 8'h39 || PA == 8'h3A || PA == 8'h3E)
            MDR1 <= D_OUT;
        if (PA == 8'h38 || PA == 8'h3C || PA == 8'h3D || PA == 8'h3F)
            MDR2 <= D_OUT;
    end
end

always @(posedge CLK) begin
    if (~RST_N) begin
        D_OUT <= 0;
    end else begin
        case (PA)
        8'h04, 8'h05, 8'h06, 8'h08, 8'h09, 8'h0A, 
            8'h14, 8'h15, 8'h16, 8'h18, 8'h19, 8'h1A, 
            8'h24, 8'h25, 8'h26, 8'h28, 8'h29:
            D_OUT <= MDR1;
        8'h34:      // MPYL
            D_OUT <= MPY[7:0];
        8'h35:      // MPYM
            D_OUT <= MPY[15:8];
        8'h36:      // MPYH
            D_OUT <= MPY[23:16];
        8'h38:      // RDOAM
            if (~OAM_ADDR[9]) begin
                if (~OAM_ADDR[0])
                    D_OUT <= OAMIO_Q[7:0];
                else
                    D_OUT <= OAMIO_Q[15:8];
            end else
                D_OUT <= HOAM_Q;
        8'h39:      // RDVRAML
            D_OUT <= VRAMDATA_Prefetch[7:0];
        8'h3A:      // RDVRAMH
            D_OUT <= VRAMDATA_Prefetch[15:8];
        8'h3E:      // STAT77
            D_OUT <= {OBJ_TIME_OFL, OBJ_RANGE_OFL, 1'b0, MDR1[4], 4'h1};
        8'h3B:      // RDCGRAM
            if (~CGADD[0])
                D_OUT <= CGRAM_Q[7:0];
            else 
                D_OUT <= {MDR2[7], CGRAM_Q[14:8]};
        8'h3C:      // OPHCT
            if (~OPHCT_latch)
                D_OUT <= OPHCT[7:0];
            else
                D_OUT <= {MDR2[7:1], OPHCT[8]};
        8'h3D:      // OPVCT
            if (~OPVCT_latch)
                D_OUT <= OPVCT[7:0];
            else
                D_OUT <= {MDR2[7:1], OPVCT[8]};
        8'h3F:      // STAT78
            D_OUT <= {FIELD, ~EXTLATCH|F_LATCH, MDR2[5], PAL, 4'h3};
        default:
            D_OUT <= DI;
        endcase
    end
end

assign DO = D_OUT;

// VRAM address generation
assign VMADD_TRANS = VMAIN_ADDRTRANS == 2'b01 ? {VMADD[15:8],VMADD[4:0],VMADD[7:5]} :
                     VMAIN_ADDRTRANS == 2'b10 ? {VMADD[15:9],VMADD[5:0],VMADD[8:6]} :
                     VMAIN_ADDRTRANS == 2'b11 ? {VMADD[15:10],VMADD[6:0],VMADD[9:7]} : VMADD[15:0];

assign VRAM2_WRITE = ~PAWR_N && PA == 8'h19 && (BG_FORCE_BLANK || IN_VBL) ? 1'b1 : 1'b0;
assign VRAM1_WRITE = ~PAWR_N && PA == 8'h18 && (BG_FORCE_BLANK || IN_VBL) ? 1'b1 : 1'b0;

assign VRAM_ADDRA = BG_FETCH && ~BG_FORCE_BLANK ? BG_VRAM_ADDRA :
                    OBJ_FETCH && ~FORCE_BLANK ? OBJ_VRAM_ADDR : VMADD_TRANS;
assign VRAM_ADDRB = BG_FETCH && ~BG_FORCE_BLANK ? BG_VRAM_ADDRB :
                    OBJ_FETCH && ~FORCE_BLANK ? OBJ_VRAM_ADDR : VMADD_TRANS;

assign VRAM_DAO = DI;
assign VRAM_DBO = DI;

assign VRAM_RD_N = ~ENABLE ? 0 : 
                   ~BG_FORCE_BLANK && ~IN_VBL ? 0:
                   PA != 8'h18 && PA != 8'h19 ? 0 : 1;
assign VRAM_WRA_N = ~ENABLE ? 1'b1 :  ~VRAM1_WRITE;
assign VRAM_WRB_N = ~ENABLE ? 1'b1 :  ~VRAM2_WRITE;

//HV counters
always @* begin
    if (~PAL) begin
        if (BGINTERLACE && ~FIELD) 
            LAST_LINE = LINE_NUM_NTSC;
        else 
            LAST_LINE = LINE_NUM_NTSC - 1;
        LAST_DOT = DOT_NUM - 1;
    end else begin
        if (BGINTERLACE && ~FIELD) 
            LAST_LINE = LINE_NUM_PAL;
        else 
            LAST_LINE = LINE_NUM_PAL - 1;
        if (V_CNT == 311 && BGINTERLACE && FIELD ) 
            LAST_DOT = DOT_NUM;
        else 
            LAST_DOT = DOT_NUM - 1;
    end
end

assign LAST_VIS_LINE = ~OVERSCAN ? {1'b0, 8'hE0} : {1'b0, 8'hEF};

always @(posedge CLK) begin : hv_counters
    reg [8:0] VSYNC_LINE;
    reg [8:0] VSYNC_HSTART;

    if (~RST_N) begin
        H_CNT <= 0;
        V_CNT <= 0;
        FIELD <= 0;
        IN_HBL <= 0;
        IN_VBL <= 0;
    end else begin
        if (ENABLE && DOT_CLKR_CE) begin
            if (~PAL)
                VSYNC_LINE = LINE_VSYNC_NTSC;
            else
                VSYNC_LINE = LINE_VSYNC_PAL;

            if (BGINTERLACE && ~FIELD) begin
                VSYNC_HSTART = VSYNC_I_HSTART;
                VSYNC_LINE = VSYNC_LINE + 1;
            end else
                VSYNC_HSTART = HSYNC_START;
            
            if (OVERSCAN)
                VSYNC_LINE = VSYNC_LINE + 8;

            H_CNT <= H_CNT + 1;
            if (H_CNT == LAST_DOT) begin
                H_CNT <= 9'b0;
                V_CNT <= V_CNT + 1;
                if (V_CNT == LAST_LINE) begin
                    V_CNT <= 9'b0;
                    FIELD <=  ~FIELD;
                end
            end

            if (H_CNT == 274-1)
                IN_HBL <= 1;
            else if (H_CNT == LAST_DOT)
                IN_HBL <= 0;
            
            if (V_CNT == LAST_VIS_LINE && H_CNT == LAST_DOT)
                IN_VBL <= 1;
            else if (V_CNT == LAST_LINE && H_CNT == LAST_DOT)
                IN_VBL <= 0;
            
            if (H_CNT == 19-1) HDE <= 1;
            if (H_CNT == 275-1) HDE <= 0;

            if (H_CNT == HSYNC_START) HSYNC <= 1;
            if (H_CNT == HSYNC_START+23) HSYNC <= 0;

            if (V_CNT == 1) VDE <= 1;
            if (V_CNT == LAST_VIS_LINE+1) VDE <= 0;
            if (V_CNT == VSYNC_LINE-3)  VDE <= 0; // make sure VDE deactivated before VSync!

            if (H_CNT == VSYNC_HSTART) begin
                if (V_CNT == VSYNC_LINE) VSYNC <= 1;
                if (V_CNT == VSYNC_LINE+3) VSYNC <= 0;
            end
        end
    end
end

always @* begin : bg_obj_signals
    if (H_CNT <= BG_FETCH_END /* && V_CNT >= 0 */ && V_CNT <= LAST_VIS_LINE) 
        BG_FETCH = 1'b1;
    else 
        BG_FETCH = 1'b0;

    if (H_CNT >= M7_FETCH_START && H_CNT <= M7_FETCH_END && V_CNT <= LAST_VIS_LINE) 
        M7_FETCH = 1'b1;
    else 
        M7_FETCH = 1'b0;

    if (H_CNT >= SPR_GET_PIX_START && H_CNT <= SPR_GET_PIX_END && V_CNT >= 1 && V_CNT <= LAST_VIS_LINE) 
        SPR_GET_PIXEL = 1'b1;
    else 
        SPR_GET_PIXEL = 1'b0;

    if (H_CNT >= BG_GET_PIX_START && H_CNT <= BG_GET_PIX_END && V_CNT >= 1 && V_CNT <= LAST_VIS_LINE) 
        BG_GET_PIXEL = 1'b1;
    else 
        BG_GET_PIXEL = 1'b0;

    if (H_CNT >= BG_MATH_START && H_CNT <= BG_MATH_END && V_CNT >= 1 && V_CNT <= LAST_VIS_LINE) 
        BG_MATH = 1'b1;
    else 
        BG_MATH = 1'b0;

    if (H_CNT >= BG_OUT_START && H_CNT <= BG_OUT_END && V_CNT >= 1 && V_CNT <= LAST_VIS_LINE) 
        BG_OUT = 1'b1;
    else 
        BG_OUT = 1'b0;

    if (H_CNT <= OBJ_RANGE_END && V_CNT < LAST_VIS_LINE) 
        OBJ_RANGE = 1'b1;
    else 
        OBJ_RANGE = 1'b0;

    if (H_CNT >= OBJ_TIME_START && H_CNT <= OBJ_TIME_END && V_CNT < LAST_VIS_LINE) 
        OBJ_TIME = 1'b1;
    else 
        OBJ_TIME = 1'b0;

    if (H_CNT >= OBJ_FETCH_START && H_CNT <= OBJ_FETCH_END && V_CNT < LAST_VIS_LINE) 
        OBJ_FETCH = 1'b1;
    else 
        OBJ_FETCH = 1'b0;
end

///////////////////////////////////////////////////////////////////////////////
// 2 - BACKGROUND ENGINE
///////////////////////////////////////////////////////////////////////////////

assign HIRES = BG_MODE == 3'b101 || BG_MODE == 3'b110 ? 1'b1 : 1'b0;
assign BF = BF_TBL[BG_MODE][H_CNT[2:0]];

reg [7:0] M7_TILE;                  
reg [23:0] M7_VRAM_X, M7_VRAM_Y;
reg M7_IS_OUTSIDE;

reg signed [8:0] M7_X, M7_Y;
reg signed [13:0] ORG_X, ORG_Y;

// Comb logic to calc background-related addresses and offsets
always @* begin : bg_addr_gen
    // variables
    reg [8:0] SCREEN_X;
    reg [7:0] SCREEN_Y;
    reg OPTH_EN, OPTV_EN;
    reg IS_OPT;
    reg [9:0] OPT_HOFS, OPT_VOFS;
    reg [7:0] MOSAIC_Y;
    reg [9:0] TILE_INFO_N;
    reg TILE_INFO_HFLIP;
    reg TILE_INFO_VFLIP;
    reg [5:0] TILE_X;
    reg [5:0] TILE_Y;
    reg [9:0] OFFSET_X;
    reg [9:0] OFFSET_Y;
    reg [9:0] TILE_N;
    reg [11:0] OFFSET;
    reg [4:0] TILE_INC;
    reg [2:0] FLIP_Y;
    reg [14:0] TILE_OFFS;
    reg [4:0] TILEPOS_INC;
    reg [15:0] BG_TILEMAP_ADDR, BG_TILEDATA_ADDR;
    reg [13:0] M7_VRAM_ADDRA, M7_VRAM_ADDRB;

    case (BG_MODE)
    3'b000 : begin
        BG_TILE_INFO[0] = BG_DATA[3];
        BG_TILE_INFO[1] = BG_DATA[2];
        BG_TILE_INFO[2] = BG_DATA[1];
        BG_TILE_INFO[3] = BG_DATA[0];
    end
    3'b001 : begin
        BG_TILE_INFO[0] = BG_DATA[2];
        BG_TILE_INFO[1] = BG_DATA[1];
        BG_TILE_INFO[2] = BG_DATA[0];
        BG_TILE_INFO[3] = 16'b0;
    end
    default : begin
        BG_TILE_INFO[0] = BG_DATA[1];
        BG_TILE_INFO[1] = BG_DATA[0];
        BG_TILE_INFO[2] = 16'b0;
        BG_TILE_INFO[3] = 16'b0;
    end
    endcase

    SCREEN_X = H_CNT;
    SCREEN_Y = V_CNT[7:0];
    
    if (BG_MOSAIC_EN[BF.BG] == 1'b0) 
        MOSAIC_Y = SCREEN_Y;
    else 
        MOSAIC_Y = SCREEN_Y - {4'b0, BG_MOSAIC_Y};
    
    // MODE 0-6
    IS_OPT = (BG_MODE[2] | BG_MODE[1]) & ( ~BG_MODE[0]);  // MODE 2,4,6

    case (BF.BG)
    BG1 : begin
        OPTH_EN = (BG_MODE[1] & BG3_OPT_DATA0[13]) | ( ~BG_MODE[1] &  ~BG3_OPT_DATA0[15] & BG3_OPT_DATA0[13]);
        OPTV_EN = (BG_MODE[1] & BG3_OPT_DATA1[13]) | ( ~BG_MODE[1] & BG3_OPT_DATA0[15] & BG3_OPT_DATA0[13]);
    end
    BG2 : begin
        OPTH_EN = (BG_MODE[1] & BG3_OPT_DATA0[14]) | ( ~BG_MODE[1] &  ~BG3_OPT_DATA0[15] & BG3_OPT_DATA0[14]);
        OPTV_EN = (BG_MODE[1] & BG3_OPT_DATA1[14]) | ( ~BG_MODE[1] & BG3_OPT_DATA0[15] & BG3_OPT_DATA0[14]);
    end
    default : begin
        OPTH_EN = 1'b0;
        OPTV_EN = 1'b0;
    end
    endcase

    OPT_HOFS = BG3_OPT_DATA0[9:0];
    if (BG_MODE[1] == 1'b0) 
        OPT_VOFS = BG3_OPT_DATA0[9:0];
    else 
        OPT_VOFS = BG3_OPT_DATA1[9:0];

    TILE_INFO_N = BG_TILE_INFO[BF.BG][9:0];
    TILE_INFO_HFLIP = BG_TILE_INFO[BF.BG][14];
    TILE_INFO_VFLIP = BG_TILE_INFO[BF.BG][15];
    
    if (BF.MODE == BF_OPT0) 
        OFFSET_X = ({SCREEN_X[8:3],3'b000}) + (BG_HOFS[BF.BG]);
    else if (BF.MODE == BF_OPT1) 
        OFFSET_X = ({SCREEN_X[8:3],3'b000}) + (BG_HOFS[BF.BG]);
    else begin
        if (IS_OPT && OPTH_EN)  //OPT
          OFFSET_X = ({SCREEN_X[8:3],3'b000}) + ({OPT_HOFS[9:3],BG_HOFS[BF.BG][2:0]});
        else 
          OFFSET_X = ({SCREEN_X[8:3],3'b000}) + (BG_HOFS[BF.BG]);
    end
    
    if (BF.MODE == BF_OPT0) 
        OFFSET_Y = BG_VOFS[BF.BG];
    else if (BF.MODE == BF_OPT1) 
        OFFSET_Y = (BG_VOFS[BF.BG]) + 8;
    else begin
        if (IS_OPT && OPTV_EN)      //OPT
          OFFSET_Y = {2'b0, MOSAIC_Y} + OPT_VOFS;
        else if (HIRES && BGINTERLACE)
          OFFSET_Y = {1'b0, MOSAIC_Y, FIELD} + BG_VOFS[BF.BG];
        else
          OFFSET_Y = {2'b0, MOSAIC_Y} + BG_VOFS[BF.BG];
    end

    if (BG_SIZE[BF.BG] == 1'b0 || HIRES) 
        TILE_X = OFFSET_X[8:3];
    else 
        TILE_X = OFFSET_X[9:4];
    if (BG_SIZE[BF.BG] == 1'b0) 
        TILE_Y = OFFSET_Y[8:3];
    else 
        TILE_Y = OFFSET_Y[9:4];

    case (BG_SC_SIZE[BF.BG])
    2'b00 : 
        OFFSET = {2'b00,TILE_Y[4:0],TILE_X[4:0]};
    2'b01 : 
        OFFSET = {1'b0,TILE_X[5],TILE_Y[4:0],TILE_X[4:0]};
    2'b10 : 
        OFFSET = {1'b0,TILE_Y[5],TILE_Y[4:0],TILE_X[4:0]};
    default : 
        OFFSET = {TILE_Y[5],TILE_X[5],TILE_Y[4:0],TILE_X[4:0]};
    endcase
    BG_TILEMAP_ADDR = {BG_SC_ADDR[BF.BG], 10'b0} + {4'b0, OFFSET};

    if (BG_SIZE[BF.BG] == 1'b0)
        TILE_INC = 5'b0;
    else if (BG_SIZE[BF.BG] && HIRES)
        TILE_INC = {OFFSET_Y[3] ^ TILE_INFO_VFLIP, 4'b0};
    else
        TILE_INC = {OFFSET_Y[3] ^ TILE_INFO_VFLIP, 3'b0, OFFSET_X[3] ^ TILE_INFO_HFLIP};
    TILE_N = TILE_INFO_N + {5'b0, TILE_INC};
    
    if (TILE_INFO_VFLIP == 1'b0) 
        FLIP_Y = OFFSET_Y[2:0];
    else 
        FLIP_Y =  ~OFFSET_Y[2:0];

    case (BG_MODE)
    3'b000 : 
        TILE_OFFS = {2'b0, TILE_N, FLIP_Y};
    3'b001 : begin
        if (BF.BG == BG1 || BF.BG == BG2) 
          TILE_OFFS = {1'b0, TILE_N, 1'b0, FLIP_Y};
        else 
          TILE_OFFS = {2'b0, TILE_N, FLIP_Y};
    end
    3'b010 : 
        TILE_OFFS = {1'b0, TILE_N, 1'b0, FLIP_Y};
    3'b011 : begin
        if (BF.BG == BG1) 
          TILE_OFFS = {TILE_N, 2'b00, FLIP_Y};
        else 
          TILE_OFFS = {1'b0, TILE_N, 1'b0, FLIP_Y};
    end
    3'b100 : begin
        if (BF.BG == BG1) 
          TILE_OFFS = {TILE_N, 2'b00, FLIP_Y};
        else 
          TILE_OFFS = {2'b0, TILE_N, FLIP_Y};
    end
    3'b101 : begin
        if (BF.BG == BG1) 
          TILE_OFFS = {1'b0, TILE_N, 1'b0, FLIP_Y};
        else 
          TILE_OFFS = {2'b0, TILE_N, FLIP_Y};
    end
    default : 
        TILE_OFFS = {1'b0, TILE_N, 1'b0, FLIP_Y};
    endcase

    case (BF.MODE)
    BF_TILEDAT1 :
        TILEPOS_INC = 5'b01000;     //8
    BF_TILEDAT2 :
        TILEPOS_INC = 5'b10000;     //16
    BF_TILEDAT3 :
        TILEPOS_INC = 5'b11000;     //24
    default :
        TILEPOS_INC = 5'b00000;     //0
    endcase
    BG_TILEDATA_ADDR = {BG_NBA[BF.BG], 12'b0} + TILE_OFFS + {11'b0, TILEPOS_INC};

    // MODE 7
    ORG_X = 14'(signed'(M7HOFS)) - 14'(signed'(M7X));
    ORG_Y = 14'(signed'(M7VOFS)) - 14'(signed'(M7Y));

    if (M7SEL[0] == 1'b0)
        M7_X = 9'(M7_SCREEN_X[7:0]);
    else
        M7_X = 9'(signed'(~M7_SCREEN_X[7:0]));    // signed extension
    
    if (M7SEL[1] == 1'b0)
        M7_Y = 9'(MOSAIC_Y);
    else
        M7_Y = 9'(signed'(~MOSAIC_Y));            // signed extension

    MPY = 24'(signed'(M7A) * signed'(M7B[15:8]));

    M7_VRAM_X = M7_TEMP_X + 24'(signed'(M7A) * M7_X);
    M7_VRAM_Y = M7_TEMP_Y + 24'(signed'(M7C) * M7_X);

    if (M7_VRAM_X[23:18] == 6'b0 && M7_VRAM_Y[23:18] == 6'b0) 
        M7_IS_OUTSIDE = 1'b0;
    else 
        M7_IS_OUTSIDE = 1'b1;

    if (M7SEL[7:6] == 2'b11 && M7_IS_OUTSIDE) 
        M7_TILE = 8'h00;
    else 
        M7_TILE = VRAM_DAI;

    M7_VRAM_ADDRA = {M7_VRAM_Y[17:11], M7_VRAM_X[17:11]};
    M7_VRAM_ADDRB = {M7_TILE_N, M7_TILE_ROW, M7_TILE_COL};

    case (BF.MODE)
    BF_TILEDATM7 : begin
        BG_VRAM_ADDRA = {2'b00, M7_VRAM_ADDRA};
        BG_VRAM_ADDRB = {2'b00, M7_VRAM_ADDRB};
    end
    BF_TILEMAP, BF_OPT0, BF_OPT1 : begin
        BG_VRAM_ADDRA = BG_TILEMAP_ADDR;
        BG_VRAM_ADDRB = BG_TILEMAP_ADDR;
    end
    default : begin
        BG_VRAM_ADDRA = BG_TILEDATA_ADDR;
        BG_VRAM_ADDRB = BG_TILEDATA_ADDR;
    end
    endcase    
end

always @(posedge CLK) begin
    if (~RST_N) begin
        M7_SCREEN_X <= 0;
        M7_TILE_N <= 8'b0;
        M7_TILE_ROW <= 3'b0;
        M7_TILE_COL <= 3'b0;
        M7_TILE_OUTSIDE <= 1'b0;
    end else begin
        if (ENABLE && DOT_CLKR_CE) begin
            if (M7_FETCH == 1)
                M7_SCREEN_X <= M7_SCREEN_X + 1;
            else if (H_CNT == LAST_DOT)
                M7_SCREEN_X <= 0;
            
            if (H_CNT == M7_XY_LATCH) begin
                M7_TEMP_X <= (24'(signed'(M7X)) << 8) + 
                        (24'(signed'(M7A) * Mode7Clip(ORG_X)) & 24'hFFFFC0) + 
                        (24'(signed'(M7B) * Mode7Clip(ORG_Y)) & 24'hFFFFC0) + 
                        (24'(signed'(M7B) * M7_Y) & 24'hFFFFC0);
                M7_TEMP_Y <= (24'(signed'(M7Y)) << 8) + 
                        (24'(signed'(M7C) * Mode7Clip(ORG_X)) & 24'hFFFFC0) + 
                        (24'(signed'(M7D) * Mode7Clip(ORG_Y)) & 24'hFFFFC0) + 
                        (24'(signed'(M7D) * M7_Y) & 24'hFFFFC0);
            end
        end

        M7_TILE_N <= M7_TILE;
        M7_TILE_COL <= M7_VRAM_X[10:8];
        M7_TILE_ROW <= M7_VRAM_Y[10:8];
        M7_TILE_OUTSIDE <= M7_IS_OUTSIDE;
    end
end

// Fetch background tiles from VRAM
always @(posedge CLK) begin : fetch_bg_tiles
    reg [7:0] M7_PIX;

    if (~RST_N) begin
        BG_DATA <= '{8{16'b0}};
        BG3_OPT_DATA0 <= 0;
        BG3_OPT_DATA1 <= 0;
        BG_MOSAIC_Y <= 0;
        BG_FORCE_BLANK <= 1;
    end else begin
        if (ENABLE && DOT_CLKR_CE) begin
            if (H_CNT == LAST_DOT && V_CNT <= LAST_VIS_LINE) begin
                BG_DATA <= '{8{16'b0}};
                BG3_OPT_DATA0 <= 0;
                BG3_OPT_DATA1 <= 0;
            end

            if (H_CNT == LAST_DOT && V_CNT >= 1 && V_CNT <= LAST_VIS_LINE) begin
                if (BG_MOSAIC_Y == MOSAIC_SIZE)
                    BG_MOSAIC_Y <= 0;
                else
                    BG_MOSAIC_Y <= BG_MOSAIC_Y + 1;
            end else if (H_CNT == LAST_DOT && V_CNT == LAST_LINE)
                BG_MOSAIC_Y <= 0;

            if (~BG_FETCH)
                BG_FORCE_BLANK <= FORCE_BLANK;
            else if (BG_FETCH && H_CNT[2:0] == 3'd0)
                BG_FORCE_BLANK <= FORCE_BLANK;

            if (BG_FETCH && ~FORCE_BLANK) begin
                if (BG_MODE != 3'b111) 
                    BG_DATA[H_CNT[2:0]] <= {VRAM_DBI, VRAM_DAI};

                if (H_CNT[2:0] == 0) begin
                    case (BG_MODE)
                    3'b000: begin
                        BG_TILES_PLANES[0][0] <= FlipPlane(BG_DATA[7][7:0], BG_TILE_INFO[BG1][14]);   // BG1 2bpp
                        BG_TILES_PLANES[0][1] <= FlipPlane(BG_DATA[7][15:8], BG_TILE_INFO[BG1][14]);

                        BG_TILES_PLANES[0][8] <= FlipPlane(BG_DATA[6][7:0], BG_TILE_INFO[BG2][14]);   // BG2 2bpp
                        BG_TILES_PLANES[0][9] <= FlipPlane(BG_DATA[6][15:8], BG_TILE_INFO[BG2][14]);

                        BG_TILES_PLANES[0][4] <= FlipPlane(BG_DATA[5][7:0], BG_TILE_INFO[BG3][14]);   // BG3 2bpp
                        BG_TILES_PLANES[0][5] <= FlipPlane(BG_DATA[5][15:8], BG_TILE_INFO[BG3][14]);

                        BG_TILES_PLANES[0][6] <= FlipPlane(BG_DATA[4][7:0], BG_TILE_INFO[BG4][14]);   // BG4 2bpp
                        BG_TILES_PLANES[0][7] <= FlipPlane(BG_DATA[4][15:8], BG_TILE_INFO[BG4][14]);
                    end
                    3'b001: begin
                        BG_TILES_PLANES[0][0] <= FlipPlane(BG_DATA[6][7:0], BG_TILE_INFO[BG1][14]);   // BG1 4bpp
                        BG_TILES_PLANES[0][1] <= FlipPlane(BG_DATA[6][15:8], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][2] <= FlipPlane(BG_DATA[7][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][3] <= FlipPlane(BG_DATA[7][15:8], BG_TILE_INFO[BG1][14]);

                        BG_TILES_PLANES[0][8] <= FlipPlane(BG_DATA[4][7:0], BG_TILE_INFO[BG2][14]);   // BG2 4bpp
                        BG_TILES_PLANES[0][9] <= FlipPlane(BG_DATA[4][15:8], BG_TILE_INFO[BG2][14]);
                        BG_TILES_PLANES[0][10] <= FlipPlane(BG_DATA[5][7:0], BG_TILE_INFO[BG2][14]);
                        BG_TILES_PLANES[0][11] <= FlipPlane(BG_DATA[5][15:8], BG_TILE_INFO[BG2][14]);

                        BG_TILES_PLANES[0][4] <= FlipPlane(BG_DATA[3][7:0], BG_TILE_INFO[BG3][14]);   // BG3 2bpp
                        BG_TILES_PLANES[0][5] <= FlipPlane(BG_DATA[3][15:8], BG_TILE_INFO[BG3][14]);
                    end
                    3'b010: begin
                        BG_TILES_PLANES[0][0] <= FlipPlane(BG_DATA[6][7:0], BG_TILE_INFO[BG1][14]);   // BG1 4bpp
                        BG_TILES_PLANES[0][1] <= FlipPlane(BG_DATA[6][15:8], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][2] <= FlipPlane(BG_DATA[7][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][3] <= FlipPlane(BG_DATA[7][15:8], BG_TILE_INFO[BG1][14]);

                        BG_TILES_PLANES[0][8] <= FlipPlane(BG_DATA[4][7:0], BG_TILE_INFO[BG2][14]);   // BG2 4bpp
                        BG_TILES_PLANES[0][9] <= FlipPlane(BG_DATA[4][15:8], BG_TILE_INFO[BG2][14]);
                        BG_TILES_PLANES[0][10] <= FlipPlane(BG_DATA[5][7:0], BG_TILE_INFO[BG2][14]);
                        BG_TILES_PLANES[0][11] <= FlipPlane(BG_DATA[5][15:8], BG_TILE_INFO[BG2][14]);
                    end
                    3'b011: begin
                        BG_TILES_PLANES[0][0] <= FlipPlane(BG_DATA[4][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][1] <= FlipPlane(BG_DATA[4][15:8], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][2] <= FlipPlane(BG_DATA[5][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][3] <= FlipPlane(BG_DATA[5][15:8], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][4] <= FlipPlane(BG_DATA[6][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][5] <= FlipPlane(BG_DATA[6][15:8], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][6] <= FlipPlane(BG_DATA[7][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][7] <= FlipPlane(BG_DATA[7][15:8], BG_TILE_INFO[BG1][14]);
                        
                        BG_TILES_PLANES[0][8] <= FlipPlane(BG_DATA[2][7:0], BG_TILE_INFO[BG2][14]);
                        BG_TILES_PLANES[0][9] <= FlipPlane(BG_DATA[2][15:8], BG_TILE_INFO[BG2][14]);
                        BG_TILES_PLANES[0][10] <= FlipPlane(BG_DATA[3][7:0], BG_TILE_INFO[BG2][14]);
                        BG_TILES_PLANES[0][11] <= FlipPlane(BG_DATA[3][15:8], BG_TILE_INFO[BG2][14]);
                    end
                    3'b100: begin
                        BG_TILES_PLANES[0][0] <= FlipPlane(BG_DATA[4][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][1] <= FlipPlane(BG_DATA[4][15:8], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][2] <= FlipPlane(BG_DATA[5][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][3] <= FlipPlane(BG_DATA[5][15:8], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][4] <= FlipPlane(BG_DATA[6][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][5] <= FlipPlane(BG_DATA[6][15:8], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][6] <= FlipPlane(BG_DATA[7][7:0], BG_TILE_INFO[BG1][14]);
                        BG_TILES_PLANES[0][7] <= FlipPlane(BG_DATA[7][15:8], BG_TILE_INFO[BG1][14]);

                        BG_TILES_PLANES[0][8] <= FlipPlane(BG_DATA[3][7:0], BG_TILE_INFO[BG2][14]);
                        BG_TILES_PLANES[0][9] <= FlipPlane(BG_DATA[3][15:8], BG_TILE_INFO[BG2][14]);
                    end
                    3'b101: begin
                        BG_TILES_PLANES[0][0] <= FlipBGPlaneHR({BG_DATA[4][7:0], BG_DATA[6][7:0]}, BG_TILE_INFO[BG1][14], 1'b0);
                        BG_TILES_PLANES[0][1] <= FlipBGPlaneHR({BG_DATA[4][15:8], BG_DATA[6][15:8]}, BG_TILE_INFO[BG1][14], 1'b0);
                        BG_TILES_PLANES[0][2] <= FlipBGPlaneHR({BG_DATA[5][7:0], BG_DATA[7][7:0]}, BG_TILE_INFO[BG1][14], 1'b0);
                        BG_TILES_PLANES[0][3] <= FlipBGPlaneHR({BG_DATA[5][15:8], BG_DATA[7][15:8]}, BG_TILE_INFO[BG1][14], 1'b0);
                        BG_TILES_PLANES[0][4] <= FlipBGPlaneHR({BG_DATA[4][7:0], BG_DATA[6][7:0]}, BG_TILE_INFO[BG1][14], 1'b1);
                        BG_TILES_PLANES[0][5] <= FlipBGPlaneHR({BG_DATA[4][15:8], BG_DATA[6][15:8]}, BG_TILE_INFO[BG1][14], 1'b1);
                        BG_TILES_PLANES[0][6] <= FlipBGPlaneHR({BG_DATA[5][7:0], BG_DATA[7][7:0]}, BG_TILE_INFO[BG1][14], 1'b1);
                        BG_TILES_PLANES[0][7] <= FlipBGPlaneHR({BG_DATA[5][15:8], BG_DATA[7][15:8]}, BG_TILE_INFO[BG1][14], 1'b1);

                        BG_TILES_PLANES[0][8] <= FlipBGPlaneHR({BG_DATA[2][7:0], BG_DATA[3][7:0]}, BG_TILE_INFO[BG2][14], 1'b0);
                        BG_TILES_PLANES[0][9] <= FlipBGPlaneHR({BG_DATA[2][15:8], BG_DATA[3][15:8]}, BG_TILE_INFO[BG2][14], 1'b0);
                        BG_TILES_PLANES[0][10] <= FlipBGPlaneHR({BG_DATA[2][7:0], BG_DATA[3][7:0]}, BG_TILE_INFO[BG2][14], 1'b1);
                        BG_TILES_PLANES[0][11] <= FlipBGPlaneHR({BG_DATA[2][15:8], BG_DATA[3][15:8]}, BG_TILE_INFO[BG2][14], 1'b1);
                    end
                    3'b110: begin
                        BG_TILES_PLANES[0][0] <= FlipBGPlaneHR({BG_DATA[4][7:0], BG_DATA[6][7:0]}, BG_TILE_INFO[BG1][14], 1'b0);
                        BG_TILES_PLANES[0][1] <= FlipBGPlaneHR({BG_DATA[4][15:8], BG_DATA[6][15:8]}, BG_TILE_INFO[BG1][14], 1'b0);
                        BG_TILES_PLANES[0][2] <= FlipBGPlaneHR({BG_DATA[5][7:0], BG_DATA[7][7:0]}, BG_TILE_INFO[BG1][14], 1'b0);
                        BG_TILES_PLANES[0][3] <= FlipBGPlaneHR({BG_DATA[5][15:8], BG_DATA[7][15:8]}, BG_TILE_INFO[BG1][14], 1'b0);
                        BG_TILES_PLANES[0][4] <= FlipBGPlaneHR({BG_DATA[4][7:0], BG_DATA[6][7:0]}, BG_TILE_INFO[BG1][14], 1'b1);
                        BG_TILES_PLANES[0][5] <= FlipBGPlaneHR({BG_DATA[4][15:8], BG_DATA[6][15:8]}, BG_TILE_INFO[BG1][14], 1'b1);
                        BG_TILES_PLANES[0][6] <= FlipBGPlaneHR({BG_DATA[5][7:0], BG_DATA[7][7:0]}, BG_TILE_INFO[BG1][14], 1'b1);
                        BG_TILES_PLANES[0][7] <= FlipBGPlaneHR({BG_DATA[5][15:8], BG_DATA[7][15:8]}, BG_TILE_INFO[BG1][14], 1'b1);
                    end
                    default: ;
                    endcase;
                    BG_TILES_ATR[0][0] <= BG_TILE_INFO[BG1][13:10];
                    BG_TILES_ATR[0][1] <= BG_TILE_INFO[BG2][13:10];
                    BG_TILES_ATR[0][2] <= BG_TILE_INFO[BG3][13:10];
                    BG_TILES_ATR[0][3] <= BG_TILE_INFO[BG4][13:10];
                    BG_TILES_PLANES[1] <= BG_TILES_PLANES[0];
                    BG_TILES_ATR[1] <= BG_TILES_ATR[0];
                end
                if (H_CNT[2:0] == 7) begin
                    BG3_OPT_DATA0 <= BG_DATA[2];
                    BG3_OPT_DATA1 <= BG_DATA[3];
                end
            end
        end
    end
end

///////////////////////////////////////////////////////////////////////////////
// 3 - SPRITE ENGINE
///////////////////////////////////////////////////////////////////////////////

// channel B: range scanning reads of OAM
ppuoam OAM(
    .clock(CLK),       
    .data_a(OAM_D), .data_b(32'b0),
    .address_a(OAM_ADDR_A), .address_b(OAM_ADDR_B),
    .wren_a(OAM_WE), .wren_b(1'b0),
    .q_a(OAMIO_Q), .q_b(OAM_Q)
);
assign OAM_D = {DI, OAM_latch};
assign OAM_ADDR_A = OAM_ADDR[8:1];
assign OAM_ADDR_B = OAM_ADDR[8:2];
assign OAM_WE = (~OAM_ADDR[9] || (~IN_VBL && ~FORCE_BLANK)) 
                && OAM_ADDR[0] && ~PAWR_N && PA == 8'h04 && SYSCLK_CE ? ENABLE : 1'b0;

reg [7:0] HOAM [0:31]  /* synthesis syn_ramstyle="distributed_ram" */;

always @(posedge CLK) begin
    HOAM_Q <= HOAM[HOAM_ADDR];
    if (HOAM_WE)
        HOAM[HOAM_ADDR] <= DI;
end

assign HOAM_ADDR = (~IN_VBL && ~FORCE_BLANK) ? OAM_ADDR[8:4] : OAM_ADDR[4:0];
assign HOAM_WE = (OAM_ADDR[9] || (~IN_VBL && ~FORCE_BLANK))
                && ~PAWR_N && PA == 8'h04 && SYSCLK_CE ? ENABLE : 1'b0;
assign HOAM_X8 = HOAM_Q[{OAM_ADDR[3:2], 1'b0}];
assign HOAM_S = HOAM_Q[{OAM_ADDR[3:2], 1'b1}];


// Sprites range engine
// Reads visible sprite tiles into SPR_TILE_DATA, SPR_TILE_PAL...
always @(posedge CLK) begin : calc_sprite_range
    reg [7:0] SCREEN_Y;
    reg [8:0] X;
    reg [7:0] Y;
    reg [5:0] W, H, H2;
    reg [5:0] NEW_RANGE_CNT;
    reg [8:0] TILE_X;
    reg [2:0] CUR_TILES_CNT;
    reg [8:0] OAM_OBJ_X;
    reg [7:0] OAM_OBJ_Y;
    reg OAM_OBJ_S;
    reg [7:0] OAM_OBJ_TILE;
    reg OAM_OBJ_N;
    reg [2:0] OAM_OBJ_PAL;
    reg [1:0] OAM_OBJ_PRIO;
    reg OAM_OBJ_HFLIP;
    reg OAM_OBJ_VFLIP;
    reg [5:0] TEMP;

    if (~RST_N) begin
        RANGE_CNT <= 6'b11_1111;
        OAM_RANGE <= '{32{7'b0}};
        TILES_OAM_CNT <= 0;
        TILES_CNT <= 0;
        OBJ_RANGE_OFL <= 0;
        OBJ_TIME_OFL <= 0;
        OBJ_RANGE_DONE <= 0;
        OBJ_TIME_DONE <= 0;
        OBJ_TIME_SAVE <= 0;
        OAM_TIME_INDEX <= 0;
        OBJ_TILE_LINE <= 0;
        OBJ_TILE_COL <= 0;
        OBJ_TILE_ROW <= 0;
        OBJ_TILE_GAP <= 0;
        OBJ_TILE_HFLIP <= 0;
        OBJ_TILE_PAL <= 0;
        OBJ_TILE_PRIO <= 0;
        OBJ_TILE_X <= 0;
        SPR_TILE_DATA <= 0;
        SPR_TILE_X <= 0;
        SPR_TILE_PAL <= 0;
        SPR_TILE_PRIO <= 0;
        SPR_TILE_DATA_TEMP <= 0;
    end else begin
        if (ENABLE && DOT_CLKR_CE) begin
            if (H_CNT == LAST_DOT && V_CNT < LAST_VIS_LINE) begin
                RANGE_CNT <= 6'b11_1111;
                if (~RANGE_CNT[5] && TILES_OAM_CNT == 34)
                    OBJ_TIME_OFL <= 1;
                OBJ_RANGE_DONE <= 0;
            end

            if (H_CNT == LAST_DOT && V_CNT == LAST_LINE) begin
                OBJ_RANGE_OFL <= 0;
                OBJ_TIME_OFL <= 0;
            end

            OAM_OBJ_X = {HOAM_X8, OAM_Q[7:0]};
            OAM_OBJ_Y = OAM_Q[15:8];
            OAM_OBJ_S = HOAM_S;	
            OAM_OBJ_TILE = OAM_Q[23:16];
            OAM_OBJ_N = OAM_Q[24];
            OAM_OBJ_PAL = OAM_Q[27:25];
            OAM_OBJ_PRIO = OAM_Q[29:28];
            OAM_OBJ_HFLIP = OAM_Q[30];
            OAM_OBJ_VFLIP = OAM_Q[31];

            SCREEN_Y = V_CNT[7:0];
            W = SprWidth({OAM_OBJ_S, OBJSIZE});
            H = SprHeight({OAM_OBJ_S, OBJSIZE});

            if (OBJINTERLACE) 
                H = {1'b0, H[5:1]};
            else
                H2 = H;
            
            // OBJ_RANGE: Collect visible tile addresses into OAM_RANGE[]
            if (OBJ_RANGE && H_CNT[0] && ~FORCE_BLANK) begin
                if ((OAM_OBJ_X <= 256 || (9'd0 - OAM_OBJ_X) <= {3'b0, W}) && (SCREEN_Y - OAM_OBJ_Y) <= {2'b0, H}) begin
                    // sprite is visible, and Y is within range
                    if (~OBJ_RANGE_DONE) begin
                        NEW_RANGE_CNT = RANGE_CNT + 1;
                        OAM_RANGE[NEW_RANGE_CNT[4:0]] <= OAM_ADDR[8:2];
                        RANGE_CNT <= NEW_RANGE_CNT;
                        if (NEW_RANGE_CNT == 31) 
                            OBJ_RANGE_DONE <= 1;
                    end else if (~OBJ_RANGE_OFL)
                        OBJ_RANGE_OFL <= 1;
                end
            end

            // OBJ_TIME: read OAM
            if (H_CNT == OBJ_TIME_START-1 && V_CNT < LAST_VIS_LINE)   // 269: load OAM_TIME_INDEX
                if (~RANGE_CNT[5])
                    OAM_TIME_INDEX <= OAM_RANGE[RANGE_CNT[4:0]];
                    // OAM_TIME_INDEX is ready next CLK_CNT 0
                    // OAM_ADDR is ready next next CLK_CNT 0
                    // OAM_Q is ready next next CLK_CNT 1
            
            if (H_CNT == OBJ_TIME_START-1 && V_CNT < LAST_VIS_LINE) begin
                TILES_OAM_CNT <= 0;
                TILES_CNT <= 0;
                OBJ_TIME_DONE <= 1;
            end
                
            // parse OAM data, generate address OBJ_VRAM_ADDR (OBJ_TILE_X, OBJ_TILE_PAL...)
            if (OBJ_TIME && H_CNT[0]) begin       // starting from 270
                if (~RANGE_CNT[5]) begin
                    if (OAM_OBJ_X[8] && TILES_CNT == 0) begin
                        TEMP = 0 - OAM_OBJ_X[5:0];
                        CUR_TILES_CNT = TEMP[5:3];
                    end else
                        CUR_TILES_CNT = TILES_CNT;
                    
                    if (~OAM_OBJ_VFLIP)
                        Y = SCREEN_Y - OAM_OBJ_Y;
                    else
                        Y = ~(SCREEN_Y - OAM_OBJ_Y);

                    if (OBJINTERLACE)
                        Y = {Y[6:0], FIELD};
                    OBJ_TILE_LINE <= Y[2:0];

                    if (~OAM_OBJ_HFLIP)
                        OBJ_TILE_COL <= OAM_OBJ_TILE[3:0] + CUR_TILES_CNT;
                    else
                        OBJ_TILE_COL <= OAM_OBJ_TILE[3:0] + {1'b0, (~CUR_TILES_CNT & W[5:3])};
                    OBJ_TILE_ROW <= OAM_OBJ_TILE[7:4] + {1'b0, (Y[5:3] & H[5:3])};

                    if (~OAM_OBJ_N)
                        OBJ_TILE_GAP <= 0;
                    else
                        OBJ_TILE_GAP <= 4096 + {OBJNAME, 12'b0};
                    
                    TILE_X = OAM_OBJ_X + {3'b0, CUR_TILES_CNT, 3'b0};
                    
                    OBJ_TILE_HFLIP <= OAM_OBJ_HFLIP;
                    OBJ_TILE_PAL <= OAM_OBJ_PAL ;
                    OBJ_TILE_PRIO <= OAM_OBJ_PRIO;
                    OBJ_TILE_X <= TILE_X;
                    
                    TILES_OAM_CNT <= TILES_OAM_CNT + 1;
                    TILES_CNT <= CUR_TILES_CNT + 1;
                    if (CUR_TILES_CNT == W[5:3] || ((TILE_X + 8) >= 256 && OAM_OBJ_X != 256)) begin
                        NEW_RANGE_CNT = RANGE_CNT - 1;
                        TILES_CNT <= 0;
                        RANGE_CNT <= NEW_RANGE_CNT;
                        if (~NEW_RANGE_CNT[5])
                            OAM_TIME_INDEX <= OAM_RANGE[NEW_RANGE_CNT[4:0]];
                    end            
                    OBJ_TIME_DONE <= 0;
                end else
                    OBJ_TIME_DONE <= 1;
            end
                
            // Fetch sprite tile (from OBJ_VRAM_ADDR) while OBJ_TIME==1 and OBJ_TIME_DONE==0
            if (OBJ_FETCH && ~FORCE_BLANK)
            if (~OBJ_TIME_DONE) begin
                if (~H_CNT[0])
                    SPR_TILE_DATA_TEMP <= {FlipPlane(VRAM_DBI, OBJ_TILE_HFLIP),
                                            FlipPlane(VRAM_DAI, OBJ_TILE_HFLIP)};
                else begin
                    // data for one of 34 8-pixel slivers
                    SPR_TILE_DATA <= {FlipPlane(VRAM_DBI, OBJ_TILE_HFLIP),
                                FlipPlane(VRAM_DAI, OBJ_TILE_HFLIP),
                                SPR_TILE_DATA_TEMP[15:0]};  // 32 bits
                    SPR_TILE_X <= OBJ_TILE_X;
                    SPR_TILE_PAL <= OBJ_TILE_PAL;
                    SPR_TILE_PRIO <= OBJ_TILE_PRIO;
                end
            end
            
            if (OBJ_FETCH && ~OBJ_TIME_DONE && H_CNT[0])
                OBJ_TIME_SAVE <= 1;
            else if (OBJ_TIME_SAVE && H_CNT[0])
                OBJ_TIME_SAVE <= 0;
        end
    end
end

assign OBJ_VRAM_ADDR = {OBJADDR, 13'b0} + {1'b0, OBJ_TILE_GAP} + 
                                       {4'b0, OBJ_TILE_ROW, OBJ_TILE_COL, H_CNT[0], OBJ_TILE_LINE};

// Sprites time engine
// write SPR_TILE_DATA into sprite buffer
always @(posedge CLK) begin : write_spr_buf
    reg [8:0] X;
    reg [3:0] PIX_DATA;

    if (~RST_N) begin
        SPR_PIX_WE_A <= 0;
        SPR_PIX_D <= 0;
        SPR_PIX_ADDR_A <= 0;
        SPR_PIX_CNT <= 0;
    end else begin 
        SPR_PIX_WE_A <= 0;
        if (OBJ_TIME_SAVE && ~CLK_CNT[2]) begin
            X = SPR_TILE_X + 9'(SPR_PIX_CNT);
            case (SPR_PIX_CNT)
            3'd0: PIX_DATA = {SPR_TILE_DATA[31-0], SPR_TILE_DATA[23-0],  SPR_TILE_DATA[15-0],  SPR_TILE_DATA[7-0]};
            3'd1: PIX_DATA = {SPR_TILE_DATA[31-1], SPR_TILE_DATA[23-1],  SPR_TILE_DATA[15-1],  SPR_TILE_DATA[7-1]};
            3'd2: PIX_DATA = {SPR_TILE_DATA[31-2], SPR_TILE_DATA[23-2],  SPR_TILE_DATA[15-2],  SPR_TILE_DATA[7-2]};
            3'd3: PIX_DATA = {SPR_TILE_DATA[31-3], SPR_TILE_DATA[23-3],  SPR_TILE_DATA[15-3],  SPR_TILE_DATA[7-3]};
            3'd4: PIX_DATA = {SPR_TILE_DATA[31-4], SPR_TILE_DATA[23-4],  SPR_TILE_DATA[15-4],  SPR_TILE_DATA[7-4]};
            3'd5: PIX_DATA = {SPR_TILE_DATA[31-5], SPR_TILE_DATA[23-5],  SPR_TILE_DATA[15-5],  SPR_TILE_DATA[7-5]};
            3'd6: PIX_DATA = {SPR_TILE_DATA[31-6], SPR_TILE_DATA[23-6],  SPR_TILE_DATA[15-6],  SPR_TILE_DATA[7-6]};
            default: PIX_DATA = {SPR_TILE_DATA[31-7], SPR_TILE_DATA[23-7],  SPR_TILE_DATA[15-7],  SPR_TILE_DATA[7-7]};
            endcase;
            
            if (~X[8] && PIX_DATA != 4'b0) begin
                SPR_PIX_D <= {SPR_TILE_PRIO, SPR_TILE_PAL, PIX_DATA};
                SPR_PIX_ADDR_A <= X[7:0];
                SPR_PIX_WE_A <= 1;
            end
            SPR_PIX_CNT <= SPR_PIX_CNT + 1;
        end
    end
end

// SPR_BUF
// Word: {SPR_TILE_PRIO 2, SPR_TILE_PAL 3, PIX_DATA 4}
// Port A: 256 * 9 bits, for writing
// Port B: 256 * 9 bits, for reading and clearing
// ppusprbuf spr_buf (
//   .clock(CLK),
//   .data_a(SPR_PIX_D), .address_a(SPR_PIX_ADDR_A), 
//   .wren_a(SPR_PIX_WE_A), .ds_a(SPR_PIX_DS_A), .q_a(),
//   .data_b(0), .address_b(SPR_PIXEL_X), .wren_b(SPR_PIX_WE_B), .q_b(SPR_PIX_Q)
// );

reg [8:0] spr_buf [256];
always @(posedge CLK) begin     // port A
    if (SPR_PIX_WE_A)
        spr_buf[SPR_PIX_ADDR_A] <= SPR_PIX_D;
end
always @(posedge CLK) begin     // port B
    if (SPR_PIX_WE_B)
        spr_buf[SPR_PIXEL_X] <= 0;
    else
        SPR_PIX_Q <= spr_buf[SPR_PIXEL_X];
end

// SPR_BUF : entity work.dpram generic map(8,9)
// port map(
// 	clock			=> CLK,
// 	data_a		=> SPR_PIX_D,
// 	address_a	=> SPR_PIX_ADDR_A,
// 	address_b	=> std_logic_vector(SPR_PIXEL_X),
// 	wren_a		=> SPR_PIX_WE_A,
// 	wren_b		=> SPR_PIX_WE_B,
// 	q_b			=> SPR_PIX_Q
// );
assign SPR_PIX_WE_B = SPR_GET_PIXEL && DOT_CLKR_CE ? 1 : 0;

always @(posedge CLK) begin
    if (~RST_N) begin
        SPR_PIX_DATA_BUF <= 0;
        SPR_PIXEL_X <= 0;
    end else begin 
        if (ENABLE && DOT_CLKR_CE) begin
            if (H_CNT == LAST_DOT && V_CNT >= 1 && V_CNT <= LAST_VIS_LINE)
                SPR_PIXEL_X <= 0;

            if (SPR_GET_PIXEL) begin
                SPR_PIX_DATA_BUF <= SPR_PIX_Q;
                
                if (M7SEL[7:6] == 2'b10 && M7_TILE_OUTSIDE)
                    M7_PIX_DATA <= 0;
                else  
                    M7_PIX_DATA <= VRAM_DBI;
            
                SPR_PIXEL_X <= SPR_PIXEL_X + 1;
            end
        end
    end
end


///////////////////////////////////////////////////////////////////////////////
// 4 - RENDERER
///////////////////////////////////////////////////////////////////////////////

wire [3:0] NN1 = ~(({1'b0,GET_PIXEL_X[2:0]}) + ({1'b0,BG_HOFS[BG1][2:0]}));

// Generate background pixel data from tiles
// always @(negedge RST_N, negedge DOT_CLK) begin : bg_pixel_gen
always @(posedge CLK) begin : bg_pixel_gen
    reg [3:0] N1, N2, N3, N4;

    if (~RST_N) begin
        GET_PIXEL_X <= 8'b0;
        BG1_PIX_DATA <= 12'b0;
        BG2_PIX_DATA <= 8'b0;
        BG3_PIX_DATA <= 6'b0;
        BG4_PIX_DATA <= 6'b0;
        SPR_PIX_DATA <= 9'b0;
    end else begin
        if (ENABLE && DOT_CLKR_CE) begin
            if (H_CNT == LAST_DOT && V_CNT >= 1 && V_CNT <= LAST_VIS_LINE) begin
                GET_PIXEL_X <= 8'b0;
                BG_MOSAIC_X <= 4'b0;
            end

            if (BG_GET_PIXEL) begin
                if (~BG_MOSAIC_EN[BG1] || BG_MOSAIC_X == 0) begin
                    if (BG_MODE != 3'b111) begin
                        N1 =  ~(({1'b0, GET_PIXEL_X[2:0]}) + ({1'b0, BG_HOFS[BG1][2:0]}));
                        BG1_PIX_DATA <= {BG_TILES_ATR[N1[3:3]][BG1],
                                            BG_TILES_PLANES[N1[3:3]][7][N1[2:0]],
                                            BG_TILES_PLANES[N1[3:3]][6][N1[2:0]],
                                            BG_TILES_PLANES[N1[3:3]][5][N1[2:0]],
                                            BG_TILES_PLANES[N1[3:3]][4][N1[2:0]],
                                            BG_TILES_PLANES[N1[3:3]][3][N1[2:0]],
                                            BG_TILES_PLANES[N1[3:3]][2][N1[2:0]],
                                            BG_TILES_PLANES[N1[3:3]][1][N1[2:0]],
                                            BG_TILES_PLANES[N1[3:3]][0][N1[2:0]]};
                    end else
                        BG1_PIX_DATA <= {4'b0, M7_PIX_DATA};
                end

                if (BG_MOSAIC_EN[BG2] == 1'b0 || BG_MOSAIC_X == 0) begin
                    if (BG_MODE != 3'b111) begin
                        N2 =  ~(({1'b0,GET_PIXEL_X[2:0]}) + ({1'b0,BG_HOFS[BG2][2:0]}));
                        BG2_PIX_DATA <= {BG_TILES_ATR[N2[3:3]][BG2], 
                                            BG_TILES_PLANES[N2[3:3]][11][N2[2:0]], 
                                            BG_TILES_PLANES[N2[3:3]][10][N2[2:0]], 
                                            BG_TILES_PLANES[N2[3:3]][9][N2[2:0]], 
                                            BG_TILES_PLANES[N2[3:3]][8][N2[2:0]]};
                    end else 
                        BG2_PIX_DATA <= M7_PIX_DATA;
                end

                if (BG_MOSAIC_EN[BG3] == 1'b0 || BG_MOSAIC_X == 0) begin
                    N3 =  ~(({1'b0,GET_PIXEL_X[2:0]}) + ({1'b0,BG_HOFS[BG3][2:0]}));
                    BG3_PIX_DATA <= {BG_TILES_ATR[N3[3:3]][BG3], 
                                        BG_TILES_PLANES[N3[3:3]][5][N3[2:0]], 
                                        BG_TILES_PLANES[N3[3:3]][4][N3[2:0]]};
                end

                if (BG_MOSAIC_EN[BG4] == 1'b0 || BG_MOSAIC_X == 0) begin
                    N4 =  ~(({1'b0,GET_PIXEL_X[2:0]}) + ({1'b0,BG_HOFS[BG4][2:0]}));
                    BG4_PIX_DATA <= {BG_TILES_ATR[N4[3:3]][BG4], 
                                        BG_TILES_PLANES[N4[3:3]][7][N4[2:0]],
                                        BG_TILES_PLANES[N4[3:3]][6][N4[2:0]]};
                end

                GET_PIXEL_X <= GET_PIXEL_X + 1;

                if (BG_MOSAIC_X == (MOSAIC_SIZE)) 
                    BG_MOSAIC_X <= 4'b0;
                else 
                    BG_MOSAIC_X <= BG_MOSAIC_X + 1;

                SPR_PIX_DATA <= SPR_PIX_DATA_BUF;
            end
        end
    end
end

// Global signals in pixel_render_addr_gen
// reg MAIN_EN_G, SUB_EN_G, MATHg;
// reg MAIN_DCM_G, SUB_DCM_G;
// reg SUB_BD_G;
reg DCM, BD, MATH;        // DCM: direct color mode
reg MAIN_EN, SUB_EN, SUB_MATH_EN, MATH_EN;
reg [4:0] COLOR_MASK;

// nand2mario: this does NOT apply anymore
/*
Timings for main/sub frame add-sub pipeline:

CLK     /‾‾‾0‾‾‾\_______/‾‾‾1‾‾‾\_______/
dotclk   /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/
h_cnt    |                x              | x+1

cycle 0
- put sub-frame pixel address in CGRAM_FETCH_ADDR and fetch CGRAM_Q
- combine CGRAM_Q (from last cycle 1) and SUB_MATH_R/G/B, to output 
  MAIN_R/G/B and SUB_R/G/B
- apply brighness to SUB_R/G/B (from last cycle 0) to output COLOR_OUT
cycle 1
- put main-frame pixel address in CGRAM_FETCH_ADDR and fetch CGRAM_Q
- calc SUB_MATH_R/G/B from CGRAM_Q
- apply brightness to MAIN_R/G/B to output COLOR_OUT

COLOR_OUT is available 2 H_CNT later.
*/
always @* begin : pixel_render_addr_gen
    reg [7:0] PAL1, PAL2, PAL3, PAL4, OBJ_PAL;
    reg PRIO1, PRIO2, PRIO3, PRIO4;
    reg [3:0] BGPR0EN, BGPR1EN;
    reg OBJPR0EN, OBJPR1EN, OBJPR2EN, OBJPR3EN;
    reg [1:0] OBJ_PRIO;
    reg [5:0] win1, win2, win1en, win2en, bglog0, bglog1, winres;
    reg [4:0] main_dis, sub_dis;
    // reg [4:0] MATH_R, MATH_G, MATH_B;
    // reg half; 

    integer i;

    if (WINDOW_X >= WH0 && WINDOW_X <= WH1) 
        win1 =  ~({WOBJSEL[4],WOBJSEL[0],W34SEL[4],W34SEL[0],W12SEL[4],W12SEL[0]});   
    else 
        win1 = {WOBJSEL[4],WOBJSEL[0],W34SEL[4],W34SEL[0],W12SEL[4],W12SEL[0]};
    if (WINDOW_X >= WH2 && WINDOW_X <= WH3) 
        win2 =  ~({WOBJSEL[6],WOBJSEL[2],W34SEL[6],W34SEL[2],W12SEL[6],W12SEL[2]});
    else 
        win2 = {WOBJSEL[6],WOBJSEL[2],W34SEL[6],W34SEL[2],W12SEL[6],W12SEL[2]};
    win1en = {WOBJSEL[5],WOBJSEL[1],W34SEL[5],W34SEL[1],W12SEL[5],W12SEL[1]};
    win2en = {WOBJSEL[7],WOBJSEL[3],W34SEL[7],W34SEL[3],W12SEL[7],W12SEL[3]};
    bglog0 = {WOBJLOG[2],WOBJLOG[0],WBGLOG[6],WBGLOG[4],WBGLOG[2],WBGLOG[0]};
    bglog1 = {WOBJLOG[3],WOBJLOG[1],WBGLOG[7],WBGLOG[5],WBGLOG[3],WBGLOG[1]};

    for (i=0; i <= 5; i = i + 1) begin
        if (~win1en[i] && ~win2en[i]) 
            winres[i] = 1'b0;
        else if (win1en[i] && ~win2en[i]) 
            winres[i] = win1[i];
        else if (~win1en[i] && win2en[i]) 
            winres[i] = win2[i];
        else begin
            if (~bglog1[i] && ~bglog0[i]) 
                winres[i] = win1[i] | win2[i];
            else if (~bglog1[i] && bglog0[i]) 
                winres[i] = win1[i] & win2[i];
            else if (bglog1[i] && ~bglog0[i]) 
                winres[i] = win1[i] ^ win2[i];
            else 
                winres[i] =  ~(win1[i] ^ win2[i]);
        end
    end

    for (i=0; i <= 4; i = i + 1) begin
        main_dis[i] = winres[i] & TMW[i];
        sub_dis[i] = winres[i] & TSW[i];
    end

    case (CGWSEL[7:6])
    2'b00 : MAIN_EN = 1'b1;
    2'b01 : MAIN_EN = winres[5];
    2'b10 : MAIN_EN =  ~winres[5];
    2'b11 : MAIN_EN = 1'b0;
    default : ;
    endcase
    case (CGWSEL[5:4])
    2'b00 : SUB_EN = 1'b1;
    2'b01 : SUB_EN = winres[5];
    2'b10 : SUB_EN =  ~winres[5];
    2'b11 : SUB_EN = 1'b0;
    default : ;
    endcase

    BD = 0;
    DCM= 0;
    MATH = 0;

    OBJ_PRIO = SPR_PIX_DATA[8:7];

    PRIO1 = BG1_PIX_DATA[11];
    PRIO2 = BG2_PIX_DATA[7];
    PRIO3 = BG3_PIX_DATA[5];
    PRIO4 = BG4_PIX_DATA[5];

    if (DOT_CLK) begin
        BGPR0EN[0] = TS[0] & ( ~sub_dis[0]) & ( ~PRIO1) & BG_EN[0];
        BGPR0EN[1] = TS[1] & ( ~sub_dis[1]) & ( ~PRIO2) & BG_EN[1];
        BGPR0EN[2] = TS[2] & ( ~sub_dis[2]) & ( ~PRIO3) & BG_EN[2];
        BGPR0EN[3] = TS[3] & ( ~sub_dis[3]) & ( ~PRIO4) & BG_EN[3];
        BGPR1EN[0] = TS[0] & ( ~sub_dis[0]) & (PRIO1) & BG_EN[0];
        BGPR1EN[1] = TS[1] & ( ~sub_dis[1]) & (PRIO2) & BG_EN[1];
        BGPR1EN[2] = TS[2] & ( ~sub_dis[2]) & (PRIO3) & BG_EN[2];
        BGPR1EN[3] = TS[3] & ( ~sub_dis[3]) & (PRIO4) & BG_EN[3];
        OBJPR0EN = TS[4] & ( ~sub_dis[4]) & ( ~OBJ_PRIO[0]) & ( ~OBJ_PRIO[1]) & BG_EN[4];
        OBJPR1EN = TS[4] & ( ~sub_dis[4]) & (OBJ_PRIO[0]) & ( ~OBJ_PRIO[1]) & BG_EN[4];
        OBJPR2EN = TS[4] & ( ~sub_dis[4]) & ( ~OBJ_PRIO[0]) & (OBJ_PRIO[1]) & BG_EN[4];
        OBJPR3EN = TS[4] & ( ~sub_dis[4]) & (OBJ_PRIO[0]) & (OBJ_PRIO[1]) & BG_EN[4];
    end else begin
        BGPR0EN[0] = TM[0] & ( ~main_dis[0]) & ( ~PRIO1) & BG_EN[0];
        BGPR0EN[1] = TM[1] & ( ~main_dis[1]) & ( ~PRIO2) & BG_EN[1];
        BGPR0EN[2] = TM[2] & ( ~main_dis[2]) & ( ~PRIO3) & BG_EN[2];
        BGPR0EN[3] = TM[3] & ( ~main_dis[3]) & ( ~PRIO4) & BG_EN[3];
        BGPR1EN[0] = TM[0] & ( ~main_dis[0]) & (PRIO1) & BG_EN[0];
        BGPR1EN[1] = TM[1] & ( ~main_dis[1]) & (PRIO2) & BG_EN[1];
        BGPR1EN[2] = TM[2] & ( ~main_dis[2]) & (PRIO3) & BG_EN[2];
        BGPR1EN[3] = TM[3] & ( ~main_dis[3]) & (PRIO4) & BG_EN[3];
        OBJPR0EN = TM[4] & ( ~main_dis[4]) & ( ~OBJ_PRIO[0]) & ( ~OBJ_PRIO[1]) & BG_EN[4];
        OBJPR1EN = TM[4] & ( ~main_dis[4]) & (OBJ_PRIO[0]) & ( ~OBJ_PRIO[1]) & BG_EN[4];
        OBJPR2EN = TM[4] & ( ~main_dis[4]) & ( ~OBJ_PRIO[0]) & (OBJ_PRIO[1]) & BG_EN[4];
        OBJPR3EN = TM[4] & ( ~main_dis[4]) & (OBJ_PRIO[0]) & (OBJ_PRIO[1]) & BG_EN[4];
    end

    if (BG_MODE == 3'b000) begin    // MODE0
        if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR3EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end else if (BG1_PIX_DATA[1:0] != 2'b00 && BGPR1EN[0]) begin
            CGRAM_FETCH_ADDR = {3'b000,BG1_PIX_DATA[10:8],BG1_PIX_DATA[1:0]};
            MATH = CGADSUB[0];
        end else if (BG2_PIX_DATA[1:0] != 2'b00 && BGPR1EN[1]) begin
            CGRAM_FETCH_ADDR = {3'b001,BG2_PIX_DATA[6:4],BG2_PIX_DATA[1:0]};
            MATH = CGADSUB[1];
        end else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR2EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end else if (BG1_PIX_DATA[1:0] != 2'b00 && BGPR0EN[0]) begin
            CGRAM_FETCH_ADDR = {3'b000,BG1_PIX_DATA[10:8],BG1_PIX_DATA[1:0]};
            MATH = CGADSUB[0];
        end else if (BG2_PIX_DATA[1:0] != 2'b00 && BGPR0EN[1]) begin
            CGRAM_FETCH_ADDR = {3'b001,BG2_PIX_DATA[6:4],BG2_PIX_DATA[1:0]};
            MATH = CGADSUB[1];
        end else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR1EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end else if (BG3_PIX_DATA[1:0] != 2'b00 && BGPR1EN[2]) begin
            CGRAM_FETCH_ADDR = {3'b010,BG3_PIX_DATA[4:2],BG3_PIX_DATA[1:0]};
            MATH = CGADSUB[2];
        end else if (BG4_PIX_DATA[1:0] != 2'b00 && BGPR1EN[3]) begin
            CGRAM_FETCH_ADDR = {3'b011,BG4_PIX_DATA[4:2],BG4_PIX_DATA[1:0]};
            MATH = CGADSUB[3];
        end else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR0EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end else if (BG3_PIX_DATA[1:0] != 2'b00 && BGPR0EN[2]) begin
            CGRAM_FETCH_ADDR = {3'b010,BG3_PIX_DATA[4:2],BG3_PIX_DATA[1:0]};
            MATH = CGADSUB[2];
        end else if (BG4_PIX_DATA[1:0] != 2'b00 && BGPR0EN[3]) begin
            CGRAM_FETCH_ADDR = {3'b011,BG4_PIX_DATA[4:2],BG4_PIX_DATA[1:0]};
            MATH = CGADSUB[3];
        end else begin
            CGRAM_FETCH_ADDR = 8'b0;
            MATH = CGADSUB[5];
            BD = 1'b1;
        end

    end else if (BG_MODE == 3'b001) begin   // MODE1
        if (BG3_PIX_DATA[1:0] != 2'b00 && BGPR1EN[2] && BG3PRIO) begin
            CGRAM_FETCH_ADDR = {3'b000,BG3_PIX_DATA[4:2],BG3_PIX_DATA[1:0]};
            MATH = CGADSUB[2];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR3EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[3:0] != 4'b0000 && BGPR1EN[0]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[3:0]};
            MATH = CGADSUB[0];
        end
        else if (BG2_PIX_DATA[3:0] != 4'b0000 && BGPR1EN[1]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG2_PIX_DATA[6:4],BG2_PIX_DATA[3:0]};
            MATH = CGADSUB[1];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR2EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[3:0] != 4'b0000 && BGPR0EN[0]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[3:0]};
            MATH = CGADSUB[0];
        end
        else if (BG2_PIX_DATA[3:0] != 4'b0000 && BGPR0EN[1]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG2_PIX_DATA[6:4],BG2_PIX_DATA[3:0]};
            MATH = CGADSUB[1];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR1EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG3_PIX_DATA[1:0] != 2'b00 && BGPR1EN[2] && BG3PRIO == 1'b0) begin
            CGRAM_FETCH_ADDR = {3'b000,BG3_PIX_DATA[4:2],BG3_PIX_DATA[1:0]};
            MATH = CGADSUB[2];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR0EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG3_PIX_DATA[1:0] != 2'b00 && BGPR0EN[2]) begin
            CGRAM_FETCH_ADDR = {3'b000,BG3_PIX_DATA[4:2],BG3_PIX_DATA[1:0]};
            MATH = CGADSUB[2];
        end
        else begin
            CGRAM_FETCH_ADDR = 8'b0;
            MATH = CGADSUB[5];
            BD = 1'b1;
        end

    end else if (BG_MODE == 3'b010) begin   // MODE2
        if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR3EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[3:0] != 4'b0000 && BGPR1EN[0]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[3:0]};
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR2EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[3:0] != 4'b0000 && BGPR1EN[1]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG2_PIX_DATA[6:4],BG2_PIX_DATA[3:0]};
            MATH = CGADSUB[1];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR1EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[3:0] != 4'b0000 && BGPR0EN[0]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[3:0]};
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR0EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[3:0] != 4'b0000 && BGPR0EN[1]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG2_PIX_DATA[6:4],BG2_PIX_DATA[3:0]};
            MATH = CGADSUB[1];
        end
        else begin
            CGRAM_FETCH_ADDR = 8'b0;
            MATH = CGADSUB[5];
            BD = 1'b1;
        end

    end else if (BG_MODE == 3'b011) begin       // MODE3
        if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR3EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:0] != 8'b00000000 && BGPR1EN[0]) begin
            CGRAM_FETCH_ADDR = BG1_PIX_DATA[7:0];
            DCM = CGWSEL[0];
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR2EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[3:0] != 4'b0000 && BGPR1EN[1]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG2_PIX_DATA[6:4],BG2_PIX_DATA[3:0]};
            MATH = CGADSUB[1];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR1EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:0] != 8'b00000000 && BGPR0EN[0]) begin
            CGRAM_FETCH_ADDR = BG1_PIX_DATA[7:0];
            DCM = CGWSEL[0];
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR0EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[3:0] != 4'b0000 && BGPR0EN[1]) begin
            CGRAM_FETCH_ADDR = {1'b0,BG2_PIX_DATA[6:4],BG2_PIX_DATA[3:0]};
            MATH = CGADSUB[1];
        end
        else begin
            CGRAM_FETCH_ADDR = 8'b0;
            MATH = CGADSUB[5];
            BD = 1'b1;
        end
    
    end else if (BG_MODE == 3'b100) begin   // MODE4
        if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR3EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:0] != 8'b00000000 && BGPR1EN[0]) begin
            CGRAM_FETCH_ADDR = BG1_PIX_DATA[7:0];
            DCM = CGWSEL[0];
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR2EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[1:0] != 2'b00 && BGPR1EN[1]) begin
            CGRAM_FETCH_ADDR = {3'b000,BG2_PIX_DATA[6:4],BG2_PIX_DATA[1:0]};
            MATH = CGADSUB[1];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR1EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:0] != 8'b00000000 && BGPR0EN[0]) begin
            CGRAM_FETCH_ADDR = BG1_PIX_DATA[7:0];
            DCM = CGWSEL[0];
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR0EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[1:0] != 2'b00 && BGPR0EN[1]) begin
            CGRAM_FETCH_ADDR = {3'b000,BG2_PIX_DATA[6:4],BG2_PIX_DATA[1:0]};
            MATH = CGADSUB[1];
        end
        else begin
            CGRAM_FETCH_ADDR = 8'b0;
            MATH = CGADSUB[5];
            BD = 1'b1;
        end

    end else if (BG_MODE == 3'b101) begin       // MODE5
        if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR3EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:4] != 4'b0000 && BGPR1EN[0] && DOT_CLK) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[3:0]};
        end
        else if (BG1_PIX_DATA[7:4] != 4'b0000 && BGPR1EN[0] && ~DOT_CLK) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[7:4]};
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR2EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[3:2] != 2'b00 && BGPR1EN[1] && DOT_CLK) begin
            CGRAM_FETCH_ADDR = {3'b000,BG2_PIX_DATA[6:4],BG2_PIX_DATA[1:0]};
        end
        else if (BG2_PIX_DATA[3:2] != 2'b00 && BGPR1EN[1] && ~DOT_CLK) begin
            CGRAM_FETCH_ADDR = {3'b000,BG2_PIX_DATA[6:4],BG2_PIX_DATA[3:2]};
            MATH = CGADSUB[1];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR1EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:4] != 4'b0000 && BGPR0EN[0] && DOT_CLK) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[3:0]};
        end
        else if (BG1_PIX_DATA[7:4] != 4'b0000 && BGPR0EN[0] && ~DOT_CLK) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[7:4]};
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR0EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[3:2] != 2'b00 && BGPR0EN[1] && DOT_CLK) begin
            CGRAM_FETCH_ADDR = {3'b000,BG2_PIX_DATA[6:4],BG2_PIX_DATA[1:0]};
        end
        else if (BG2_PIX_DATA[3:2] != 2'b00 && BGPR0EN[1] && ~DOT_CLK) begin
            CGRAM_FETCH_ADDR = {3'b000,BG2_PIX_DATA[6:4],BG2_PIX_DATA[3:2]};
            MATH = CGADSUB[1];
        end
        else begin
            CGRAM_FETCH_ADDR = 8'b0;
            MATH = CGADSUB[5];
            BD = 1'b1;
        end

    end else if (BG_MODE == 3'b110) begin       // MODE6
        if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR3EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:4] != 4'b0000 && BGPR1EN[0] && DOT_CLK) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[3:0]};
        end
        else if (BG1_PIX_DATA[7:4] != 4'b0000 && BGPR1EN[0] && ~DOT_CLK) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[7:4]};
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR2EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR1EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:4] != 4'b0000 && BGPR0EN[0] && DOT_CLK) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[3:0]};
        end
        else if (BG1_PIX_DATA[7:4] != 4'b0000 && BGPR0EN[0] && ~DOT_CLK) begin
            CGRAM_FETCH_ADDR = {1'b0,BG1_PIX_DATA[10:8],BG1_PIX_DATA[7:4]};
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR0EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else begin
            CGRAM_FETCH_ADDR = 8'b0;
            MATH = CGADSUB[5];
            BD = 1'b1;
        end

    end else begin  // MODE7      
        if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR3EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR2EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[6:0] != 7'b0000000 && BGPR1EN[1] && M7EXTBG)  begin
            CGRAM_FETCH_ADDR = {1'b0,BG2_PIX_DATA[6:0]};
            MATH = CGADSUB[1];
        end else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR1EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG1_PIX_DATA[7:0] != 8'b00000000 && BGPR0EN[0]) begin
            CGRAM_FETCH_ADDR = BG1_PIX_DATA[7:0];
            DCM = CGWSEL[0];
            MATH = CGADSUB[0];
        end
        else if (SPR_PIX_DATA[3:0] != 4'b0000 && OBJPR0EN) begin
            CGRAM_FETCH_ADDR = {1'b1,SPR_PIX_DATA[6:0]};
            MATH = CGADSUB[4] & SPR_PIX_DATA[6];
        end
        else if (BG2_PIX_DATA[6:0] != 7'b0000000 && BGPR0EN[1] && M7EXTBG) begin 
            CGRAM_FETCH_ADDR = {1'b0,BG2_PIX_DATA[6:0]};
            MATH = CGADSUB[1];
        end else begin
            CGRAM_FETCH_ADDR = 8'b0;
            MATH = CGADSUB[5];
            BD = 1'b1;
        end
    end
end

// Pixel renderer: combine BGx_PIX_DATA and CRAM_MAIN_DATA(SPR_PIX_DATA) according to the mode 
// we are in to generate pixel color (to CGRAM_FETCH_ADDR/CRAM_SUB_ADDR).

reg [14:0] MAIN_COLOR_W;

// always @(negedge RST_N, negedge DOT_CLK) begin : pixel_render
always @(posedge CLK) begin : pixel_render
    reg [14:0] MAIN_COLOR, SUB_COLOR;
    reg HALF;
    reg [14:0] COLOR;
    reg [4:0] MATH_R, MATH_G, MATH_B;

    if (~RST_N) begin
        WINDOW_X <= 0;
        SUB_R <= 0;
        SUB_G <= 0;
        SUB_B <= 0;
        MAIN_R <= 0;
        MAIN_G <= 0;
        MAIN_B <= 0;
        SUB_BD <= 0;
        PREV_COLOR <= 0;
        SUB_MATH_R <= 0;
        SUB_MATH_G <= 0;
        SUB_MATH_B <= 0;       
    end else begin
        if (ENABLE) begin
            if (BG_GET_PIXEL && DOT_CLKR_CE) 
                WINDOW_X <= GET_PIXEL_X;

            if (H_CNT == LAST_DOT && DOT_CLKR_CE)
                PREV_COLOR <= 0;

            if (BG_MATH) begin
                if (DOT_CLKF_CE)
                    SUB_BD <= BD;

                if (DOT_CLKR_CE) begin
                    MATH_EN = MATH;
                    HALF = CGADSUB[6] && MAIN_EN && ~(SUB_BD && CGWSEL[1]);
                    SUB_MATH_EN = CGWSEL[1] && ~SUB_BD;

                    if (~MAIN_EN)
                        COLOR_MASK = 0;
                    else
                        COLOR_MASK = 5'b11111;
                end

                if (DOT_CLKF_CE || DOT_CLKR_CE) begin
                    if (DCM)    // mode 3 direct color mode
                        COLOR = GetDCM(BG1_PIX_DATA[10:0]);
                    else 
                        COLOR = CGRAM_Q;
                    PREV_COLOR <= COLOR;

                    if (FORCE_BLANK) begin
                        MATH_R = 0;
                        MATH_G = 0;
                        MATH_B = 0;
                    end else if (PSEUDOHIRES && BLEND) begin
                        MATH_R = AddSub(COLOR[4:0] & COLOR_MASK, PREV_COLOR[4:0] & COLOR_MASK, 1, 1);
                        MATH_G = AddSub(COLOR[9:5] & COLOR_MASK, PREV_COLOR[9:5] & COLOR_MASK, 1, 1);
                        MATH_B = AddSub(COLOR[14:10] & COLOR_MASK, PREV_COLOR[14:10] & COLOR_MASK, 1, 1);
                    end else if (MATH_EN && SUB_EN) begin
                        if (SUB_MATH_EN) begin
                            MATH_R = AddSub(COLOR[4:0] & COLOR_MASK, PREV_COLOR[4:0], ~CGADSUB[7], HALF);
                            MATH_G = AddSub(COLOR[9:5] & COLOR_MASK, PREV_COLOR[9:5], ~CGADSUB[7], HALF);
                            MATH_B = AddSub(COLOR[14:10] & COLOR_MASK, PREV_COLOR[14:10], ~CGADSUB[7], HALF);
                        end else begin
                            MATH_R = AddSub(COLOR[4:0] & COLOR_MASK, SUBCOLBD[4:0], ~CGADSUB[7], HALF);
                            MATH_G = AddSub(COLOR[9:5] & COLOR_MASK, SUBCOLBD[9:5], ~CGADSUB[7], HALF);
                            MATH_B = AddSub(COLOR[14:10] & COLOR_MASK, SUBCOLBD[14:10], ~CGADSUB[7], HALF);
                        end
                    end else begin
                        MATH_R = COLOR[4:0] & COLOR_MASK;
                        MATH_G = COLOR[9:5] & COLOR_MASK;
                        MATH_B = COLOR[14:10] & COLOR_MASK;
                    end

                    if (DOT_CLKF_CE) begin
                        SUB_MATH_R <= MATH_R;
                        SUB_MATH_G <= MATH_G;
                        SUB_MATH_B <= MATH_B;
                    end

                    if (DOT_CLKR_CE) begin
                        // combine CGRAM_Q from last cycle 1 and SUB_MATH_R/G/B, to output MATH_R/G/B and SUB_R/G/B
                        MAIN_R <= MATH_R;
                        MAIN_G <= MATH_G;
                        MAIN_B <= MATH_B;

                        if (HIRES || (PSEUDOHIRES && ~BLEND)) begin
                            SUB_R <= SUB_MATH_R;
                            SUB_G <= SUB_MATH_G;
                            SUB_B <= SUB_MATH_B;
                        end else begin
                            SUB_R <= MATH_R;
                            SUB_G <= MATH_G;
                            SUB_B <= MATH_B;
                        end
                    end

                end
            end
        end
    end
end

// scan_screen: increment X, Y, and finally generate COLOR_OUT
always @(posedge CLK) begin : scan_screen
    if (~RST_N) begin
        OUT_Y <= 8'b0;
        OUT_X <= 8'b0;
    end else begin
        if (ENABLE && DOT_CLKR_CE) begin
            if (H_CNT == LAST_DOT && V_CNT >= 1 && V_CNT <= LAST_VIS_LINE) 
                OUT_Y <= OUT_Y + 1;
            if (H_CNT == LAST_DOT && V_CNT == LAST_LINE) 
                OUT_Y <= 8'b0;
            if (BG_MATH) 
                OUT_X <= WINDOW_X;
            FRAME_OUT <= BG_OUT;
        end
    end
end

// output COLOR_OUT using last H_CNT's SUB_R/G/B
assign COLOR_OUT = DOT_CLK ? {Bright(MB, SUB_B), Bright(MB, SUB_G), Bright(MB, SUB_R)} :
                   {Bright(MB, MAIN_B), Bright(MB, MAIN_G), Bright(MB, MAIN_R)};

assign DOTCLK = DOT_CLK;
assign HBLANK = IN_HBL;
assign VBLANK = IN_VBL;
assign HIGH_RES = HIRES || (PSEUDOHIRES && ~BLEND);

// assign FRAME_OUT = BG_OUT;
assign X_OUT = {OUT_X, DOT_CLK};
assign Y_OUT = {FIELD, OUT_Y};
assign V224 =  ~OVERSCAN;

assign FIELD_OUT = FIELD;
assign INTERLACE = BGINTERLACE;

endmodule
