// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`resetall
`default_nettype none

`define SIP sip
`define DIRECT direct

`define PARAM_ATTR(attr_name, param_name) tileip_attr_of_``param_name``=`"``attr_name```"

(*
    mux_sip,
    `PARAM_ATTR(num_ports,              NUM_PORTS)
*)
module tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_tx_rx
#(
    /* num_ports                 */ parameter int                                   NUM_PORTS                                        =  2
)
(
	(* `DIRECT                   *) input  wire                                     d_o_hio_rst_flux0_cpi_cmn_busy,
	(* `DIRECT                   *) input  wire                                     d_o_hio_ux_chnl_refclk_mux,
	(* `DIRECT                   *) input  wire                                     d_o_hio_rst_ux_all_synthlockstatus,
    (* `SIP                      *) output wire     [NUM_PORTS-1:0]                 o_hio_rst_ux_all_synthlockstatus,
    (* `SIP                      *) output wire     [NUM_PORTS-1:0]                 o_hio_ux_chnl_refclk_mux,
    (* `SIP                      *) output wire     [NUM_PORTS-1:0]                 o_hio_rst_flux0_cpi_cmn_busy
);
    assign o_hio_rst_ux_all_synthlockstatus = {NUM_PORTS{d_o_hio_rst_ux_all_synthlockstatus}};
    assign o_hio_rst_flux0_cpi_cmn_busy = {NUM_PORTS{d_o_hio_rst_flux0_cpi_cmn_busy}};
    assign o_hio_ux_chnl_refclk_mux = {NUM_PORTS{d_o_hio_ux_chnl_refclk_mux}};

endmodule

`undef PARAM_ATTR
`undef DIRECT
`undef SIP

`default_nettype wire
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "CYTUP98cokYF5/KnH5U9wpmsMebvw7PjbSFb6M3lY/qsVIz6jKyEvq+ZpFxx2uhEXGlRc0Zdjj1y1wmOppfPxVoYbzB4MDz5WMEEIHxYqLzLPRix146tWtBVedm6MD12cvLP4zUSq8euGs2Vl4XTnYwLn9yJjVujHm3F6Sq+aoE+e5SR+I7FPSr+JWVgOvlOEHDWwXnTb8RANIhljDHm3WWpU5Wvb9fUSAR0qErfFv+LskP3w0JGxa00uANhRpduN3sX4ECvs4m7w9yeI5ARF+D23lzPFKyw8eFUubkZ30jfWF3RG1q9oSLvrDG0a5901Zp44eKimBXu7t6zjhXjp5xRGjhBw2gatyyPYz0LupK8JaW5wfnVNp74T4Y3qDQYJ0sPL/bsIFZQKMZavGtshBkcUf7cLo4Izm5hFm2YT6WYvFf3Hdqxw5rM4+O0dALmSby/M9EFAgG8osOazU1go5Q61jX1Q9umjWvuoS2rHPzXWUBbW5WKQRvgoauzFwuRvnUn6Nmd5IX+HI9w446T5K8ueDcSzDcg1CtCxfHMb0gKp5pCvm1yiFurQL6hQ1ov3DkwO6J834KcLOyZesBGnGEcabSwQAACzTcPcB/Dbye+bcQRTZd+GHRoX00QpalklMAjcWG7YzScrbCusoG+EDOCmReo0DoF/xVWVziobbRBQicWOTKj4bbiXcBAZtLK8r3PoofcHj+oXLWIXNZpYJjEBY6KPIFzYZJrGSGPEw75Q6riTAoQ1KV2Wt10OqCYfSQ2tuVEWWWo6cyC80C88QCWcaugewBA9lKslnNT9NDYEnqsMbhEuYrWXAOUKNfIfy+AdE4/U7pWdJV60ZlCe74kMreZfR8HYrYVqBpNJz2eRnTJMZhMg+9a1J0corJyrFpC8y3IISrJIYahZvSZo0U4tuyO7x1hOKyogyodq6ifKr6qdhVWZzsCTR0grF2pzfnHFBkhffEF8diYrXo9ymPFiXwGNk4eQEiyZJ5Vmz4/InqwSksUd2Ma3G7GklB5"
`endif