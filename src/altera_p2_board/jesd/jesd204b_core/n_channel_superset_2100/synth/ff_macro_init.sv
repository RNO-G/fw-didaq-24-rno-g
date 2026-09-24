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


module ff_macro_init # (
 parameter DATA_WIDTH = 256,
 parameter DIRECTION = "INPUT",
 parameter NUM_FLOPS = 1 // based on number of flops you need in 1 dir 
 ) (
 input logic clk,
 
 input [DATA_WIDTH -1:0] in_data ,
 
 output [DATA_WIDTH -1:0] out_data
 
);
 
    genvar i;
 
    generate
        if ((DIRECTION == "INPUT") && (NUM_FLOPS == 0)) begin : CORE_TO_PERIPHERY_DIRECT
            assign out_data = in_data;
        end
 
        else if (DIRECTION == "INPUT") begin : CORE_TO_PERIPHERY_REG
            (* altera_attribute = {"-name PRESERVE_REGISTER ON; -name FORCE_HYPER_REGISTER_FOR_CORE_PERIPHERY_TRANSFER ON; -name HYPER_REGISTER_DELAY_CHAIN 225"} *)
            reg [DATA_WIDTH-1:0] out_data_reg;
            reg [DATA_WIDTH-1:0] in_data_reg [NUM_FLOPS-1:0]; 
        
            assign in_data_reg[0] = in_data;
 
            for (i=0 ; i<NUM_FLOPS-1 ; i=i+1 ) begin : PIPELINE_REG
                always @(posedge clk) begin
                    in_data_reg[i+1] <= in_data_reg[i];
                end
            end
 
            always @(posedge clk) begin
                out_data_reg <= in_data_reg[NUM_FLOPS-1];
            end
 
            assign out_data = out_data_reg;
        
        end
 
        else begin : PERIPHERY_TO_CORE_REG
            (* altera_attribute = {"-name PRESERVE_REGISTER ON; -name PRESERVE_FANOUT_FREE_NODE ON; -name FORCE_HYPER_REGISTER_FOR_PERIPHERY_CORE_TRANSFER ON"} *)
            reg [DATA_WIDTH-1:0] in_data_reg [NUM_FLOPS:0];
        
            assign in_data_reg[0] = in_data;
 
            for (i=0 ; i<NUM_FLOPS ; i=i+1 ) begin : PIPELINE_REG
                always @(posedge clk) begin
                in_data_reg[i+1] <= in_data_reg[i];
                end
            end
 
            assign out_data = in_data_reg[NUM_FLOPS];
        end
    endgenerate 
    
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "11LIYRQQfbcIILvOzHeNg/vIX40VVp5HrhTQFjXrGHbtsSgtccqpT42TNySh0R8XlU7e0x5cX/J3MeRfGn6+BwXOZvNgE4rIo5IEhMAEj9TCLHfPErPj1cJSfwJZktP6CpsgEN63kZciygkTPajkumFaY8w9H3nkh+RMiA9vav9xORaXLaGd8D+CEwMzFAI+If638zrXOLt8W6Nmjo9ybrBZDERYVgWrzpLwGNO0HdmUNhUvXnXPOQ8nZIJ9cclOAEwg44CbxItyHyEl3c0ZsXpHtkxpPanp+/SUJb3lOAM7/SuakndyBtMkCvApuGq9eHnOhvBqQVsyfYvrIGzip3EaQZP7+ct4tBAfxwAcASfWCHNjYJPWfrS2R345WKTZqbILw4JYzRhWxPfrQhxGYW3dou6zAaak5CDyDTznHaKJCDXVHPE6E/jZwnVQxgLGUbAUnujdeIelr1xk2kPN5T9SW2bCf6v8lLJa+koj/t9qb9zge3PEgwYu84zJOsF55xaySkZQ1kGMwKZu69Q+FzXRyItZ4WAb5crl82FUgq2kzuXqXLUNAdMZ+qGZhpINl+mtUsm8bEFl9kLWdQVr4/PdxInWwlhaajfB4SxHj1elMdsPx0CuKqwG7twuJHillZ4Og6l3I35BrTFCwuByTh3XM0Yln3QNtoYy967kaAhHEwqUmvq7g4VC6w6QxEkRwL2aEbTKzmvtgS98Tz5td6XqQZHg8XwJDwufGH93OlLNuRTxgut+EeKF7597OhPaJhT4m0maTyuSFc06vv3jcgHCgV2C0iQ+3ZPhb45uqid2LJRDfoBGDWrTV9vPHMD+WkpMeWFHZYXrnoW8ksdCHSpN39T50iplvjDkPCItpUPJy22csGC8HzlFE0uB81OWB8JR+TKsola/R0dfizC99DELsMqawr4q0Yw2hDyWi/tcbvnMM4NseNhKQqTHDvMvoEdy+pn5GZxBar8IFmpTTaz5EwkxyEG2Sa6tOOw3l4f2o3cVvIzFOjMj274MYtpY"
`endif