`timescale 1ns/1ps

module mbist_controller #(
    parameter ADDR_WIDTH   = 8,
    parameter DATA_WIDTH   = 32,
    parameter READ_LATENCY = 1
)(
    input  wire                       clk,
    input  wire                       reset_n,
    input  wire                       start,

    // memory 
    output reg                        mem_cs,
    output reg                        mem_we,
    output reg                        mem_re,
    output reg  [ADDR_WIDTH-1:0]      mem_addr,
    output reg  [DATA_WIDTH-1:0]      mem_wdata,
    input  wire [DATA_WIDTH-1:0]      mem_rdata,

    // status   
    output wire                        test_done,
    output wire                        fail_flag,
    output wire  [ADDR_WIDTH-1:0]      fail_addr,

    // DEBUG 
    output wire [1:0]                 dbg_op,
    output wire                       dbg_exp_bit,
    output wire [1:0]                 dbg_element,
    output wire [3:0]                 dbg_micro_idx
);


    reg [3:0]  element;     
    reg [3:0]  micro_idx;   
    reg [3:0]  wait_cnt;
    reg        start_elem;
    reg        dir_up;
    reg        addr_step;   

    reg [1:0]  latched_op;
    reg        latched_exp_bit;
    reg [ADDR_WIDTH-1:0] latched_addr;
    wire [1:0] op;
    wire       wr_bit;
    wire       exp_bit;
    wire       last;
    
    reg                      fail_flag_r;
    reg [ADDR_WIDTH-1:0]     fail_addr_r;
    reg                      test_done_r;
    
    assign fail_flag = fail_flag_r;
    assign fail_addr = fail_addr_r;
    assign test_done = test_done_r;


    mbist_microcode u_mcode (
        .index   (micro_idx),
        .element (element),
        .op      (op),
        .wr_bit  (wr_bit),
        .exp_bit (exp_bit),
        .last    (last)
    );

    wire [ADDR_WIDTH-1:0] addr_out;
    wire sweep_done;

    mbist_addrgen #(.ADDR_WIDTH(ADDR_WIDTH)) u_addrgen (
        .clk        (clk),
        .reset_n    (reset_n),
        .start_elem (start_elem),
        .dir_up     (dir_up),
        .addr_step  (addr_step),
        .addr       (addr_out),
        .sweep_done (sweep_done)
    );

    assign dbg_op        = op;
    assign dbg_exp_bit   = exp_bit;
    assign dbg_element   = element;
    assign dbg_micro_idx = micro_idx;

    localparam ST_IDLE  = 3'd0;
    localparam ST_ELEM  = 3'd1;
    localparam ST_MICRO = 3'd2;
    localparam ST_WAIT  = 3'd3;
    localparam ST_CHECK = 3'd4;
    localparam ST_DONE  = 3'd5;

    reg [2:0] state, next_state;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

     always @(*) begin
        next_state = state;

        case(state)
            ST_IDLE:
                if (start) next_state = ST_ELEM;

            ST_ELEM:
                next_state = ST_MICRO;

            ST_MICRO:
                if (op == 2'b01) next_state = ST_WAIT;  
                else             next_state = ST_CHECK; 

            ST_WAIT:
                if (wait_cnt == READ_LATENCY) next_state = ST_CHECK;

            ST_CHECK: begin
                if (last) begin
                    if (sweep_done)
                        next_state = (element == 4) ? ST_DONE : ST_ELEM;
                    else
                        next_state = ST_MICRO;
                end else
                    next_state = ST_MICRO;
            end

            ST_DONE:
                next_state = ST_DONE;
            
            default: ;
        endcase
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            element    <= 0;
            micro_idx  <= 0;
            fail_flag_r  <= 0;
            test_done_r  <= 0;
            start_elem <= 0;
            dir_up     <= 1;
            addr_step  <= 0;
            wait_cnt   <= 0;
            mem_cs     <= 0;
            mem_we     <= 0;
            mem_re     <= 0;
            latched_op <= 2'b00;
            latched_exp_bit <= 1'b0;
            latched_addr <= {ADDR_WIDTH{1'b0}};
            fail_addr_r <= {ADDR_WIDTH{1'b0}};
        end else begin
       
            addr_step <= 0;
            mem_cs    <= 0;
            mem_we    <= 0;
            mem_re    <= 0;

            case(state)

            ST_IDLE: begin
                test_done_r  <= 0;
                fail_flag_r  <= 0;
                element    <= 0;
            end

            ST_ELEM: begin
                micro_idx  <= 0;
                start_elem <= 1;
                dir_up     <= (element != 2);
                latched_op <= 2'b00;
                latched_exp_bit <= 1'b0;
            end

            ST_MICRO: begin
                start_elem <= 0;
                mem_cs     <= 1;
                mem_addr   <= addr_out;

                if (op == 2'b01) begin
                    latched_op <= op;
                    latched_exp_bit <= exp_bit;
                    latched_addr <= addr_out;
                    mem_re <= 1;
                    wait_cnt <= 0;
                end
                else if (op == 2'b10) begin 
                    mem_we    <= 1;
                    mem_wdata <= wr_bit ? { {DATA_WIDTH-1{1'b0}},1'b1 } : { DATA_WIDTH{1'b0} };
                end
            end

            ST_WAIT: begin
                wait_cnt <= wait_cnt + 1;
            end

            ST_CHECK: begin
                if ((latched_op == 2'b01) && !fail_flag_r) begin
                    if (mem_rdata[0] != latched_exp_bit) begin
                        fail_flag_r <= 1;
                        fail_addr_r <= latched_addr;
                    end
                end

                if (last) begin
                    micro_idx <= 0;

                    if (!sweep_done)
                        addr_step <= 1;

                    if (sweep_done)
                        element <= element + 1;

                    latched_op <= 2'b00;
                    latched_exp_bit <= 1'b0;
                end else begin
                    micro_idx <= micro_idx + 1'b1;
                end
            end

            ST_DONE: begin
                test_done_r <= 1;
            end

            endcase
        end
    end
    
//    always @(posedge clk) begin
//    if (fail_flag_r && !fail_flag) begin
//        $display("Internal detect at T=%0t", $time);
//    end
//    if (fail_flag) begin
//        $display("Output visible at T=%0t", $time);
//    end
//end


endmodule
