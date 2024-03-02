
module SWRAM (
    input CLK,
    input SYSCLK_CE,
    input RST_N,
    input ENABLE,

    input [23:0] CA,
    input CPURD_N,
    input CPUWR_N,
    input RAMSEL_N,

    input [7:0] PA,
    input PARD_N,
    input PAWR_N,

    input CPURD_CYC_N,  // for DMA data is read before SYSCLKR_CE
    input PARD_CYC_N,

    input  [7:0] DI,
    output [7:0] DO,

    output [16:0] RAM_A,
    output [7:0] RAM_D,
    input [7:0] RAM_Q,
    output RAM_WE_N,
    output RAM_CE_N,
    output RAM_OE_N,
    output RAM_RD_N
);

    reg [23:0] WMADD;

    always @(posedge CLK) begin
        if (~RST_N ) begin
            WMADD <= 0;
        end else begin
            if (ENABLE && SYSCLK_CE) begin
                if (~PAWR_N) begin
                    case (PA)
                        8'h80: begin
                            if (RAMSEL_N) begin
                                //check if DMA use WRAM in BUS B
                                WMADD <= WMADD + 24'd1;
                            end
                        end
                        8'h81:   WMADD[7:0] <= DI;
                        8'h82:   WMADD[15:8] <= DI;
                        8'h83:   WMADD[23:16] <= DI;
                        default: ;
                    endcase

                end else if (~PARD_N) begin
                    case (PA)
                        8'h80: begin
                            if (RAMSEL_N) begin
                                //check if DMA use WRAM in ABUS
                                WMADD <= WMADD + 24'd1;
                            end
                        end
                        default: ;
                    endcase
                end
            end
        end
    end

    assign DO = RAM_Q;

    assign RAM_D = PA == 8'h80 && RAMSEL_N == 1'b0 ? 8'hFF : DI;

    assign RAM_A = RAMSEL_N == 1'b0 ? CA[16:0] : WMADD[16:0];

    assign RAM_CE_N =   ~ENABLE ? 1'b0 :
                        ~RAMSEL_N ? 1'b0 : 
                        PA == 8'h80 ? 1'b0 : 
                        1'b1;

    assign RAM_OE_N =   ~ENABLE ? 1'b0 : 
                        ~RAMSEL_N && ~CPURD_N ? 1'b0 :
                        PA == 8'h80 && ~PARD_N && RAMSEL_N ? 1'b0 : 
                        1'b1;

    assign RAM_RD_N =   ~ENABLE ? 1'b1 :        // nand2mario: do not read WRAM when CPU disabled
                        ~RAMSEL_N && ~CPURD_CYC_N ? 1'b0 : 
                        PA == 8'h80 && ~PARD_CYC_N && RAMSEL_N ? 1'b0 : 
                        1'b1;

    assign RAM_WE_N =   ~ENABLE ? 1'b1 : 
                        ~RAMSEL_N && ~CPUWR_N ? 1'b0 : 
                        PA == 8'h80 && ~PAWR_N && RAMSEL_N ? 1'b0 : 
                        1'b1;

endmodule
