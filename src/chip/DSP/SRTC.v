
module SRTC (
    input CLK,
    input A0,
    input [7:0] DI,
    output [7:0] DO,
    input CS,
    input CPURD_N,
    input CPUWR_N,
    input SYSCLKF_CE,
    input [64:0] EXT_RTC
);

reg [3:0] REGS[0:12];
reg [31:0] INDEX = 15;
reg [31:0] MODE = 0;
reg [31:0] SEC_DIV = 0;
reg SEC_TICK = 1'b0;
reg LAST_RTC64 = 1'b0;
// Last day of each month
localparam [7:0] DAYS_TBL[0:12] = {
    8'd31, 8'd31, 8'd28, 8'd31, 8'd30, 8'd31, 8'd30, 8'd31, 
    8'd31, 8'd30, 8'd31, 8'd30, 8'd31
};

always @(posedge CLK) begin
    SEC_TICK <= 1'b0;
    SEC_DIV  <= SEC_DIV + 1;
    if (SEC_DIV == (21477270 - 1)) begin
        SEC_DIV  <= 0;
        SEC_TICK <= 1'b1;
    end
end

always @(posedge CLK) begin : P1
    reg [3:0] DAY_OF_MONTH_L;
    reg [3:0] DAY_OF_MONTH_H;

    DAY_OF_MONTH_H = DAYS_TBL[REGS[8]][7:4];
    DAY_OF_MONTH_L = DAYS_TBL[REGS[8]][3:0];
    if (SEC_TICK == 1'b1) begin
        REGS[0] <= (REGS[0]) + 1;
        //sec low inc
        if (REGS[0] == 4'h9) begin
            REGS[0] <= 0;
            REGS[1] <= (REGS[1]) + 1;
            //sec high inc
            if (REGS[1] == 4'h5) begin
                REGS[1] <= 0;
                REGS[2] <= (REGS[2]) + 1;
                //min low inc
                if (REGS[2] == 4'h9) begin
                    REGS[2] <= 0;
                    REGS[3] <= (REGS[3]) + 1;
                    //min high inc
                    if (REGS[3] == 4'h5) begin
                        REGS[3] <= 0;
                        REGS[4] <= (REGS[4]) + 1;
                        //hour low inc
                        if (REGS[4] == 4'h9 && REGS[5] <= 4'h2) begin
                            REGS[4] <= 0;
                            REGS[5] <= (REGS[5]) + 1;
                            //hour high inc
                        end else if (REGS[4] == 4'h3 && REGS[5] == 4'h2) begin
                            REGS[4] <= 0;
                            REGS[5] <= 0;
                            REGS[6] <= (REGS[6]) + 1;
                            //day low inc
                            if (REGS[6] == 4'h9 && REGS[7][1:0] <= 2) begin
                                REGS[6] <= 0;
                                REGS[7] <= (REGS[7]) + 1;
                                //day high inc
                            end
            else if(REGS[6] == DAY_OF_MONTH_L && REGS[7] == DAY_OF_MONTH_H) begin
                                REGS[6] <= 4'h1;
                                REGS[7] <= 0;
                                REGS[8] <= (REGS[8]) + 1;
                                //month inc
                                if (REGS[8] == 4'hC) begin
                                    REGS[8] <= 4'h1;
                                    REGS[9] <= (REGS[9]) + 1;
                                    //year low inc
                                    if (REGS[9] == 4'h9) begin
                                        REGS[9]  <= 0;
                                        REGS[10] <= (REGS[10]) + 1;
                                        //year high inc
                                        if (REGS[10] == 4'h9) begin
                                            REGS[10] <= 0;
                                            REGS[11] <= (REGS[11]) + 1;
                                            //century inc
                                            if (REGS[11] == 4'hC) begin
                                                REGS[11] <= 0;
                                            end
                                        end
                                    end
                                end
                            end
                            REGS[12] <= (REGS[12]) + 1;
                            //weeks inc
                            if (REGS[12] == 4'h6) begin
                                REGS[12] <= 0;
                            end
                        end
                    end
                end
            end
        end
    end
    if (EXT_RTC[64] != LAST_RTC64) begin
        LAST_RTC64 <= EXT_RTC[64];
        REGS[0] <= EXT_RTC[3:0];
        REGS[1] <= EXT_RTC[7:4];
        REGS[2] <= EXT_RTC[11:8];
        REGS[3] <= EXT_RTC[15:12];
        REGS[4] <= EXT_RTC[19:16];
        REGS[5] <= EXT_RTC[23:20];
        REGS[6] <= EXT_RTC[27:24];
        REGS[7] <= EXT_RTC[31:28];
        if (EXT_RTC[36] == 1'b0) begin
            REGS[8] <= EXT_RTC[35:32];
        end else begin
            REGS[8] <= (EXT_RTC[35:32]) + 10;
        end
        REGS[9]  <= EXT_RTC[43:40];
        REGS[10] <= EXT_RTC[47:44];
        REGS[11] <= 4'hA;
        REGS[12] <= EXT_RTC[51:48];
    end
    if (CS == 1'b1 && SYSCLKF_CE == 1'b1) begin
        if (CPUWR_N == 1'b0 && A0 == 1'b1) begin
            if (DI[3:0] == 4'hD) begin
                INDEX <= 15;
                MODE  <= 0;
            end else if (DI[3:0] == 4'hE) begin
                MODE <= 1;
            end else begin
                if (MODE == 1) begin
                    case (DI[3:0])
                        4'h0: begin
                            MODE  <= 2;
                            INDEX <= 0;
                        end
                        default: begin
                            MODE <= 3;
                        end
                    endcase
                end else if (MODE == 2) begin
                    if (INDEX < 12) begin
                        REGS[INDEX] <= DI[3:0];
                        INDEX <= INDEX + 1;
                    end
                end
            end
        end
        if (CPURD_N == 1'b0 && A0 == 1'b0) begin
            if (MODE == 0) begin
                if (INDEX == 13) begin
                    INDEX <= 15;
                end else begin
                    INDEX <= INDEX + 1;
                end
            end
        end
    end
end

assign DO = INDEX <= 12 ? {4'h0, REGS[INDEX]} : 8'h0F;

endmodule
