# Tomasulo-Machine

This a basic Out-of-Order pipelined processor that can process LOAD, ADD, SUB, MUL & DIV instructions. Instructions ADD & SUB have got the same RS and similarly instructions MUL & DIV have got the same RS. LOAD instructions are stored in the LSQ before getting issued. The concept of ROB and RAT is also implemented. Each instruction has got a single cycle latency.
