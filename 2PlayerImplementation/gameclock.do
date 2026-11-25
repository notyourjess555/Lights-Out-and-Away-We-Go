# ============================================================================
# gameclock.do  -  ModelSim test for gameclock.v (REAL speed, no changes needed)
#
# HOW TO RUN: put gameclock.do next to gameclock.v, then:  do gameclock.do
#
# 50 MHz clock -> 50,000 clocks per ms. ModelSim simulates 3 ms
# (150,000 clocks) in a few seconds, so we test the REAL 49999 value.
#
# WHAT TO CHECK:
#   1. one_millisecond is a 1-clock pulse (20 ns wide)
#   2. pulses are exactly 1 ms apart: place cursor 1 on one pulse,
#      cursor 2 on the next one -> the time between cursors = 1 ms
#   3. counter goes 0 -> 49999 then back to 0 (set counter radix to unsigned)
# ============================================================================

vlib work
vlog gameclock.v
vsim gameclock

log {/*}
add wave {/*}
radix -unsigned

force {CLOCK_50} 0 0ns, 1 10ns -r 20ns

force {resetn} 0
run 100ns
force {resetn} 1

run 3ms
