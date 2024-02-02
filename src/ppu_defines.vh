// Converted from PPU_PKG.vhd

parameter [8:0] DOT_NUM = 9'b101010100;         // 340 
parameter [8:0] LINE_NUM_NTSC = 9'b100000110;   // 262 
parameter [8:0] LINE_NUM_PAL = 9'b100111000;    // 312 

parameter [8:0] LINE_VSYNC_NTSC = 9'b011101100; // 236
parameter [8:0] LINE_VSYNC_PAL = 9'b100000100;  // 260

parameter [8:0] HSYNC_START = 9'b100101000;     // 296
parameter [8:0] VSYNC_I_HSTART = 9'b001111110;  // 126

parameter [1:0] BG1 = 0, BG2 = 1, BG3 = 2, BG4 = 3;

parameter [3:0] BF_TILEMAP = 0, BF_TILEDAT0 = 1, BF_TILEDAT1 = 2,
                BF_TILEDAT2 = 3, BF_TILEDAT3 = 4, BF_TILEDATM7 = 5,
                BF_OPT0 = 6, BF_OPT1 = 7, BF_MODE7 = 8;
typedef struct packed {
    logic [1:0] BG;
    logic [3:0] MODE;
} BgFetch_r;

parameter BgFetch_r BF_TBL [0:7][0:7] = '{
'{{BG4,BF_TILEMAP},  {BG3,BF_TILEMAP},  {BG2,BF_TILEMAP},  {BG1,BF_TILEMAP},  {BG4,BF_TILEDAT0}, {BG3,BF_TILEDAT0}, {BG2,BF_TILEDAT0}, {BG1,BF_TILEDAT0}},// MODE 0
'{{BG3,BF_TILEMAP},  {BG2,BF_TILEMAP},  {BG1,BF_TILEMAP},  {BG3,BF_TILEDAT0}, {BG2,BF_TILEDAT0}, {BG2,BF_TILEDAT1}, {BG1,BF_TILEDAT0}, {BG1,BF_TILEDAT1}},// MODE 1
'{{BG2,BF_TILEMAP},  {BG1,BF_TILEMAP},  {BG3,BF_OPT0},     {BG3,BF_OPT1},     {BG2,BF_TILEDAT0}, {BG2,BF_TILEDAT1}, {BG1,BF_TILEDAT0}, {BG1,BF_TILEDAT1}},// MODE 2
'{{BG2,BF_TILEMAP},  {BG1,BF_TILEMAP},  {BG2,BF_TILEDAT0}, {BG2,BF_TILEDAT1}, {BG1,BF_TILEDAT0}, {BG1,BF_TILEDAT1}, {BG1,BF_TILEDAT2}, {BG1,BF_TILEDAT3}},// MODE 3
'{{BG2,BF_TILEMAP},  {BG1,BF_TILEMAP},  {BG3,BF_OPT0},     {BG2,BF_TILEDAT0}, {BG1,BF_TILEDAT0}, {BG1,BF_TILEDAT1}, {BG1,BF_TILEDAT2}, {BG1,BF_TILEDAT3}},// MODE 4
'{{BG2,BF_TILEMAP},  {BG1,BF_TILEMAP},  {BG2,BF_TILEDAT0}, {BG2,BF_TILEDAT1}, {BG1,BF_TILEDAT0}, {BG1,BF_TILEDAT1}, {BG1,BF_TILEDAT2}, {BG1,BF_TILEDAT3}},// MODE 5
'{{BG2,BF_TILEMAP},  {BG1,BF_TILEMAP},  {BG3,BF_OPT0},     {BG3,BF_OPT1},     {BG1,BF_TILEDAT0}, {BG1,BF_TILEDAT1}, {BG1,BF_TILEDAT2}, {BG1,BF_TILEDAT3}},// MODE 6
'{{BG1,BF_TILEDATM7},{BG1,BF_TILEDATM7},{BG1,BF_TILEDATM7},{BG1,BF_TILEDATM7},{BG1,BF_TILEDATM7},{BG1,BF_TILEDATM7},{BG1,BF_TILEDATM7},{BG1,BF_TILEDATM7}} // MODE 7
};

typedef logic [5:0] BgScAddr_t [0:3];
typedef logic [1:0] BgScSize_t [0:3];
typedef logic [3:0] BgTileAddr_t [0:3];
typedef logic [9:0] BgScroll_t [0:3];
typedef logic [15:0] BgData_t [0:7];
typedef logic [15:0] BgTileInfo_t [0:3];

// typedef logic [3:0] BgTileAtr_t [0:3];
// typedef logic [7:0] BgPlanes_t [0:11];
// typedef struct packed {
//     BgPlanes_t  PLANES;
//     BgTileAtr_t ATR;
// } BgTileInfo_r;
// typedef BgTileInfo_r BgTileInfos_t[0:1];

parameter [8:0] BG_FETCH_START		= 9'b000000000; 	// 0 
parameter [8:0] BG_FETCH_END		= 9'b100001111; 	// (256+16)-1=271
parameter [8:0] M7_FETCH_START		= 9'b000001111; 	// 15
parameter [8:0] M7_FETCH_END		= 9'b100001110; 	// (15+256)-1=270
parameter [8:0] M7_XY_LATCH			= 9'b000001011; 	// 11
parameter [8:0] SPR_GET_PIX_START	= 9'b000010000; 	// 16 
parameter [8:0] SPR_GET_PIX_END	    = 9'b100001111; 	// (16+256)-1=271
parameter [8:0] BG_GET_PIX_START	= 9'b000010001; 	// 17
parameter [8:0] BG_GET_PIX_END		= 9'b100010000; 	// (17+256)-1=272
parameter [8:0] BG_MATH_START		= 9'b000010010; 	// 18
parameter [8:0] BG_MATH_END			= 9'b100010001; 	// (18+256)-1=273
parameter [8:0] BG_OUT_START		= 9'b000010011; 	// 19
parameter [8:0] BG_OUT_END			= 9'b100010010; 	// (19+256)-1=274

parameter [8:0] OBJ_RANGE_START	    = 9'b000000000; 	// 0 
parameter [8:0] OBJ_RANGE_END		= 9'b011111111; 	// 256-1=255
parameter [8:0] OBJ_TIME_START		= 9'b100001110; 	// (16+256)-2=270 
parameter [8:0] OBJ_TIME_END		= 9'b101010001; 	// (16+256+68)-2-1=337 
parameter [8:0] OBJ_FETCH_START	    = 9'b100010000; 	// (16+256)=272
parameter [8:0] OBJ_FETCH_END		= 9'b101010011; 	// (16+256+68)-1=339

// typedef struct packed { // 34 bits
//     logic [8:0] X;
//     logic [7:0] Y;
//     logic [7:0] TILE;
//     logic       N;
//     logic [2:0] PAL;
//     logic [1:0] PRIO;
//     logic       HFLIP;
//     logic       VFLIP;
//     logic       S;      // size
// } Sprite_r;
// typedef Sprite_r RangeOam_t[0:31];
typedef logic [6:0] RangeOam_t[0:31];

typedef logic [7:0] SprSize_t [0:15];
parameter SprSize_t SPR_WIDTH = '{
    8'h07, 8'h07, 8'h07, 8'h0F, 8'h0F, 8'h1F, 8'h0F, 8'h0F,
    8'h0F, 8'h1F, 8'h3F, 8'h1F, 8'h3F, 8'h3F, 8'h1F, 8'h1F
};
parameter SprSize_t SPR_HEIGHT = '{
    8'h07, 8'h07, 8'h07, 8'h0F, 8'h0F, 8'h1F, 8'h1F, 8'h1F,
    8'h0F, 8'h1F, 8'h3F, 8'h1F, 8'h3F, 8'h3F, 8'h3F, 8'h1F
};

// typedef logic [3:0] SprTilePixels_t [0:7];
// typedef struct packed {
//     logic [31:0] DATA;
//     logic [8:0]  X;
//     logic [2:0]  PAL;
//     logic [1:0]  PRIO;
//     logic        VALID;
// } SprTile_r;
// typedef SprTile_r SprTiles_t[0:33];

function logic [7:0] FlipPlane(logic [7:0] bp, logic flip);
    return flip ? {bp[0], bp[1], bp[2], bp[3], bp[4], bp[5], bp[6], bp[7]} : bp;
endfunction

function automatic logic [7:0] FlipBGPlaneHR(logic [15:0] bp, logic flip, logic main);
    logic [15:0] t = flip ? {bp[0], bp[1], bp[2], bp[3], bp[4], bp[5], bp[6], bp[7],
                             bp[8], bp[9], bp[10], bp[11], bp[12], bp[13], bp[14], bp[15]} : bp;
    return main ? {t[14], t[12], t[10], t[8], t[6], t[4], t[2], t[0]} :
                  {t[15], t[13], t[11], t[9], t[7], t[5], t[3], t[1]};
endfunction

function logic [5:0] SprWidth(logic [3:0] size);
    return SPR_WIDTH[size][5:0];
endfunction

function logic [5:0] SprHeight(logic [3:0] size);
    return SPR_HEIGHT[size][5:0];
endfunction

// function logic [3:0] GetSpriteTilePixel(SprTile_r t, logic [7:0] x);
//     logic signed [8:0] i;
//     logic signed [8:0] temp;
//     temp = {1'b0, x};
//     i = temp - t.X;
//     if (i >= 0 && i <= 7 && t.VALID)
//         return {t.DATA[31-i], t.DATA[23-i], t.DATA[15-i], t.DATA[7-i]};
//     else 
//         return 4'b0;
// endfunction

// Saturated add or sub
function logic [4:0] AddSub(logic [4:0] a, logic [4:0] b, logic add, logic half);
    logic [5:0] temp;
    if (add) begin
        temp = {1'b0, a} + {1'b0, b};
        if (temp[5])
            temp = 6'b111111;
    end else begin
        temp = {1'b0, a} - {1'b0, b};
        if (temp[5])
            temp = 6'b0;
    end
    if (half)
        return temp[5:1];
    else
        return temp[4:0];
endfunction

function logic [14:0] GetDCM(logic [10:0] a);
    return {a[7:6], a[10], 2'b00, a[5:3], a[9], 1'b0, a[2:0], a[8], 1'b0};
endfunction

function logic [4:0] Bright(logic [3:0] mb, logic [4:0] b);
    logic [8:0] temp;
    temp = b * mb + {4'b0, b};
    if (mb == 4'b0)
        return 5'b0;
    else
        return temp[8:4];
endfunction

function logic signed [15:0] Mode7Clip(logic signed [13:0] a);
    return {{6{a[13]}}, a[9:0]};
endfunction;

