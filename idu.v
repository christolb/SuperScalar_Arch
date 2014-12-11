///////////////////////////////////////////////////////////////////////////////////////////
//
// Author         : CB
// Date           : 12-04-2014
// Design Name    : inst_dispatch
// Description    : Instruction Dispatch Unit 
//
///////////////////////////////////////////////////////////////////////////////////////////


module inst_dispatch #
(
   parameter NUM_RS       = 8,     // Number of reservation stations in design
   parameter NUM_REG      = 4,     // Number of registers in the design
   parameter CLK_DELAY    = 2000,  // Clock period in ns
   parameter INS_PART_WID = 4,     // Bitwidth of each part of instruction
   parameter TAG_LEN      = 4      // Bit width of tags
)
(
   input                       clk,
   // Instruction 1 components (First Instruction)
   input                       inst_1_valid,
   input [INS_PART_WID-1:0]    inst_1_type,
   input [INS_PART_WID-1:0]    inst_1_dest,
   input [INS_PART_WID-1:0]    inst_1_src0,
   input [INS_PART_WID-1:0]    inst_1_src1,
   output                      inst_1_fetch,
 
   // Instruction 2 components (Second Instruction)
   input                       inst_2_valid,
   input [INS_PART_WID-1:0]    inst_2_type,
   input [INS_PART_WID-1:0]    inst_2_dest,
   input [INS_PART_WID-1:0]    inst_2_src0,
   input [INS_PART_WID-1:0]    inst_2_src1,
   output                      inst_2_fetch,

   // Instruction Dispatch Bus 1
   output [INS_PART_WID*3-1:0] instruction1, // <RS_TO_USE, SOURCE_1, SOURCE_2>
   output                      inst_1_valid,
   output [1:0]                status_bus_tag1,
    
   // Instruction Dispatch Bus 2
   output [INS_PART_WID*3-1:0] instruction2, // <RS_TO_USE, SOURCE_1, SOURCE_2> 
   output                      inst_2_valid,
   output [1:0]                status_bus_tag2,
);

    
// Reservation Status table: Stores the busy status
// for each reservation station
reg rs_status_table[0:NUM_RS] = 0;

// Register Status table: Stores the tag from 
// which each register obtains its value + status 
// bit which indicates whether it's busy
reg [TAG_LEN+1-1:0] reg_status_table[0:NUM_REG] = 0;

// Instruction1 Dependency checks 
always@(*)
if(clk) // Positive phase of clk
   case(inst_1_type)
      4'b0001 : begin // ADD instruction
                   if(rs_status_table[ADD_0] != 1) // Check if ADD_0 is busy
                   begin
                      rs_status_table[ADD_0] = 1;
                      reg_status_table[inst_1_dest][TAG_LEN:0] = {ADD_0,1'b1};
		      inst_assigned[1] = ADD_0;
                   end
                   else if(rs_status_table[ADD_1] != 1) // Check if ADD_1 is busy
                   begin
                      rs_status_table[ADD_1] = 1;
                      reg_status_table[inst_1_dest][TAG_LEN:0] = {ADD_1,1'b1};
                   end
                end
      4'b0010 : begin // MULT instruction
                   if(rs_status_table[MULT_0] != 1) // Check if MULT_0 is busy
                   begin
                      rs_status_table[MULT_0] = 1;
                      reg_status_table[inst_1_dest][TAG_LEN:0] = {MULT_0,1'b1};
                   end
                   else if(rs_status_table[ADD_1] != 1) // Check if MULT_1 is busy
                   begin
                      rs_status_table[MULT_1] = 1;
                      reg_status_table[inst_1_dest][TAG_LEN:0] = {MULT_1,1'b1};
                   end
                end
      4'b0011 : begin // LOAD instruction
                   if(rs_status_table[LOAD_0] != 1) // Check if MULT_0 is busy
                   begin
                      rs_status_table[LOAD_0] = 1;
                      reg_status_table[inst_1_dest][TAG_LEN:0] = {LOAD_0,1'b1};
                   end
                   else if(rs_status_table[LOAD_1] != 1) // Check if MULT_1 is busy
                   begin
                      rs_status_table[LOAD_1] = 1;
                      reg_status_table[inst_1_dest][TAG_LEN:0] = {LOAD_1,1'b1};
                   end
                end
      4'b0100 : begin // STORE instruction
                   if(rs_status_table[LOAD_0] != 1) // Check if MULT_0 is busy
                   begin
                      rs_status_table[LOAD_0] = 1;
                      reg_status_table[inst_1_dest][TAG_LEN:0] = {LOAD_0,1'b1};
                   end
                   else if(rs_status_table[LOAD_1] != 1) // Check if MULT_1 is busy
                   begin
                      rs_status_table[LOAD_1] = 1;
                      reg_status_table[inst_1_dest][TAG_LEN:0] = {LOAD_1,1'b1};
                   end
                end



endmodule
