`timescale 1ns/1ps

module mbist_addrgen #(
    parameter ADDR_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     reset_n,
    input  wire                     start_elem,    
    input  wire                     dir_up,        // 1 = up, 0 = down
    input  wire                     addr_step,     
    output reg  [ADDR_WIDTH-1:0]    addr,
    output reg                      sweep_done
);

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        addr <= {ADDR_WIDTH{1'b0}};
        sweep_done <= 1'b0;
    end

    else if (start_elem) begin
        sweep_done <= 1'b0;
        addr <= dir_up ? {ADDR_WIDTH{1'b0}} : {ADDR_WIDTH{1'b1}};
    end

    else if (addr_step) begin
        if (dir_up) begin
            if (addr == {ADDR_WIDTH{1'b1}})
                sweep_done <= 1'b1;
            else
                addr <= addr + 1'b1;
        end else begin
            if (addr == {ADDR_WIDTH{1'b0}})
                sweep_done <= 1'b1;
            else
                addr <= addr - 1'b1;
        end
    end
end

endmodule
