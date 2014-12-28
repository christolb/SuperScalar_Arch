module register_file
(
    input             clk,
    input [1:0]       adder_done,
    input [1:0]       mult_done,
    input [1:0]       fetch_done,
    input [11:0]      instruction1,
    input [11:0]      instruction2,
    input [3:0]       reg1_status_table,
    input [3:0]       reg2_status_table,
    input [3:0]       reg3_status_table,
    input [3:0]       reg4_status_table,
    input [7:0]       outadd,
    input [7:0]       outmul,
    input [7:0]       outfetch,
    output reg [7:0]  r0,
    output reg [7:0]  r1,
    output reg [7:0]  r2,
    output reg [7:0]  r3
);

// Define reservation station IDs
localparam ADD_0   = 4'b0001; localparam ADD_1   = 4'b0010;
localparam MULT_0  = 4'b0011; localparam MULT_1  = 4'b0100;
localparam FETCH_0 = 4'b0101; localparam FETCH_1 = 4'b0110;
localparam STORE_0 = 4'b0111; localparam STORE_1 = 4'b1000;

// Write into the appropriate register based on done signal
always @(*)
if(!clk)
begin
   r0 = (|adder_done && ((reg1_status_table == ADD_0) || (reg1_status_table == ADD_1))) ? outadd : (|mult_done && ((reg1_status_table == MULT_0) || (reg1_status_table == MULT_1))) ? outmul : (|fetch_done && ((reg1_status_table == FETCH_0) || (reg1_status_table == FETCH_1))) ? outfetch : r0; 
   r1 = (|adder_done && ((reg2_status_table == ADD_0) || (reg2_status_table == ADD_1))) ? outadd : (|mult_done && ((reg2_status_table == MULT_0) || (reg2_status_table == MULT_1))) ? outmul : (|fetch_done && ((reg2_status_table == FETCH_0) || (reg2_status_table == FETCH_1))) ? outfetch : r1; 
   r2 = (|adder_done && ((reg3_status_table == ADD_0) || (reg3_status_table == ADD_1))) ? outadd : (|mult_done && ((reg3_status_table == MULT_0) || (reg3_status_table == MULT_1))) ? outmul : (|fetch_done && ((reg3_status_table == FETCH_0) || (reg3_status_table == FETCH_1))) ? outfetch : r2; 
   r3 = (|adder_done && ((reg4_status_table == ADD_0) || (reg4_status_table == ADD_1))) ? outadd : (|mult_done && ((reg4_status_table == MULT_0) || (reg4_status_table == MULT_1))) ? outmul : (|fetch_done && ((reg4_status_table == FETCH_0) || (reg4_status_table == FETCH_1))) ? outfetch : r3; 
end

endmodule
