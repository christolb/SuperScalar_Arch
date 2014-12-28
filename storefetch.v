module storefetch(
input [15:0] instruction1,
input [15:0] instruction2,
input        clk,
input [1:0]  status_bus_tag1, // Tells us whether the tag is real or virtual (for Instruction1)
input [1:0]  status_bus_tag2, // For Instruction2
input [11:0] outmul,
input [11:0] outadd,
input [11:0]reg_bus1,
input [11:0]reg_bus2,
input       send1,
input       send2,
output reg [11:0]outfetch,
output reg donefetch_0,
output reg donefetch_1,
output reg donestore_0,
output reg donestore_1
);
reg [15:0]inst1      = 16'b1111111111111111;
reg [15:0]inst2      = 16'b1111111111111111;
reg [15:0]inst      = 16'b1111111111111111;
reg [1:0]status_tag1 = 1'b0;
reg [1:0]status_tag2 = 1'b0;
reg [11:0]reg1 	     = 12'b0;
reg [11:0]reg2 	     = 12'b0;
reg [24:0]res_fetch[0:1];
reg [24:0]res_store[0:1];
reg [15:0]inst_f0;
reg [15:0]inst_f1;
reg [15:0]inst_s0    = 16'b1111111111111111;
reg [15:0]inst_s1    = 16'b1111111111111111;
reg [1:0] stag_s0    = 1'b0;
reg [1:0] stag_s1    = 1'b0;
reg [1:0] stag_f0    = 1'b0;
reg [1:0] stag_f1    = 1'b0;
reg [7:0] flag;
reg memwrite0 =1'b0;
reg memwrite1 =1'b0;
reg memread0 =1'b0;
reg memread1 =1'b0;
reg [7:0] memory[0:1023];
reg [3:0] fetch;
reg [3:0] store;
reg [1:0] recent;
reg data_41;//store s0 data
reg data_51; // store s1 data
reg war;
reg [2:0] raw=0;

initial
begin
   donestore_0 =1'b1;
   donestore_1 =1'b1;
   donefetch_0 =1'b1;
   donefetch_1 =1'b1;
   res_store[0] = 25'b0;
   res_store[1] = 25'b0;
   res_fetch[0] = 25'b0;
   res_fetch[1] = 25'b0;
end

always@(clk)
begin
if(clk == 1'b1)
begin
	if(send1 == 1'b1)
	begin
	inst1 = instruction1;
	status_tag1 = status_bus_tag1;
	reg1 = reg_bus1;
        end
	if(send2 == 1'b1)
	begin
	inst2 = instruction2;
	status_tag2 = status_bus_tag2;
	reg2 = reg_bus2;
	end
end
end

always @ (clk)
begin
	if(clk==1'b1)
	begin
	  if(memwrite0==1'b1 && memread0!=1 && memread1!=0)
	  begin
	    flag = res_store[0][20:13];
	    memory[flag] = res_store[0][8:1];
	    res_store[0][0] = 1'b0;
	    donestore_0 = 1'b1;
	    store = 4'b0110;
	  end
	end
end

always @ (clk)
begin
	if(clk == 1'b0)
	begin
	  if(((inst1[15:12]==4'b0110) || (inst2[15:12]==4'b0110)) && ((res_store[0][0]!=1'b1) || (donestore_0!=1'b0)) && (store!=4'b0110)) // checks if it's SO
	  begin
	  donestore_0=1'b0;
	    if(inst1[15:12]==4'b0110)
	    begin
	      inst_s0=inst1;
  	      stag_s0=status_tag1;//[1]-s1 tag; [0]-s2 tag; is equal to 1 - virtual tag; 0 -real tag
	    end
	    else
            begin
              inst_s0=inst2;  
	      stag_s0=status_tag2;
            end
	  end
	  if(donestore_0==0)
	  begin
	  res_store[0][12:9]=inst_s0[3:0]; // tag 
	  res_store[0][20:13]=inst_s0[11:4]; // s1 tag
	  res_store[0][0]=1'b1;// f0 reservation status is being used
	  recent = 2'b01;
	    if( ((res_store[0][12:9]==reg1[11:8]) || (res_store[0][12:9]==reg2[11:8])) && (stag_s0!=1)) 
		    //check if res station a0's s2tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
	      if(res_store[0][12:9]==reg1[11:8])
	      begin
	        res_store[0][8:1] = reg1[7:0];
	        data_41 = 1'b1; // f0 data present
	      end
              if(res_store[0][12:9]==reg2[11:8])
	      begin
   	        res_store[0][8:1] = reg2[7:0];
	        data_41 = 1'b1;
	      end
	    end
 	  	 	
	    if(stag_s0==1'b1) // If tag is virtual ie from other reservation stations' outputs
	    begin
	      if(res_store[0][12:9]==outadd[11:8])
	      begin
	        res_store[0][8:1] = outadd[7:0];
	        data_41 = 1'b1;			
	      end
	      if(res_store[0][12:9]==outmul[11:8])
	      begin
       	        res_store[0][8:1] = outmul[7:0];
                data_41 = 1'b1;			
	      end
              if(res_store[0][12:9]==outfetch[11:8])
       	      begin
	        res_store[0][8:1] = outfetch[7:0];
	        data_41 = 1'b1;			
              end
	    end	 
	    if(data_41==1'b1 && war !=1'b1 && donestore_0==1'b0)
            begin
              memwrite0=1'b1;
	      data_41=1'b0;
	      #10 memwrite0 = 1'b0;
	    end
	  end
      end
   end



always @ (clk)
begin
	if(clk ==1'b0)
	begin
	  if(((inst1[15:12]==4'b0111) || (inst2[15:12]==4'b0111)) && ((res_store[1][0]!=1'b1) || (donestore_1!=1'b0)) && (store!=4'b0111)) // checks if it's SO
	  begin
	  donestore_1=1'b0;
	    if(inst1[15:12]==4'b0111)
	    begin
	      inst_s1=inst1;
  	      stag_s1=status_tag1;//[1]-s1 tag; [0]-s2 tag; is equal to 1 - virtual tag; 0 -real tag
	    end
	    else
            begin
              inst_s1=inst2;		  
	      stag_s1=status_tag2;
            end
	  end
	  if(donestore_1==0)
	  begin
	  res_store[1][12:9]=inst_s1[3:0]; // tag 
	  res_store[1][20:13]=inst_s1[11:4]; // memory address
	  res_store[1][0]=1'b1;// f1 reservation status is being used
	  recent = 2'b10;
	    if(((res_store[1][12:9]==reg1[11:8]) || (res_store[1][12:9]==reg2[11:8])) && (stag_s1!=1)) 
		    //check if res station a0's s2tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
	      if(res_store[1][12:9]==reg1[11:8])
	      begin
	        res_store[1][8:1] = reg1[7:0];
	        data_51 = 1'b1; // f1 data present
	      end
              if(res_store[1][12:9]==reg2[11:8])
	      begin
   	        res_store[1][8:1] = reg2[7:0];
	        data_51 = 1'b1;
	      end
	    end
 	  	 	
	    if(stag_s1==1'b1) // If tag is virtual ie from other reservation stations' outputs
	    begin
	      if(res_store[1][12:9]==outadd[11:8])
	      begin
	        res_store[1][8:1] = outadd[7:0];
	        data_51 = 1'b1;			
	      end
	      if(res_store[1][12:9]==outmul[11:8])
	      begin
       	        res_store[1][8:1] = outmul[7:0];
                data_51 = 1'b1;			
	      end
              if(res_store[1][12:9]==outfetch[11:8])
       	      begin
	        res_store[1][8:1] = outfetch[7:0];
	        data_51 = 1'b1;			
              end
	    end	 
	    if(data_51==1'b1 && war !=1'b1 && donestore_1==1'b0)
            begin
              memwrite1=1'b1;
	      data_51=1'b0;
	      #10 memwrite1 = 1'b0;
	    end
	  end
	end


end

always @ (clk)
begin
	if (clk==1'b1)
	begin
	  if (memwrite0 == 1'b1 && memwrite1 == 1'b1 && res_store[0][20:13] == res_store[1][20:13] && memread0 != 1'b1 && memread1 != 1'b1)
	  begin
	    if ( recent ==2'b10 && res_store[0][0] == 1'b1 )
	    begin
	      flag = res_store[0][20:13];
	      memory[flag] = res_store[0][8:1];
	      res_store[0][0] = 1'b0;
	      donestore_0 = 1'b1;
	      store = 4'b0110;
	      recent = 2'b01;
	    end
	    else if ( recent ==2'b01 && res_store[1][0] == 1'b1 )
	    begin 
	      flag = res_store[1][20:13];
	      memory[flag] = res_store[1][8:1];
	      res_store[1][0] = 1'b0;
	      donestore_1 = 1'b1;
	      store = 4'b0111;
	      recent = 2'b10;
	    end
	  end
	  if (memwrite0 == 1'b1 && memwrite1 == 1'b1 &&  memread0 != 1'b1 && memread1 != 1'b1) //WAW
	  begin
	    flag = res_store[1][20:13];
	    memory[flag] = res_store[1][8:1];
	    res_store[1][0] = 1'b0;
	    donestore_1 = 1'b1;
	    store = 4'b0111;
	  end
	end
end

always@(clk)
begin
	if(clk == 1'b0)
	begin
		if((instruction1[15:12] == 4'b0100 || instruction2[15:12] == 4'b0100) && (res_fetch[0][0] != 1'b1 || donefetch_0 != 1'b1) && (outfetch[11:8] != 4'b0100)) // At least one of the instructions is from reservation station F0 && F0 is not busy && the previous fetch was not from the same reservation station
		begin
			if(instruction1[15:12] == 4'b0100 && donefetch_0 == 1'b1) // Instruction1 is in F0
			begin
				inst = instruction1; // latch
				if(res_fetch[0][0] == 1'b1 && res_fetch[0][20:13] == inst[7:0]) // S0 is busy && S0 has the address in the instruction
				begin
					raw = 3'b001;
					if(res_fetch[1][0] == 1'b1 && res_fetch[1][20:13] == inst[7:0]) // S1 is busy && S1 has the address in the instruction
						begin
							raw = 3'b010;
							donefetch_0=1'b0;
						end
					else if(instruction2[15:12] == 4'b0100 && donefetch_0 == 1'b1)
					begin
						inst = instruction2;
						if((res_fetch[0][0] == 1'b1 && res_fetch[0][20:13] == inst[7:0]) || instruction1[15:4] == {4'b0111, inst[7:0]})
						begin
							raw = 3'b001;
							donefetch_0 = 1'b0;
						end
						if((res_fetch[0][0]==1'b1 && res_fetch[0][20:13]== inst[7:0]) || instruction1[15:4]== {4'b0111,inst[7:0]}) 
						begin
							raw = 3'b010;  
					                donefetch_0 = 1'b0; 
						end 

						res_fetch[0][0] = 1'b1;
						res_fetch[0][8:1] = inst[7:0];

						if(raw == 3'b000)
						begin
							memread0 = 1'b1; //CHECK VARIABLE
							#10 memread0 = 1'b0;
						end
					end
				end
			end
		end
	end
end

always@(clk)
begin
	if(clk==1'b1)
	begin
		if(memread0 == 1'b1)
		begin
			flag = res_fetch[0][8:1];
			outfetch = {4'b0100, memory[flag]};
			res_fetch[0][0] = 1'b0;
			fetch = 4'b0100;
			donefetch_1=1'b1;
			
		end
	end
end

always@(clk)
begin
   if(clk == 1'b0)
   begin
      if(((instruction1[15:12] == 4'b0101) || (instruction2[15:12] == 4'b0101)) && (res_fetch[1][0] != 1'b1 || donefetch_1 == 1'b0) && outfetch[12:9] != 1'b1)
      begin
     	 if(instruction1[15:12] == 4'b0101 && donefetch_0 == 1'b1)
     	 begin
     			inst1 = instruction1;
     			if(res_fetch[0][0]==1'b1 && res_fetch[0][20:13]== inst1[7:0])
     			begin
     				raw = 3'b011;
     				if(res_fetch[1][0]==1'b1 && res_fetch[1][20:13]== inst1[7:0]) 
     				begin 
     					raw = 3'b100;
     		      			donefetch_1 = 1'b0; 
     				end 
     				else if(instruction2[15:12] == 4'b0101 && donefetch_1==1'b1)
     				begin
     					inst1=instruction2;
     					if((res_fetch[0][0]==1'b1 && res_fetch[0][20:13]== inst[7:0]) || instruction1 == {4'b0110,inst[7:0]}) 
     						raw = 3'b011; 
     				  	if((res_fetch[0][0]==1'b1 && res_fetch[0][20:13]== inst[7:0]) || instruction1 == {4'b0111,inst[7:0]}) 
     					begin
     				       		raw = 3'b100;    
     						donefetch_1=1'b0; 
     					end
     					res_fetch[1][10] = 1'b1;
     					res_fetch[1][8:1] = inst1[7:0];
     					if(raw == 1'b1)
     					begin
     						memread1 = 1'b1;
     						#10 memread1 = 1'b0;
					end
				end
			end
     	     end
     	end
    end	
end

always @ (clk)
begin
if (clk ==1'b1)
begin
	if ( inst1 != 16'b1111111111111111 && inst2 != 16'b1111111111111111 )
	begin
	  if (( inst1[15:12] == 4'b0100 || inst1[15:12] == 4'b0101 ) && ( inst2[15:12] == 4'b0110 || inst2[15:12] == 4'b0111))
	  begin
	    if ( inst1[11:4] == inst2[11:4] )
	    begin
	      war = 1'b1;
	      #20 war = 1'b0;
	    end 
	  end
	end
end
end

always @ (clk)
begin
	if(clk==1'b0)
	begin
	  if(raw == 3'b001 && donestore_0 == 1'b1)
	  begin
	    outfetch= {4'b0100,res_store[0][8:1]};
	    res_fetch[0][0]=1'b0;
	    fetch=4'b0100;
	    raw=3'b0;
	    donefetch_0=1'b1;
	  end
	  if(raw==3'b010 && donestore_1==1'b1)
	  begin	
	    outfetch= {4'b0100,res_store[1][8:1]};
	    res_fetch[0][0]=1'b0;
	    fetch=4'b0100;
	    raw=3'b0;
	    donefetch_0=1'b1;
	  end
	  if(raw==3'b011 && donestore_0==1'b1)
	  begin
	    outfetch= {4'b0101,res_store[0][8:1]};
	    res_fetch[1][0]=1'b0;
	    fetch=4'b0101;
	    raw=3'b0;
	    donefetch_1=1'b1;
	  end
	  if(raw==3'b100 && donestore_1==1'b1)
	  begin
	    outfetch= {4'b0101,res_store[1][8:1]};
	    res_fetch[1][0]=1'b0;
	    fetch=4'b0101;
	    raw=3'b0;
	    donefetch_1=1'b1;
          end
	end
end
endmodule
