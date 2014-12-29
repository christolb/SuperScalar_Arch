///////////////////////////////////////////////////////////////////////////////////////////
// Author         : CB
// Date           : 12-04-2014
// Design Name    : inst_queue
// Description    : Instruction Queue
//                  Latches two instructions on +ve cycle  : Instruction_1 and Instruction_2 
//                  Outputs two instructions on -ve cycle upon receiving fetch
//                  from IDU
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
   output reg                       inst_1_valid,
   output reg [INS_PART_WID-1:0]    inst_1_type,
   output reg [INS_PART_WID-1:0]    inst_1_dest,
   output reg [INS_PART_WID-1:0]    inst_1_src0,
   output reg [INS_PART_WID-1:0]    inst_1_src1,

   // Instruction 1
   input                        inst_2_fetch,
   output reg                       inst_2_valid,
   output reg [INS_PART_WID-1:0]    inst_2_type,
   output reg [INS_PART_WID-1:0]    inst_2_dest,
   output reg [INS_PART_WID-1:0]    inst_2_src0,
   output reg [INS_PART_WID-1:0]    inst_2_src1
);

// Generate the Queue for storing two instructions 
reg [15:0]  instruction_q1[0:QUEUE_DEPTH-1];
wire  [15:0]  instruction1_q_0;
wire  [15:0]  instruction1_q_1;
wire  [15:0]  instruction1_q_2;
wire  [15:0]  instruction1_q_3;
reg [15:0]  instruction_q2[0:QUEUE_DEPTH-1];

localparam PTR_WIDTH = 5;

reg [PTR_WIDTH-1:0] wr_ptr1=0, wr_ptr2=0;
reg [PTR_WIDTH-1:0] rd_ptr1=0, rd_ptr2=0;

initial begin
   inst_1_valid = 0;
   inst_1_type  = 0;
   inst_1_dest  = 0;
   inst_1_src0  = 0;
   inst_1_src1  = 0;

   inst_2_valid = 0;
   inst_2_type  = 0;
   inst_2_dest  = 0;
   inst_2_src0  = 0;
   inst_2_src1  = 0;
end


assign instruction1_q_0 = instruction_q1[0];
assign instruction1_q_1 = instruction_q1[1];
assign instruction1_q_2 = instruction_q1[2];
assign instruction1_q_3 = instruction_q1[3];

// Store the instructions into the Queue

always @(*)   // Latch the processor1 instruction on positive clk cycle
if(clk)
begin
   if(instruction_val_1)
   begin
      instruction_q1[wr_ptr1]  =  instruction_1;
   end
end

always @(*)
if(clk)
begin
  if(instruction_val_1)
  begin
      wr_ptr1         =  wr_ptr1 + 1;
  end
end

always @(*)
if(clk)   // Latch the processor1 instruction on positive clk cycle
begin
   if(instruction_val_2)
   begin
      instruction_q2[wr_ptr2]  =  instruction_2;
   end
end

always @(*)
if(clk)
begin
   if(instruction_val_2)
   begin
      wr_ptr2         =  wr_ptr2 + 1;
   end
end

assign instruction_q1_empty = (wr_ptr1 == rd_ptr1);

// Generate the outputs on receiving a fetch signal

always @(*)
if(!clk)
begin
   if(inst_1_fetch & !instruction_q1_empty) // Fetch the instruction1 on negative clk cycle
   begin
      inst_1_type = instruction_q1[rd_ptr1][15:12]; 
   end
end

always @(*)
if(!clk)
begin
   if(inst_1_fetch & !instruction_q1_empty) // Fetch the instruction1 on negative clk cycle
   begin
      inst_1_dest = instruction_q1[rd_ptr1][11:8]; 
      inst_1_src1 = instruction_q1[rd_ptr1][7:4]; 
      inst_1_src0 = instruction_q1[rd_ptr1][3:0]; 
   end
end

always @(*)
if(!clk)
begin
   if(inst_1_fetch & !instruction_q1_empty)
   begin
      #CLK_DELAY rd_ptr1     = rd_ptr1 + 1; 
   end
end

// Generate instruction valid 1
always @(*)
if(!clk)
begin
   if(inst_1_fetch & !instruction_q1_empty)
       inst_1_valid = 1;
   #CLK_DELAY inst_1_valid = 0;
end 

assign instruction_q2_empty = (wr_ptr2 - rd_ptr2);

always @(*)
if(!clk)
begin
   if(inst_2_fetch & !instruction_q2_empty) // Fetch the instruction2 on negative clk cycle
   begin
      inst_2_type = instruction_q2[rd_ptr2][15:12]; 
      inst_2_dest = instruction_q2[rd_ptr2][11:8]; 
      inst_2_src1 = instruction_q2[rd_ptr2][7:4]; 
      inst_2_src0 = instruction_q2[rd_ptr2][3:0]; 
   end
end

always @(*)
begin
   if(inst_2_fetch & !instruction_q2_empty)
   begin
      #CLK_DELAY rd_ptr2     = rd_ptr2 + 1; 
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
