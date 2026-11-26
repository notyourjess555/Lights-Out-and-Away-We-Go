# ============================================================================
# vgafsm.do  -  ModelSim test for the VGA FSM in vgadisplaycircle.v
#
# HOW TO RUN: put these in one folder, then:  do vgafsm.do
#   vgadisplaycircle.v, vga_adapter.v, vga_controller.v,
#   vga_address_translator.v, vga_pll.v, f1_home_320_9.mif
#
# -L altera_mf_ver loads Intel's library for the adapter's memory (altsyncram)
# and PLL (altpll). It comes with ModelSim - Intel FPGA Edition.
#
# WHAT TO CHECK:
#   1. after reset: y_Q goes WAIT(1) -> CHECK(2) -> DRAW_ROW(3)/NEXT_ROW(4) ...
#      -> NEXT_LIGHT(5) for all 5 lights (first pass draws them grey)
#   2. DRAW_ROW: XC counts 0..13, write = 1, pixel_x/pixel_y move across the box
#      NEXT_ROW: XC back to 0, YC + 1   (YC counts 0..27)
#   3. lights = 10000: ONLY light LC = 0 is redrawn (colour = 1C0 red / 100 dark red),
#      LC = 1..4 go CHECK -> NEXT_LIGHT straight away (write stays 0)
#   4. back in WAIT, drawn_lights = lights
# ============================================================================

vlib work
vlog vgadisplaycircle.v vga_adapter.v vga_controller.v vga_address_translator.v vga_pll.v
vsim -L altera_mf_ver vgadisplaycircle

log {/*}
add wave -radix unsigned {/vgadisplaycircle/y_Q}
add wave -radix unsigned {/vgadisplaycircle/LC}
add wave -radix unsigned {/vgadisplaycircle/XC}
add wave -radix unsigned {/vgadisplaycircle/YC}
add wave {/vgadisplaycircle/write}
add wave -radix hexadecimal {/vgadisplaycircle/colour}
add wave -radix unsigned {/vgadisplaycircle/pixel_x}
add wave -radix unsigned {/vgadisplaycircle/pixel_y}
add wave -radix binary {/vgadisplaycircle/lights}
add wave -radix binary {/vgadisplaycircle/drawn_lights}
add wave {/vgadisplaycircle/target_on}

force {CLOCK_50} 0 0ns, 1 10ns -r 20ns

# 1. reset, all lights off -> first pass draws all 5 grey (~42 us)
force {lights} 5'b00000
force {resetn} 0
run 100ns
force {resetn} 1
run 50us

# 2. first light turns on -> only light 0 is redrawn (~9 us)
force {lights} 5'b10000
run 10us

# 3. second light turns on -> only light 1 is redrawn
force {lights} 5'b11000
run 10us
