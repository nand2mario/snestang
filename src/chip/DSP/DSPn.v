module DSPn(
    input CLK,
    input CE,
    input RST_N,
    input ENABLE,
    input A0,
    input [7:0] DI,
    output reg [7:0] DO,
    input CS_N,
    input RD_N,
    input WR_N,
    input [11:0] DP_ADDR,
    input DP_SEL,
    input [2:0] VER,    // 00-DSP1, 01-DSP2, 10-DSP3, 11-DSP4
    input REV           //  1-DSP1B
);

parameter ACC_A = 0;
parameter ACC_B = 1;
parameter FLAG_OV0 = 0;
parameter FLAG_OV1 = 1;
parameter FLAG_Z = 2;
parameter FLAG_C = 3;
parameter FLAG_S0 = 4;
parameter FLAG_S1 = 5;

parameter INSTR_OP = 2'b00;
parameter INSTR_RT = 2'b01;
parameter INSTR_JP = 2'b10;
parameter INSTR_LD = 2'b11;

// IO Registers
reg [15:0] DR;
wire [15:0] SR;
reg [10:0] DP;
reg [10:0] RP;
reg [10:0] PC;
reg [10:0] STACK_RAM[0:7];
reg [2:0] SP;
reg [15:0] K, L, M, N;
wire [15:0] P, Q;
reg [15:0] ACC[0:1];
reg [5:0] FLAGS[0:1];
reg [15:0] TR, TRB;
reg [15:0] SI, SO;
wire [15:0] SGN;
reg RQM;
reg DRS, DRC;
reg USF0, USF1;
reg P0, P1;
reg EI, DMA;

wire [3:0]  OP_DST;
wire [3:0]  OP_SRC;
wire        OP_RP;
wire [3:0]  OP_DPH;
wire [1:0]  OP_DPL;
wire        OP_A;
wire [3:0]  OP_ALU;
wire [1:0]  OP_P;
wire [15:0] OP_ID;
wire [10:0] OP_NA;
wire [8:0]  OP_BRCH;
wire [1:0]  OP_INSTR;

wire [15:0] IDB;
reg [15:0] ALU_R;

wire [12:0] PROG_ROM_ADDR;
reg [23:0] PROG_ROM_Q;
wire [12:0] DATA_ROM_ADDR;
reg [15:0] DATA_ROM_Q;
wire [10:0] DATA_RAM_ADDR_A, DATA_RAM_ADDR_B;
reg [15:0] DATA_RAM_Q_A, DATA_RAM_Q_B;
wire DATA_RAM_WE;

wire EN;
reg [2:0] RD_Nr, WR_Nr;
reg PORT_ACTIVE;

//debug
wire DBG_RUN_LAST;
wire DBG_DAT_WRr;
wire [10:0] DBG_BRK_ADDR = 1'b1;
wire [7:0] DBG_CTRL = 1'b0;

assign EN = ENABLE & CE;
assign OP_INSTR = PROG_ROM_Q[23:22];
assign OP_P = PROG_ROM_Q[21:20];
assign OP_ALU = PROG_ROM_Q[19:16];
assign OP_A = PROG_ROM_Q[15:15];
assign OP_DPL = PROG_ROM_Q[14:13];
assign OP_DPH = PROG_ROM_Q[12:9];
assign OP_RP = PROG_ROM_Q[8];
assign OP_SRC = PROG_ROM_Q[7:4];
assign OP_DST = PROG_ROM_Q[3:0];
assign OP_ID = OP_INSTR == INSTR_LD ? PROG_ROM_Q[21:6] : IDB;
assign OP_NA = PROG_ROM_Q[12:2];
assign OP_BRCH = PROG_ROM_Q[21:13];

assign SGN = 16'h8000 ^ {16{FLAGS[ACC_A][FLAG_S1]}};   // SGN <= x"8000" xor (0 to 15 => FLAGS(ACC_A)(FLAG_S1));
assign SR = {RQM, USF1, USF0, DRS, DMA, DRC, 2'b00, EI, 5'b00000, P1, P0};
assign SI = 0;
assign IDB =    OP_SRC == 4'h0 ? TRB : 
                OP_SRC == 4'h1 ? ACC[ACC_A] : 
                OP_SRC == 4'h2 ? ACC[ACC_B] : 
                OP_SRC == 4'h3 ? TR : 
                OP_SRC == 4'h4 && VER[2] == 1'b1 ? {5'b00000,DP} : 
                OP_SRC == 4'h5 && VER[2] == 1'b1 ? {5'b00000,RP} : 
                OP_SRC == 4'h4 ? {8'h00,DP[7:0]} : 
                OP_SRC == 4'h5 ? {6'b000000,RP[9:0]} : 
                OP_SRC == 4'h6 ? DATA_ROM_Q : 
                OP_SRC == 4'h7 ? SGN : 
                OP_SRC == 4'h8 ? DR : 
                OP_SRC == 4'h9 ? DR : 
                OP_SRC == 4'hA ? SR : 
                OP_SRC == 4'hB ? SI : 
                OP_SRC == 4'hC ? SI : 
                OP_SRC == 4'hD ? K : 
                OP_SRC == 4'hE ? L : 
                OP_SRC == 4'hF ? DATA_RAM_Q_A : 
                16'h0000;

//ALU
assign Q =  ACC[OP_A];
assign P =  OP_ALU[3:1] == 3'b100 ? 16'h0001 : 
            OP_P == 2'b00 ? DATA_RAM_Q_A : 
            OP_P == 2'b01 ? IDB : 
            OP_P == 2'b10 ? M : 
            N;

always @(OP_ALU, P, Q, ALU_R, FLAGS, OP_A) begin : P5
    reg FC;
    reg [15:0] CARRY;

    FC = FLAGS[~OP_A][FLAG_C];  // FC := FLAGS(to_integer(not OP_A))(FLAG_C);
    CARRY = {15'b0, FC};    // CARRY := (0 => FC, others => '0');
    case(OP_ALU)
    4'h1 : ALU_R <= Q | P;
    4'h2 : ALU_R <= Q & P;
    4'h3 : ALU_R <= Q ^ P;
    4'h4 : ALU_R <= Q - P;
    4'h5 : ALU_R <= Q + P;
    4'h6 : ALU_R <= Q - P - CARRY;
    4'h7 : ALU_R <= Q + P + CARRY;
    4'h8 : ALU_R <= Q - P;
    4'h9 : ALU_R <= Q + P;
    4'hA : ALU_R <=  ~Q;
    4'hB : ALU_R <= {Q[15], Q[15:1]};
    4'hC : ALU_R <= {Q[14:0], FC};
    4'hD : ALU_R <= {Q[13:0], 2'b11};
    4'hE : ALU_R <= {Q[11:0], 4'b1111};
    4'hF : ALU_R <= {Q[7:0], Q[15:8]};
    default : ALU_R <= Q;
    endcase
end

//Flags
always @(posedge CLK) begin : P4
    reg OV0;

    if (~RST_N) begin
        FLAGS <= '{2{6'b0}};
    end else begin
        if (EN) begin
            if ((OP_INSTR == INSTR_OP || OP_INSTR == INSTR_RT) && OP_ALU != 4'h0) begin
                FLAGS[OP_A][FLAG_S0] <= ALU_R[15];
                
                if (ALU_R == 16'h0000) 
                    FLAGS[OP_A][FLAG_Z] <= 1'b1;
                else
                    FLAGS[OP_A][FLAG_Z] <= 1'b0;
                
                case (OP_ALU)
                4'h1,4'h2,4'h3,4'hA,4'hD,4'hE,4'hF : 
                    FLAGS[OP_A][FLAG_C] <= 0;
                4'h4,4'h6,4'h8 : begin
                    if (ALU_R > Q) 
                        FLAGS[OP_A][FLAG_C] <= 1;
                    else 
                        FLAGS[OP_A][FLAG_C] <= 0;
                end
                4'h5,4'h7,4'h9 : begin
                    if (ALU_R < Q) 
                        FLAGS[OP_A][FLAG_C] <= 1;
                    else 
                        FLAGS[OP_A][FLAG_C] <= 0;
                end
                4'hB : 
                    FLAGS[OP_A][FLAG_C] <= Q[0];
                4'hC : 
                    FLAGS[OP_A][FLAG_C] <= Q[15];
                default : ;
                endcase

                OV0 = (Q[15] ^ ALU_R[15]) & (Q[15] ^ P[15] ^ OP_ALU[0]);
                
                case (OP_ALU)
                4'h1,4'h2,4'h3,4'hA,4'hB,4'hC,4'hD,4'hE,4'hF : begin
                    FLAGS[OP_A][FLAG_OV0] <= 0;
                    FLAGS[OP_A][FLAG_OV1] <= 0;
                end
                4'h4,4'h5,4'h6,4'h7,4'h8,4'h9 : begin
                    FLAGS[OP_A][FLAG_OV0] <= OV0;
                    if (OV0) begin
                        FLAGS[OP_A][FLAG_S1] <= FLAGS[OP_A][FLAG_OV1] ^ ~ALU_R[15];
                        FLAGS[OP_A][FLAG_OV1] <= ~FLAGS[OP_A][FLAG_OV1];
                    end
                end
                default : ;
                endcase
            end
        end
    end
end

// Multiplier
always @(K, L) begin : P3
    reg [30:0] TEMP;

    TEMP = 30'(signed'(K) * signed'(L)); // TEMP := resize((signed(K) * signed(L)),TEMP'length);
    M <= TEMP[30:15];
    N <= {TEMP[14:0], 1'b0};
end

//Registers
always @(posedge CLK) begin : P2
    reg [15:0] DAT;

    if (~RST_N) begin
        ACC <= '{2{16'b0}};
        TR <= 0;
        DP <= 0;
        RP <= {11{1'b1}};
        DRC <= 0;
        USF1 <= 0;
        USF0 <= 0;
        DMA <= 0;
        EI <= 0;
        P1 <= 0;
        P0 <= 0;
        TRB <= 0;
        SO <= 0;
        K <= 0;
        L <= 0;
    end else begin
        if (EN) begin
            if ((OP_INSTR == INSTR_OP || OP_INSTR == INSTR_RT)) begin
                if(OP_ALU != 4'h0) 
                    ACC[OP_A] <= ALU_R;
                
                case(OP_DPL)
                2'b01 : DP[3:0] <= DP[3:0] + 1;
                2'b10 : DP[3:0] <= DP[3:0] - 1;
                2'b11 : DP[3:0] <= 0;
                default : ;
                endcase
                DP[7:4] <= DP[7:4] ^ OP_DPH;

                if (OP_RP) 
                    RP <= RP - 1;
            end

            if (OP_INSTR != INSTR_JP) begin
                case(OP_DST)
                4'h1 : ACC[ACC_A] <= OP_ID;
                4'h2 : ACC[ACC_B] <= OP_ID;
                4'h3 : TR <= OP_ID;
                4'h4 : DP <= OP_ID[10:0];
                4'h5 : RP <= OP_ID[10:0];
                4'h7 : begin
                    USF1 <= OP_ID[14];
                    USF0 <= OP_ID[13];
                    DMA <= OP_ID[11];
                    DRC <= OP_ID[10];
                    EI <= OP_ID[7];
                    P1 <= OP_ID[1];
                    P0 <= OP_ID[0];
                end
                4'h8 : SO <= OP_ID;
                4'h9 : SO <= OP_ID;
                4'hA : K <= OP_ID;
                4'hB : begin
                    K <= OP_ID;
                    L <= DATA_ROM_Q;
                end
                4'hC : begin
                    K <= DATA_RAM_Q_B;
                    L <= OP_ID;
                end
                4'hD : L <= OP_ID;
                4'hE : TRB <= OP_ID;
                default : ;
                endcase
            end
        end
    end
end

always @(posedge CLK) begin
    reg [2:0] NEXT_SP;
    reg [10:0] NEXT_PC;
    reg COND;

    if (~RST_N) begin
        STACK_RAM <= '{8{11'b0}};
        SP <= 0;
        PC <= 0;
    end else begin
        if (EN) begin
            NEXT_PC = (PC) + 1;
            if (OP_INSTR == INSTR_RT) begin
                NEXT_SP = SP - 1;
                // PC <= STACK_RAM(to_integer((NEXT_SP(2) and VER(2))&NEXT_SP(1 downto 0)));
                PC <= STACK_RAM[{NEXT_SP[2] & VER[2], NEXT_SP[1:0]}];
                SP <= NEXT_SP;
            end else if(OP_INSTR == INSTR_JP) begin
                case (OP_BRCH[5:2])
                4'b0000 : COND = FLAGS[ACC_A][FLAG_C] ^ ( ~OP_BRCH[1]);
                4'b0001 : COND = FLAGS[ACC_B][FLAG_C] ^ ( ~OP_BRCH[1]);
                4'b0010 : COND = FLAGS[ACC_A][FLAG_Z] ^ ( ~OP_BRCH[1]);
                4'b0011 : COND = FLAGS[ACC_B][FLAG_Z] ^ ( ~OP_BRCH[1]);
                4'b0100 : COND = FLAGS[ACC_A][FLAG_OV0] ^ ( ~OP_BRCH[1]);
                4'b0101 : COND = FLAGS[ACC_B][FLAG_OV0] ^ ( ~OP_BRCH[1]);
                4'b0110 : COND = FLAGS[ACC_A][FLAG_OV1] ^ ( ~OP_BRCH[1]);
                4'b0111 : COND = FLAGS[ACC_B][FLAG_OV1] ^ ( ~OP_BRCH[1]);
                4'b1000 : COND = FLAGS[ACC_A][FLAG_S0] ^ ( ~OP_BRCH[1]);
                4'b1001 : COND = FLAGS[ACC_B][FLAG_S0] ^ ( ~OP_BRCH[1]);
                4'b1010 : COND = FLAGS[ACC_A][FLAG_S1] ^ ( ~OP_BRCH[1]);
                4'b1011 : COND = FLAGS[ACC_B][FLAG_S1] ^ ( ~OP_BRCH[1]);
                4'b1100 : begin
                    //if (DP(3 downto 0) = (0 to 3 => OP_BRCH(1)) and OP_BRCH(0) = '0') or
                    // 	(DP(3 downto 0) /= (0 to 3 => OP_BRCH(1)) and OP_BRCH(0) = '1') then
                    if ((DP[3:0] == {4{OP_BRCH[1]}} && ~OP_BRCH[0]) ||
                        (DP[3:0] != {4{OP_BRCH[1]}} && OP_BRCH[0]))
                        COND = 1;
                    else
                        COND = 0;
                end
                4'b1111 : COND = RQM ^ ( ~OP_BRCH[1]);
                default : COND = 1'b0;
                endcase

                if (OP_BRCH == 9'b0) 
                    PC <= SO[10:0];
                else if (OP_BRCH[8:6] == 3'b010 && COND) 
                    PC <= OP_NA;
                else if (OP_BRCH[8:7] == 2'b10 && OP_BRCH[5:0] == 6'b0) begin
                    PC <= OP_NA;
                    if (OP_BRCH[6] == 1'b1) begin
                    //XXX STACK_RAM(to_integer((SP(2) and VER(2))&SP(1 downto 0))) <= NEXT_PC;
                        STACK_RAM[{SP[2] & VER[2], SP[1:0]}] <= NEXT_PC;
                        SP <= SP + 1;
                    end
                end else 
                    PC <= NEXT_PC;
            end else 
                PC <= NEXT_PC;
        end
    end
end

// TODO: Both prom and drom are compressible. 
//       There are a lot of duplicate and empty lines

// Program ROM (8096 * 24, 12 BRAM blocks)
// 0000: dsp1.rom
// 04F2: dsp1b.rom
// 09E5: dsp2.rom
// 10B8: dsp3.rom
// 16BD: dsp4.rom
// 1D8B: st010.rom
assign PROG_ROM_ADDR =  VER == 3'b000 && REV == 1'b0 ? PC + {1'b0, 12'h000} : 
                        VER == 3'b000 && REV == 1'b1 ? PC + {1'b0, 12'h4F2} : 
                        VER == 3'b001                ? PC + {1'b0, 12'h9E5} : 
                        VER == 3'b010                ? PC + {1'b1, 12'h0B8} : 
                        VER == 3'b011                ? PC + {1'b1, 12'h6BD} : 
                                                       PC + {1'b1, 12'hD8B};
reg [23:0] PROG_ROM [8*1024] /* synthesis syn_ramstyle="block_ram" */;
initial $readmemh("dsp11b23410_p.hex", PROG_ROM);
always @(posedge CLK) PROG_ROM_Q <= PROG_ROM[PROG_ROM_ADDR];

// Data ROM (7168 * 16, 6 BRAM blocks)
// 0000: dsp1.rom
// 0400: dsp1b.rom
// 0800: dsp2.rom
// 0C00: dsp3.rom
// 1000: dsp4.rom
// 1400: st010.rom
assign DATA_ROM_ADDR =  VER == 3'b000 && REV == 1'b0 ? RP[9:0] + {1'b0,12'h000} :
                        VER == 3'b000 && REV == 1'b1 ? RP[9:0] + {1'b0,12'h400} : 
                        VER == 3'b001                ? RP[9:0] + {1'b0,12'h800} : 
                        VER == 3'b010                ? RP[9:0] + {1'b0,12'hC00} : 
                        VER == 3'b011                ? RP[9:0] + {1'b1,12'h000} : 
                                                       RP[10:0] + {1'b1,12'h400};
reg [15:0] DATA_ROM[7168] /* synthesis syn_ramstyle="block_ram" */;
initial $readmemh("dsp11b23410_d.hex", DATA_ROM);
always @(posedge CLK) DATA_ROM_Q <= DATA_ROM[DATA_ROM_ADDR];

assign DATA_RAM_ADDR_A = VER[2] == 1'b0 ? {3'b000,DP[7:0]} : DP;
assign DATA_RAM_ADDR_B = DP_SEL == 1'b1 && (WR_N == 1'b0 || RD_N == 1'b0) ? DP_ADDR[11:1] : DATA_RAM_ADDR_A | 8'h40;
assign DATA_RAM_WE = OP_INSTR != INSTR_JP && OP_DST == 4'hF && EN == 1'b1 ? 1'b1 : 1'b0;

// Data RAM (2048 * 16, 2 BRAM blocks)
reg [15:0] DATA_RAM[2048] /* synthesis syn_ramstyle="block_ram" */;
always @(posedge CLK) begin // port A
    if (DATA_RAM_WE)
        DATA_RAM[DATA_RAM_ADDR_A] <= OP_ID;
    DATA_RAM_Q_A <= DATA_RAM[DATA_RAM_ADDR_A];
end
always @(posedge CLK) begin // port B
    if (~WR_N & DP_SEL & ~DP_ADDR[0])
        DATA_RAM[DATA_RAM_ADDR_B] <= DI;
    DATA_RAM_Q_B <= DATA_RAM[DATA_RAM_ADDR_B];
end

// DATA_RAML : entity work.dpram generic map(11, 8)
// port map(
// 	clock			=> CLK,
// 	address_a	=> DATA_RAM_ADDR_A,
// 	data_a		=> OP_ID(7 downto 0),
// 	wren_a		=> DATA_RAM_WE,
// 	q_a			=> DATA_RAM_Q_A(7 downto 0),
// 	address_b	=> DATA_RAM_ADDR_B,
// 	data_b		=> DI,
// 	wren_b		=> not WR_N and DP_SEL and not DP_ADDR(0),
// 	q_b			=> DATA_RAM_Q_B(7 downto 0)
// );
// DATA_RAMH : entity work.dpram generic map(11, 8)
// port map(
// 	clock			=> CLK,
// 	address_a	=> DATA_RAM_ADDR_A,
// 	data_a		=> OP_ID(15 downto 8),
// 	wren_a		=> DATA_RAM_WE,
// 	q_a			=> DATA_RAM_Q_A(15 downto 8),
// 	address_b	=> DATA_RAM_ADDR_B,
// 	data_b		=> DI,
// 	wren_b		=> not WR_N and DP_SEL and DP_ADDR(0),
// 	q_b			=> DATA_RAM_Q_B(15 downto 8)
// );

//I/O Ports
always @(posedge CLK) begin
    if (~RST_N) begin
        DRS <= 1'b0;
        RQM <= 1'b0;
        DR <= {16{1'b0}};
        WR_Nr <= {3{1'b1}};
        RD_Nr <= {3{1'b1}};
        PORT_ACTIVE <= 1'b0;
    end else begin
        if (ENABLE) begin
            WR_Nr <= {WR_Nr[1:0],WR_N};
            RD_Nr <= {RD_Nr[1:0],RD_N};

            if (WR_Nr == 3'b110 && ~CS_N && ~A0) begin
                if (~DRC) begin
                    if (~DRS) 
                        DR[7:0] <= DI;
                    else 
                        DR[15:8] <= DI;
                end else 
                    DR[7:0] <= DI;
                PORT_ACTIVE <= 1'b1;
            end else if (RD_Nr == 3'b110 && ~CS_N && ~A0) 
                PORT_ACTIVE <= 1'b1;

            if ((WR_Nr == 3'b001 || RD_Nr == 3'b001) && PORT_ACTIVE) begin
                if (~DRC) begin
                    if (~DRS) 
                        DRS <= 1;
                    else begin
                        RQM <= 0;
                        DRS <= 0;
                    end
                end else 
                    RQM <= 0;
                PORT_ACTIVE <= 1'b0;
            end else if (EN) begin
                if (OP_INSTR != INSTR_JP && OP_DST == 4'h6) begin
                    DR <= OP_ID;
                    RQM <= 1;
                end else if((OP_INSTR == INSTR_OP || OP_INSTR == INSTR_RT) && OP_SRC == 4'h8) 
                    RQM <= 1'b1;
            end
        end
    end
end

always @(A0, SR, DR, DRC, DRS, DP_SEL, DP_ADDR, DATA_RAM_Q_B) begin
    if (DP_SEL) begin
        if (~DP_ADDR[0]) 
            DO <= DATA_RAM_Q_B[7:0];
        else 
            DO <= DATA_RAM_Q_B[15:8];
    end else if (A0) begin
        DO <= SR[15:8];
    end else begin
        if (~DRC) begin
            if (~DRS) 
                DO <= DR[7:0];
            else 
                DO <= DR[15:8];
        end else 
            DO <= DR[7:0];
    end
end

endmodule
