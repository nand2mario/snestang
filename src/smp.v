// SNES sound processor module

module SMP (
    input CLK,
    input RST_N,
    input CE,
    input ENABLE,
    input SYSCLKF_CE,

    // SMP to memory
    output [15:0] A,
    input [7:0] DI,
    output [7:0] DO,
    output WE_N,

    // PA from CPU
    input [1:0] PA,
    input PARD_N,
    input PAWR_N,
    input [7:0] CPU_DI,
    output [7:0] CPU_DO,
    input CS,
    input CS_N,

    // Debug
    input [7:0] DBG_REG,
    input [7:0] DBG_DAT_IN,
    output reg [7:0] DBG_SMP_DAT,
    output [7:0] DBG_CPU_DAT,
    input DBG_CPU_DAT_WR,
    input DBG_SMP_DAT_WR,
    output BRK_OUT
);

reg [7:0] SPC700_D_IN, SPC700_D_OUT;
wire [15:0] SPC700_A;
wire SPC700_R_WN;
wire SPC700_CE;
wire TIMER_CE;

reg [7:0] CPUI[0:3];
reg [7:0] CPUO[0:3];
reg PAWR_N_OLD;

reg [7:0] TEST;
reg [1:0] CLK_SPEED;
reg [1:0] TM_SPEED;
reg TIMERS_ENABLE, TIMERS_DISABLE;
reg [2:0] TM_EN;
reg IPL_EN;
reg [7:0] T0DIV;
reg [7:0] T1DIV;
reg [7:0] T2DIV;
reg [3:0] T0OUT;
reg [3:0] T1OUT;
reg [3:0] T2OUT;
reg [7:0] AUX [2];

reg [1:0] RESET_PORT;
reg [8:0] TM01_CNT;
reg [5:0] TM2_CNT;
reg [7:0] T0_CNT, T1_CNT, T2_CNT;
wire RESET01, RESET23;
localparam [7:0] IPLROM[0:63] = '{
    8'hcd, 8'hef, 8'hbd, 8'he8, 8'h00, 8'hc6, 8'h1d, 8'hd0,
    8'hfc, 8'h8f, 8'haa, 8'hf4, 8'h8f, 8'hbb, 8'hf5, 8'h78,
    8'hcc, 8'hf4, 8'hd0, 8'hfb, 8'h2f, 8'h19, 8'heb, 8'hf4,
    8'hd0, 8'hfc, 8'h7e, 8'hf4, 8'hd0, 8'h0b, 8'he4, 8'hf5,
    8'hcb, 8'hf4, 8'hd7, 8'h00, 8'hfc, 8'hd0, 8'hf3, 8'hab,
    8'h01, 8'h10, 8'hef, 8'h7e, 8'hf4, 8'h10, 8'heb, 8'hba,
    8'hf6, 8'hda, 8'h00, 8'hba, 8'hf4, 8'hc4, 8'hf4, 8'hdd,
    8'h5d, 8'hd0, 8'hdb, 8'h1f, 8'h00, 8'h00, 8'hc0, 8'hff};

assign SPC700_CE = ENABLE & CE;

always @(posedge CLK) begin
    if (RST_N == 1'b0) begin
        CPUI <= '{4{8'b0}};
        PAWR_N_OLD <= 1'b1;
    end else begin
        PAWR_N_OLD <= PAWR_N;
        if (~PAWR_N && PAWR_N_OLD && CS && ~CS_N) begin
            // $2140-2143
            // PA: CPUI[ 01xx_xxPA ]
            CPUI[PA] <= CPU_DI;
            $display("APU: CPUI%d=%02x", PA[1:0], CPU_DI);
        end
        if (SPC700_CE) begin
            if (SPC700_A == 16'h00F1 && ~SPC700_R_WN) begin
                if (SPC700_D_OUT[4]) begin
                    CPUI[0] <= 8'b0;
                    CPUI[1] <= 8'b0;
                end
                if (SPC700_D_OUT[5]) begin
                    CPUI[2] <= 0;
                    CPUI[3] <= 0;
                end
            end
        end
    end
end

assign CPU_DO = CPUO[PA[1:0]];

SPC700 SPC700 (
    .CLK(CLK),
    .RST_N(RST_N),
    .RDY(SPC700_CE),
    .IRQ_N(1'b1),
    .A_OUT(SPC700_A),
    .D_IN(SPC700_D_IN),
    .D_OUT(SPC700_D_OUT),
    .WE_N(SPC700_R_WN),

    .DBG_REG(DBG_REG),
    .DBG_DAT_IN(DBG_DAT_IN),
    .DBG_DAT_OUT(DBG_CPU_DAT),
    .DBG_DAT_WR(DBG_CPU_DAT_WR),
    .BRK_OUT(BRK_OUT)
);

always @(posedge CLK) begin : spc_timers
    reg [4:0] TM_STEP;
    reg [8:0] NEW_TM01_CNT;
    reg [5:0] NEW_TM2_CNT;

    if (~RST_N) begin
        CLK_SPEED <= 0;
        TM_SPEED <= 0;
        TIMERS_ENABLE <= 1'b1;
        TIMERS_DISABLE <= 1'b0;
        RAM_TIMER_EN <= 1;
        IPL_EN <= 1'b1;
        TM_EN <= 3'b0;
        // RESET_PORT <= 2'b11;
        CPUO <= '{4{8'b0}};
        T0OUT <= 4'b0;
        T1OUT <= 4'b0;
        T2OUT <= 4'b0;
        T0DIV <= 8'b1111_1111;
        T1DIV <= 8'b1111_1111;
        T2DIV <= 8'b1111_1111;
        AUX <= '{2{8'b0}};

        TM01_CNT <= 0;
        TM2_CNT <= 0;
        T0_CNT <= 8'b0;
        T1_CNT <= 8'b0;
        T2_CNT <= 8'b0;

        TIMER_CE <= 0;
    end else begin
        TIMER_CE <= 0;
        if (~ENABLE) begin
            if (DBG_SMP_DAT_WR) begin
                case (DBG_REG)
                    8'h01: begin
                        IPL_EN <= DBG_DAT_IN[7];
                        TM_EN <= DBG_DAT_IN[2:0];
                        RESET_PORT <= DBG_DAT_IN[5:4];
                    end
                    8'h0A: begin
                        T0DIV <= DBG_DAT_IN;
                    end
                    8'h0B: begin
                        T1DIV <= DBG_DAT_IN;
                    end
                    8'h0C: begin
                        T2DIV <= DBG_DAT_IN;
                    end
                    default: begin
                    end
                endcase
            end
        end else if (SPC700_CE) begin
            TIMER_CE <= 1;
            if (SPC700_A[15:4] == 12'h00F) begin
                if (~SPC700_R_WN) begin
                    case (SPC700_A[3:0])
                        4'h0: begin
                            CLK_SPEED <= SPC700_D_OUT[7:6];
                            TM_SPEED <= SPC700_D_OUT[5:4];
                            TIMERS_ENABLE <= SPC700_D_OUT[3];
                            RAM_WRITER_EN <= SPC700_D_OUT[1];
                            TIMERS_DISABLE <= SPC700_D_OUT[0];
                        end
                        4'h1: begin
                            IPL_EN <= SPC700_D_OUT[7];
                            // RESET_PORT <= SPC700_D_OUT[5:4];
                            TM_EN <= SPC700_D_OUT[2:0];
                            if (SPC700_D_OUT[0] && TM_EN[0] == 1'b0) begin
                                T0OUT  <= 4'b0;
                                T0_CNT <= 8'b0;
                            end
                            if (SPC700_D_OUT[1] && TM_EN[1] == 1'b0) begin
                                T1OUT  <= 4'b0;
                                T1_CNT <= 8'b0;
                            end
                            if (SPC700_D_OUT[2] && TM_EN[2] == 1'b0) begin
                                T2OUT  <= 4'b0;
                                T2_CNT <= 8'b0;
                            end
                        end
                        4'h4, 4'h5, 4'h6, 4'h7: begin
                            CPUO[SPC700_A[1:0]] <= SPC700_D_OUT;
                            $display("APU: CPUO%d=%02x", SPC700_A[1:0], SPC700_D_OUT);
                        end
                        4'h8, 4'h9:
                            AUX[SPC700_A[0:0]] <= SPC700_D_OUT;
                        4'hA: 
                            T0DIV <= SPC700_D_OUT;
                        4'hB: 
                            T1DIV <= SPC700_D_OUT;
                        4'hC: 
                            T2DIV <= SPC700_D_OUT;
                        default: begin
                        end
                    endcase
                end else begin
                    case (SPC700_A[3:0])
                        4'hD: T0OUT <= 4'b0;
                        4'hE: T1OUT <= 4'b0;
                        4'hF: T2OUT <= 4'b0;
                        default: ;
                    endcase
                end
            end

            if (TIMER_CE) begin
                TM_STEP = (5'b00001 << CLK_SPEED) + (5'b00010 << TM_SPEED);
                NEW_TM01_CNT = TM01_CNT + 9'(TM_STEP);
                if (NEW_TM01_CNT[8:7] == 2'b11) begin
                    TM01_CNT <= NEW_TM01_CNT & 9'b001111111;
                    if (TM_EN[0] && TIMERS_ENABLE && ~TIMERS_DISABLE) begin
                        T0_CNT <= T0_CNT + 1;
                        if (T0_CNT + 1 == T0DIV) begin
                            T0_CNT <= 0;
                            T0OUT  <= T0OUT + 1;
                        end
                    end
                    if (TM_EN[1] && TIMERS_ENABLE && ~TIMERS_DISABLE) begin
                        T1_CNT <= T1_CNT + 1;
                        if (T1_CNT + 1 == T1DIV) begin
                            T1_CNT <= 0;
                            T1OUT  <= T1OUT + 1;
                        end
                    end
                end else 
                    TM01_CNT <= NEW_TM01_CNT;

                NEW_TM2_CNT = TM2_CNT + TM_STEP;
                if (NEW_TM2_CNT[5:4] == 2'b11) begin
                    TM2_CNT <= NEW_TM2_CNT & 6'b001111;
                    if (TM_EN[2] && TIMERS_ENABLE && ~TIMERS_DISABLE) begin
                        T2_CNT <= T2_CNT + 1;
                        if (T2_CNT + 1 == T2DIV) begin
                            T2_CNT <= 0;
                            T2OUT  <= T2OUT + 1;
                        end
                    end
                end else 
                    TM2_CNT <= NEW_TM2_CNT;
            end
        end
    end
end

always @* begin
    if (SPC700_A[15:4] == 12'h00F) begin
        case (SPC700_A[3:0])
            4'h2, 4'h3:        //DSPADDR/DSPDATA
                SPC700_D_IN = DI;
            4'h4, 4'h5, 4'h6, 4'h7: 
                SPC700_D_IN = CPUI[SPC700_A[1:0]];
            4'hD: 
                SPC700_D_IN = {4'h0, T0OUT};
            4'hE: 
                SPC700_D_IN = {4'h0, T1OUT};
            4'hF: 
                SPC700_D_IN = {4'h0, T2OUT};
            default: 
                SPC700_D_IN = 8'b0;
        endcase
    end else if (SPC700_A >= 16'hFFC0 && IPL_EN) 
        SPC700_D_IN = IPLROM[SPC700_A[5:0]];
    else 
        SPC700_D_IN = DI;
end

assign A = SPC700_A;
assign WE_N = SPC700_R_WN;
assign DO = SPC700_D_OUT;

always @* begin
    case (DBG_REG)
        8'h00: DBG_SMP_DAT = CPUI[0];
        8'h01: DBG_SMP_DAT = CPUI[1];
        8'h02: DBG_SMP_DAT = CPUI[2];
        8'h03: DBG_SMP_DAT = CPUI[3];
        8'h04: DBG_SMP_DAT = CPUO[0];
        8'h05: DBG_SMP_DAT = CPUO[1];
        8'h06: DBG_SMP_DAT = CPUO[2];
        8'h07: DBG_SMP_DAT = CPUO[3];
        8'h08: DBG_SMP_DAT = TEST;
        8'h09: DBG_SMP_DAT = {IPL_EN, 1'b0, RESET_PORT, 1'b0, TM_EN};
        8'h0A: DBG_SMP_DAT = T0DIV;
        8'h0B: DBG_SMP_DAT = T1DIV;
        8'h0C: DBG_SMP_DAT = T2DIV;
        8'h0D: DBG_SMP_DAT = {4'b0000, T0OUT};
        8'h0E: DBG_SMP_DAT = {4'b0000, T1OUT};
        8'h0F: DBG_SMP_DAT = {4'b0000, T2OUT};
        // 8'h10:
        //   DBG_SMP_DAT = CPUI0_history[7:0];
        // 8'h11:
        //   DBG_SMP_DAT = CPUI0_history[15:8];
        // 8'h12:
        //   DBG_SMP_DAT = CPUI0_history[23:16];
        // 8'h13:
        //   DBG_SMP_DAT = CPUI0_history[31:24];

        default: DBG_SMP_DAT = 8'h00;
    endcase
end

endmodule
