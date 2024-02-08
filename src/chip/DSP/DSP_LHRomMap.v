// File DSP_LHRomMap.vhd translated with vhd2vl 3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001-2023 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2023 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

// no timescale needed

module DSP_LHRomMap(
  input WCLK,
  input RST_N,
  input ENABLE,

  input [23:0] CA,
  input [7:0] DI,
  output [7:0] DO,
  input CPURD_N,
  input CPUWR_N,

  input [7:0] PA,
  input PARD_N,
  input PAWR_N,
  input ROMSEL_N,
  input RAMSEL_N,

  input SYSCLKF_CE,
  input SYSCLKR_CE,
  input REFRESH,

  output IRQ_N,

  output [23:0] ROM_ADDR,
  input [15:0] ROM_Q,
  output ROM_CE_N,
  output ROM_OE_N,
  output ROM_WORD,

  output [19:0] BSRAM_ADDR,
  output [7:0] BSRAM_D,
  input [7:0] BSRAM_Q,
  output BSRAM_CE_N,
  output BSRAM_OE_N,
  output BSRAM_WE_N,

  output MAP_ACTIVE,
  input [7:0] MAP_CTRL,
  input [23:0] ROM_MASK,
  input [23:0] BSRAM_MASK,
  
  input [64:0] EXT_RTC
);

reg [23:0] CART_ADDR;
wire ROM_SEL;
reg [19:0] BRAM_ADDR;
reg BSRAM_SEL;
reg NO_BSRAM_SEL;
reg DP_SEL;
reg DSP_SEL;
wire [7:0] DSP_DO;
reg DSP_A0;
wire DSP_CS_N;
wire DSP_CE;
reg OBC1_SEL;
wire [12:0] OBC1_SRAM_A;
wire [7:0] OBC1_SRAM_DO;
wire [7:0] SRTC_DO;
reg SRTC_SEL;
reg [7:0] OPENBUS;
wire [2:0] MAP_DSP_VER;
wire MAP_DSP_SEL;
wire MAP_OBC1_SEL;
wire [31:0] DSP_CLK;
reg ROM_RD;
wire OBC1_RSTN;

  assign MAP_DSP_VER = {MAP_CTRL[3],MAP_CTRL[5:4]};
  assign MAP_DSP_SEL =  ~MAP_CTRL[6] & (MAP_CTRL[7] |  ~(MAP_CTRL[5] | MAP_CTRL[4]));
  //8..B
  assign MAP_OBC1_SEL = MAP_CTRL[7] & MAP_CTRL[6] &  ~MAP_CTRL[5] &  ~MAP_CTRL[4];
  //C
  assign MAP_ACTIVE = MAP_DSP_SEL | MAP_OBC1_SEL;
  CEGen CEGen(
    .CLK(WCLK),
    .RST_N(RST_N),
    .IN_CLK(10_800_000),
    .OUT_CLK(DSP_CLK),
    .CE(DSP_CE));

  assign DSP_CLK = MAP_CTRL[3] == 1'b0 ? 760000 : 1000000;
  always @(CA, MAP_CTRL, ROMSEL_N, RAMSEL_N, BSRAM_MASK, ROM_MASK) begin
    DP_SEL <= 1'b0;
    DSP_SEL <= 1'b0;
    OBC1_SEL <= 1'b0;
    SRTC_SEL <= 1'b0;
    BSRAM_SEL <= 1'b0;
    NO_BSRAM_SEL <= 1'b0;
    if(ROM_MASK[23] == 1'b0) begin
      case(MAP_CTRL[1:0])
      2'b00 : begin
        // LoROM/ExLoROM
        CART_ADDR <= {1'b0, ~CA[23],CA[22:16],CA[14:0]};
        BRAM_ADDR <= {CA[20:16],CA[14:0]};
        if(MAP_CTRL[3] == 1'b0) begin   // LoROM
          if(CA[22:20] == 3'b111 && ROMSEL_N == 1'b0) begin // 70-7D and F0-FF
            if(ROM_MASK[20] == 1'b1 || BSRAM_MASK[15] == 1'b1 || MAP_CTRL[7] == 1'b1) begin
              // rom_size >= 2MB, or ram_size >= 64KB, or map_ctrl[7]
              BSRAM_SEL <=  ~CA[15] & BSRAM_MASK[10];       // :0000-7FFF 
              NO_BSRAM_SEL <=  ~CA[15] &  ~MAP_CTRL[7] &  ~BSRAM_MASK[10];
            end else begin
              BRAM_ADDR <= CA[19:0];
              BSRAM_SEL <= BSRAM_MASK[10];
              NO_BSRAM_SEL <= ~CA[15] & ~MAP_CTRL[7] &  ~BSRAM_MASK[10];
            end
          end
          //60-6F/E0-EF:0000-7FFF
          //20-3F/A0-BF:8000-FFFF
          if((CA[22:21] == 2'b01 && CA[15] == 1'b1 && ROM_MASK[20] == 1'b0) || (CA[22:20] == 3'b110 && CA[15] == 1'b0 && ROM_MASK[20] == 1'b1)) begin
            DSP_SEL <= MAP_CTRL[7] &  ~MAP_CTRL[6];
          end
          DSP_A0 <= CA[14];
          if(CA[22] == 1'b0 && CA[15:13] == 3'b011) begin
            //00-3F/80-BF:6000-7FFF
            OBC1_SEL <= MAP_CTRL[7] & MAP_CTRL[6];
          end
        end else begin                  // ExLoROM
          if(CA[22:19] == 4'b1101 && ROMSEL_N == 1'b0) begin
            //68-6F/E8-EF:0000-0FFF
            DP_SEL <=  ~CA[11];
            BSRAM_SEL <= CA[11];
          end
          if(CA[22:19] == 4'b1100) begin
            //60-67/E0-E7:0000-0001
            DSP_SEL <= MAP_CTRL[7] &  ~MAP_CTRL[6];
          end
          DSP_A0 <= CA[0];
        end
      end
      2'b01 : begin
        // HiROM
        CART_ADDR <= {2'b00,CA[21:0]};
        BRAM_ADDR <= {2'b00,CA[20:16],CA[12:0]};
        if(CA[22:21] == 2'b01 && CA[15:13] == 3'b011 && BSRAM_MASK[10] == 1'b1) begin
          BSRAM_SEL <= 1'b1;
        end
        if(CA[22:21] == 2'b00 && CA[15:13] == 3'b011) begin
          //00-1F/80-9f:6000-7FFF
          DSP_SEL <= MAP_CTRL[7] &  ~MAP_CTRL[6];
        end
        DSP_A0 <= CA[12];
      end
      2'b10 : begin
        // ExHiROM
        CART_ADDR <= {1'b0, ~CA[23],CA[21:0]};
        BRAM_ADDR <= {1'b0,CA[21:16],CA[12:0]};
        if(CA[22:21] == 2'b01 && CA[15:13] == 3'b011 && BSRAM_MASK[10] == 1'b1) begin
          BSRAM_SEL <= 1'b1;
        end
        DSP_SEL <= 1'b0;
        DSP_A0 <= 1'b1;
        if(CA[22] == 1'b0 && CA[15:1] == {12'h280,3'b000} && MAP_CTRL[3] == 1'b1) begin
          SRTC_SEL <= 1'b1;
        end
      end
      default : begin
        // SpecialLoROM
        CART_ADDR <= {2'b00,CA[23] &  ~CA[21],CA[21:16],CA[14:0]};
        //00-1F:8000-FFFF; 20-3F/A0-BF:8000-FFFF; 80-9F:8000-FFFF
        BRAM_ADDR <= {CA[20:16],CA[14:0]};
        if(CA[22:20] == 3'b111 && CA[15] == 1'b0 && ROMSEL_N == 1'b0 && BSRAM_MASK[10] == 1'b1) begin
          BSRAM_SEL <= 1'b1;
        end
        DSP_SEL <= 1'b0;
        DSP_A0 <= 1'b1;
      end
      endcase
    end
    else begin
      //96Mbit 
      if(CA[15] == 1'b0) begin
        CART_ADDR <= {2'b10,CA[23],CA[21:16],CA[14:0]};
      end
      else begin
        CART_ADDR <= {1'b0,CA[23:16],CA[14:0]};
      end
      BRAM_ADDR <= {2'b00,CA[20:16],CA[12:0]};
      if(CA[22:21] == 2'b01 && CA[15:13] == 3'b011 && BSRAM_MASK[10] == 1'b1) begin
        BSRAM_SEL <= 1'b1;
      end
      DSP_SEL <= 1'b0;
      DSP_A0 <= 1'b1;
    end
  end

  assign ROM_SEL =  ~ROMSEL_N &  ~DSP_SEL &  ~DP_SEL &  ~SRTC_SEL &  ~BSRAM_SEL &  ~OBC1_SEL &  ~NO_BSRAM_SEL;
  assign DSP_CS_N =  ~DSP_SEL;
  DSPn dsp(
    .CLK(WCLK), .CE(DSP_CE), .RST_N(RST_N & MAP_DSP_SEL),
    .ENABLE(ENABLE),
    .A0(DSP_A0), .DI(DI), .DO(DSP_DO),
    .CS_N(DSP_CS_N), .RD_N(CPURD_N), .WR_N(CPUWR_N),
    .DP_ADDR(CA[11:0]), .DP_SEL(DP_SEL),
    .VER(MAP_DSP_VER), .REV(~MAP_CTRL[2])
  );
  // DSPn_BLOCK: if USE_DSPn = '1' generate
  // DSPn : entity work.DSPn
  // port map(
  // 	CLK			=> WCLK,
  // 	CE				=> DSP_CE,
  // 	RST_N			=> RST_N and MAP_DSP_SEL,
  // 	ENABLE		=> ENABLE,
  // 	A0				=> DSP_A0,
  // 	DI				=> DI,
  // 	DO				=> DSP_DO,
  // 	CS_N			=> DSP_CS_N,
  // 	RD_N			=> CPURD_N,
  // 	WR_N			=> CPUWR_N,
  // 	DP_ADDR     => CA(11 downto 0),
  // 	DP_SEL      => DP_SEL,
  // 	VER			=> MAP_DSP_VER,
  // 	REV			=> not MAP_CTRL(2)
  // );
  // end generate;
  assign OBC1_RSTN = RST_N & MAP_OBC1_SEL;
  OBC1 OBC1(
    .CLK(WCLK),
    .RST_N(OBC1_RSTN),
    .ENABLE(ENABLE),
    .CA(CA),
    .DI(DI),
    .CPURD_N(CPURD_N),
    .CPUWR_N(CPUWR_N),
    .SYSCLKF_CE(SYSCLKF_CE),
    .CS(OBC1_SEL),
    .SRAM_A(OBC1_SRAM_A),
    .SRAM_DI(BSRAM_Q),
    .SRAM_DO(OBC1_SRAM_DO));

  SRTC SRTC(
    .CLK(WCLK),
    .A0(CA[0]),
    .DI(DI),
    .DO(SRTC_DO),
    .CS(SRTC_SEL),
    .CPURD_N(CPURD_N),
    .CPUWR_N(CPUWR_N),
    .SYSCLKF_CE(SYSCLKF_CE),
    .EXT_RTC(EXT_RTC));

  always @(posedge WCLK) begin
    ROM_RD <= SYSCLKF_CE | SYSCLKR_CE;
  end

  assign ROM_ADDR = CART_ADDR & ROM_MASK;
  assign ROM_CE_N = ROMSEL_N;
  assign ROM_OE_N =  ~ROM_RD;
  assign ROM_WORD = 1'b0;
  assign BSRAM_ADDR = OBC1_SEL == 1'b1 ? {7'b0000000,OBC1_SRAM_A} : BRAM_ADDR & BSRAM_MASK[19:0];
  assign BSRAM_CE_N =  ~(BSRAM_SEL | OBC1_SEL);
  assign BSRAM_OE_N = CPURD_N;
  assign BSRAM_WE_N = CPUWR_N;
  assign BSRAM_D = OBC1_SEL == 1'b1 ? OBC1_SRAM_DO : DI;
  always @(posedge WCLK) begin
    if(~RST_N) begin
      OPENBUS <= {8{1'b1}};
    end else begin
      if(SYSCLKR_CE) begin
        OPENBUS <= DI;
      end
    end
  end

  assign DO = ROM_SEL == 1'b1 ? ROM_Q[7:0] : DSP_SEL == 1'b1 || DP_SEL == 1'b1 ? DSP_DO : SRTC_SEL == 1'b1 ? SRTC_DO : BSRAM_SEL == 1'b1 || OBC1_SEL == 1'b1 ? BSRAM_Q : OPENBUS;
  assign IRQ_N = 1'b1;

endmodule
