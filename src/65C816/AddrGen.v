
module AddrGen(CLK, RST_N, EN, LOAD_PC, PCDec, GotInterrupt, ADDR_CTRL, IND_CTRL, D_IN, X, Y, D, S, T, DR, DBR, e6502, PC, AA, AB, DX, AALCarry, JumpNoOfl);
   input         CLK;
   input         RST_N;
   input         EN;
   input [2:0]   LOAD_PC;
   input         PCDec;
   input         GotInterrupt;
   input [7:0]   ADDR_CTRL;
   input [1:0]   IND_CTRL;
   input [7:0]   D_IN;
   input [15:0]  X;
   input [15:0]  Y;
   input [15:0]  D;
   input [15:0]  S;
   input [15:0]  T;
   input [7:0]   DR;
   input [7:0]   DBR;
   input         e6502;
   output [15:0] PC;
   output [16:0] AA;
   output [7:0]  AB;
   reg [7:0]     AB;
   output [15:0] DX;
   output        AALCarry;
   output        JumpNoOfl;


   reg [7:0]     AAL;
   reg [7:0]     AAH;
   reg [7:0]     DL;
   reg [7:0]     DH;
   reg           SavedCarry;
   reg           AAHCarry;

   reg [8:0]     NewAAL;
   reg [8:0]     NewAAH;
   wire [8:0]    NewAAHWithCarry;
   wire [8:0]    NewDL;
   wire [15:0]   InnerDS;

   reg [15:0]    PCr;
   reg [15:0]     PCOffset;
   reg [15:0]    NextPC;
   wire [15:0]   NewPCWithOffset;
   wire [15:0]   NewPCWithOffset16;

   wire [2:0]    AALCtrl;
   wire [2:0]    AAHCtrl;
   wire [1:0]    ABSCtrl;

   assign NewPCWithOffset16 = (PCr + PCOffset);
   assign NewPCWithOffset = PCr + { {8{DR[7]}}, DR };

   always @* begin
      case (LOAD_PC)
         3'b000 :
            NextPC = PCr;
         3'b001 :
            if (GotInterrupt == 1'b0)
               NextPC = (PCr + 16'd1);
            else
               NextPC = PCr;
         3'b010 :
            NextPC = {D_IN, DR};
         3'b011 :
            NextPC = NewPCWithOffset16;
         3'b100 :
            NextPC = NewPCWithOffset;
         3'b101 :
            NextPC = NewPCWithOffset16;
         3'b110 :
            NextPC = {AAH, AAL};
         3'b111 :
            if (PCDec == 1'b1)
               NextPC = (PCr - 16'd3);
            else
               NextPC = PCr;
         default :
            NextPC = PCr;
      endcase
   end

   always @(posedge CLK) begin
      if (RST_N == 1'b0)
      begin
         PCr <= 16'b0;
         PCOffset <= 16'b0;
      end
      else
      begin
         if (EN == 1'b1)
         begin
            PCOffset <= ({D_IN, DR});
            PCr <= NextPC;
         end
      end
   end

   assign JumpNoOfl = ((~(PCr[8] ^ NewPCWithOffset[8]))) & ((~LOAD_PC[0])) & ((~LOAD_PC[1])) & LOAD_PC[2];

   assign AALCtrl = ADDR_CTRL[7:5];
   assign AAHCtrl = ADDR_CTRL[4:2];
   assign ABSCtrl = ADDR_CTRL[1:0];


   always @*
   begin
      case (IND_CTRL)
         2'b00 :
            if (AALCtrl[2] == 1'b0)
               NewAAL = (({1'b0, AAL}) + ({1'b0, X[7:0]}));
            else
               NewAAL = (({1'b0, DL}) + ({1'b0, X[7:0]}));
         2'b01 :
            if (AALCtrl[2] == 1'b0)
               NewAAL = (({1'b0, AAL}) + ({1'b0, Y[7:0]}));
            else
               NewAAL = (({1'b0, DL}) + ({1'b0, Y[7:0]}));
         2'b10 :
            NewAAL = {1'b0, X[7:0]};
         2'b11 :
            NewAAL = {1'b0, Y[7:0]};
         default :
            ;
      endcase

      if (e6502 == 1'b0)
         case (IND_CTRL)
            2'b00 :
               if (AAHCtrl[2] == 1'b0)
                  NewAAH = (({1'b0, AAH}) + ({1'b0, X[15:8]}));
               else
                  NewAAH = (({1'b0, DH}) + ({1'b0, X[15:8]}) + ({8'b00000000, NewAAL[8]}));
            2'b01 :
               if (AAHCtrl[2] == 1'b0)
                  NewAAH = (({1'b0, AAH}) + ({1'b0, Y[15:8]}));
               else
                  NewAAH = (({1'b0, DH}) + ({1'b0, Y[15:8]}) + ({8'b00000000, NewAAL[8]}));
            2'b10 :
               NewAAH = {1'b0, X[15:8]};
            2'b11 :
               NewAAH = {1'b0, Y[15:8]};
            default :
               ;
         endcase
      else
         if (AAHCtrl[2] == 1'b0)
            NewAAH = {1'b0, AAH};
         else
            NewAAH = {1'b0, DH};
   end

   assign InnerDS = (ABSCtrl == 2'b11 & (AALCtrl[2] == 1'b1 | AAHCtrl[2] == 1'b1)) ? S :
                    (e6502 == 1'b0) ? D :
                    {D[15:8], 8'h00};

   assign NewDL = (({1'b0, InnerDS[7:0]}) + ({1'b0, D_IN}));
   assign NewAAHWithCarry = (NewAAH + ({8'b00000000, SavedCarry}));


   always @(posedge CLK)
      if (RST_N == 1'b0)
      begin
         AAL <= 8'd0;
         AAH <= 8'd0;
         AB <= 8'd0;
         DL <= 8'd0;
         DH <= 8'd0;
         AAHCarry <= 1'b0;
         SavedCarry <= 1'b0;
      end
      else
      begin
         if (EN == 1'b1)
         begin
            case (AALCtrl)
               3'b000 :
                  begin
                     if (IND_CTRL[1] == 1'b1)
                        AAL <= NewAAL[7:0];
                     SavedCarry <= 1'b0;
                  end
               3'b001 :
                  begin
                     AAL <= NewAAL[7:0];
                     SavedCarry <= NewAAL[8];
                  end
               3'b010 :
                  begin
                     AAL <= D_IN;
                     SavedCarry <= 1'b0;
                  end
               3'b011 :
                  begin
                     AAL <= NewPCWithOffset16[7:0];
                     SavedCarry <= 1'b0;
                  end
               3'b100 :
                  begin
                     DL <= NewAAL[7:0];
                     SavedCarry <= NewAAL[8];
                  end
               3'b101 :
                  begin
                     DL <= NewDL[7:0];
                     SavedCarry <= NewDL[8];
                  end
               3'b111 :
                  ;
               default :
                  ;
            endcase

            case (AAHCtrl)
               3'b000 :
                  if (IND_CTRL[1] == 1'b1)
                  begin
                     AAH <= NewAAH[7:0];
                     AAHCarry <= 1'b0;
                  end
               3'b001 :
                  begin
                     AAH <= NewAAHWithCarry[7:0];
                     AAHCarry <= NewAAHWithCarry[8];
                  end
               3'b010 :
                  begin
                     AAH <= D_IN;
                     AAHCarry <= 1'b0;
                  end
               3'b011 :
                  begin
                     AAH <= NewPCWithOffset16[15:8];
                     AAHCarry <= 1'b0;
                  end
               3'b100 :
                  begin
                     DH <= NewAAH[7:0];
                     AAHCarry <= 1'b0;
                  end
               3'b101 :
                  begin
                     DH <= InnerDS[15:8];
                     AAHCarry <= 1'b0;
                  end
               3'b110 :
                  begin
                     DH <= (DH + ({7'b0000000, SavedCarry}));
                     AAHCarry <= 1'b0;
                  end
               3'b111 :
                  ;
               default :
                  ;
            endcase

            case (ABSCtrl)
               2'b00 :
                  ;
               2'b01 :
                  AB <= D_IN;
               2'b10 :
                  AB <= (D_IN + ({7'b0000000, NewAAHWithCarry[8]}));
               2'b11 :
                  if (AALCtrl[2] == 1'b0 & AAHCtrl[2] == 1'b0)
                     AB <= DBR;
               default :
                  ;
            endcase
         end
      end

   assign AALCarry = NewAAL[8];
   assign AA = {AAHCarry, AAH, AAL};
   assign DX = {DH, DL};
   assign PC = PCr;

endmodule
