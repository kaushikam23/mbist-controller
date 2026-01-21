`timescale 1ns/1ps

module sram_wrapper #(
    parameter USE_IP      = 0,            // 0=use behavioral model, 1=use FPGA IP
    parameter ADDR_WIDTH  = 8,
    parameter DATA_WIDTH  = 32,
    parameter READ_LATENCY = 1
)(
    input  wire                       clk,
    input  wire                       reset_n,
    input  wire                       cs,
    input  wire                       we,
    input  wire                       re,
    input  wire [ADDR_WIDTH-1:0]      addr,
    input  wire [DATA_WIDTH-1:0]      wdata,
    output wire [DATA_WIDTH-1:0]      rdata,


    input  wire                       fault_enable,
    input  wire [ADDR_WIDTH-1:0]      fault_addr,
    input  wire [2:0]                 fault_type,  
    input  wire [ADDR_WIDTH-1:0]      fault_target
);

generate
if (USE_IP == 1) begin : FPGA_IP
    // BRAM IP instantiation 
    assign rdata = 'h0;   
end else begin : BEHAVIORAL_MODEL
    sram_model #(
        .ADDR_WIDTH   (ADDR_WIDTH),
        .DATA_WIDTH   (DATA_WIDTH),
        .DEPTH        (1 << ADDR_WIDTH),
        .READ_LATENCY (READ_LATENCY)
    ) MODEL (
        .clk          (clk),
        .reset_n      (reset_n),
        .cs           (cs),
        .we           (we),
        .re           (re),
        .addr         (addr),
        .wdata        (wdata),
        .rdata        (rdata),     
        .fault_enable (fault_enable),
        .fault_addr   (fault_addr),
        .fault_kind   (fault_type),     
        .fault_target (fault_target)
    );

end
endgenerate

endmodule
