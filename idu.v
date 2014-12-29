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
   parameter CLK_DELAY    = 2000, // Clock period in ns
   parameter CLK_DELAYBY2 = 1000, // Half Clock period in ns
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
   output reg inst_1_fetch,

   // Instruction 2 components (Second Instruction)
   input inst_2_valid,
   input [INS_PART_WID-1:0] inst_2_type,
   input [INS_PART_WID-1:0] inst_2_dest,
   input [INS_PART_WID-1:0] inst_2_src0,
   input [INS_PART_WID-1:0] inst_2_src1,
   output reg inst_2_fetch,

   // Instruction Dispatch Bus 1
   output [INS_PART_WID*4-1:0] instruction1, // <RS_TO_USE, 4'b0000, SOURCE_1, SOURCE_2>
   output                      instruction1_valid,
   output [1:0]                status_bus_tag1,

   // Instruction Dispatch Bus 2
   output [INS_PART_WID*4-1:0] instruction2, // <RS_TO_USE, 4'b0000, SOURCE_1, SOURCE_2>
   output                      instruction2_valid,
   output [1:0]                status_bus_tag2,

   // Done signals from reservation stations
   input [NUM_RS/4-1:0]     adder_done,
   input [NUM_RS/4-1:0]     mult_done,
   input [NUM_RS/4-1:0]     fetch_done,
   input [NUM_RS/4-1:0]     store_done,

   // Register status table to outside logic
   output reg [TAG_LEN+1-1:0]  reg1_status_table, 
   output reg [TAG_LEN+1-1:0]  reg2_status_table, 
   output reg [TAG_LEN+1-1:0]  reg3_status_table, 
   output reg [TAG_LEN+1-1:0]  reg4_status_table 

);

// Define reservation station IDs
localparam ADD_0   = 4'b0001; localparam ADD_1   = 4'b0010;
localparam MULT_0  = 4'b0011; localparam MULT_1  = 4'b0100;
localparam FETCH_0 = 4'b0101; localparam FETCH_1 = 4'b0110;
localparam STORE_0 = 4'b0111; localparam STORE_1 = 4'b1000;


// Reservation Status table: Stores the busy status
// for each reservation station
reg rs_status_table[0:NUM_RS] ;

assign rs_stat_0 = rs_status_table[1];
assign rs_stat_1 = rs_status_table[2];
assign rs_stat_2 = rs_status_table[3];
assign rs_stat_3 = rs_status_table[4];
assign rs_stat_4 = rs_status_table[5];
assign rs_stat_5 = rs_status_table[6];
assign rs_stat_6 = rs_status_table[7];
assign rs_stat_7 = rs_status_table[8];

// Register Status table: Stores the tag from
// which each register obtains its value + status
// bit which indicates whether it's busy
reg [TAG_LEN+1-1:0] reg_status_table[0:NUM_REG] ;

reg dispatch_inst1_d,dispatch_inst1_2d;
reg dispatch_inst2_d,dispatch_inst2_2d;

always @(*)
begin
   reg1_status_table = reg_status_table[0]-2;
   reg2_status_table = reg_status_table[1]-2;
   reg3_status_table = reg_status_table[2]-2;
   reg4_status_table = reg_status_table[3]-2;
end

// Wires and signals
reg [TAG_LEN-1:0] instruction1_src0, instruction1_src1, instruction2_src0, instruction2_src1;
reg [TAG_LEN-1:0] instruction1_rs, instruction2_rs;
reg               inst1_stall, inst2_stall;
reg               dispatch_inst1, dispatch_inst2;
reg [TAG_LEN-1:0] inst1_rs, inst2_rs;
wire              inst2_to_inst1;
integer           i;

initial begin
for( i =0; i<=NUM_RS; i=i+1)
    rs_status_table[i] = 0;
for( i =0; i<=NUM_REG; i=i+1)
    reg_status_table[i] = 0;
end

// Instruction 1 and 2 : Check for dependencies
always @(*)
if(!clk)  // Negative phase of clock
begin // {
   // Reset busy status for each reservation station upon completion of operation
   if(adder_done[0]) rs_status_table[ADD_0]   = 0;  if(adder_done[1]) rs_status_table[ADD_1]   = 0; 
   if(mult_done[0])  rs_status_table[MULT_0]  = 0;  if(mult_done[1])  rs_status_table[MULT_1]  = 0;
   if(fetch_done[0]) rs_status_table[FETCH_0] = 0;  if(fetch_done[1]) rs_status_table[FETCH_1] = 0;
   if(store_done[0]) rs_status_table[STORE_0] = 0;  if(store_done[1]) rs_status_table[STORE_1] = 0;

   ////////////////////////////////////////////////////////////////////////////////////////
   // INSTRUCTION 1 DEPENDENCY CHECKS
   ////////////////////////////////////////////////////////////////////////////////////////
   if( (inst_1_src0 == instruction2_rs) || (inst_1_src1 == instruction2_rs) )  // RAW hazard check
   begin
       instruction1_src0 = (inst_1_src0 == instruction2_rs) ? instruction2_rs : inst_1_src0;      
       instruction1_src1 = (inst_1_src1 == instruction2_rs) ? instruction2_rs : inst_1_src1;      
       inst1_stall = 1;
   end else
       inst1_stall = 0;
   if (!inst1_stall || inst2_to_inst1) begin // {
      case(inst_1_type) // {
      4'b0001: begin // ADD instruction
                  if(rs_status_table[ADD_0] != 1) begin // Check if ADD_0 RS is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = ADD_0;
                      rs_status_table[ADD_0]  = 1; // Make ADD_0 busy
                      reg_status_table[inst_1_dest-9] = {ADD_0, 1'b1}; 
                  end else if(!dispatch_inst1 && rs_status_table[ADD_1] != 1) begin // Check if ADD_1 is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = ADD_1;
                      rs_status_table[ADD_1]  = 1; // Make ADD_1 busy
                      reg_status_table[inst_1_dest-9] = {ADD_1, 1'b1}; 
                  end else if (!dispatch_inst1) begin
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                  end
               end
      4'b0010: begin // MULT instruction
                  if(rs_status_table[MULT_0] != 1) begin // Check if MULT_0 RS is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = MULT_0;
                      rs_status_table[MULT_0]  = 1; // Make MULT_0 busy
                      reg_status_table[inst_1_dest-9] = {MULT_0, 1'b1}; 
                  end else if(!dispatch_inst1 && rs_status_table[MULT_1] != 1) begin // Check if MULT_1 is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = MULT_1;
                      rs_status_table[MULT_1]  = 1; // Make MULT_1 busy
                      reg_status_table[inst_1_dest-9] = {MULT_1, 1'b1}; 
                  end else if (!dispatch_inst1) begin
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                  end
               end
      4'b0011: begin // FETCH instruction
                  if(rs_status_table[FETCH_0] != 1) begin // Check if FETCH_0 RS is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = FETCH_0;
                      rs_status_table[FETCH_0]  = 1; // Make FETCH_0 busy
                      reg_status_table[inst_1_dest-9] = {FETCH_0, 1'b1}; 
                  end else if(!dispatch_inst1 && rs_status_table[FETCH_1] != 1) begin // Check if FETCH_1 is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = FETCH_1;
                      rs_status_table[FETCH_1]  = 1; // Make FETCH_1 busy
                      reg_status_table[inst_1_dest-9] = {FETCH_1, 1'b1}; 
                  end else if (!dispatch_inst1) begin
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                  end
               end
      4'b0100: begin // STORE instruction
                  if(rs_status_table[STORE_0] != 1) begin // Check if STORE_0 RS is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = STORE_0;
                      rs_status_table[STORE_0]  = 1; // Make STORE_0 busy
                      reg_status_table[inst_1_dest-9] = {STORE_0, 1'b1}; 
                  end else if(!dispatch_inst1 && rs_status_table[STORE_1] != 1) begin // Check if STORE_1 is busy
                      dispatch_inst1          = 1;
                      inst1_rs                = STORE_1;
                      rs_status_table[STORE_1]  = 1; // Make STORE_1 busy
                      reg_status_table[inst_1_dest-9] = {STORE_1, 1'b1}; 
                  end else if (!dispatch_inst1) begin
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                  end
               end
      default : begin // Illegal instruction
                      dispatch_inst1          = 0;
                      inst1_rs                = 0;
                      reg_status_table[inst_1_dest-9] = 0; 
                end
      endcase // }
   end // }
   ////////////////////////////////////////////////////////////////////////////////////////
   // INSTRUCTION 2 DEPENDENCY CHECKS
   ////////////////////////////////////////////////////////////////////////////////////////
   if( (inst_2_src0 == instruction1_rs) || (inst_2_src1 == instruction1_rs) )  // RAW hazard check
   begin
       inst2_stall = 1;
       instruction2_src0 = (inst_2_src0 == instruction1_rs) ? instruction1_rs : inst_2_src0;      
       instruction2_src1 = (inst_2_src1 == instruction1_rs) ? instruction1_rs : inst_2_src1;      
   end else 
       inst2_stall = 1;
   if(!inst2_stall) begin // {
      case(inst_2_type) // {
      4'b0001: begin // ADD instruction
                  if(rs_status_table[ADD_0] != 1) begin // Check if ADD_0 RS is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = ADD_0;
                      rs_status_table[ADD_0]  = 1; // Make ADD_0 busy
                      reg_status_table[inst_2_dest-9] = {ADD_0, 1'b1}; 
                  end else if(!dispatch_inst2 && rs_status_table[ADD_1] != 1) begin // Check if ADD_1 is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = ADD_1;
                      rs_status_table[ADD_1]  = 1; // Make ADD_1 busy
                      reg_status_table[inst_2_dest-9] = {ADD_1, 1'b1}; 
                  end else if (!dispatch_inst2) begin
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                  end
               end
      4'b0010: begin // MULT instruction
                  if(rs_status_table[MULT_0] != 1) begin // Check if MULT_0 RS is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = MULT_0;
                      rs_status_table[MULT_0]  = 1; // Make MULT_0 busy
                      reg_status_table[inst_2_dest-9] = {MULT_0, 1'b1}; 
                  end else if(!dispatch_inst2 && rs_status_table[MULT_1] != 1) begin // Check if MULT_1 is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = MULT_1;
                      rs_status_table[MULT_1]  = 1; // Make MULT_1 busy
                      reg_status_table[inst_2_dest-9] = {MULT_1, 1'b1}; 
                  end else if (!dispatch_inst2) begin
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                  end
               end
      4'b0011: begin // FETCH instruction
                  if(rs_status_table[FETCH_0] != 1) begin // Check if FETCH_0 RS is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = FETCH_0;
                      rs_status_table[FETCH_0]  = 1; // Make FETCH_0 busy
                      reg_status_table[inst_2_dest-9] = {FETCH_0, 1'b1}; 
                  end else if(!dispatch_inst2 && rs_status_table[FETCH_1] != 1) begin // Check if FETCH_1 is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = FETCH_1;
                      rs_status_table[FETCH_1]  = 1; // Make FETCH_1 busy
                      reg_status_table[inst_2_dest-9] = {FETCH_1, 1'b1}; 
                  end else if (!dispatch_inst2) begin
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                  end
               end
      4'b0100: begin // STORE instruction
                  if(rs_status_table[STORE_0] != 1) begin // Check if STORE_0 RS is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = STORE_0;
                      rs_status_table[STORE_0]  = 1; // Make STORE_0 busy
                      reg_status_table[inst_2_dest-9] = {STORE_0, 1'b1}; 
                  end else if(!dispatch_inst2 && rs_status_table[STORE_1] != 1) begin // Check if STORE_1 is busy
                      dispatch_inst2          = !dispatch_inst1 ? 1'b0 : 1; // Dispatch inst2 only if dispatch_inst1==1
                      inst2_rs                = STORE_1;
                      rs_status_table[STORE_1]  = 1; // Make STORE_1 busy
                      reg_status_table[inst_2_dest-9] = {STORE_1, 1'b1}; 
                  end else if (!dispatch_inst2) begin
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                  end
               end 
      default : begin // Illegal instruction
                      dispatch_inst2          = 0;
                      inst2_rs                = 0;
                      reg_status_table[inst_2_dest-9] = 0; 
                end
      endcase //}
   end // }

end // }

assign status_bus_tag1[0] = !(instruction1_src1 >= 4'b1001 && instruction1_src1 <= 4'b1100); 
assign status_bus_tag1[1] = !(instruction1_src0 >= 4'b1001 && instruction1_src0 <= 4'b1100); 

assign status_bus_tag2[0] = !(instruction2_src1 >= 4'b1001 && instruction2_src1 <= 4'b1100); 
assign status_bus_tag2[1] = !(instruction2_src0 >= 4'b1001 && instruction2_src0 <= 4'b1100); 

// Dispatch logic
always @(*)
if(clk) // Positive phase of clock
begin
    if(dispatch_inst1)
    begin
        instruction1_rs   = inst1_rs;
        instruction1_src0 = inst_1_src0;
        instruction1_src1 = inst_1_src1;
    end
    if(dispatch_inst2)
    begin
        instruction2_rs   = inst2_rs;
        instruction2_src0 = inst_2_src0;
        instruction2_src1 = inst_2_src1;
    end
end

// Collect outputs
assign instruction1 = {instruction1_rs, 4'b0000, instruction1_src0, instruction1_src1}; 
assign instruction2 = {instruction2_rs, 4'b0000, instruction2_src0, instruction2_src1}; 

// Generate valid signal
always @(*)
if(clk)
begin
    #CLK_DELAYBY2 dispatch_inst1_d  = dispatch_inst1;
end

always @(*)
if(!clk)
begin
    #CLK_DELAYBY2 dispatch_inst1_2d = dispatch_inst1_d;
end

always @(*)
if(clk)
begin
    #CLK_DELAYBY2 dispatch_inst2_d  = dispatch_inst2;
end

always @(*)
if(!clk)
begin
    #CLK_DELAYBY2 dispatch_inst2_2d = dispatch_inst2_d;
end

assign instruction1_valid = dispatch_inst1 & !dispatch_inst1_d;
assign instruction2_valid = dispatch_inst2 & !dispatch_inst2_d;

initial begin
    inst_1_fetch = 1;
    #CLK_DELAY;
    #CLK_DELAYBY2 inst_1_fetch = 0;
end

always @(*)
if(clk)
begin
    if(dispatch_inst1)
    begin
        #CLK_DELAY inst_1_fetch = 1;
        #CLK_DELAY inst_1_fetch = 0;
    end
end

initial begin
    inst_2_fetch = 1;
    #CLK_DELAY;
    #CLK_DELAYBY2 inst_2_fetch = 0;
end

always @(*)
if(clk)
begin
    if(dispatch_inst2)
    begin
        #CLK_DELAY inst_2_fetch = 1;
        #CLK_DELAY inst_2_fetch = 0;
    end
end

endmodule
