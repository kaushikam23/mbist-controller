`timescale 1ns/1ps

module sram_model #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = (1<<ADDR_WIDTH),
    parameter READ_LATENCY = 1
)(
    input  wire                       clk,
    input  wire                       reset_n,
    input  wire                       cs,
    input  wire                       we,
    input  wire                       re,
    input  wire [ADDR_WIDTH-1:0]      addr,
    input  wire [DATA_WIDTH-1:0]      wdata,
    output reg  [DATA_WIDTH-1:0]      rdata,
    
    input  wire                       fault_enable,
    input  wire [ADDR_WIDTH-1:0]      fault_addr,
    input  wire [2:0]                 fault_kind, 
    input  wire [ADDR_WIDTH-1:0]      fault_target 
);

// Fault Types
localparam F_NONE           = 3'd0;
localparam F_SA0            = 3'd1; // stuck-at-0 
localparam F_SA1            = 3'd2; // stuck-at-1 
localparam F_INVERT         = 3'd3; // invert read data
localparam F_TRANSIENT_READ = 3'd4; // transient read flip 
localparam F_WRITE_BLOCK    = 3'd5; // writes ignored
localparam F_TF_RISE        = 3'd6; // prevents 0->1 writes 
localparam F_COUPLE_ADDR    = 3'd7; // writing fault_addr affects fault_target 


reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
integer i;

reg [ADDR_WIDTH-1:0] read_addr_pipe [0:READ_LATENCY-1];
integer p;

initial begin
    for (i=0;i<DEPTH;i=i+1) mem[i] = {DATA_WIDTH{1'b0}};
    for (p=0;p<READ_LATENCY;p=p+1) read_addr_pipe[p] = {ADDR_WIDTH{1'b0}};
    rdata = {DATA_WIDTH{1'b0}};
end


task apply_write;
    input [ADDR_WIDTH-1:0] waddr;
    input [DATA_WIDTH-1:0] wdata_in;
    begin
        if (fault_enable && (waddr == fault_addr)) begin
            case (fault_kind)
                F_WRITE_BLOCK: begin
                    // ignore writes
                end
                F_TF_RISE: begin
                    mem[waddr] <= mem[waddr] | (mem[waddr] & wdata_in); 
                    mem[waddr] <= (mem[waddr] & wdata_in) | (mem[waddr] & ~wdata_in);
                end
                F_COUPLE_ADDR: begin
                    mem[waddr] <= wdata_in;
                    mem[fault_target] <= mem[fault_target] ^ {{(DATA_WIDTH-1){1'b0}},1'b1};
                end
                default: begin
                    mem[waddr] <= wdata_in;
                end
            endcase
        end else begin
            mem[waddr] <= wdata_in;
        end
    end
endtask


always @(posedge clk) begin
    if (!reset_n) begin
    end else begin
        if (cs && we) begin
            apply_write(addr, wdata);
        end
    end
end


reg transient_consumed; 
always @(posedge clk) begin
    if (!reset_n) begin
        for (p=0;p<READ_LATENCY;p=p+1) read_addr_pipe[p] <= {ADDR_WIDTH{1'b0}};
        rdata <= {DATA_WIDTH{1'b0}};
        transient_consumed <= 1'b0;
    end else begin
        if (cs && re)
            read_addr_pipe[0] <= addr;
        else
            read_addr_pipe[0] <= read_addr_pipe[0];

        for (p=1;p<READ_LATENCY;p=p+1)
            read_addr_pipe[p] <= read_addr_pipe[p-1];

        if (READ_LATENCY == 0) rdata <= mem[addr];
        else rdata <= mem[ read_addr_pipe[READ_LATENCY-1] ];


        if (fault_enable && ( (READ_LATENCY==0 ? addr : read_addr_pipe[READ_LATENCY-1]) == fault_addr )) begin
            case (fault_kind)
                F_SA0: rdata <= {DATA_WIDTH{1'b0}};
                F_SA1: rdata <= {DATA_WIDTH{1'b1}};
                F_INVERT: rdata <= ~rdata;
                F_TRANSIENT_READ: begin
                    if (!transient_consumed) begin
                        rdata <= rdata ^ {{(DATA_WIDTH-1){1'b0}},1'b1}; // flip LSB once
                        transient_consumed <= 1'b1;
                    end
                end
                default: rdata <= rdata;
            endcase
        end
    end
end

endmodule
