// SNES sound processor module

module SMP (
    input CLK,     // dclk: 24.75Mhz
    input RST_N,
    input CE,
    input ENABLE,
    input SYSCLKF_CE,

    // SMP to memory
    output wire [15:0] A,
    input wire [7:0] DI,
    output wire [7:0] DO,
    output wire WE_N,

    // PA from CPU
    input wire [1:0] PA,
    input wire PARD_N,
    input wire PAWR_N,
    input wire [7:0] CPU_DI,
    output wire [7:0] CPU_DO,
    input wire CS,
    input wire CS_N,

    // Debug
    input wire [7:0] DBG_REG,
    input wire [7:0] DBG_DAT_IN,
    output reg [7:0] DBG_SMP_DAT,
    output wire [7:0] DBG_CPU_DAT,
    input wire DBG_CPU_DAT_WR,
    input wire DBG_SMP_DAT_WR,
    output wire BRK_OUT
);

reg [7:0] SPC700_D_IN; wire [7:0] SPC700_D_OUT;
wire [15:0] SPC700_A;
wire SPC700_WE_N;
wire SPC700_CE;
reg TIMER_CE;

reg [7:0] CPUI[0:3];
reg [7:0] CPUO[0:3];
reg [7:0] TEST;
reg [2:0] TM_EN;
reg IPL_EN;
reg [7:0] T0DIV;
reg [7:0] T1DIV;
reg [7:0] T2DIV;
reg [3:0] T0OUT;
reg [3:0] T1OUT;
reg [3:0] T2OUT;
reg [1:0] RESET_PORT;
reg [6:0] TM_CNT = 7'b0;
reg [7:0] T0_CNT, T1_CNT, T2_CNT;
wire RESET01, RESET23;
reg [3:0] PAWR_Nr;
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

// always @(negedge RST_N, negedge CLK_24M) begin
always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      CPUI <= '{4{8'b0}};
      PAWR_Nr <= 4'b1111;
    end else begin
      if(ENABLE == 1'b0) begin
        if(DBG_SMP_DAT_WR == 1'b1) begin
          case(DBG_REG)
          8'h04 : begin
            CPUI[0] <= DBG_DAT_IN;
          end
          8'h05 : begin
            CPUI[1] <= DBG_DAT_IN;
          end
          8'h06 : begin
            CPUI[2] <= DBG_DAT_IN;
          end
          8'h07 : begin
            CPUI[3] <= DBG_DAT_IN;
          end
          default : begin
          end
          endcase
        end
      end else begin
        if(RESET_PORT[0] == 1'b1) begin
          CPUI[0] <= 8'b0;
          CPUI[1] <= 8'b0;
        end
        if(RESET_PORT[1] == 1'b1) begin
          CPUI[2] <= 8'b0;
          CPUI[3] <= 8'b0;
        end
      end
      PAWR_Nr <= {PAWR_Nr[2:0], PAWR_N};
      if(PAWR_Nr == 4'b1100) begin
        if(CS == 1'b1 && CS_N == 1'b0) begin
          CPUI[PA] <= CPU_DI;
        end
      end
    end
end

assign CPU_DO = CPUO[PA[1:0]];

SPC700 SPC700(
    .CLK(CLK),
    .RST_N(RST_N),
    .RDY(SPC700_CE),
    .IRQ_N(1'b1),
    .A_OUT(SPC700_A),
    .D_IN(SPC700_D_IN),
    .D_OUT(SPC700_D_OUT),
    .WE_N(SPC700_WE_N),
    .DBG_REG(DBG_REG),
    .DBG_DAT_IN(DBG_DAT_IN),
    .DBG_DAT_OUT(DBG_CPU_DAT),
    .DBG_DAT_WR(DBG_CPU_DAT_WR),
    .BRK_OUT(BRK_OUT));

always @(posedge CLK) begin
    if(RST_N == 1'b0) begin
      TEST <= 8'h0A;
      IPL_EN <= 1'b1;
      // synthesis translate_off
      IPL_EN <= 1'b0;
      // synthesis translate_on
      TM_EN <= 3'b0;
      RESET_PORT <= 2'b11;
      CPUO <= '{4{8'b0}};
      T0OUT <= 4'b0;
      T1OUT <= 4'b0;
      T2OUT <= 4'b0;
      T0DIV <= 8'b1111_1111;
      T1DIV <= 8'b1111_1111;
      T2DIV <= 8'b1111_1111;
      TM_CNT <= 7'b0;
      T0_CNT <= 8'b0;
      T1_CNT <= 8'b0;
      T2_CNT <= 8'b0;
    end else begin
      if(ENABLE == 1'b0) begin
        if(DBG_SMP_DAT_WR == 1'b1) begin
          case(DBG_REG)
          8'h01 : begin
            IPL_EN <= DBG_DAT_IN[7];
            TM_EN <= DBG_DAT_IN[2:0];
            RESET_PORT <= DBG_DAT_IN[5:4];
          end
          8'h0A : begin
            T0DIV <= DBG_DAT_IN;
          end
          8'h0B : begin
            T1DIV <= DBG_DAT_IN;
          end
          8'h0C : begin
            T2DIV <= DBG_DAT_IN;
          end
          default : begin
          end
          endcase
        end
      end
      else if (SPC700_CE) begin
        RESET_PORT <= 2'b00;
        TM_CNT <= TM_CNT + 1;
        if(TM_CNT == 127) begin
          if(TM_EN[0] == 1'b1) begin
            T0_CNT <= T0_CNT + 1;
            if((T0_CNT + 1) == (T0DIV)) begin
              T0_CNT <= 8'b0;
              T0OUT <= (T0OUT) + 1;
            end
          end
          if(TM_EN[1] == 1'b1) begin
            T1_CNT <= T1_CNT + 1;
            if((T1_CNT + 1) == (T1DIV)) begin
              T1_CNT <= 8'b0;
              T1OUT <= (T1OUT) + 1;
            end
          end
        end
        if(TM_CNT[3:0] == 15) begin
          if(TM_EN[2] == 1'b1) begin
            T2_CNT <= T2_CNT + 1;
            if((T2_CNT + 1) == (T2DIV)) begin
              T2_CNT <= 8'b0;
              T2OUT <= (T2OUT) + 1;
            end
          end
        end
        if(SPC700_A[15:4] == 12'h00F) begin
          if(SPC700_WE_N == 1'b0) begin
            case(SPC700_A[3:0])
            4'h0 : begin
              TEST <= SPC700_D_OUT;
            end
            4'h1 : begin
              IPL_EN <= SPC700_D_OUT[7];
              RESET_PORT <= SPC700_D_OUT[5:4];
              TM_EN <= SPC700_D_OUT[2:0];
              if(SPC700_D_OUT[0] == 1'b1 && TM_EN[0] == 1'b0) begin
                T0OUT <= 4'b0;
                T0_CNT <= 8'b0;
              end
              if(SPC700_D_OUT[1] == 1'b1 && TM_EN[1] == 1'b0) begin
                T1OUT <= 4'b0;
                T1_CNT <= 8'b0;
              end
              if(SPC700_D_OUT[2] == 1'b1 && TM_EN[2] == 1'b0) begin
                T2OUT <= 4'b0;
                T2_CNT <= 8'b0;
              end
            end
            4'h4,4'h5,4'h6,4'h7 : begin
              CPUO[SPC700_A[1:0]] <= SPC700_D_OUT;
            end
            4'hA : begin
              T0DIV <= SPC700_D_OUT;
            end
            4'hB : begin
              T1DIV <= SPC700_D_OUT;
            end
            4'hC : begin
              T2DIV <= SPC700_D_OUT;
            end
            default : begin
            end
            endcase
          end
          else begin
            case(SPC700_A[3:0])
            4'hD : begin
              if((T0_CNT + 1) != T0DIV) begin
                T0OUT <= 4'b0;
              end
            end
            4'hE : begin
              if((T1_CNT + 1) != T1DIV) begin
                T1OUT <= 4'b0;
              end
            end
            4'hF : begin
              if((T2_CNT + 1) != T2DIV) begin
                T2OUT <= 4'b0;
              end
            end
            default : begin
            end
            endcase
          end
        end
      end
    end
end

always @* begin
    if(SPC700_A[15:4] == 12'h00F) begin
      case(SPC700_A[3:0])
      4'h2,4'h3 : begin
        //DSPADDR/DSPDATA
        SPC700_D_IN = DI;
      end
      4'h4,4'h5,4'h6,4'h7 : begin
        SPC700_D_IN = CPUI[SPC700_A[1:0]];
      end
      4'hD : begin
        SPC700_D_IN = {4'h0,T0OUT};
      end
      4'hE : begin
        SPC700_D_IN = {4'h0,T1OUT};
      end
      4'hF : begin
        SPC700_D_IN = {4'h0,T2OUT};
      end
      default : 
        SPC700_D_IN = 8'b0;
      endcase
    end else if(SPC700_A >= 16'hFFC0 && IPL_EN == 1'b1) 
      SPC700_D_IN = IPLROM[SPC700_A[5:0]];
    else
      SPC700_D_IN = DI;
end

assign A = SPC700_A;
assign WE_N = SPC700_WE_N;
assign DO = SPC700_D_OUT;
always @* begin
    case(DBG_REG)
    8'h00 : 
      DBG_SMP_DAT = CPUI[0];
    8'h01 : 
      DBG_SMP_DAT = CPUI[1];
    8'h02 : 
      DBG_SMP_DAT = CPUI[2];
    8'h03 : 
      DBG_SMP_DAT = CPUI[3];
    8'h04 : 
      DBG_SMP_DAT = CPUO[0];
    8'h05 : 
      DBG_SMP_DAT = CPUO[1];
    8'h06 : 
      DBG_SMP_DAT = CPUO[2];
    8'h07 : 
      DBG_SMP_DAT = CPUO[3];
    8'h08 : 
      DBG_SMP_DAT = TEST;
    8'h09 : 
      DBG_SMP_DAT = {IPL_EN,1'b0,RESET_PORT,1'b0,TM_EN};
    8'h0A : 
      DBG_SMP_DAT = T0DIV;
    8'h0B : 
      DBG_SMP_DAT = T1DIV;
    8'h0C : 
      DBG_SMP_DAT = T2DIV;
    8'h0D : 
      DBG_SMP_DAT = {4'b0000,T0OUT};
    8'h0E : 
      DBG_SMP_DAT = {4'b0000,T1OUT};
    8'h0F : 
      DBG_SMP_DAT = {4'b0000,T2OUT};
    default : 
      DBG_SMP_DAT = 8'h00;
    endcase
end


endmodule
