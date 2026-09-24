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


## SDC ##
 
## set global variables
global ::ip_sdc_debug
 
 
 set ip_sdc_debug 0
 
 ## get current IP instance 
 set ip_inst_name [get_current_instance]
 if {$ip_sdc_debug == 1} { 
	post_message -type info "IP SDC: $ip_inst_name"
 }

set clock_search [get_clocks -nowarn ${ip_inst_name}_src_divided_osc_clk[0]]

if {[get_collection_size $clock_search] == 0 } {
create_generated_clock -divide_by 2 \
       -source [get_nodes {*|intosc|oscillator_dut~oscillator_clock}] \
         -name "${ip_inst_name}_src_divided_osc_clk[0]"  [get_registers "${ip_inst_name}*|divided_osc_clk" ]
}

## ----------------------------------------------------------------------------- #
## ---  Clock Crosser constraint and skew constraint                       --- #
## ----------------------------------------------------------------------------- #
#
proc constraint_net_delay {from_reg to_reg max_net_delay {check_exist 0} {get_pins 1} {set_skew_constraint 1} {set_mstable 1} {set_no_synchronizer 0}} {
    # Check for instances
    set inst [get_registers -nowarn ${to_reg}]
    
    # Check number of instances
    set inst_num [llength [query_collection -report -all $inst]]
    if {$inst_num > 0} {
        # Uncomment line below for debug purpose
        #puts "${inst_num} ${to_reg} instance(s) found"
    } else {
        # Uncomment line below for debug purpose
        #puts "No ${to_reg} instance found"
    }
  if {($set_skew_constraint == 0)} {   
    if {($check_exist == 0) || ($inst_num > 0)} {
        if { [string equal "quartus_sta" $::TimeQuestInfo(nameofexecutable)] } {
            if {$set_no_synchronizer == 1} {
                set_max_delay -no_synchronizer -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] 200ns
            } else {
                set_max_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] 200ns
            }
            set_min_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] -200ns
        } else {
            if {$get_pins == 0} {
                set_net_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] -max $max_net_delay
            } else {
                set_net_delay -from [get_pins -compatibility_mode ${from_reg}|q] -to [get_registers ${to_reg}] -max $max_net_delay
            }
            
            # Relax the fitter effort
            if {$set_no_synchronizer == 1} {
                set_max_delay -no_synchronizer -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] 200ns
            } else {
                set_max_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] 200ns
            }
            set_min_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] -200ns
        }
    }
  } else {   
        #set skew and min/max delay for EFIFO
        # control skew for bits
        set_max_skew -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8
        # path delay (exception for net delay)
        if { ![string equal "quartus_sta" $::TimeQuestInfo(nameofexecutable)] } {
            set_net_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
        }
        #relax setup and hold calculation
        if {$set_no_synchronizer == 1} {
            set_max_delay -no_synchronizer -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] 100
        } else {
            set_max_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] 100
        }
        set_min_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] -100		
  }
	
    #set Meta stability for EFIFO 
    if {($set_mstable == 1)} {
		if { ![string equal "quartus_sta" $::TimeQuestInfo(nameofexecutable)] } {
			set_net_delay -from [get_registers ${from_reg}] -to [get_registers ${to_reg}] -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
		}
    }
}
#------------------------------------------------------------------------
constraint_net_delay  *  *|src_lane|sm_src_csr|sclr_d1 2.2ns 1 0 0 0 0	
constraint_net_delay  *  *|src_lane|sm_src_csr|sclr_d2 2.2ns 1 0 0 0 0	
# csr_readdata
constraint_net_delay  *  *|src_lane|sm_src_csr|dr_csr_rdata[*]  2.2ns 1 0 0 0 0
									 
constraint_net_delay  *  *|src_lane|sm_src_csr|csr_read_count_reg[*] 2.2ns 1 0 0 0 0
									 
constraint_net_delay  *  *|src_lane|sm_src_csr|dr_csr_write_reg[0] 2.2ns 1 0 0 0 0
#------------------------------------------------------------------------

set src_role_cfg_net [get_registers -nowarn *|src_lane|sm_src_csr|src_role_cfg[*]]
  if {[get_collection_size $src_role_cfg_net] > 0 } {
    constraint_net_delay *|src_lane|sm_src_csr|src_role_cfg[*] *  2.2ns 1 0 0 0 0
}

set src_functional_mode_cnf_net [get_registers -nowarn *|src_lane|sm_src_csr|src_functional_mode_cnf[*]]
  if {[get_collection_size $src_functional_mode_cnf_net] > 0 } {
    constraint_net_delay *|src_lane|sm_src_csr|src_functional_mode_cnf[*] *  2.2ns 1 0 0 0 0
}

set src_target_enable_net [get_registers -nowarn *|src_lane|sm_src_csr|src_target_enable[*]]
  if {[get_collection_size $src_target_enable_net] > 0 } {
    constraint_net_delay *|src_lane|sm_src_csr|src_target_enable[*] *  2.2ns 1 0 0 0 0
}
