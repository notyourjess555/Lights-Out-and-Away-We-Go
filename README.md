# Lights-Out-and-Away-We-Go
Lights Out and Away We Go: Formula 1 Launch Reflex Game

"It's lights out and away we go!" 
Think you have the reflexes of an F1 driver? Test your launch reaction time on real FPGA hardware. Five red lights illuminate sequentially before holding for a randomized delay. The second they go dark, slam the button to lock in your millisecond score. Did you win over your friend?

## Introduction
A hardware-level Formula 1 race-start reaction game built in mainly with Verilog. 


This project uses digital logic and Iis implementedmplemented entirely in synthesizable Verilog, FPGA, VGA and Audio controller. 

The system uses a Finite State Machine (FSM), clock dividers, and a Linear Feedback Shift Register (LFSR) to generate a non-deterministic launch window. Record their millisecond response time on a 7-segment display, with multiple rounds.