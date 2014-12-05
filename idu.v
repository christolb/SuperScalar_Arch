///////////////////////////////////////////////////////////////////////////////////////////
// Author    : CB
// Date        : 12-04-2014
// Design Name    : inst_dispatch
// Description    : Instruction Dispatch Unit 
//
///////////////////////////////////////////////////////////////////////////////////////////


module inst_dispatch #
(
   parameter NUM_RS       = 8,
   parameter NUM_REG      = 4,
   parameter CLK_DELAY    = 2000,
   parameter INS_PART_WID = 4,
   parameter TAG_LEN      = 4
)
(
   input                       clk,
   // Instruction 0 components
   input                       inst_1_valid,
   input [INS_PART_WID-1:0]    inst_type_1,
   input [INS_PART_WID-1:0]    inst_dest_1,
   input [INS_PART_WID-1:0]    inst_src0_1,
   input [INS_PART_WID-1:0]    inst_src1_1,
   output                      inst_1_fetch,
 
   // Instruction 1 components
   input                       inst_2_valid,
   input [INS_PART_WID-1:0]    inst_type_2,
   input [INS_PART_WID-1:0]    inst_dest_2,
   input [INS_PART_WID-1:0]    inst_src0_2,
   input [INS_PART_WID-1:0]    inst_src1_2,
   output                      inst_2_fetch,

   // Instruction Dispatch Bus 1
   output [INS_PART_WID*4-1:0] instruction1,
   output [1:0]                status_bus_tag1,
    
   // Instruction Dispatch Bus 2
   output [INS_PART_WID*4-1:0] instruction2,
   output [1:0]                status_bus_tag2,
);

    
// Reservation Status table
reg [TAG_LEN-1:0] rs_status_table[0:NUM_RS];

// Register Status table
reg [TAG_LEN-1:0] reg_status_table[0:NUM_REG];

endmodule
