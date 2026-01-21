`timescale 1ns/1ps

module mbist_microcode (
    input  wire [3:0] index,      
    input  wire [3:0] element,    
    output reg  [1:0] op,         
    output reg        wr_bit,     
    output reg        exp_bit,    
    output reg        last        
);

always @(*) begin  
    op      = 2'b00;
    wr_bit = 1'b0;
    exp_bit = 1'b0;
    last    = 1'b0;

    case (element)
    // ELEMENT 0 : INIT (↑) : w0
    3'd0: begin
        case (index)
            4'd0: begin
                op   = 2'b10;    
                wr_bit = 1'b0;   
                last = 1'b1;
            end
            default: ;
        endcase
    end

    // ELEMENT 1 : UP (↑) : r0, w1
    3'd1: begin
        case (index)
            4'd0: begin
                op = 2'b01;       
                exp_bit = 1'b0;
            end
            4'd1: begin
                op = 2'b10;       
                wr_bit = 1'b1;
                last = 1'b1;
            end
            default: ;
        endcase
    end

    // ELEMENT 2 : DOWN (↓) : r1, w0
    3'd2: begin
        case (index)
            4'd0: begin
                op = 2'b01;       
                exp_bit = 1'b1;
            end
            4'd1: begin
                op = 2'b10;       
                wr_bit = 1'b0;
                last = 1'b1;
            end
            default: ;
        endcase
    end

    // ELEMENT 3 : UP (↑) : r0, w1, r1
    3'd3: begin
        case (index)
            4'd0: begin
                op = 2'b01;       
                exp_bit = 1'b0;
            end
            4'd1: begin
                op = 2'b10;       
                wr_bit = 1'b1;
            end
            4'd2: begin
                op = 2'b01;       
                exp_bit = 1'b1;
                last = 1'b1;
            end
            default: ;
        endcase
    end

    // ELEMENT 4 : DOWN (↓) : r1, w0, r0
    3'd4: begin
        case (index)
            4'd0: begin
                op = 2'b01;       
                exp_bit = 1'b1;
            end
            4'd1: begin
                op = 2'b10;       
                wr_bit = 1'b0;
            end
            4'd2: begin
                op = 2'b01;      
                exp_bit = 1'b0;
                last = 1'b1;
            end
            default: ;
        endcase
    end

    default: begin
        op = 2'b00;
    end

    endcase
end

endmodule
