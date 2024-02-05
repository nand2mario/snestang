N=snestang_top
D=../src
SRCS=$D/dsp.v $D/snestang_top.v $D/smp.v $D/spc700/_spc700_package.v $D/spc700/addrgen.v \
	 $D/spc700/addsub.v $D/spc700/alu.v $D/spc700/bcdadj.v $D/spc700/mcode.v $D/spc700/muldiv.v $D/spc700/spc700.v \
	 $D/cpu.v $D/ppu.v $D/CEGen.v $D/main.v $D/ppuhoam.v $D/ppuoam.v $D/testrom.v \
	 $D/65C816/common.sv $D/65C816/ALU.v $D/65C816/AddSubBCD.v $D/65C816/AddrGen.v $D/65C816/BCDAdder.v \
	 $D/65C816/adder4.v $D/65C816/bit_adder.v $D/65C816/mcode.sv $D/65C816/P65C816.v \
	 $D/chip/DSP/DSP_LHRomMap.v $D/chip/DSP/OBC1.v $D/chip/DSP/SRTC.v \
	 $D/vram.v $D/test_loader.v $D/SNES.v $D/sdram_sim.v $D/swram.v
DEPS=$D/ppu_defines.vh
INCLUDES=-I$D -I$D/spc700 -I$D/65C816

CFLAGS_SDL=$(shell sdl2-config --cflags) -O3
LIBS_SDL=$(shell sdl2-config --libs)

.PHONY: build sim verilate clean gtkwave audio
	
build: ./obj_dir/V$N

verilate: ./obj_dir/V$N.cpp

./obj_dir/V$N.cpp: sim_main.cpp $(SRCS) $(DEPS)
	@echo
	@echo "### VERILATE ####"
	mkdir -p obj_dir
	#verilator --top-module $N --trace -cc -O3 --exe -CFLAGS "$(CFLAGS_SDL)" -LDFLAGS "$(LIBS_SDL)" $(INCLUDES) $(SRCS) sim_main.cpp
	verilator --top-module $N --trace-fst -cc -O3 --exe -CFLAGS "$(CFLAGS_SDL)" -LDFLAGS "$(LIBS_SDL)" $(INCLUDES) $(SRCS) sim_main.cpp

./obj_dir/V$N: verilate
	@echo
	@echo "### BUILDING SIM ###"
	make -C obj_dir -f V$N.mk V$N
	cp -a $D/roms obj_dir
#	cp -a $D/spc700/mcode.bin obj_dir
#	cp -a $D/65C816/mcode_65c816*.bin obj_dir
	test -s obj_dir/random_4m_words.hex || hexdump -vn8388608 -e '8/2 "%04x ""\n"' /dev/random > obj_dir/random_4m_words.hex

sim: ./obj_dir/V$N
	@echo
	@echo "### SIMULATION (GUI) ###"
	@cd obj_dir && ./V$N -c 200000000

trace: ./obj_dir/V$N
	@echo
	@echo "### SIMULATION (trace) ###"
	@cd obj_dir && ./V$N -t -c 400000000 -s 300000000
# @cd obj_dir && ./V$N -t -c 100000000 -s 75000000

trace2: ./obj_dir/V$N
	@echo
	@echo "### SIMULATION (trace) ###"
	@cd obj_dir && ./V$N -t -c 120000000

gtkwave:
	gtkwave obj_dir/waveform.vcd

audio:
	ffmpeg -y -f s16le -ar 32k -ac 2 -i obj_dir/snes.aud snes.wav

clean:
	rm -rf obj_dir
