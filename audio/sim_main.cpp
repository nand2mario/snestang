#include <cstdio>
#include <iostream>
#include <SDL.h>
#include <cstdlib>
#include <climits>
#include <cstring>
#include <vector>
#include <cctype>

#include "Vsnestang_top.h"
#include "Vsnestang_top_snestang_top.h"
#include "verilated.h"
//#include <verilated_vcd_c.h>
#include <verilated_fst_c.h>

#define TRACE_ON

using namespace std;

// See: https://projectf.io/posts/verilog-sim-verilator-sdl/
const int H_RES = 256;
const int V_RES = 224;		// E0

typedef struct Pixel {  // for SDL texture
    uint8_t a;  // transparency
    uint8_t b;  // blue
    uint8_t g;  // green
    uint8_t r;  // red
} Pixel;

Pixel screenbuffer[H_RES*V_RES];

bool trace = false;
// Default 10 million clock cycles
long long max_sim_time = 10000000LL;
long long start_trace_time = 0;

void usage() {
	printf("Usage: sim [-t] [-c T]\n");
	printf("  -t     output trace file waveform.vcd\n");
	printf("  -s T0  start tracing from time T0\n");
	printf("  -c T   limit simulate lenght to T time steps. T=0 means infinite.\n");
}

VerilatedFstC *m_trace;
Vsnestang_top* top = new Vsnestang_top;

// split by spaces
vector<string> tokenize(string s);
long long parse_num(string s);
void trace_on();
void trace_off();

vluint64_t sim_time;
int main(int argc, char** argv, char** env) {
	Verilated::commandArgs(argc, argv);
	Vsnestang_top_snestang_top *snes = top->snestang_top;
	bool frame_updated = false;
	uint64_t start_ticks = SDL_GetPerformanceCounter();
	int frame_count = 0;

	// parse options
	for (int i = 1; i < argc; i++) {
		char *eptr;
		if (strcmp(argv[i], "-t") == 0) {
			trace = true;
			printf("Tracing ON\n");
		} else if (strcmp(argv[i], "-c") == 0 && i+1 < argc) {
			max_sim_time = strtoll(argv[++i], &eptr, 10); 
			if (max_sim_time == 0)
				printf("Simulating forever.\n");
			else
				printf("Simulating %lld steps\n", max_sim_time);
		} else if (strcmp(argv[i], "-s") == 0 && i+1 < argc) {
			start_trace_time = strtoll(argv[++i], &eptr, 10);
			printf("Start tracing from %lld\n", start_trace_time);
		} else {
			printf("Unrecognized option: %s\n", argv[i]);
			usage();
			exit(1);
		}
	}

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed.\n");
        return 1;
    }

    SDL_Window*   sdl_window   = NULL;
    SDL_Renderer* sdl_renderer = NULL;
    SDL_Texture*  sdl_texture  = NULL;

    sdl_window = SDL_CreateWindow("snestang", SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED, H_RES*2, V_RES*2, SDL_WINDOW_SHOWN);
    if (!sdl_window) {
        printf("Window creation failed: %s\n", SDL_GetError());
        return 1;
    }
    sdl_renderer = SDL_CreateRenderer(sdl_window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!sdl_renderer) {
        printf("Renderer creation failed: %s\n", SDL_GetError());
        return 1;
    }

    sdl_texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_TARGET, H_RES, V_RES);
    if (!sdl_texture) {
        printf("Texture creation failed: %s\n", SDL_GetError());
        return 1;
    }

	//VerilatedVcdC *m_trace;
	if (trace)
		trace_on();

	int audio_ready_r = 0;
	FILE *f = fopen("snes.aud", "w");
	long long samples = 0;
	bool done = false;

	while (!done) {
		while (max_sim_time == 0 || sim_time < max_sim_time) {
			top->sys_clk ^= 1;
			top->eval(); 
			if (trace && sim_time >= start_trace_time)
				m_trace->dump(sim_time);

			// collect audio sample
			if (snes->audio_ready && audio_ready_r == 0) {
				short ar, al;
				ar = snes->audio_r;
				al = snes->audio_l;			
				fwrite(&ar, sizeof(ar), 1, f);
				fwrite(&al, sizeof(al), 1, f);
				samples ++;
				if (samples % 1000 == 0)
					printf("%lld samples\n", samples);
				// printf("%hd %hd\n", top->spcplayer_top->audio_l, top->spcplayer_top->audio_r);
			}
			audio_ready_r = snes->audio_ready;

			if (snes->dotclk >= 0 && snes->y_out < V_RES && (snes->x_out >> 1) < H_RES) {
				Pixel* p = &screenbuffer[snes->y_out*H_RES + (snes->x_out >> 1)];
				int rgb = snes->rgb_out;
				p->a = 0xFF;  // transparency
				p->b = (rgb >> 10) << 3;		// convert 5-bit BGR to 8-bit RGB
				p->g = ((rgb >> 5) & 0x1f) << 3;
				p->r = (rgb & 0x1f) << 3;
			}		

			// update texture once per frame (in blanking)
			if (snes->y_out == V_RES) {
				if (!frame_updated) {
					// check for quit event
					SDL_Event e;
					if (SDL_PollEvent(&e)) {
						if (e.type == SDL_QUIT) {
							break;
						}
					}
					frame_updated = true;
					SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES*sizeof(Pixel));
					SDL_RenderClear(sdl_renderer);
					SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
					SDL_RenderPresent(sdl_renderer);
					frame_count++;				

					if (frame_count % 10 == 0)
						printf("Frame #%d\n", frame_count);
				}
			} else
				frame_updated = false;

			sim_time++;
		}	

		printf("Simulation done, time=%lu\n", sim_time);
		printf("Choose: (S)imulate, (E)nd, (T)race On, or (O)ff\n");
		printf("  s 100m - simulate 100 million clock cycles\n");
		printf("  s 0    - simulate forever\n");
		printf("  s      - simulate 10 million clock cycles\n");
		do {
			string line;
			std::getline(cin, line);
			vector<string> ss = tokenize(line);
			if (ss.size() == 0) continue;
		    transform(ss[0].begin(), ss[0].end(), ss[0].begin(), ::tolower); 
			if (ss[0] == "s" || ss[0] == "simulate") {
				long long cycles = 10000000LL;
				if (ss.size() > 1) {
					cycles = parse_num(ss[1]);
					if (cycles == -1) {
						cout << "Cannot parse number: " << ss[1] << endl;
						continue;
					}
				}
				max_sim_time += cycles;
				break;
			} else if (ss[0] == "e" || ss[0] == "end") {
				done = true;
				break;
			} else if (ss[0] == "t" || ss[0] == "trace") {
				cout << "trace on" << endl;
				trace_on();
			} else if (ss[0] == "o" || ss[0] == "off") {
				cout << "trace off" << endl;
				trace_off();
			}
		} while (1);
	}

	fclose(f);
	printf("Audio output to snes.aud done.\n");

	if (m_trace)
		m_trace->close();
	delete top;

    // calculate frame rate
    uint64_t end_ticks = SDL_GetPerformanceCounter();
    double duration = ((double)(end_ticks-start_ticks))/SDL_GetPerformanceFrequency();
    double fps = (double)frame_count/duration;
    printf("Frames per second: %.1f. Total frames=%d\n", fps, frame_count);	

    SDL_DestroyTexture(sdl_texture);
    SDL_DestroyRenderer(sdl_renderer);
    SDL_DestroyWindow(sdl_window);
    SDL_Quit();

	return 0;
}

bool is_space(char c) {
	return c == ' ' || c == '\t';
}

vector<string> tokenize(string s) {
	string w;
	vector<string> r;

	for (int i = 0; i < s.size(); i++) {
		char c = s[i];
		if (is_space(c) && w.size() > 0) {
			r.push_back(w);
			w = "";
		}
		if (!is_space(c))
			w += c;
	}
	if (w.size() > 0)
		r.push_back(w);
	return r;
}

// parse something like 100m or 10k
// return -1 if there's an error
long long parse_num(string s) {
	long long times = 1;
	if (s.size() == 0)
		return -1;
	char last = tolower(s[s.size()-1]);
	if (last >= 'a' && last <= 'z') {
		s = s.substr(0, s.size()-1);
		if (last == 'k')
		 	times = 1000LL;
		else if (last == 'm')
			times = 1000000LL;
		else if (last == 'g')
			times = 1000000000LL;
		else 
			return -1;
	}
	return atoll(s.c_str()) * times;
}

void trace_on() {
	if (!m_trace) {
		//m_trace = new VerilatedVcdC;
		//m_trace->open("waveform.vcd");
		m_trace = new VerilatedFstC;
		top->trace(m_trace, 5);
		Verilated::traceEverOn(true);
		m_trace->open("waveform.fst");
	}
}

void trace_off() {
	if (m_trace) {
		top->trace(m_trace, 0);
	}
}
