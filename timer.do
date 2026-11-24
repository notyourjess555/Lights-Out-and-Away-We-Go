# ============================================================================
# timer.do  -  ModelSim test for timer.v (BCD reaction timer)
#
# HOW TO RUN: in ModelSim, File > Change Directory to the folder with timer.v,
#             then in the Transcript type:  do timer.do
#
# In this test "1 ms" = 1 pulse every 5 clocks (100 ns), so it runs fast.
# reaction_time is shown in HEX radix, so the BCD digits read as decimal ms.
#
# WHAT TO CHECK IN THE WAVEFORM:
#   1. reset / clear   -> reaction_time = 0000, finished = 0
#   2. run = 0         -> nothing counts (game not in GO yet)
#   3. run = 1         -> counts 0001, 0002 ... 0009, 0010 (carry!), ... 0099, 0100
#   4. stop_pulse      -> finished = 1, time frozen at 0123
#   5. more ms pulses  -> still 0123 (frozen)
#   6. clear           -> back to 0000, finished = 0
# ============================================================================

vlib work
vlog timer.v
vsim timer

log {/*}
add wave {/*}
radix -hexadecimal

# 50 MHz clock: 20 ns period
force {CLOCK_50} 0 0ns, 1 10ns -r 20ns

# "1 ms" tick: high for 1 clock every 5 clocks
force {one_millisecond} 0 0ns, 1 80ns -r 100ns

# 1. reset
force {resetn} 0
force {clear} 0
force {run} 0
force {stop_pulse} 0
run 100ns
force {resetn} 1

# 2. not running yet: should stay 0000
run 500ns

# 3. GO: count for 123 "ms"
force {run} 1
run 12300ns

# 4. player presses: one clock pulse
force {stop_pulse} 1
run 20ns
force {stop_pulse} 0

# 5. stays frozen
run 1000ns

# 6. next round: clear
force {run} 0
force {clear} 1
run 40ns
force {clear} 0
run 200ns
