///////////////////////////////////////////////////////////////////////////////////////////
//
// Author : CB
// Date : 12-04-2014
// Design Name : inst_dispatch
// Description : Instruction Dispatch Unit
//
///////////////////////////////////////////////////////////////////////////////////////////
module idu #
(
   parameter NUM_RS = 8, // Number of reservation stations in design
   parameter NUM_REG = 4, // Number of registers in the design
   parameter CLK_DELAY = 2000, // Clock period in ns
   parameter INS_PART_WID = 4, // Bitwidth of each part of instruction
   parameter TAG_LEN = 4 // Bit width of tags
)
(
   input clk,

   // Instruction 1 components (First Instruction)
   input inst_1_valid,
   input [INS_PART_WID-1:0] inst_1_type,
   input [INS_PART_WID-1:0] inst_1_dest,
   input [INS_PART_WID-1:0] inst_1_src0,
   input [INS_PART_WID-1:0] inst_1_src1,
   output inst_1_fetch,

   // Instruction 2 components (Second Instruction)
   input inst_2_valid,
   input [INS_PART_WID-1:0] inst_2_type,
   input [INS_PART_WID-1:0] inst_2_dest,
   input [INS_PART_WID-1:0] inst_2_src0,
   input [INS_PART_WID-1:0] inst_2_src1,
   output inst_2_fetch,

   // Instruction Dispatch Bus 1
   output [INS_PART_WID*3-1:0] instruction1, // <RS_TO_USE, SOURCE_1, SOURCE_2>
   output                      instruction1_valid,
   output [1:0]                status_bus_tag1,

   // Instruction Dispatch Bus 2
   output [INS_PART_WID*3-1:0] instruction2, // <RS_TO_USE, SOURCE_1, SOURCE_2>
   output                      instruction2_valid,
   output [1:0]                status_bus_tag2,

   // Done signals from reservation stations
   input [NUM_RS/4-1:0]     adder_done,
   input [NUM_RS/4-1:0]     mult_done,
   input [NUM_RS/4-1:0]     fetch_done,
   input [NUM_RS/4-1:0]     store_done

   // Register status table to outside logic
   output                   reg_status_table[0:NUM_REG], 

);

// Define reservation station IDs
localparam ADD_0   = 4'b0001; localparam ADD_1   = 4'b0010;
localparam MULT_0  = 4'b0011; localparam MULT_1  = 4'b0100;
localparam FETCH_0 = 4'b0101; localparam FETCH_1 = 4'b0110;
localparam STORE_0 = 4'b0111; localparam STORE_1 = 4'b1000;


// Reservation Status table: Stores the busy status
// for each reservation station
reg rs_status_table[0:NUM_RS] = 0;

// Register Status table: Stores the tag from
// which each register obtains its value + status
// bit which indicates whether it's busy
reg [TAG_LEN+1-1:0] reg_status_table[0:NUM_REG] = 0;

// Instruction 1 and 2 : Check for dependencies
always @(*)
if(!clk)  // Negative phase of clock
begin // {
   // Reset busy status for each reservation station upon completion of operation
   rs_status_table[ADD_0]   = !adder_done[0]; rs_status_table[ADD_1]   = !adder_done[1];
   rs_status_table[MULT_0]  = !mult_done[0] ; rs_status_table[MULT_1]  = !mult_done[1] ;
   rs_status_table[FETCH_0] = !fetch_done[0]; rs_status_table[FETCH_1] = !fetch_done[1];
   rs_status_table[STORE_0] = !store_done[0]; rs_status_table[STORE_1] = !fetch_done[1];

   ////////////////////////////////////////////////////////////////////////////////////////
   // INSTRUCTION 1 DEPENDENCY CHECKS
   ////////////////////////////////////////////////////////////////////////////////////////
   if( (inst_1_src0 == instruction2_rs) || (inst_1_src1 == instruction2_rs) )  // RAW hazard check
       inst1_stall = 1;
   else
       inst1_stall = 0;
   if (!inst1_stall || inst2_to_inst1) begin // {
      case(inst_1_type) // {
      4'b0001: begin // ADD instruction
                  if(rs_status_table[ADD_0] != 1) begin // Check if ADD_0 RS is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = ADD_0;
                      rs_status_table[ADD_0]  = 1; // Make ADD_0 busy
                      reg_status_table[inst_1_dest] = {ADD_0, 1'b1}; 
                  end else if(rs_status_table[ADD_1] != 1) begin // Check if ADD_1 is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = ADD_1;
                      rs_status_table[ADD_1]  = 1; // Make ADD_1 busy
                      reg_status_table[inst_1_dest] = {ADD_1, 1'b1}; 
                  end else begin
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                  end
               end
      4'b0010: begin // MULT instruction
                  if(rs_status_table[MULT_0] != 1) begin // Check if MULT_0 RS is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = MULT_0;
                      rs_status_table[MULT_0]  = 1; // Make MULT_0 busy
                      reg_status_table[inst_1_dest] = {MULT_0, 1'b1}; 
                  end else if(rs_status_table[MULT_1] != 1) begin // Check if MULT_1 is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = MULT_1;
                      rs_status_table[MULT_1]  = 1; // Make MULT_1 busy
                      reg_status_table[inst_1_dest] = {MULT_1, 1'b1}; 
                  end else begin
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                  end
               end
      4'b0011: begin // FETCH instruction
                  if(rs_status_table[FETCH_0] != 1) begin // Check if FETCH_0 RS is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = FETCH_0;
                      rs_status_table[FETCH_0]  = 1; // Make FETCH_0 busy
                      reg_status_table[inst_1_dest] = {FETCH_0, 1'b1}; 
                  end else if(rs_status_table[FETCH_1] != 1) begin // Check if FETCH_1 is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = FETCH_1;
                      rs_status_table[FETCH_1]  = 1; // Make FETCH_1 busy
                      reg_status_table[inst_1_dest] = {FETCH_1, 1'b1}; 
                  end else begin
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                  end
               end
      4'b0100: begin // STORE instruction
                  if(rs_status_table[STORE_0] != 1) begin // Check if STORE_0 RS is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = STORE_0;
                      rs_status_table[STORE_0]  = 1; // Make STORE_0 busy
                      reg_status_table[inst_1_dest] = {STORE_0, 1'b1}; 
                  end else if(rs_status_table[STORE_1] != 1) begin // Check if STORE_1 is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = STORE_1;
                      rs_status_table[STORE_1]  = 1; // Make STORE_1 busy
                      reg_status_table[inst_1_dest] = {STORE_1, 1'b1}; 
                  end else begin
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                  end
               end
      default : begin // Illegal instruction
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                      reg_status_table[inst_1_dest] = 0; 
                end
      endcase // }
   end // }
   ////////////////////////////////////////////////////////////////////////////////////////
   // INSTRUCTION 2 DEPENDENCY CHECKS
   ////////////////////////////////////////////////////////////////////////////////////////
   if( (inst_2_src0 == instruction1_rs) || (inst_2_src1 == instruction1_rs) )  // RAW hazard check
       inst2_stall = 1;
   else 
       inst2_stall = 1;
   if(!inst2_stall) begin // {
      case(inst_2_type) // {
      4'b0001: begin // ADD instruction
                  if(rs_status_table[ADD_0] != 1) begin // Check if ADD_0 RS is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = ADD_0;
                      rs_status_table[ADD_0]  = 1; // Make ADD_0 busy
                      reg_status_table[inst_2_dest] = {ADD_0, 1'b1}; 
                  end else if(rs_status_table[ADD_1] != 1) begin // Check if ADD_1 is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = ADD_1;
                      rs_status_table[ADD_1]  = 1; // Make ADD_1 busy
                      reg_status_table[inst_2_dest] = {ADD_1, 1'b1}; 
                  end else begin
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                  end
               end
      4'b0010: begin // MULT instruction
                  if(rs_status_table[MULT_0] != 1) begin // Check if MULT_0 RS is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = MULT_0;
                      rs_status_table[MULT_0]  = 1; // Make MULT_0 busy
                      reg_status_table[inst_2_dest] = {MULT_0, 1'b1}; 
                  end else if(rs_status_table[MULT_1] != 1) begin // Check if MULT_1 is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = MULT_1;
                      rs_status_table[MULT_1]  = 1; // Make MULT_1 busy
                      reg_status_table[inst_2_dest] = {MULT_1, 1'b1}; 
                  end else begin
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                  end
               end
      4'b0011: begin // FETCH instruction
                  if(rs_status_table[FETCH_0] != 1) begin // Check if FETCH_0 RS is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = FETCH_0;
                      rs_status_table[FETCH_0]  = 1; // Make FETCH_0 busy
                      reg_status_table[inst_2_dest] = {FETCH_0, 1'b1}; 
                  end else if(rs_status_table[FETCH_1] != 1) begin // Check if FETCH_1 is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = FETCH_1;
                      rs_status_table[FETCH_1]  = 1; // Make FETCH_1 busy
                      reg_status_table[inst_2_dest] = {FETCH_1, 1'b1}; 
                  end else begin
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                  end
               end
      4'b0100: begin // STORE instruction
                  if(rs_status_table[STORE_0] != 1) begin // Check if STORE_0 RS is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = STORE_0;
                      rs_status_table[STORE_0]  = 1; // Make STORE_0 busy
                      reg_status_table[inst_2_dest] = {STORE_0, 1'b1}; 
                  end else if(rs_status_table[STORE_1] != 1) begin // Check if STORE_1 is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = STORE_1;
                      rs_status_table[STORE_1]  = 1; // Make STORE_1 busy
                      reg_status_table[inst_2_dest] = {STORE_1, 1'b1}; 
                  end else begin
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                  end
               end 
      default : begin // Illegal instruction
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                      reg_status_table[inst_2_dest] = 0; 
                end
      endcase //}
   end // }

end // }

// Dispatch logic
always @(*)
if(clk) // Positive phase of clock
begin
    if(dispatch_inst1)
    begin
        intruction1_rs    = inst1_rs;
        instruction1_src0 = inst_1_src0;
        instruction1_src1 = inst_1_src1;
    end
    if(dispatch_inst2)
    begin
        intruction2_rs    = inst2_rs;
        instruction2_src0 = inst_2_src0;
        instruction2_src1 = inst_2_src1;
    end
end

// Collect outputs
assign instruction1 = {intruction1_rs, intruction1_src0, intruction1_src1}; 
assign instruction2 = {intruction2_rs, intruction2_src0, intruction2_src1}; 

endmodule
