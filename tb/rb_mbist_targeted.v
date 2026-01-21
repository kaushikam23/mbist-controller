// ------------------------------------------------------------
// tb_mbist_targeted.v
// Targeted fault detection testbench for MBIST (mSR+)
// ------------------------------------------------------------
`timescale 1ns/1ps

module tb_mbist_targeted;

parameter ADDR_WIDTH   = 8;
parameter DATA_WIDTH   = 32;
parameter READ_LATENCY = 1;

// ------------------------------------------------------------
// Clock & Reset
// ------------------------------------------------------------
reg clk = 0;
always #5 clk = ~clk;

reg reset_n;

// ------------------------------------------------------------
// DUT interconnect
// ------------------------------------------------------------
wire mem_cs, mem_we, mem_re;
wire [ADDR_WIDTH-1:0] mem_addr;
wire [DATA_WIDTH-1:0] mem_wdata;
wire [DATA_WIDTH-1:0] mem_rdata;

// MBIST control
reg start;
wire test_done;
wire fail_flag;
wire [ADDR_WIDTH-1:0] fail_addr;

// Fault injection
reg fault_enable;
reg [ADDR_WIDTH-1:0] fault_addr;
reg [2:0] fault_kind;
reg [ADDR_WIDTH-1:0] fault_target;

// ------------------------------------------------------------
// Fault kind encoding (matches sram_model)
// ------------------------------------------------------------
localparam FK_SA0  = 3'd1;
localparam FK_SA1  = 3'd2;
localparam FK_INV  = 3'd3;
localparam FK_TR   = 3'd4;
localparam FK_WB   = 3'd5;
localparam FK_TFR  = 3'd6;
localparam FK_CPL  = 3'd7;

// ------------------------------------------------------------
// Instantiate SRAM wrapper (behavioral model)
// ------------------------------------------------------------
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

// ------------------------------------------------------------
// Instantiate MBIST controller
// ------------------------------------------------------------
mbist_controller #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .READ_LATENCY(READ_LATENCY)
) CTRL (
    .clk(clk), .reset_n(reset_n), .start(start),
    .mem_cs(mem_cs), .mem_we(mem_we), .mem_re(mem_re),
    .mem_addr(mem_addr), .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .test_done(test_done),
    .fail_flag(fail_flag),
    .fail_addr(fail_addr)
);

// ------------------------------------------------------------
// Utility task: wait for MBIST completion
// ------------------------------------------------------------
task wait_for_done;
    integer timeout;
    begin
        timeout = 0;
        while (!test_done && timeout < 2_000_000) begin
            #10;
            timeout = timeout + 1;
        end
        if (!test_done)
            $display("ERROR: MBIST timeout!");
    end
endtask

// ------------------------------------------------------------
// Utility task: run one targeted test
// ------------------------------------------------------------
task run_test;
    input [2:0] fk;
    input [ADDR_WIDTH-1:0] addr;
    input [ADDR_WIDTH-1:0] target;
    begin
        // Configure fault
        fault_enable = 1;
        fault_kind   = fk;
        fault_addr   = addr;
        fault_target = target;

        // Reset controller
        reset_n = 0; #40;
        reset_n = 1; #40;

        // Start MBIST
        start = 1; #10;
        start = 0;

        // Wait for completion
        wait_for_done();

        // Report result
        if (fail_flag)
            $display("PASS: FK=%0d injected at %0d → detected (reported at %0d)",
                     fk, addr, fail_addr);
        else
            $display("FAIL: FK=%0d injected at %0d → NOT detected",
                     fk, addr);

        #100;
    end
endtask

// ------------------------------------------------------------
// Test sequence
// ------------------------------------------------------------
initial begin
    // Defaults
    start        = 0;
    fault_enable = 0;
    fault_addr   = 0;
    fault_kind   = 0;
    fault_target = 0;

    // Global reset
    reset_n = 0;
    #100;
    reset_n = 1;
    #100;

    $display("==============================================");
    $display(" Targeted MBIST Fault Detection Tests");
    $display("==============================================");

    // --------------------------------------------------------
    // Test 1: Stuck-at-0 at address 12
    // --------------------------------------------------------
    run_test(FK_SA0, 8'd12, 8'd0);

    // --------------------------------------------------------
    // Test 2: Transition fault (0->1) at address 45
    // --------------------------------------------------------
    run_test(FK_TFR, 8'd45, 8'd0);

    // --------------------------------------------------------
    // Test 3: Coupling fault (100 affects 101)
    // --------------------------------------------------------
    run_test(FK_CPL, 8'd100, 8'd101);

    $display("==============================================");
    $display(" Targeted tests completed");
    $display("==============================================");

    $finish;
end

endmodule
