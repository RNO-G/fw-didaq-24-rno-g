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



// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  alt_async_fifo_wr32_rd32_32_deep_dr_la_fifo_1941_4gmv4ey  (
    aclr,
    data,
    rdclk,
    rdreq,
    wrclk,
    wrreq,
    q,
    rdempty,
    rdfull,
    rdusedw,
    wrfull,
    wrusedw);

    input    aclr;
    input  [31:0]  data;
    input    rdclk;
    input    rdreq;
    input    wrclk;
    input    wrreq;
    output [31:0]  q;
    output   rdempty;
    output   rdfull;
    output [4:0]  rdusedw;
    output   wrfull;
    output [4:0]  wrusedw;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri0     aclr;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [31:0] sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire [4:0] sub_wire3;
    wire  sub_wire4;
    wire [4:0] sub_wire5;
    wire [31:0] q = sub_wire0[31:0];
    wire  rdempty = sub_wire1;
    wire  rdfull = sub_wire2;
    wire [4:0] rdusedw = sub_wire3[4:0];
    wire  wrfull = sub_wire4;
    wire [4:0] wrusedw = sub_wire5[4:0];

    dcfifo  dcfifo_component (
                .aclr (aclr),
                .data (data),
                .rdclk (rdclk),
                .rdreq (rdreq),
                .wrclk (wrclk),
                .wrreq (wrreq),
                .q (sub_wire0),
                .rdempty (sub_wire1),
                .rdfull (sub_wire2),
                .rdusedw (sub_wire3),
                .wrfull (sub_wire4),
                .wrusedw (sub_wire5),
                .eccstatus (),
                .wrempty ());
    defparam
        dcfifo_component.clocks_are_synchronized  = "FALSE",
        dcfifo_component.enable_ecc  = "FALSE",
        dcfifo_component.intended_device_family  = "Agilex 5",
        dcfifo_component.lpm_hint  = "RAM_BLOCK_TYPE=M20K,DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
        dcfifo_component.lpm_numwords  = 32,
        dcfifo_component.lpm_showahead  = "ON",
        dcfifo_component.lpm_type  = "dcfifo",
        dcfifo_component.lpm_width  = 32,
        dcfifo_component.lpm_widthu  = 5,
        dcfifo_component.overflow_checking  = "ON",
        dcfifo_component.rdsync_delaypipe  = 5,
        dcfifo_component.read_aclr_synch  = "ON",
        dcfifo_component.underflow_checking  = "ON",
        dcfifo_component.use_eab  = "OFF",
        dcfifo_component.write_aclr_synch  = "ON",
        dcfifo_component.wrsync_delaypipe  = 5;


endmodule


