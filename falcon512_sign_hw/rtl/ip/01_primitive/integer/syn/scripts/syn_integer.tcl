#============================================================
# syn_integer.tcl
# Synthesis script for 01_primitive/integer/
# Tool: Synopsys Design Compiler
# Library: SAED 90nm typical
#============================================================

#------------------------------------------------------------
# Library setup
#------------------------------------------------------------
set LIB_PATH /home/ltk/ASIC_LIB/ICC/lib/db

set target_library [list $LIB_PATH/saed90nm_typ.db]
set link_library   [concat "*" $target_library]

#------------------------------------------------------------
# Work library
#------------------------------------------------------------
define_design_lib WORK -path ./work

#------------------------------------------------------------
# RTL file list
# Do not include testbench files
#------------------------------------------------------------
set RTL_LIST [list \
    ../int_add.v \
    ../int_sub.v \
    ../abs.v \
    ../square.v \
    ../accumulator.v \
    ../comparator.v \
]

#------------------------------------------------------------
# Top modules to synthesize
#------------------------------------------------------------
set TOP_LIST [list \
    int_add \
    int_sub \
    abs \
    square \
    accumulator \
    comparator \
]

#------------------------------------------------------------
# Basic constraint
#------------------------------------------------------------
set CLK_PERIOD 10.0

#------------------------------------------------------------
# Synthesis each integer primitive
#------------------------------------------------------------
foreach TOP $TOP_LIST {

    puts "============================================================"
    puts "SYNTHESIS TOP: $TOP"
    puts "============================================================"

    remove_design -all

    analyze -format verilog $RTL_LIST
    elaborate $TOP
    current_design $TOP
    link
    uniquify

    #--------------------------------------------------------
    # Timing constraints
    #--------------------------------------------------------
    set clk_ports [get_ports -quiet clk]

    if {[sizeof_collection $clk_ports] > 0} {
        create_clock -name clk -period $CLK_PERIOD $clk_ports
        set_dont_touch_network $clk_ports

        set rst_ports [get_ports -quiet rst_n]
        if {[sizeof_collection $rst_ports] > 0} {
            set_false_path -from $rst_ports
        }

        set input_ports_no_clk [remove_from_collection [all_inputs] $clk_ports]
        set_input_delay  1.0 -clock clk $input_ports_no_clk
        set_output_delay 1.0 -clock clk [all_outputs]
    } else {
        # For pure combinational modules
        set_max_delay $CLK_PERIOD -from [all_inputs] -to [all_outputs]
    }

    set_max_area 0

    #--------------------------------------------------------
    # Check design before compile
    #--------------------------------------------------------
    check_design > reports/${TOP}_check_design.rpt

    #--------------------------------------------------------
    # Compile
    #--------------------------------------------------------
    compile

    #--------------------------------------------------------
    # Reports
    #--------------------------------------------------------
    report_area   > reports/${TOP}_area.rpt
    report_timing > reports/${TOP}_timing.rpt
    report_power  > reports/${TOP}_power.rpt
    report_cell   > reports/${TOP}_cell.rpt
    check_design  > reports/${TOP}_check_after_compile.rpt

    #--------------------------------------------------------
    # Output synthesized files
    #--------------------------------------------------------
    write -format verilog -hierarchy -output netlist/${TOP}_syn.v
    write_sdf sdf/${TOP}.sdf

    puts "DONE SYNTHESIS TOP: $TOP"
}

quit
