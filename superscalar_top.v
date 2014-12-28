module superscalar_top #
(
   parameter  CLK_DELAY    = 2000,
   parameter  INS_PART_WID = 4,
   parameter  QUEUE_DEPTH  = 32
)
(
   input                       clk,
   input [INS_PART_WID*4-1:0]  instruction_1,
   input                       instruction_val_1,
   input [INS_PART_WID*4-1:0]  instruction_2,
   input                       instruction_val_2
);

// Wires and signals
wire                     inst_1_fetch;
wire                     inst_1_valid;
wire [INS_PART_WID-1:0]  inst_1_type;
wire [INS_PART_WID-1:0]  inst_1_dest;
wire [INS_PART_WID-1:0]  inst_1_src0;
wire [INS_PART_WID-1:0]  inst_1_src1;

wire                     inst_2_fetch;
wire                     inst_2_valid;
wire [INS_PART_WID-1:0]  inst_2_type;
wire [INS_PART_WID-1:0]  inst_2_dest;
wire [INS_PART_WID-1:0]  inst_2_src0;
wire [INS_PART_WID-1:0]  inst_2_src1;

wire [1:0]               adder_done;
wire [1:0]               mult_done;
wire [1:0]               fetch_done;
wire [1:0]               store_done;

wire [15:0]              instruction1; 
wire [15:0]              instruction2; 

wire [3:0]               reg1_status_table;
wire [3:0]               reg2_status_table;
wire [3:0]               reg3_status_table;
wire [3:0]               reg4_status_table;

wire [11:0]              outadd;
wire [11:0]              outmul; 
wire [11:0]              outfetch;
wire [7:0]               r0; 
wire [7:0]               r1;     
wire [7:0]               r2;     
wire [7:0]               r3;     
wire [3:0]               reg_sel_src1, reg_sel_src2;

reg  [11:0]              reg_bus1, reg_bus2;

wire [1:0]               status_bus_tag1, status_bus_tag2;

inst_queue #
(
   .CLK_DELAY    (2000),
   .INS_PART_WID (4),
   .QUEUE_DEPTH  (32)
)
inst_queue
(
   .clk                 (clk) ,
   .instruction_1       (instruction_1),
   .instruction_val_1   (instruction_val_1),
   .instruction_2       (instruction_2),
   .instruction_val_2   (instruction_val_2),
   
   .inst_1_fetch        (inst_1_fetch),
   .inst_1_valid        (inst_1_valid),
   .inst_1_type         (inst_1_type),
   .inst_1_dest         (inst_1_dest),
   .inst_1_src0         (inst_1_src0),
   .inst_1_src1         (inst_1_src1),

   .inst_2_fetch        (inst_2_fetch),
   .inst_2_valid        (inst_2_valid),
   .inst_2_type         (inst_2_type),
   .inst_2_dest         (inst_2_dest),
   .inst_2_src0         (inst_2_src0),
   .inst_2_src1         (inst_2_src1)
);

idu #
(
   .NUM_RS       (8),
   .NUM_REG      (4),
   .CLK_DELAY    (2000),
   .INS_PART_WID (4),
   .TAG_LEN      (4)
)
idu
(
   .clk             (clk),

   .inst_1_valid            (inst_1_valid),
   .inst_1_type             (inst_1_type),
   .inst_1_dest             (inst_1_dest),
   .inst_1_src0             (inst_1_src0),
   .inst_1_src1             (inst_1_src1),
   .inst_1_fetch            (inst_1_fetch),

   .inst_2_valid            (inst_2_valid),
   .inst_2_type             (inst_2_type),
   .inst_2_dest             (inst_2_dest),
   .inst_2_src0             (inst_2_src0),
   .inst_2_src1             (inst_2_src1),
   .inst_2_fetch            (inst_2_fetch),

   .instruction1            (instruction1), // <RS_TO_USE, SOURCE_1, SOURCE_2>
   .instruction1_valid      (instruction1_valid),
   .status_bus_tag1         (status_bus_tag1),

   .instruction2            (instruction2), // <RS_TO_USE, SOURCE_1, SOURCE_2>
   .instruction2_valid      (instruction2_valid),
   .status_bus_tag2         (status_bus_tag2),

   .adder_done              (adder_done),
   .mult_done               (mult_done),
   .fetch_done              (fetch_done),
   .store_done              (store_done),

   .reg1_status_table       (reg1_status_table), 
   .reg2_status_table       (reg2_status_table), 
   .reg3_status_table       (reg3_status_table), 
   .reg4_status_table       (reg4_status_table)

);

assign reg_sel_src1 = instruction1_valid ? instruction1[7:4] : instruction2[7:4];
assign reg_sel_src2 = instruction1_valid ? instruction1[3:0] : instruction2[3:0];

always @(*)
begin
   case(reg_sel_src1)
      4'b1001 : reg_bus1 = {4'b1001,r0};
      4'b1010 : reg_bus1 = {4'b1010,r1};
      4'b1011 : reg_bus1 = {4'b1011,r2};
      4'b1100 : reg_bus1 = {4'b1100,r3};
      default : reg_bus1 = {4'b1001,r0};
   endcase
end

always @(*)
begin
   case(reg_sel_src2)
      4'b1001 : reg_bus2 = {4'b1001,r0};
      4'b1010 : reg_bus2 = {4'b1010,r1};
      4'b1011 : reg_bus2 = {4'b1011,r2};
      4'b1100 : reg_bus2 = {4'b1100,r3};
      default : reg_bus2 = {4'b1001,r0};
   endcase
end

storefetch storefetch 
(
   .instruction1   (instruction1),
   .instruction2   (instruction2),
   .clk            (clk),
   .status_bus_tag1 (status_bus_tag1), 
   .status_bus_tag2 (status_bus_tag2), 
   .outmul          (outmul),
   .outadd          (outadd),
   .reg_bus1        (reg_bus1),
   .reg_bus2        (reg_bus2),
   .send1           (instruction1_valid),
   .send2           (instruction2_valid),
   .outfetch        (outfetch),
   .donefetch_0     (fetch_done[0]),
   .donefetch_1     (fetch_done[1]),
   .donestore_0     (store_done[0]),
   .donestore_1     (store_done[0])
);

reservation_station reservation_stn
(
   .clk             (clk),
   .instruction1    (instruction1),
   .instruction2    (instruction2),
   .status_bus_tag1 (status_bus_tag1),
   .status_bus_tag2 (status_bus_tag2),
   .outfetch        (outfetch),
   .reg_bus1        (reg_bus1),
   .reg_bus2        (reg_bus2),
   .send1           (instruction1_valid),
   .send2           (instruction2_valid),
   .outadd          (outadd),
   .outmul          (outmul),
   .doneadd_0       (adder_done[0]),
   .doneadd_1       (adder_done[1]),
   .donemul_0       (mult_done[0]),
   .donemul_1       (mult_done[1])
);

register_file reg_file
(
    .clk                (clk),
    .adder_done         (adder_done),
    .mult_done          (mult_done),
    .fetch_done         (fetch_done),
    .instruction1       (instruction1),
    .instruction2       (instruction2),
    .reg1_status_table  (reg1_status_table),
    .reg2_status_table  (reg2_status_table),
    .reg3_status_table  (reg3_status_table),
    .reg4_status_table  (reg4_status_table),
    .outadd             (outadd[7:0]),
    .outmul             (outmul[7:0]),
    .outfetch           (outfetch[7:0]),
    .r0                 (r0),
    .r1                 (r1),
    .r2                 (r2),
    .r3                 (r3)
);

endmodule
