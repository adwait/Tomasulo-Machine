#include "unistd.h"
#include "getopt.h"
#include "Vverilator_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <iostream>
#include <time.h>
#include <stdlib.h>

#define VCD_PATH_LENGTH 256
#define NUM_CYCLES 100

using namespace std;

int main(int argc, char **argv, char **env) {
  
    int c;
    int digit_optind = 0;
    char vcdfile[VCD_PATH_LENGTH];

    strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);


    while (1) {
        int this_option_optind = optind ? optind : 1;
        int option_index = 0;
        static struct option long_options[] = {
            {"vcdfile", required_argument, 0,  0 },
            {0,         0,                 0,  0 }
        };

        c = getopt_long(argc, argv, "",
                        long_options, &option_index);
        if (c == -1) break;
        
        switch (c) {
        case 0:
        if (optarg)
            strncpy(vcdfile,optarg,VCD_PATH_LENGTH);
            break;
            default:
            break;
        }
    }

    // srand(time(NULL));
    // bool arbiter_token[NUM_CYCLES];
    // int randval;
    // int cycle_count = 0;
    // for (int i = 0; i < NUM_CYCLES; i++) {
    //     randval = rand() % 2;
    //     std::cout << randval;
    //     if (randval == 0) {
    //       arbiter_token[i] = false;  
    //     }
    //     else {
    //       // change this for single core design
    //       arbiter_token[i] = false;
    //     }
        
            
    // }

  // std::cout << "here: " << arbiter_token[30] << std::endl;

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vverilator_top* verilator_top = new Vverilator_top;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);
  vluint64_t main_time = 0;
  while (!Verilated::gotFinish()) {
    // verilator_top->reset = (main_time < 20) ? 1 : 0;
    if (main_time % 10 == 5) {
    //   cycle_count = main_time/100;
    //   if (cycle_count < NUM_CYCLES)
    //     verilator_top->arbiter_token = arbiter_token[cycle_count];
    //   else
    //     verilator_top->arbiter_token = arbiter_token[NUM_CYCLES-1];
      verilator_top->clk = 0;
    }
    if (main_time % 10 == 0) {
      verilator_top->clk = 1;
    }
    verilator_top->eval();
    tfp->dump(main_time);
    main_time += 5;
  }
  delete verilator_top;
  tfp->close();
  exit(0);
}
