`timescale 1ns/1ps

module tb_mbist_faults();

parameter ADDR_WIDTH   = 8;
parameter DATA_WIDTH   = 32;
parameter READ_LATENCY = 1;

reg clk = 0;
always #5 clk = ~clk;

reg reset_n;

initial begin
    reset_n = 0;
    #100;
    reset_n = 1;
end

wire mem_cs, mem_we, mem_re;
wire [ADDR_WIDTH-1:0] mem_addr;
wire [DATA_WIDTH-1:0] mem_wdata;
wire [DATA_WIDTH-1:0] mem_rdata;

reg fault_enable;
reg [ADDR_WIDTH-1:0] fault_addr;
reg [2:0] fault_kind;
reg [ADDR_WIDTH-1:0] fault_target;

wire test_done;
wire fail_flag;
wire [ADDR_WIDTH-1:0] fail_addr;

reg start;

sram_wrapper #(
    .USE_IP(0),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .READ_LATENCY(READ_LATENCY)
) MEM (
    .clk(clk), .reset_n(reset_n),
    .cs(mem_cs), .we(mem_we), .re(mem_re),
    .addr(mem_addr), .wdata(mem_wdata), .rdata(mem_rdata),
    .fault_enable(fault_enable),
    .fault_addr(fault_addr),
    .fault_type(fault_kind),
    .fault_target(fault_target)
);

mbist_controller #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .READ_LATENCY(READ_LATENCY)
) CTRL (
    .clk(clk), .reset_n(reset_n), .start(start),
    .mem_cs(mem_cs), .mem_we(mem_we), .mem_re(mem_re),
    .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
    .test_done(test_done), .fail_flag(fail_flag), .fail_addr(fail_addr)
);

localparam FK_NONE = 3'd0;
localparam FK_SA0  = 3'd1;
localparam FK_SA1  = 3'd2;
localparam FK_INV  = 3'd3;
localparam FK_TR   = 3'd4;
localparam FK_WB   = 3'd5;
localparam FK_TFR  = 3'd6;
localparam FK_CPL  = 3'd7;

integer addr_i;
integer fk_i;
integer total_tests;
integer detected;

task wait_for_done;
    input integer timeout;
    integer count;
begin
    count = 0;
    while (!test_done && count < timeout) begin
        #1000;
        count = count + 1;
    end
end
endtask

initial begin
    start = 0;
    fault_enable = 0;
    fault_addr = 0;
    fault_kind = 0;
    fault_target = 0;
    total_tests = 0;
    detected = 0;
    #100;

    for (fk_i = FK_SA0; fk_i <= FK_CPL; fk_i = fk_i + 1) begin
        for (addr_i = 0; addr_i < (1 << ADDR_WIDTH); addr_i = addr_i + 1) begin

            fault_enable = 1;
            fault_addr   = addr_i;
            fault_kind   = fk_i;
            fault_target = addr_i ^ 1;
            reset_n = 0;
            #40;                
            reset_n = 1;
            #40;                 

            start = 1; #10; start = 0;
            wait_for_done(2000000);

            total_tests = total_tests + 1;
            if (fail_flag) begin
                detected = detected + 1;
                $display("FK=%0d ADDR=%0d -> DETECTED ", fk_i, addr_i);
            end else begin
                $display("FK=%0d ADDR=%0d -> NOT_DETECTED", fk_i, addr_i);
            end
            #50;
        end
    end

    $display("MBIST Fault Test Summary:");
    $display("Total tests = %0d", total_tests);
    $display("Detected    = %0d", detected);
    $display("Coverage    = %.2f%%", (100.0*detected)/total_tests);

    $finish;
end

endmodule
