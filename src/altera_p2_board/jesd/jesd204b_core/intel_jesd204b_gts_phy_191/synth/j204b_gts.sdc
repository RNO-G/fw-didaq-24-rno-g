# (C) 2001-2025 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


## JESD204B IP SDC start  ####################################
set jesd204_sdc_debug 0

# Check if port exists
proc jesd204_port_existence {port_name} {
   set port_collection [get_ports -nowarn $port_name]
   if { [get_collection_size $port_collection] > 0 } {
      return 1
   } else {
      return 0
   }
}

# Return existing clock target list
proc jesd204_get_clock_target_list {} {
   upvar 1 jesd204_sdc_debug jesd204_sdc_debug

   set result [list]
   set clocks_collection [get_clocks -nowarn]
   foreach_in_collection clock $clocks_collection { 
      set clock_name       [get_clock_info -name $clock] 
      set clock_target_col [get_clock_info -targets $clock]
      lappend result       [query_collection -report -all $clock_target_col]
      if {$jesd204_sdc_debug} { post_message -type info "clock_name : $clock_name" }
   }
   if {$jesd204_sdc_debug} { post_message -type info "JESD204 clock_target list: $result" }

   return $result
}

#Return searched clock name
proc get_clock_name {name} {
    set result [list]
    set clocks_collection [get_clocks -nowarn $name]
    foreach_in_collection clock $clocks_collection {
        set clock_name     [get_clock_info -name $clock] 
        append result      "$clock_name "
    }
    return $result
}

############### create clocks  ####################################################################
    set jesd204_clock_target_list [jesd204_get_clock_target_list]

		set jesd204_rx_avs_clk_ext      [jesd204_port_existence jesd204_rx_avs_clk]
		set jesd204_rx_avs_clk_lsrc     [lsearch -exact $jesd204_clock_target_list jesd204_rx_avs_clk]
			if {$jesd204_rx_avs_clk_ext && $jesd204_rx_avs_clk_lsrc == -1} {
				create_clock -name "jesd204_rx_avs_clk"       -period 8.000ns       [get_ports jesd204_rx_avs_clk] 
			}
		set rxlink_clk_ext      [jesd204_port_existence rxlink_clk]
		set rxlink_clk_lsrc     [lsearch -exact $jesd204_clock_target_list rxlink_clk]
			if {$rxlink_clk_ext && $rxlink_clk_lsrc == -1} {
				create_clock -name "rxlink_clk"       -period 4.000ns      [get_ports rxlink_clk]
			}


############### set clock group  ####################################################################
    ############## RX set clock group command ####################################
    set clock_grp_rx_tmp {set_clock_groups -asynchronous }

			set rx_clkout [get_clock_name *o_rx_clkout[*]]
			set rx_clkout_collection [get_clocks -nowarn *o_rx_clkout[*]]
			if {[get_collection_size $rx_clkout_collection] > 0 } {
				append clock_grp_rx_tmp "-group {$rx_clkout } "    
			}

	if {$jesd204_rx_avs_clk_ext} {
		append clock_grp_rx_tmp "-group {jesd204_rx_avs_clk} "
	}
	if {$rxlink_clk_ext} {
		append clock_grp_rx_tmp "-group {rxlink_clk} "
	}
	if {$jesd204_sdc_debug} { post_message -type info "set_clock_group command: $clock_grp_rx_tmp"}
        if {$jesd204_rx_avs_clk_ext} {
            eval $clock_grp_rx_tmp
        }





