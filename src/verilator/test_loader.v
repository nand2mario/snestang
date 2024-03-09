// this is basically hello.img but takes up less space

module test_loader (
    input clk,
    input resetn,
    output reg [7:0] dout,
    output reg dout_valid,
    output loading,
    output fail
);

// PeterLemon tests, 32KB
// localparam SIZE = 33280;
// localparam string FILE = "roms/CPUADC.hex";
// localparam string FILE = "roms/SPC700ADC.hex";
// localparam string FILE = "roms/SPC700AND.hex";
// localparam string FILE = "roms/SPC700ORA.hex";
// localparam string FILE = "roms/memtest.hex";

// 64KB ROMS
// localparam SIZE=66048;
// localparam string FILE = "roms/sram_4.hex";
// localparam string FILE = "roms/hvdma_max.hex";
// localparam string FILE = "roms/div_behavior.hex";
// localparam string FILE = "roms/div_timings.hex";
// localparam string FILE = "roms/mul_behavior.hex";
// localparam string FILE = "roms/mul_timings.hex";

// 96KB ROMS
// localparam SIZE = 98816;
///localparam string FILE = "roms/HiColor575Myst.hex";
// localparam string FILE = "roms/MosaicMode3.hex";

// 128KB ROMS
 localparam SIZE = 131584;
//  localparam string FILE = "roms/hello.hex";
// localparam string FILE = "roms/hello2.hex";
// localparam string FILE = "roms/textbuffer-hello-world.hex";
localparam string FILE = "roms/Perspective.hex";
// localparam string FILE = "roms/test_dmavalid.hex";
// localparam string FILE = "roms/test_irq4200.hex";
// localparam string FILE = "roms/test_math.hex";
// localparam string FILE = "roms/demo_irq.hex";
// localparam string FILE = "roms/dsp1demo.hex";
// localparam string FILE = "roms/SuperFX.hex";

// 512KB roms
// localparam SIZE = 524800;
// localparam string FILE = "roms/inidisp_extend_vblank.hex";

// 256KB ROMS
//localparam SIZE = 262656;
//localparam string FILE = "roms/snes_10.hex";
// localparam string FILE = "roms/hdma-textbox-wipe.hex";
// localparam string FILE = "roms/window-precalculated-symmetrical.hex";
// localparam string FILE = "roms/gradient-test.hex";

// examples
// localparam string FILE = "roms/window-shapes-single.hex";
// localparam string FILE = "roms/hdma-double-buffered-indirect-shear.hex";
// localparam string FILE = "roms/hdma-double-buffered-parallax.hex";
// localparam string FILE = "roms/hdma-indirect-repeating-pattern.hex";
// localparam string FILE = "roms/hdma-to-cgram.hex";
// localparam string FILE = "roms/vram-writes-without-dma.hex";

// effects
// localparam string FILE = "roms/vmain-vertical-scrolling.hex";
// localparam string FILE = "roms/repeating_hdma_pattern.hex";
// localparam string FILE = "roms/window-shapes-single.hex";    
// localparam string FILE = "roms/window-precalculated-single.hex";
// localparam string FILE = "roms/window-precalculated-symmetrical.hex";

// glitches
// localparam string FILE = "roms/setini-early-read-obj.hex";

// vmain-address-remapping
// localparam string FILE = "roms/vmain-1bpp-no-remapping.hex";
// localparam string FILE = "roms/vmain-8bpp-with-remapping.hex";

// 3MB ROM
// localparam SIZE = 3146240;
// localparam string FILE = "roms/super_metroid.hex";


reg [7:0] rom [0:SIZE-1];
initial begin
   $readmemh(FILE, rom);
end

reg [$clog2(SIZE)-1:0] addr = 0;
assign fail = 1'b0;
assign loading = addr != SIZE;
reg [1:0] cnt;

always @(posedge clk) begin
    if (~resetn) begin
        addr <= 0;
    end else begin
        cnt <= cnt + 1;
        case (cnt)
        2'd0: begin
            dout_valid <= 1;
            dout <= rom[addr];
        end
        2'd1: begin
            dout_valid <= 0;
            addr <= addr + 1;
            if (addr == 63)     // header is 64 bytes long
                addr <= 512;
        end
        2'd2: ;
        2'd3: 
            if (addr == SIZE)
                cnt <= 3;       // done
        endcase
    end
end

endmodule
