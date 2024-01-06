
parameter V0VOLL = 8'h00;
parameter V1VOLL = 8'h10;
parameter V2VOLL = 8'h20;
parameter V3VOLL = 8'h30;
parameter V4VOLL = 8'h40;
parameter V5VOLL = 8'h50;
parameter V6VOLL = 8'h60;
parameter V7VOLL = 8'h70;
parameter V0VOLR = 8'h01;
parameter V1VOLR = 8'h11;
parameter V2VOLR = 8'h21;
parameter V3VOLR = 8'h31;
parameter V4VOLR = 8'h41;
parameter V5VOLR = 8'h51;
parameter V6VOLR = 8'h61;
parameter V7VOLR = 8'h71;
parameter V0PITCHL = 8'h02;
parameter V1PITCHL = 8'h12;
parameter V2PITCHL = 8'h22;
parameter V3PITCHL = 8'h32;
parameter V4PITCHL = 8'h42;
parameter V5PITCHL = 8'h52;
parameter V6PITCHL = 8'h62;
parameter V7PITCHL = 8'h72;
parameter V0PITCHH = 8'h03;
parameter V1PITCHH = 8'h13;
parameter V2PITCHH = 8'h23;
parameter V3PITCHH = 8'h33;
parameter V4PITCHH = 8'h43;
parameter V5PITCHH = 8'h53;
parameter V6PITCHH = 8'h63;
parameter V7PITCHH = 8'h73;
parameter V0SRCN = 8'h04;
parameter V1SRCN = 8'h14;
parameter V2SRCN = 8'h24;
parameter V3SRCN = 8'h34;
parameter V4SRCN = 8'h44;
parameter V5SRCN = 8'h54;
parameter V6SRCN = 8'h64;
parameter V7SRCN = 8'h74;
parameter V0ADSR1 = 8'h05;
parameter V1ADSR1 = 8'h15;
parameter V2ADSR1 = 8'h25;
parameter V3ADSR1 = 8'h35;
parameter V4ADSR1 = 8'h45;
parameter V5ADSR1 = 8'h55;
parameter V6ADSR1 = 8'h65;
parameter V7ADSR1 = 8'h75;
parameter V0ADSR2 = 8'h06;
parameter V1ADSR2 = 8'h16;
parameter V2ADSR2 = 8'h26;
parameter V3ADSR2 = 8'h36;
parameter V4ADSR2 = 8'h46;
parameter V5ADSR2 = 8'h56;
parameter V6ADSR2 = 8'h66;
parameter V7ADSR2 = 8'h76;
parameter V0GAIN = 8'h07;
parameter V1GAIN = 8'h17;
parameter V2GAIN = 8'h27;
parameter V3GAIN = 8'h37;
parameter V4GAIN = 8'h47;
parameter V5GAIN = 8'h57;
parameter V6GAIN = 8'h67;
parameter V7GAIN = 8'h77;
parameter V0ENVX = 8'h08;
parameter V1ENVX = 8'h18;
parameter V2ENVX = 8'h28;
parameter V3ENVX = 8'h38;
parameter V4ENVX = 8'h48;
parameter V5ENVX = 8'h58;
parameter V6ENVX = 8'h68;
parameter V7ENVX = 8'h78;
parameter V0OUTX = 8'h09;
parameter V1OUTX = 8'h19;
parameter V2OUTX = 8'h29;
parameter V3OUTX = 8'h39;
parameter V4OUTX = 8'h49;
parameter V5OUTX = 8'h59;
parameter V6OUTX = 8'h69;
parameter V7OUTX = 8'h79;
parameter MVOLL = 8'h0C;
parameter MVOLR = 8'h1C;
parameter EVOLL = 8'h2C;
parameter EVOLR = 8'h3C;
parameter KON = 8'h4C;
parameter KOFF = 8'h5C;
parameter FLG = 8'h6C;
// nand2mario: this is shadowed by register of the same name 
// parameter ENDX = 8'h7C;
parameter EFB = 8'h0D;
parameter PMON = 8'h2D;
parameter NON = 8'h3D;
parameter EON = 8'h4D;
parameter DIR = 8'h5D;
parameter ESA = 8'h6D;
parameter EDL = 8'h7D;
parameter FIR0 = 8'h0F;
parameter FIR1 = 8'h1F;
parameter FIR2 = 8'h2F;
parameter FIR3 = 8'h3F;
parameter FIR4 = 8'h4F;
parameter FIR5 = 8'h5F;
parameter FIR6 = 8'h6F;
parameter FIR7 = 8'h7F; 

// Register access 
// type RegsAccessTbl_t is array(0 to 31, 0 to 3) of std_logic_vector(7 downto 0);
localparam [7:0] RA_TBL[0:31][0:3] = '{
'{V0VOLR, V1PITCHL, V1ADSR1, 8'h7E},    // 0
'{V0ENVX, V1PITCHH, V1ADSR2, 8'h7E},
'{V0OUTX, V1VOLL,   V3SRCN,  8'h7E},
'{V1VOLR, V2PITCHL, V2ADSR1, 8'h7E},
'{V1ENVX, V2PITCHH, V2ADSR2, 8'h7E},    // 4
'{V1OUTX, V2VOLL,   V4SRCN,  8'h7E},
'{V2VOLR, V3PITCHL, V3ADSR1, 8'h7E},
'{V2ENVX, V3PITCHH, V3ADSR2, 8'h7E},
'{V2OUTX, V3VOLL,   V5SRCN,  8'h7E},    // 8
'{V3VOLR, V4PITCHL, V4ADSR1, 8'h7E},
'{V3ENVX, V4PITCHH, V4ADSR2, 8'h7E},
'{V3OUTX, V4VOLL,   V6SRCN,  8'h7E},
'{V4VOLR, V5PITCHL, V5ADSR1, 8'h7E},    // 12
'{V4ENVX, V5PITCHH, V5ADSR2, 8'h7E},
'{V4OUTX, V5VOLL,   V7SRCN,  8'h7E},
'{V5VOLR, V6PITCHL, V6ADSR1, 8'h7E},
'{V5ENVX, V6PITCHH, V6ADSR2, 8'h7E},    // 16
'{V5OUTX, V6VOLL,   V0SRCN,  8'h7E},
'{V6VOLR, V7PITCHL, V7ADSR1, 8'h7E},
'{V6ENVX, V7PITCHH, V7ADSR2, 8'h7E},
'{V6OUTX, V7VOLL,   V1SRCN,  8'h7E},    // 20
'{V7VOLR, V0PITCHL, V0ADSR1, 8'h7E},
'{V7ENVX, V0PITCHH, FIR0, 	 8'h7E},
'{V7OUTX, FIR1,     FIR2,    8'h7E},
'{FIR3,   FIR4,     FIR5,    8'h7E},    // 24
'{FIR6,   FIR7,     8'h7E,   8'h7E},
'{MVOLL,  EVOLL, 	EFB,     8'h7E},
'{MVOLR,  EVOLR, 	PMON,    8'h7E},
'{NON,    EON,      DIR,     8'h7E},    // 28
'{EDL,    ESA,      KON,     8'h7E},
'{KOFF,   FLG,      V0ADSR2, 8'h7E},
'{8'h7E,  V0VOLL,   V2SRCN,  8'h7E}
};

// VoiceStep_t
parameter [5:0] VS_IDLE = 0, VS_VOLL = 1, VS_VOLR = 2, VS_PITCHL = 3,
                VS_PITCHH = 4, VS_ADSR1 = 5, VS_ADSR2 = 6, VS_SRCN = 7,
                VS_ENVX = 8, VS_OUTX = 9, VS_FIR0 = 10, VS_FIR1 = 11,
                VS_FIR2 = 12, VS_FIR3 = 13, VS_FIR4 = 14, VS_FIR5 = 15,
                VS_FIR6 = 16, VS_FIR7 = 17, VS_MVOLL = 18, VS_MVOLR = 19,
                VS_EVOLL = 20, VS_EVOLR = 21, VS_EFB = 22, VS_PMON = 23,
                VS_NON = 24, VS_EON = 25, VS_DIR = 26, VS_EDL = 27,
                VS_ESA = 28, VS_KON = 29, VS_KOFF = 30, VS_FLG = 31,
                VS_ECHO = 32;
typedef struct packed {
    logic [5:0] S;      // Step: see above
    logic [2:0] V;      // Voice: 0 - 7
} VoiceStep_r;

// type VoiceStepTbl_t is array{0 to 31, 0 to 3) of VoiceStep_r;
localparam VoiceStep_r VS_TBL[0:31][0:3] = '{
'{{VS_VOLR,3'd0},  {VS_PITCHL,3'd1}, {VS_ADSR1,3'd1}, {VS_IDLE,3'd0}},  // 0
'{{VS_ENVX,3'd0},  {VS_PITCHH,3'd1}, {VS_ADSR2,3'd1}, {VS_IDLE,3'd0}},
'{{VS_OUTX,3'd0},  {VS_VOLL,3'd1},   {VS_SRCN,3'd3},  {VS_IDLE,3'd0}},
'{{VS_VOLR,3'd1},  {VS_PITCHL,3'd2}, {VS_ADSR1,3'd2}, {VS_IDLE,3'd0}},
'{{VS_ENVX,3'd1},  {VS_PITCHH,3'd2}, {VS_ADSR2,3'd2}, {VS_IDLE,3'd0}},  // 4
'{{VS_OUTX,3'd1},  {VS_VOLL,3'd2},   {VS_SRCN,3'd4},  {VS_IDLE,3'd0}},
'{{VS_VOLR,3'd2},  {VS_PITCHL,3'd3}, {VS_ADSR1,3'd3}, {VS_IDLE,3'd0}},
'{{VS_ENVX,3'd2},  {VS_PITCHH,3'd3}, {VS_ADSR2,3'd3}, {VS_IDLE,3'd0}},
'{{VS_OUTX,3'd2},  {VS_VOLL,3'd3},   {VS_SRCN,3'd5},  {VS_IDLE,3'd0}},  // 8
'{{VS_VOLR,3'd3},  {VS_PITCHL,3'd4}, {VS_ADSR1,3'd4}, {VS_IDLE,3'd0}},
'{{VS_ENVX,3'd3},  {VS_PITCHH,3'd4}, {VS_ADSR2,3'd4}, {VS_IDLE,3'd0}},
'{{VS_OUTX,3'd3},  {VS_VOLL,3'd4},   {VS_SRCN,3'd6},  {VS_IDLE,3'd0}},
'{{VS_VOLR,3'd4},  {VS_PITCHL,3'd5}, {VS_ADSR1,3'd5}, {VS_IDLE,3'd0}},  // 12
'{{VS_ENVX,3'd4},  {VS_PITCHH,3'd5}, {VS_ADSR2,3'd5}, {VS_IDLE,3'd0}},
'{{VS_OUTX,3'd4},  {VS_VOLL,3'd5},   {VS_SRCN,3'd7},  {VS_IDLE,3'd0}},
'{{VS_VOLR,3'd5},  {VS_PITCHL,3'd6}, {VS_ADSR1,3'd6}, {VS_IDLE,3'd0}},
'{{VS_ENVX,3'd5},  {VS_PITCHH,3'd6}, {VS_ADSR2,3'd6}, {VS_IDLE,3'd0}},  // 16
'{{VS_OUTX,3'd5},  {VS_VOLL,3'd6},   {VS_SRCN,3'd0},  {VS_IDLE,3'd0}},
'{{VS_VOLR,3'd6},  {VS_PITCHL,3'd7}, {VS_ADSR1,3'd7}, {VS_IDLE,3'd0}},
'{{VS_ENVX,3'd6},  {VS_PITCHH,3'd7}, {VS_ADSR2,3'd7}, {VS_IDLE,3'd0}},
'{{VS_OUTX,3'd6},  {VS_VOLL,3'd7},   {VS_SRCN,3'd1},  {VS_IDLE,3'd0}},  // 20
'{{VS_VOLR,3'd7},  {VS_PITCHL,3'd0}, {VS_ADSR1,3'd0}, {VS_IDLE,3'd0}},
'{{VS_ENVX,3'd7},  {VS_PITCHH,3'd0}, {VS_FIR0,3'd0},  {VS_IDLE,3'd0}},
'{{VS_OUTX,3'd7},  {VS_FIR1,3'd1},   {VS_FIR2,3'd2},  {VS_IDLE,3'd0}},
'{{VS_FIR3,3'd3},  {VS_FIR4,3'd4},   {VS_FIR5,3'd5},  {VS_IDLE,3'd0}},  // 24
'{{VS_FIR6,3'd6},  {VS_FIR7,3'd7},   {VS_IDLE,3'd0},  {VS_IDLE,3'd0}},
'{{VS_MVOLL,3'd0}, {VS_EVOLL,3'd0},  {VS_EFB,3'd0},   {VS_IDLE,3'd0}},
'{{VS_MVOLR,3'd0}, {VS_EVOLR,3'd0},  {VS_PMON,3'd0},  {VS_IDLE,3'd0}},
'{{VS_NON,3'd0},   {VS_EON,3'd0},    {VS_DIR,3'd0},   {VS_IDLE,3'd0}},  // 28
'{{VS_EDL,3'd0},   {VS_ESA,3'd0},    {VS_KON,3'd0},   {VS_IDLE,3'd0}},
'{{VS_KOFF,3'd0},  {VS_FLG,3'd0},    {VS_ADSR2,3'd0}, {VS_IDLE,3'd0}},
'{{VS_ECHO,3'd0},  {VS_VOLL,3'd0},   {VS_SRCN,3'd2},  {VS_IDLE,3'd0}}
};

// RAM Access
parameter [3:0] RS_IDLE = 0, RS_BRRH = 1, RS_BRR1 = 2, RS_BRR2 = 3,
                RS_SRCNL = 4, RS_SRCNH = 5, RS_ECHORDL = 6, RS_ECHORDH = 7,
                RS_ECHOWRL = 8, RS_ECHOWRH = 9, RS_SMP = 10;
// type RamStepTbl_t is array(0 to 31, 0 to 3) of RamStep_t;
localparam [3:0] RS_TBL[0:31][0:3] = '{
'{RS_SRCNL,    RS_SRCNH,    RS_IDLE,  RS_SMP},
'{RS_BRR1,     RS_BRRH,     RS_IDLE,  RS_SMP},
'{RS_BRR2,     RS_IDLE,     RS_IDLE,  RS_SMP},
'{RS_SRCNL,    RS_SRCNH,    RS_IDLE,  RS_SMP},
'{RS_BRR1,     RS_BRRH,     RS_IDLE,  RS_SMP},
'{RS_BRR2,     RS_IDLE,     RS_IDLE,  RS_SMP},
'{RS_SRCNL,    RS_SRCNH,    RS_IDLE,  RS_SMP},
'{RS_BRR1,     RS_BRRH,     RS_IDLE,  RS_SMP},
'{RS_BRR2,     RS_IDLE,     RS_IDLE,  RS_SMP},
'{RS_SRCNL,    RS_SRCNH,    RS_IDLE,  RS_SMP},
'{RS_BRR1,     RS_BRRH,     RS_IDLE,  RS_SMP},
'{RS_BRR2,     RS_IDLE,     RS_IDLE,  RS_SMP},
'{RS_SRCNL,    RS_SRCNH,    RS_IDLE,  RS_SMP},
'{RS_BRR1,     RS_BRRH,     RS_IDLE,  RS_SMP},
'{RS_BRR2,     RS_IDLE,     RS_IDLE,  RS_SMP},
'{RS_SRCNL,    RS_SRCNH,    RS_IDLE,  RS_SMP},
'{RS_BRR1,     RS_BRRH,     RS_IDLE,  RS_SMP},  // 16
'{RS_BRR2,     RS_IDLE,     RS_IDLE,  RS_SMP},
'{RS_SRCNL,    RS_SRCNH,    RS_IDLE,  RS_SMP},
'{RS_BRR1,     RS_BRRH,     RS_IDLE,  RS_SMP},
'{RS_BRR2,     RS_IDLE,     RS_IDLE,  RS_SMP},  // 20
'{RS_SRCNL,    RS_SRCNH,    RS_IDLE,  RS_SMP},
'{RS_ECHORDL,  RS_ECHORDH,  RS_IDLE,  RS_SMP},
'{RS_ECHORDL,  RS_ECHORDH,  RS_IDLE,  RS_SMP},
'{RS_IDLE,     RS_IDLE,     RS_IDLE,  RS_SMP},  // 24
'{RS_BRR1,     RS_BRRH,     RS_IDLE,  RS_SMP},
'{RS_IDLE,     RS_IDLE,     RS_IDLE,  RS_SMP},
'{RS_IDLE,     RS_IDLE,     RS_IDLE,  RS_SMP},
'{RS_IDLE,     RS_IDLE,     RS_IDLE,  RS_SMP},  // 28
'{RS_ECHOWRL,  RS_ECHOWRH,  RS_IDLE,  RS_SMP},
'{RS_ECHOWRL,  RS_ECHOWRH,  RS_IDLE,  RS_SMP},
'{RS_BRR2,     RS_IDLE,     RS_IDLE,  RS_SMP}
};

// type BrrVoiceTbl_t is array(0 to 31) of integer range 0 to 7;
localparam [2:0] BRR_VOICE_TBL[0:31] = '{
3'd1, 3'd1, 3'd1, 3'd2, 3'd2, 3'd2, 3'd3, 3'd3, 
3'd3, 3'd4, 3'd4, 3'd4, 3'd5, 3'd5, 3'd5, 3'd6, 
3'd6, 3'd6, 3'd7, 3'd7, 3'd7, 3'd0, 3'd0, 3'd0, 
3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0
};

// BRR Decode
parameter [2:0] BDS_IDLE = 0, BDS_SMPL0 = 1, BDS_SMPL1 = 2, 
                BDS_SMPL2 = 3, BDS_SMPL3 = 4;
typedef struct packed {
    logic [2:0] S;      // BDS_IDLE ...
    logic [2:0] V;      // 0 - 7
} BRRDecodeStep_r;

// type BRRDecodeStepTbl_t is array(0 to 31, 0 to 3) of BRRDecodeStep_r;
localparam BRRDecodeStep_r BDS_TBL [0:31][0:3] = '{
'{{BDS_SMPL2,3'd0}, {BDS_SMPL3,3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_SMPL0,3'd1}, {BDS_SMPL1,3'd1}},
'{{BDS_SMPL2,3'd1}, {BDS_SMPL3,3'd1}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_SMPL0,3'd2}, {BDS_SMPL1,3'd2}},
'{{BDS_SMPL2,3'd2}, {BDS_SMPL3,3'd2}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_SMPL0,3'd3}, {BDS_SMPL1,3'd3}},
'{{BDS_SMPL2,3'd3}, {BDS_SMPL3,3'd3}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_SMPL0,3'd4}, {BDS_SMPL1,3'd4}},
'{{BDS_SMPL2,3'd4}, {BDS_SMPL3,3'd4}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_SMPL0,3'd5}, {BDS_SMPL1,3'd5}},
'{{BDS_SMPL2,3'd5}, {BDS_SMPL3,3'd5}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_SMPL0,3'd6}, {BDS_SMPL1,3'd6}},
'{{BDS_SMPL2,3'd6}, {BDS_SMPL3,3'd6}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_SMPL0,3'd7}, {BDS_SMPL1,3'd7}},
'{{BDS_SMPL2,3'd7}, {BDS_SMPL3,3'd7}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}},
'{{BDS_IDLE, 3'd0}, {BDS_IDLE, 3'd0}, {BDS_SMPL0,3'd0}, {BDS_SMPL1,3'd0}}
};

// RAM Access
parameter [1:0]  IS_IDLE = 0, IS_ENV = 1, IS_ENV2 = 2;
typedef struct packed {
    logic [1:0] S;      // IS_IDLE ...
    logic [2:0] V;      // 0 - 7
} IntStep_r;

// type IntStepTbl_t is array(0 to 31, 0 to 3) of IntStep_r;
localparam IntStep_r IS_TBL[0:31][0:3] = '{
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd1},    {IS_ENV,  3'd1},    {IS_ENV2, 3'd1}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd2},    {IS_ENV,  3'd2},    {IS_ENV2, 3'd2}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd3},    {IS_ENV,  3'd3},    {IS_ENV2, 3'd3}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd4},    {IS_ENV,  3'd4},    {IS_ENV2, 3'd4}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd5},    {IS_ENV,  3'd5},    {IS_ENV2, 3'd5}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd6},    {IS_ENV,  3'd6},    {IS_ENV2, 3'd6}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd7},    {IS_ENV,  3'd7},    {IS_ENV2, 3'd7}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_ENV,  3'd0},    {IS_ENV2, 3'd0}},
'{{IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0},    {IS_IDLE, 3'd0}}
};

// Envelope Modes
parameter [1:0]
  EM_RELEASE = 0,
  EM_ATTACK = 1,
  EM_DECAY = 2,
  EM_SUSTAIN = 3;

// type GaussTbl_t is array(0 to 511) of signed(11 downto 0);
localparam signed [11:0] GTBL[0:511] = '{
12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000,     // 0
12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000,
12'h001, 12'h001, 12'h001, 12'h001, 12'h001, 12'h001, 12'h001, 12'h001,
12'h001, 12'h001, 12'h001, 12'h002, 12'h002, 12'h002, 12'h002, 12'h002,
12'h002, 12'h002, 12'h003, 12'h003, 12'h003, 12'h003, 12'h003, 12'h004,     // 32
12'h004, 12'h004, 12'h004, 12'h004, 12'h005, 12'h005, 12'h005, 12'h005,
12'h006, 12'h006, 12'h006, 12'h006, 12'h007, 12'h007, 12'h007, 12'h008,
12'h008, 12'h008, 12'h009, 12'h009, 12'h009, 12'h00A, 12'h00A, 12'h00A,
12'h00B, 12'h00B, 12'h00B, 12'h00C, 12'h00C, 12'h00D, 12'h00D, 12'h00E,     // 64
12'h00E, 12'h00F, 12'h00F, 12'h00F, 12'h010, 12'h010, 12'h011, 12'h011,
12'h012, 12'h013, 12'h013, 12'h014, 12'h014, 12'h015, 12'h015, 12'h016,
12'h017, 12'h017, 12'h018, 12'h018, 12'h019, 12'h01A, 12'h01B, 12'h01B,
12'h01C, 12'h01D, 12'h01D, 12'h01E, 12'h01F, 12'h020, 12'h020, 12'h021,     // 96
12'h022, 12'h023, 12'h024, 12'h024, 12'h025, 12'h026, 12'h027, 12'h028,
12'h029, 12'h02A, 12'h02B, 12'h02C, 12'h02D, 12'h02E, 12'h02F, 12'h030,
12'h031, 12'h032, 12'h033, 12'h034, 12'h035, 12'h036, 12'h037, 12'h038,
12'h03A, 12'h03B, 12'h03C, 12'h03D, 12'h03E, 12'h040, 12'h041, 12'h042,     // 128
12'h043, 12'h045, 12'h046, 12'h047, 12'h049, 12'h04A, 12'h04C, 12'h04D,
12'h04E, 12'h050, 12'h051, 12'h053, 12'h054, 12'h056, 12'h057, 12'h059,
12'h05A, 12'h05C, 12'h05E, 12'h05F, 12'h061, 12'h063, 12'h064, 12'h066,
12'h068, 12'h06A, 12'h06B, 12'h06D, 12'h06F, 12'h071, 12'h073, 12'h075,     // 160
12'h076, 12'h078, 12'h07A, 12'h07C, 12'h07E, 12'h080, 12'h082, 12'h084,
12'h086, 12'h089, 12'h08B, 12'h08D, 12'h08F, 12'h091, 12'h093, 12'h096,
12'h098, 12'h09A, 12'h09C, 12'h09F, 12'h0A1, 12'h0A3, 12'h0A6, 12'h0A8,
12'h0AB, 12'h0AD, 12'h0AF, 12'h0B2, 12'h0B4, 12'h0B7, 12'h0BA, 12'h0BC,     // 192
12'h0BF, 12'h0C1, 12'h0C4, 12'h0C7, 12'h0C9, 12'h0CC, 12'h0CF, 12'h0D2,
12'h0D4, 12'h0D7, 12'h0DA, 12'h0DD, 12'h0E0, 12'h0E3, 12'h0E6, 12'h0E9,
12'h0EC, 12'h0EF, 12'h0F2, 12'h0F5, 12'h0F8, 12'h0FB, 12'h0FE, 12'h101,
12'h104, 12'h107, 12'h10B, 12'h10E, 12'h111, 12'h114, 12'h118, 12'h11B,     // 224
12'h11E, 12'h122, 12'h125, 12'h129, 12'h12C, 12'h130, 12'h133, 12'h137,
12'h13A, 12'h13E, 12'h141, 12'h145, 12'h148, 12'h14C, 12'h150, 12'h153,
12'h157, 12'h15B, 12'h15F, 12'h162, 12'h166, 12'h16A, 12'h16E, 12'h172,
12'h176, 12'h17A, 12'h17D, 12'h181, 12'h185, 12'h189, 12'h18D, 12'h191,     // 256
12'h195, 12'h19A, 12'h19E, 12'h1A2, 12'h1A6, 12'h1AA, 12'h1AE, 12'h1B2,
12'h1B7, 12'h1BB, 12'h1BF, 12'h1C3, 12'h1C8, 12'h1CC, 12'h1D0, 12'h1D5,
12'h1D9, 12'h1DD, 12'h1E2, 12'h1E6, 12'h1EB, 12'h1EF, 12'h1F3, 12'h1F8,
12'h1FC, 12'h201, 12'h205, 12'h20A, 12'h20F, 12'h213, 12'h218, 12'h21C,     // 288
12'h221, 12'h226, 12'h22A, 12'h22F, 12'h233, 12'h238, 12'h23D, 12'h241,
12'h246, 12'h24B, 12'h250, 12'h254, 12'h259, 12'h25E, 12'h263, 12'h267,
12'h26C, 12'h271, 12'h276, 12'h27B, 12'h280, 12'h284, 12'h289, 12'h28E,
12'h293, 12'h298, 12'h29D, 12'h2A2, 12'h2A6, 12'h2AB, 12'h2B0, 12'h2B5,     // 320
12'h2BA, 12'h2BF, 12'h2C4, 12'h2C9, 12'h2CE, 12'h2D3, 12'h2D8, 12'h2DC,
12'h2E1, 12'h2E6, 12'h2EB, 12'h2F0, 12'h2F5, 12'h2FA, 12'h2FF, 12'h304,
12'h309, 12'h30E, 12'h313, 12'h318, 12'h31D, 12'h322, 12'h326, 12'h32B,
12'h330, 12'h335, 12'h33A, 12'h33F, 12'h344, 12'h349, 12'h34E, 12'h353,     // 352
12'h357, 12'h35C, 12'h361, 12'h366, 12'h36B, 12'h370, 12'h374, 12'h379,
12'h37E, 12'h383, 12'h388, 12'h38C, 12'h391, 12'h396, 12'h39B, 12'h39F,
12'h3A4, 12'h3A9, 12'h3AD, 12'h3B2, 12'h3B7, 12'h3BB, 12'h3C0, 12'h3C5,
12'h3C9, 12'h3CE, 12'h3D2, 12'h3D7, 12'h3DC, 12'h3E0, 12'h3E5, 12'h3E9,     // 384
12'h3ED, 12'h3F2, 12'h3F6, 12'h3FB, 12'h3FF, 12'h403, 12'h408, 12'h40C,
12'h410, 12'h415, 12'h419, 12'h41D, 12'h421, 12'h425, 12'h42A, 12'h42E,
12'h432, 12'h436, 12'h43A, 12'h43E, 12'h442, 12'h446, 12'h44A, 12'h44E,
12'h452, 12'h455, 12'h459, 12'h45D, 12'h461, 12'h465, 12'h468, 12'h46C,     // 416
12'h470, 12'h473, 12'h477, 12'h47A, 12'h47E, 12'h481, 12'h485, 12'h488,
12'h48C, 12'h48F, 12'h492, 12'h496, 12'h499, 12'h49C, 12'h49F, 12'h4A2,
12'h4A6, 12'h4A9, 12'h4AC, 12'h4AF, 12'h4B2, 12'h4B5, 12'h4B7, 12'h4BA,
12'h4BD, 12'h4C0, 12'h4C3, 12'h4C5, 12'h4C8, 12'h4CB, 12'h4CD, 12'h4D0,     // 448
12'h4D2, 12'h4D5, 12'h4D7, 12'h4D9, 12'h4DC, 12'h4DE, 12'h4E0, 12'h4E3,
12'h4E5, 12'h4E7, 12'h4E9, 12'h4EB, 12'h4ED, 12'h4EF, 12'h4F1, 12'h4F3,
12'h4F5, 12'h4F6, 12'h4F8, 12'h4FA, 12'h4FB, 12'h4FD, 12'h4FF, 12'h500,
12'h502, 12'h503, 12'h504, 12'h506, 12'h507, 12'h508, 12'h50A, 12'h50B,     // 480
12'h50C, 12'h50D, 12'h50E, 12'h50F, 12'h510, 12'h511, 12'h511, 12'h512,
12'h513, 12'h514, 12'h514, 12'h515, 12'h516, 12'h516, 12'h517, 12'h517,
12'h517, 12'h518, 12'h518, 12'h518, 12'h518, 12'h518, 12'h519, 12'h519 
};

// clamp a 17-bit signed integer to 16-bit signed (max 0x7fff and min 0x8000)
function logic signed [15:0] CLAMP16(logic signed [16:0] a);
    return a[16:15] == 2'b01 ? 16'h7fff :
           a[16:15] == 2'b10 ? 16'h8000 :
           16'(a);
endfunction
