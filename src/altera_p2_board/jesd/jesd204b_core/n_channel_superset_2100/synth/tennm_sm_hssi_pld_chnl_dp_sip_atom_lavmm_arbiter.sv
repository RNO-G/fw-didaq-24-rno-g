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
`define ONE_HOT_SEL one_hot_sel
`define CLK_USE_ONE(port_name) tileip_mux_write_connected_parameter=`"CONNECTED_``port_name```"

`define PARAM_ATTR(attr_name, param_name) tileip_attr_of_``param_name``=`"``attr_name```"

(*
    arbiter_sip,
    `PARAM_ATTR(num_ports, NUM_PORTS)
*)
module tennm_sm_hssi_pld_chnl_dp_sip_atom_lavmm_arbiter
#(
    // DR Tool needs the default to be a valid configuring, so use this for all Quartus runs, and use extra checks in simulations
`ifdef ALTERA_RESERVED_QIS
/* `ATTR_DS_MERGE__COMPUTE   */ parameter int                                   NUM_PORTS                                        = 2,
`else
/* `ATTR_DS_MERGE__COMPUTE   */ parameter int                                   NUM_PORTS                                        = -1,
`endif
                                parameter bit [NUM_PORTS-1:0]                   CONNECTED_i_hio_det_lat_sampling_clk             = '0 // One bit per port set to 1 if connected
)
(
    (* `SIP                      *) input  wire     [NUM_PORTS-1:0]                 i_hio_det_lat_sampling_clk,
    // DPHY will drive 'z on all LAVMM ports when not enabled, so use tri0 inputs to workaround this (fixes compilation, might not be functional)
    (* `SIP                      *) input  tri0     [NUM_PORTS-1:0][20:0]           i_hio_lavmm_addr,
    (* `SIP                      *) input  tri0     [NUM_PORTS-1:0][3:0]            i_hio_lavmm_be,
    (* `SIP                      *) input  tri0     [NUM_PORTS-1:0]                 i_hio_lavmm_clk,
    (* `SIP                      *) input  tri0     [NUM_PORTS-1:0]                 i_hio_lavmm_read,
    (* `SIP                      *) input  tri1     [NUM_PORTS-1:0]                 i_hio_lavmm_rstn, // Tri1 so that undriven inputs do not affect output.
    (* `SIP                      *) input  tri0     [NUM_PORTS-1:0][31:0]           i_hio_lavmm_wdata,
    (* `SIP                      *) input  tri0     [NUM_PORTS-1:0]                 i_hio_lavmm_write,
    (* `SIP                      *) output wire     [NUM_PORTS-1:0][31:0]           o_hio_lavmm_rdata,
    (* `SIP                      *) output wire     [NUM_PORTS-1:0]                 o_hio_lavmm_rdata_valid,
    (* `SIP                      *) output wire     [NUM_PORTS-1:0]                 o_hio_lavmm_waitreq,
    (* `DIRECT                   *) output wire                                     d_i_hio_det_lat_sampling_clk,
    (* `DIRECT                   *) output wire     [20:0]                          d_i_hio_lavmm_addr,
    (* `DIRECT                   *) output wire     [3:0]                           d_i_hio_lavmm_be,
    (* `DIRECT                   *) output wire                                     d_i_hio_lavmm_clk,
    (* `DIRECT                   *) output wire                                     d_i_hio_lavmm_read,
    (* `DIRECT                   *) output wire                                     d_i_hio_lavmm_rstn,
    (* `DIRECT                   *) output wire     [31:0]                          d_i_hio_lavmm_wdata,
    (* `DIRECT                   *) output wire                                     d_i_hio_lavmm_write,
    (* `DIRECT                   *) input  wire     [31:0]                          d_o_hio_lavmm_rdata,
    (* `DIRECT                   *) input  wire                                     d_o_hio_lavmm_rdata_valid,
    (* `DIRECT                   *) input  wire                                     d_o_hio_lavmm_waitreq
);

    // -------------------------------------------------------------------------
    // Overview:
    // ---------
    // LAVMM Arbiter - Implements arbitration between multiple LAVMM requesters
    // and generates one combined LAVMM interface towards the responder. All
    // LAVMM interfaces must use the same clock to avoid clock domain crossings.
    //
    // The interface on the arbiter does not include any error indication, so no
    // resources will be used to try to detect errors.
    //
    // Note: The arbiter will always clock and reset from index 0, and the
    // output clock is from index 0 while the reset is a combination of all
    // incoming resets. The input ports are declared as tri0/tri1 as some QHIPs
    // will tri-state the interface when in a configuration where it is not
    // used. This avoids compilation issues, but will not be functional if the
    // used clock ends up being 0.
    // -------------------------------------------------------------------------

    // Verify that all parameter values are legal
    if (NUM_PORTS<1) $fatal(1,"Number of ports must be > 0");
    // Assertions (ports)
    // As any LAVMM clock can de set to constant 0, verifying that all clocks
    // are identical is considered too expensive, and not done at the moment.
    // All System PLL Lock signals and deterministic latency sampling clocks
    // also has to be identical. Currently this is not checked as these
    // assertions are expensive, but checks for this can be added.

    typedef struct packed {
        logic [20:0] addr;
        logic [3:0]  be;
        logic        read;
        logic [31:0] wdata;
        logic        write;
    } lavmm_req_s;
    localparam lavmm_req_s LAVMM_REQ_IDLE = '{default: '0};
    typedef struct packed {
        logic [31:0] rdata;
        logic        rdata_valid;
        logic        waitreq;
    } lavmm_rsp_s;
    localparam lavmm_rsp_s LAVMM_RSP_IDLE = '{
        rdata       : '0,
        rdata_valid : '0,
        waitreq     : 1'b1
    };

    // Map ports to structs to ease mux implementation -------------------------
    lavmm_req_s lavmm_reqs[NUM_PORTS];
    lavmm_rsp_s lavmm_rsps[NUM_PORTS];
    lavmm_req_s lavmm_req;
    lavmm_rsp_s lavmm_rsp;
    for (genvar i=0; i<NUM_PORTS; i++) begin : gen_lavmm_map
        assign lavmm_reqs[i] = '{
            addr  : i_hio_lavmm_addr[i],
            be    : i_hio_lavmm_be[i],
            read  : i_hio_lavmm_read[i],
            wdata : i_hio_lavmm_wdata[i],
            write : i_hio_lavmm_write[i]
        };
        assign o_hio_lavmm_rdata[i]       = lavmm_rsps[i].rdata;
        assign o_hio_lavmm_rdata_valid[i] = lavmm_rsps[i].rdata_valid;
        assign o_hio_lavmm_waitreq[i]     = lavmm_rsps[i].waitreq;
    end : gen_lavmm_map
    assign d_i_hio_lavmm_addr  = lavmm_req.addr;
    assign d_i_hio_lavmm_be    = lavmm_req.be;
    assign d_i_hio_lavmm_read  = lavmm_req.read;
    assign d_i_hio_lavmm_wdata = lavmm_req.wdata;
    assign d_i_hio_lavmm_write = lavmm_req.write;
    assign lavmm_rsp = '{
        rdata       : d_o_hio_lavmm_rdata,
        rdata_valid : d_o_hio_lavmm_rdata_valid,
        waitreq     : d_o_hio_lavmm_waitreq
    };

    // LAVMM Arbitration -------------------------------------------------------
    if (NUM_PORTS == 1) begin : gen_arb_1
        // One port, no arbitration, pass through
        assign lavmm_req = lavmm_reqs[0];
        assign lavmm_rsps[0] = lavmm_rsp;
    end else begin : gen_arb_n
        // Implement arbitration between LAVMM ports using wait request to stall
        // accesses to avoid any buffering. To ensure fairness use round robin
        // between all ports.
        function automatic logic rr_arb (
            input logic [NUM_PORTS-1:0] reqs,
            input logic [$clog2(NUM_PORTS)-1:0] cur,
            output logic [$clog2(NUM_PORTS)-1:0] nxt
        );
            logic [2*NUM_PORTS-2:0] reqs_int;
            logic [2*NUM_PORTS-2:0] mask;
            reqs_int = {reqs[NUM_PORTS-2:0],reqs};
            mask = '0;
            if (cur == (NUM_PORTS-1))
                mask[NUM_PORTS-1:0] = '1;
            else
                mask[(cur+1'b1)+:NUM_PORTS] = '1;
            reqs_int = reqs_int & mask;
            foreach (reqs_int[i])
                if (reqs_int[i])
                    nxt =($clog2(NUM_PORTS))'((i > (NUM_PORTS-1)) ? (i-NUM_PORTS) : i);
            return (|reqs);
        endfunction
        (* preserve, dont_replicate *) enum logic[1:0] {
            WAITING  = 2'b00,
            REQ      = 2'b01,
            WAIT_RSP = 2'b10,
            RSP      = 2'b11} state;
        logic [$clog2(NUM_PORTS)-1:0] cur;
        logic wait_for_rd_data;
        always_ff @(posedge i_hio_lavmm_clk[0] or negedge i_hio_lavmm_rstn[0]) begin : arb_proc
            automatic logic [$clog2(NUM_PORTS)-1:0] nxt;
            // Use LAVMM reset signal from first requester as async reset as it
            // satisfies the requirements, even though the signal is otherwise
            // only used for clock gating.
            if (!i_hio_lavmm_rstn[0]) begin
                state <= WAITING;
                lavmm_req <= LAVMM_REQ_IDLE;
                lavmm_rsps <= '{default: LAVMM_RSP_IDLE};
                cur <= '0;
                wait_for_rd_data <= '0;
            end else begin
                unique case (state)
                    WAITING:
                        begin
                            lavmm_rsps <= '{default: LAVMM_RSP_IDLE};
                            if (rr_arb(.reqs(i_hio_lavmm_read | i_hio_lavmm_write),.cur(cur),.nxt(nxt))) begin
                                cur <= nxt;
                                state <= REQ;
                            end
                        end
                    REQ:
                        begin
                            lavmm_req <= lavmm_reqs[cur];
                            state <= WAIT_RSP;
                        end
                    WAIT_RSP:
                        begin
                            if (!lavmm_rsp.waitreq) begin
                                lavmm_req <= LAVMM_REQ_IDLE; // Clear request once wait request has been deasserted
                                lavmm_rsps[cur].waitreq    <= 1'b0;
                                if (lavmm_req.read)
                                    wait_for_rd_data <= 1'b1;
                                else
                                    wait_for_rd_data <= 1'b0;
                                state <= RSP;
                            end
                        end
                    RSP:
                        begin
                            if (!wait_for_rd_data) begin
                                state <= WAITING;
                            end else begin
                                if (lavmm_rsp.rdata_valid) begin // Wait until read data valid received
                                    lavmm_rsps[cur].rdata       <= lavmm_rsp.rdata;
                                    lavmm_rsps[cur].rdata_valid <= lavmm_rsp.rdata_valid;
                                    wait_for_rd_data            <= 1'b0;
                                    state                       <= WAITING;
                                end
                            end
                        end
                endcase
            end
        end : arb_proc
    end : gen_arb_n

    // LAVMM Clock & Reset -----------------------------------------------------
    // All LAVMM interfaces must use the same clock to avoid clock domain
    // crossings, so pass one copy to responder and leave the rest unconnected.
    assign d_i_hio_lavmm_clk = i_hio_lavmm_clk[0];
    if (NUM_PORTS>1) begin : gen_lavmm_clk_nc
        logic [NUM_PORTS-1:1] i_hio_lavmm_clk_nc;
        assign i_hio_lavmm_clk_nc = i_hio_lavmm_clk[NUM_PORTS-1:1];
    end : gen_lavmm_clk_nc
    // The LAVMM Reset input is used for clock gating (not reset) to avoid
    // glitches. Shall be asserted from power on, deasserted after user mode is
    // entered, and not be asserted again. Assert reset output if any input is
    // asserted.
    assign d_i_hio_lavmm_rstn = &i_hio_lavmm_rstn;

    // DL Clocks ---------------------------------------------------------------
    // For the deterministic latency clocks, avoid logic on the signal
    // pick one and always use that. Must pick one that is driven by a valid
    // clock, DR Tool indicates which input bits a driven, pick anyone of them
    logic [NUM_PORTS-1:0] i_hio_det_lat_sampling_clk_nc;
    logic d_i_hio_det_lat_sampling_clk_int;
    always_comb begin : dl_clk_proc
        i_hio_det_lat_sampling_clk_nc = i_hio_det_lat_sampling_clk;
        d_i_hio_det_lat_sampling_clk_int = 1'b0;
        foreach (CONNECTED_i_hio_det_lat_sampling_clk[i])
            if (CONNECTED_i_hio_det_lat_sampling_clk[i]) begin
                d_i_hio_det_lat_sampling_clk_int = i_hio_det_lat_sampling_clk[i];
                i_hio_det_lat_sampling_clk_nc[i] = 1'b0;
            end
    end : dl_clk_proc
    assign d_i_hio_det_lat_sampling_clk = d_i_hio_det_lat_sampling_clk_int;

    // LAVMM SIP Side asserts --------------------------------------------------
`ifndef ALTERA_RESERVED_QIS
    for (genvar i=0; i<NUM_PORTS; i++) begin : gen_lavmm_a
        logic wr_in_prog = 1'b0;
        logic rd_in_prog = 1'b0;
        logic [NUM_PORTS-1:0] one_hot_sel_full;
        always @(posedge i_hio_lavmm_clk[i]) begin: lavmm_a_proc
            urw_a: assert (!($isunknown({i_hio_lavmm_read[i],i_hio_lavmm_write[i]}))) else
                $warning("Unknown value on LAVMM read/write on port %d.",i);
            rw_a: assert (!(i_hio_lavmm_read[i] && i_hio_lavmm_write[i])) else
                $warning("Reading and writing in same cycles on LAVMM port %d.",i);
            if (i_hio_lavmm_write[i]) begin
                wr_in_prog <= o_hio_lavmm_waitreq[i];
                wu_a: assert (!($isunknown({i_hio_lavmm_addr[i],i_hio_lavmm_be[i],i_hio_lavmm_wdata[i]}))) else
                    $warning("Unknown values on control signals during write on LAVMM port %d.",i);
                wrp: assert (!rd_in_prog) else
                    $warning("Write initiated while read in progress on LAVMM port %d",i);
            end
            if (i_hio_lavmm_read[i]) begin
                rd_in_prog <= o_hio_lavmm_waitreq[i];
                ru_a: assert (!($isunknown({i_hio_lavmm_addr[i],i_hio_lavmm_be[i]}))) else
                    $warning("Unknown values on control signals during read on LAVMM port %d.",i);
                rwp: assert (!wr_in_prog) else
                    $warning("Read initiated while write in progress on LAVMM port %d.",i);
            end
        end : lavmm_a_proc
    end : gen_lavmm_a
`endif // ifndef ALTERA_RESERVED_QIS
endmodule : tennm_sm_hssi_pld_chnl_dp_sip_atom_lavmm_arbiter
`undef PARAM_ATTR
`undef CLK_USE_ONE
`undef ONE_HOT_SEL
`undef DIRECT
`undef SIP
`default_nettype wire
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "CYTUP98cokYF5/KnH5U9wpmsMebvw7PjbSFb6M3lY/qsVIz6jKyEvq+ZpFxx2uhEXGlRc0Zdjj1y1wmOppfPxVoYbzB4MDz5WMEEIHxYqLzLPRix146tWtBVedm6MD12cvLP4zUSq8euGs2Vl4XTnYwLn9yJjVujHm3F6Sq+aoE+e5SR+I7FPSr+JWVgOvlOEHDWwXnTb8RANIhljDHm3WWpU5Wvb9fUSAR0qErfFv8fZ5mlFKBx4XG+qpJBPs+6jTt+cP2wxuiX/1vOHur8xvU2W6ZtiAYro1MXX9tA2hvr4BDYxHKlLClMZEytsugQ/7Fvv3sxSEVIW1EtxnDL9gfIlL0dB1IWhItC3jAl/RK1t56n5Fk53oDaShVf5JF0XNzypB3RyTKFGtq9E/2titUoKyZndDp4yQs1meii5Nzm6X1Liwi/osBMhd76zdM5f2RipdNl7FSEpjvg1JxqXdrxyRkoc4VggIPPj0NCxto0BWn1dPwsf/2yR7WR6/M1f3M1eSQbDDYylP1BgeXUzh50RcpV4TcmbxwEEZYjFJOMzVDE2OoYbRlclPWL6cyrpfAZvX+Z1CL7TGQ9oQcAOGf92cTyTrALV0JhLSAqG/S0gUEN0aqN+z73DlhgqfF0pYLlyRPz53Ui/ztif/2/WtmPGTptK10yFOh+wVcJnAlUCkldldyppAMmDiHciPc6DYcNZc4T6EoUe2MpnIY6KwyAQiopJj/ryDW+3ar1/o78t4YZ01iQcSPtld69Tn1/ozrFpE0rFK0nLV7SYbHvmaEyRZkjHjA+IDQZpSzC5gGLJJoANFgxZJLM49Z8wy6migj4BnXo+l963Wp6XtGQpXA0P91sQQ/MuT5MxVA/3F2hXbrqgipUeePm7Pi9F/U1LAozaNH3ic1+ZHbEFhDeYxUFf2GKPTqZv3vVoW+XtEpSI0rNGimjlAy+iqp47roW1zPqBPhK5eu1uXxET5uP6cbt4p2XNdPxUgaT7Xe6g8/XDGC9fi3+9umfK9+onPei"
`endif