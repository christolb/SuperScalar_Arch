///////////////////////////////////////////////////////////////////////////////////////////
// Author    : CB
// Date        : 12-04-2014
// Design Name    : inst_queue
// Description    : Instruction Queue
//                Latches two instructions on +ve cycle  : Instruction_1 and Instruction_2 
//                Outputs two instructions on -ve cycle upon receiving fetch
//                from IDU
//
///////////////////////////////////////////////////////////////////////////////////////////

module inst_queue #
(
parameter CLK_DELAY    = 2000,
parameter INS_PART_WID = 4,
parameter QUEUE_DEPTH  = 32
)
(
   input                        clk,
   input  [INS_PART_WID*4-1:0]  instruction_1,
   input                        instruction_val_1,
   input  [INS_PART_WID*4-1:0]  instruction_2,
   input                        instruction_val_2,
   // Instruction 0
   input                        inst_1_fetch,
   output                       inst_1_valid,
   output [INS_PART_WID-1:0]    inst_type_1,
   output [INS_PART_WID-1:0]    inst_dest_1,
   output [INS_PART_WID-1:0]    inst_src0_1,
   output [INS_PART_WID-1:0]    inst_src1_1,

   // Instruction 1
   input                        inst_2_fetch,
   output                       inst_2_valid,
   output [INS_PART_WID-1:0]    inst_type_2,
   output [INS_PART_WID-1:0]    inst_dest_2,
   output [INS_PART_WID-1:0]    inst_src0_2,
   output [INS_PART_WID-1:0]    inst_src1_2
);

// Generate the Queue for storing two instructions 
reg [15:0]  instruction_q1[0:QUEUE_DEPTH-1];
reg [15:0]  instruction_q2[0:QUEUE_DEPTH-1];

localparam PTR_WIDTH = 5;

reg [PTR_WIDTH-1:0] wr_ptr1, wr_ptr2;
reg [PTR_WIDTH-1:0] rd_ptr1, rd_ptr2;

// Store the instructions into the Queue

always @(*)
if(clk)   // Latch the processor1 instruction on positive clk cycle
begin
   if(instruction_val_1)
   begin
      instruction_q1  =  instruction_1;
      wr_ptr1         =  wr_ptr1 + 1;
   end
end

always @(*)
if(clk)   // Latch the processor1 instruction on positive clk cycle
begin
   if(instruction_val_2)
   begin
      instruction_q2  =  instruction_2;
      wr_ptr2         =  wr_ptr2 + 1;
   end
end

// Generate the outputs on receiving a fetch signal

always @(*)
if(!clk)
begin
   if(inst_1_fetch) // Fetch the instruction1 on negative clk cycle
   begin
      inst_type_1 = instruction_q1[rd_ptr1][INS_PART_WID*4-1:-INS_PART_WID]; 
      inst_dest_1 = instruction_q1[rd_ptr1][INS_PART_WID*3-1:-INS_PART_WID]; 
      inst_src1_1 = instruction_q1[rd_ptr1][INS_PART_WID*2-1:-INS_PART_WID]; 
      inst_src0_1 = instruction_q1[rd_ptr1][INS_PART_WID*1-1:-INS_PART_WID]; 
      rd_ptr1     = rd_ptr1 + 1; 
   end
end

// Generate instruction valid 1
always @(*)
if(!clk)
begin
   if(inst_1_fetch)
       inst_1_valid = 1;
   #CLK_DELAY inst_1_valid = 0;
end 

always @(*)
if(!clk)
begin
   if(inst_2_fetch) // Fetch the instruction2 on negative clk cycle
   begin
      inst_type_2 = instruction_q2[rd_ptr2][INS_PART_WID*4-1:-INS_PART_WID]; 
      inst_dest_2 = instruction_q2[rd_ptr2][INS_PART_WID*3-1:-INS_PART_WID]; 
      inst_src1_2 = instruction_q2[rd_ptr2][INS_PART_WID*2-1:-INS_PART_WID]; 
      inst_src0_2 = instruction_q2[rd_ptr2][INS_PART_WID*1-1:-INS_PART_WID]; 
      rd_ptr2     = rd_ptr2 + 1; 
   end
end

// Generate instruction valid 1
always @(*)
if(!clk)
begin
   if(inst_2_fetch)
       inst_2_valid = 1;
   #CLK_DELAY inst_2_valid = 0;
end 

endmodule
