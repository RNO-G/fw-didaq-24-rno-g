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


// Clocked priority encoder with state
//
// On each clock cycle, updates state to show which request is granted.
// Most recent grant holder is always the highest priority.
// If current grant holder is not making a request, while others are, 
// then new grant holder is always the requester with lowest bit number.
// If no requests, current grant holder retains grant state

// $Header$

// Same as  ../../../altera_xcvr_generic/ctrl/alt_xcvr_arbiter.sv without timescale

//altera message_off 16753
module alt_xcvr_arbiter #(
	parameter width = 2
) (
	input  wire clock,
	input  wire [width-1:0] req,	// req[n] requests for this cycle
	output reg  [width-1:0] grant	// grant[n] means requester n is grantee in this cycle
);

	wire idle;	// idle when no requests
	wire [width-1:0] keep;	// keep[n] means requester n is requesting, and already has the grant
							// Note: current grantee is always highest priority for next grant
	wire [width-1:0] take;	// take[n] means requester n is requesting, and there are no higher-priority requests

	assign keep = req & grant;	// current grantee is always highest priority for next grant
	assign idle = ~| req;		// idle when no requests

	initial begin
		grant = 0;
	end

	// grant next state depends on current grant and take priority
	always @(posedge clock) begin
		grant <= 
// synthesis translate_off
                    (grant === {width{1'bx}})? {width{1'b0}} :
// synthesis translate_on
				keep				// if current grantee is requesting, gets to keep grant
				 | ({width{idle}} & grant)	// if no requests, grant state remains unchanged
				 | take;			// take applies only if current grantee is not requesting
	end

	// 'take' bus encodes priority.  Request with lowest bit number wins when current grantee not requesting
	assign take[0] = req[0]
					 & (~| (keep & ({width{1'b1}} << 1)));	// no 'keep' from lower-priority inputs
	genvar i;
	generate
	for (i=1; i < width; i = i + 1) begin : arb
		assign take[i] = req[i]
						 & (~| (keep & ({width{1'b1}} << (i+1))))	// no 'keep' from lower-priority inputs
						 & (~| (req & {i{1'b1}}));	// no 'req' from higher-priority inputs
	end
	endgenerate
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HWRifsYDx7mAVNgZY40CJyydmOszW9uhe/rsNditBZ0UDRgiXqV42ImPpR6m9xiaWKRgaKlFkF6KK6FmPDH2+YTVexYoyOPxRMrtL3iU5rZ/BzIAVEDzf2OSLzl3DzcbZUhYv1J65varL0cmt2msr82ut4s/Bq1y/R9MF/Ul1vgeUzikZsRxfDG760DPWOwXNM4918/2wtuZDys7U8LqJhJquu1tqsPz/aqjxUTVHHf75M7xssP9FkyPSYCOR4Z9RizTgTkS83sgtr4i28DJPGJi6zykZGHDTQDVVQcSn89NCyKLMgDye51YQzSZBQSsPRXAtAWq1/pOjQaGlSS+UsauCbPXRVLRYADmyX34XTefFGbgcdtClk0R2nmp2xhNYgy9TB7FOs+Wgf3pep4vcVV3sOO0sqTAFSZdKMD8gqAFkYDjDv053tPrNfUweGc92qlMzRExS7S/Dzep33M5plyLTdMX9z6Ns4yDuSVs7PATQWS7oWKZvorjD2JyDHxQqXux4TkdEHk56ROLjXLXkdo0qtft0VuRAeUZTjdn3FGq+txZWF3wZlUfHYAVRz8NwP08+j7oXhZlP7rqRrfI1gYgv75zV1iW5pN94oicnEMQE8pslksnuOYq9fce4OmH87IJSPZCBFg6IL4D7iQWZ/lfIy/Y9VhzTo5Z6Ge8hlSSBe2R7tTCV6//GGO+RCZYsL6hzbYkdvPL1ahqbOfskPzuPoCZt4tUiV9HANnlE+WGf5D7EIJigwCTiNMpxLhNOIiDpqNjWQN+9H6OkM35arxSz9obknwx6LYswayFmAr96VDHS94KbRIJ2h5Z0By8NuiWVLNEh26zSTwRyNmjCnSdCUrTz6JSasaCzG564b9kdhjKG68ADEzJY4iJgYWjlxoMYrAUjveg+8RcnCtJ9+E4HDaSIlxHsIEMGte60eoLDSFcAdkAe3Uqe9du+hOCyyxmuKOpJVe1TLg4XqVQ9qbGlCw4CN85kfeVFFGpSQOGUupa/+5VVF4e1Y28jUpM"
`endif