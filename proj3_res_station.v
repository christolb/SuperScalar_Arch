module reservation_station  #
(
   parameter CLK_DELAY    = 2000 // Clock period in ns
)
(
input 	         clk,
input wire [15:0]instruction1,
input wire [15:0]instruction2,
input wire [1:0] status_bus_tag1, // Tells us whether the tag is real or virtual (for Instruction1)
input wire [1:0] status_bus_tag2, // For Instruction2
input      [11:0] outfetch, 
input wire [11:0]reg_bus1,
input wire [11:0]reg_bus2,
input wire 	 send1,
input wire 	 send2,
output reg [11:0]outadd,
output reg [11:0]outmul,
output reg doneadd_0,
output reg doneadd_1,
output reg donemul_0,
output reg donemul_1
);




reg a0_free  		= 1'b1;
reg a1_free  		= 1'b1;
reg m0_free  		= 1'b1;
reg m1_free 		= 1'b1;
reg a0_first 		= 1'b0;
reg a1_first 		= 1'b0;
reg m0_first 		= 1'b0;
reg m1_first 		= 1'b0;
reg [15:0]inst1      = 16'b1111111111111111;
reg [15:0]inst2      = 16'b1111111111111111;
reg [1:0]status_tag1 = 1'b0;
reg [1:0]status_tag2 = 1'b0;
reg [11:0]reg1 	     = 12'b0;
reg [11:0]reg2 	     = 12'b0;
reg [15:0]inst 	     = 16'b1111111111111111;
reg [1:0]stag 	     = 1'b0;
reg [15:0]inst_a0    = 16'b1111111111111111;
reg [15:0]inst_a1    = 16'b1111111111111111;
reg [15:0]inst_m0    = 16'b1111111111111111;
reg [15:0]inst_m1    = 16'b1111111111111111;
reg [1:0] stag_a0    = 1'b0;
reg [1:0] stag_a1    = 1'b0;
reg [1:0] stag_m0    = 1'b0;
reg [1:0] stag_m1    = 1'b0;
reg data01     = 1'b0;
reg data02     = 1'b0;
reg data11     = 1'b0;
reg data12     = 1'b0;
reg data21     = 1'b0;
reg data22     = 1'b0;
reg data31     = 1'b0;
reg data32     = 1'b0;
reg [24:0] res_add[0:1];
reg [24:0] res_mul[0:1];
reg [1:0]    count0=0;
reg [1:0]    count1=0;
reg [1:0]    count2=0;
reg [1:0]    count3=0;
reg [7:0]    sum=0;
reg [7:0]    mul=0;

initial
begin
res_add[0] 	= 25'b0;
res_add[1] 	= 25'b0;
res_mul[0] 	= 25'b0;
res_mul[1] 	= 25'b0;
doneadd_0 		= 1'b1;
doneadd_1 		= 1'b1;
donemul_0 		= 1'b1;
donemul_1 		= 1'b1;
end

always@(*)
begin
if(clk == 1'b1)
begin
	if(send1 == 1'b1)
	begin
	inst1 = instruction1;
	status_tag1 = status_bus_tag1;
	reg1 = reg_bus1;
	reg2 = reg_bus2;
        end
	if(send2 == 1'b1)
	begin
	inst2 = instruction2;
	status_tag2 = status_bus_tag2;
	reg1 = reg_bus1;
	reg2 = reg_bus2;
	end
end
end

reg data01_d, data02_d;

always @(*)
if(clk)
   #CLK_DELAY data01_d = data01;

always @(*)
if(clk)
   #CLK_DELAY data02_d = data02;

always @ (clk)
begin
if (clk ==1'b1)
begin
	if ( (data01 && !data01_d) || (data02 && !data02_d))
	begin
		count0 = 0;
	end
	else if ( count0 == 3 )
	begin
		count0 = 0 ;
	end
	else
	begin
		count0 = count0 + 1;
	end
	if ( data11 == 1'b1 && data12 == 1'b1)
	begin
		count1 = 0;
	end
	else if ( count1 == 3 )
	begin
		count1 = 0 ;
	end
	else
	begin
		count1 = count1 + 1;
	end
end
end

always @ (clk)
begin
if (clk ==1'b1)
begin
	if ( data21 == 1'b1 && data22 == 1'b1)
	begin
		count2 = 0;
	end
	else if ( count2 == 4 )
	begin
		count2 = 0 ;
	end
	else
	begin
		count2 = count2 + 1;
	end
	if ( data31 == 1'b1 && data32 == 1'b1)
	begin
		count3 = 0;
	end
	else if ( count3 == 4 )
	begin
		count3 = 0 ;
	end
	else
	begin
		count3 = count3 + 1;
	end
end
end

wire [7:0] res_add_0_8_1   = res_add[0][8:1];
wire [7:0] res_add_0_20_13 = res_add[0][20:13];
wire [3:0] res_add_0_12_9  = res_add[0][12:9];
wire [3:0] res_add_0_24_21 = res_add[0][24:21];

reg enter_1=0, enter_2=0, enter_3=0, enter_4=0, enter_5=0, enter_6=0, enter_7=0, enter_8=0, enter_9=0, enter_10=0;

always@(clk)
begin
if(clk == 1'b0)
begin
	if(count0 == 3)
	begin
           enter_1 = 1;
	   a0_free=1'b1; // a0 is free to get filled
	   doneadd_0=1'b1; //add over
	   outadd={4'b0,sum[7:0]};
	   res_add[0][0]=1'b0; // reservation station is not being used
	   count0 = 0;
	end
	
	if(((inst1[15:12]<=4'd2) || (inst2[15:12]<=4'd2)) && ((res_add[0][0]!=1'b1) || (doneadd_0!=1'b0))) // checks if it's AO
	begin
           enter_2 = 1;
	doneadd_0=1'b0;
	  if(inst1[15:12]==4'b1)
	  begin
           enter_3 = 1;
	    inst_a0=inst1;
  	    stag_a0=status_tag1;//[1]-s1 tag; [0]-s2 tag; is equal to 1 - virtual tag; 0 -real tag
	  end
	  else
          begin
            inst_a0=inst2;		  
	    stag_a0=status_tag2;
          end
	  if(a0_free ==1'b1)
	  begin
           enter_4 = 1;
	  res_add[0][12:9]=inst_a0[3:0]; // s2 tag 
	  res_add[0][24:21]=inst_a0[7:4]; // s1 tag
	  res_add[0][0]=1'b1;// a0 reservation status is being used
	    if(((res_add[0][12:9]==reg1[11:8]) || (res_add[0][12:9]==reg2[11:8])) && (stag_a0[0]!=1)) 
		    //check if res station a0's s2tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
           enter_5 = 1;
	    	 if(res_add[0][12:9]==reg1[11:8])
		 begin
                         enter_6 = 1;
			 res_add[0][8:1] = reg1[7:0];
			 data02 = 1'b1; // A0 S2 data present
		 end

	    	 if(res_add[0][12:9]==reg2[11:8])
		 begin
                         enter_7 = 1;
			 res_add[0][8:1] = reg2[7:0];
			 data02 = 1'b1;
		 end
	    end

	    if(((res_add[0][24:21]==reg1[11:8]) || (res_add[0][24:21]==reg2[11:8])) && (stag_a0[1]!=1)) 
		    //check if res station a0's s1tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
           enter_10 = 1;
	    	 if(res_add[0][24:21]==reg1[11:8])
		 begin
                         enter_8 = 1;
			 res_add[0][20:13] = reg1[7:0];
			 data01 = 1'b1;
		 end

	    	 if(res_add[0][24:21]==reg2[11:8])
		 begin
                         enter_9 = 1;
			 res_add[0][20:13] = reg2[7:0];
			 data01 = 1'b1; 
		 end	
	    end	 	
	    if(stag_a0[0]==1'b1) // If tag is virtual ie from other reservation stations' outputs
	    begin
	    	 if(res_add[0][12:9]==outadd[11:8])
		 begin
			 res_add[0][8:1] = outadd[7:0];
			 data02 = 1'b1;			
		 end
	    	 if(res_add[0][12:9]==outmul[11:8])
		 begin
			 res_add[0][8:1] = outmul[7:0];
			 data02 = 1'b1;			
		 end
	    	 if(res_add[0][12:9]==outfetch[11:8])
		 begin
			 res_add[0][8:1] = outfetch[7:0];
			 data02 = 1'b1;			
		 end
	    	 
		 if(res_add[0][24:21]==outadd[11:8])
		 begin
			 res_add[0][20:13] = outadd[7:0];
			 data01 = 1'b1;			
		 end
	    	 if(res_add[0][24:21]==outmul[11:8])
		 begin
			 res_add[0][20:13] = outmul[7:0];
			 data01 = 1'b1;			
		 end
	    	 if(res_add[0][24:21]==outfetch[11:8])
		 begin
			 res_add[0][20:13] = outfetch[7:0];
			 data01 = 1'b1;			
		 end
		
	    end
	    if(data01 == 1'b1 && data02 == 1'b1 && count0 == 1'b0 && a0_free == 1'b1) // COUNT NEEDS WORK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    begin
		sum = res_add[0][20:13] + res_add[0][8:1];
		data01 = 1'b0;
		data02 = 1'b0;
		doneadd_0 = 1'b1; 
		// WHAT ABOUT COUNT?????????????????
	    end
	  end

	end
  end
end

always @(*)
begin
if(clk == 1'b0)
begin


	if(count1 == 3) //CHECKKKKKKKKKKKK
	begin
	a1_free=1'b1; // a1 is free to get filled
	doneadd_1=1'b1; //add over
	outadd={4'b0001,sum[7:0]};
	res_add[1][0]=1'b0; // reservation station is not being used
	count1 = 0;
	end
	
	if(((inst1[15:12]==4'b0001) || (inst2[15:12]==4'b0001)) && ((res_add[1][0]!=1'b1) || (doneadd_1!=1'b0))) // checks if it's A1
	begin
	doneadd_1=1'b0;
	  if(inst1[15:12]==4'b0001)
	  begin
	    inst_a1=inst1;
  	    stag_a1=status_tag1;//[1]-s1 tag; [0]-s2 tag; is equal to 1 - virtual tag; 0 -real tag
	  end
	  else
          begin
            inst_a1=inst2;		  
	    stag_a1=status_tag2;
          end
	  if(a1_free ==1'b1)
	  begin
	  res_add[1][12:9]=inst_a1[3:0]; // s2 tag 
	  res_add[1][24:21]=inst_a1[7:4]; // s1 tag
	  res_add[1][0]=1'b1;// a0 reservation status is being used
	    if(((res_add[1][12:9]==reg1[11:8]) || (res_add[1][12:9]==reg2[11:8])) && (stag_a1[0]!=1)) 
		    //check if res station a1's s2tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
	    	 if(res_add[1][12:9]==reg1[11:8])
		 begin
			 res_add[1][8:1] = reg1[7:0];
			 data12 = 1'b1; // A1 S2 data present
		 end

	    	 if(res_add[1][12:9]==reg2[11:8])
		 begin
			 res_add[1][8:1] = reg2[7:0];
			 data12 = 1'b1;
		 end
	    end

	    if(((res_add[1][24:21]==reg1[11:8]) || (res_add[1][24:21]==reg2[11:8])) && (stag_a1[1]!=1)) 
		    //check if res station a0's s1tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
	    	 if(res_add[1][24:21]==reg1[11:8])
		 begin
			 res_add[1][20:13] = reg1[7:0];
			 data11 = 1'b1;
		 end

	    	 if(res_add[1][24:21]==reg2[11:8])
		 begin
			 res_add[1][20:13] = reg2[7:0];
			 data11 = 1'b1; 
		 end	
	    end	 	
	    if(stag_a1[0]==1'b1) // If tag is virtual ie from other reservation stations' outputs
	    begin
	    	 if(res_add[1][12:9]==outadd[11:8])
		 begin
			 res_add[1][8:1] = outadd[7:0];
			 data12 = 1'b1;			
		 end
	    	 if(res_add[1][12:9]==outmul[11:8])
		 begin
			 res_add[1][8:1] = outmul[7:0];
			 data12 = 1'b1;			
		 end
	    	 if(res_add[1][12:9]==outfetch[11:8])
		 begin
			 res_add[1][8:1] = outfetch[7:0];
			 data12 = 1'b1;			
		 end
	    	 
		 if(res_add[1][24:21]==outadd[11:8])
		 begin
			 res_add[1][20:13] = outadd[7:0];
			 data11 = 1'b1;			
		 end
	    	 if(res_add[1][24:21]==outmul[11:8])
		 begin
			 res_add[1][20:13] = outmul[7:0];
			 data11 = 1'b1;			
		 end
	    	 if(res_add[1][24:21]==outfetch[11:8])
		 begin
			 res_add[1][20:13] = outfetch[7:0];
			 data11 = 1'b1;			
		 end
		
	    end
	    if(data11 == 1'b1 && data12 == 1'b1 && count1 == 1'b0 && a1_free == 1'b1) // COUNT NEEDS WORK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    begin
		sum = res_add[1][20:13] + res_add[1][8:1];
		data11 = 1'b0;
		data12 = 1'b0;
		doneadd_1 = 1'b1; 
		// WHAT ABOUT COUNT?????????????????
	    end

	  end
  end
  end
  end

  // MULTIPLICATION BEGINS
 

always@(clk)
begin
if(clk == 1'b0)
begin
	if(count2 == 4) //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	begin
	m0_free=1'b1; // m0 is free and ready to be occupied
	donemul_0=1'b1; // Multiplication complete
	outmul={4'b0,mul[7:0]};
	res_mul[0][0]=1'b0; // Reservation station is not being used
	count2 = 0; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	end
	
	if(((inst1[15:12]==4'b0010) || (inst2[15:12]==4'b0010)) && ((res_mul[0][0]!=1'b1) || (donemul_0!=1'b0))) // checks if it's AO
	begin
	donemul_0=1'b0;
	  if(inst1[15:12]==4'b0010)
	  begin
	    inst_m0=inst1;
  	    stag_m0=status_tag1;// [1]-s1 tag; [0]-s2 tag; is equal to 1 - virtual tag; 0 -real tag
	  end
	  else
          begin
            inst_m0=inst2;
	    stag_m0=status_tag2;
          end
	  if(m0_free ==1'b1)
	  begin
	  res_mul[0][12:9]=inst_m0[3:0]; // s2 tag 
	  res_mul[0][24:21]=inst_m0[7:4]; // s1 tag
	  res_mul[0][0]=1'b1;// m0 reservation status is being used
	    if(((res_mul[0][12:9]==reg1[11:8]) || (res_mul[0][12:9]==reg2[11:8])) && (stag_m0[0]!=1)) 
		    //check if res station a0's s2tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
	    	 if(res_mul[0][12:9]==reg1[11:8])
		 begin
			 res_mul[0][8:1] = reg1[7:0];
			 data22 = 1'b1; // M0 S2 data present
		 end

	    	 if(res_mul[0][12:9]==reg2[11:8])
		 begin
			 res_mul[0][8:1] = reg2[7:0];
			 data22 = 1'b1;
		 end
	    end

	    if(((res_mul[0][24:21]==reg1[11:8]) || (res_mul[0][24:21]==reg2[11:8])) && (stag[1]!=1)) 
		    //check if res station a0's s1tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
	    	 if(res_mul[0][24:21]==reg1[11:8])
		 begin
			 res_mul[0][20:13] = reg1[7:0];
			 data21 = 1'b1;
		 end

	    	 if(res_mul[0][24:21]==reg2[11:8])
		 begin
			 res_mul[0][20:13] = reg2[7:0];
			 data21 = 1'b1; 
		 end	
	    end	 	
	    if(stag_m0[0]==1'b1) // If tag is virtual ie from other reservation stations' outputs
	    begin
	    	 if(res_mul[0][12:9]==outmul[11:8])
		 begin
			 res_mul[0][8:1] = outmul[7:0];
			 data22 = 1'b1;			
		 end
	    	 if(res_mul[0][12:9]==outadd[11:8])
		 begin
			 res_mul[0][8:1] = outadd[7:0];
			 data22 = 1'b1;			
		 end
	    	 if(res_add[0][12:9]==outfetch[11:8])
		 begin
			 res_mul[0][8:1] = outfetch[7:0];
			 data22 = 1'b1;			
		 end
	    	 
		 if(res_add[0][24:21]==outadd[11:8])
		 begin
			 res_mul[0][20:13] = outmul[7:0];
			 data21 = 1'b1;			
		 end
	    	 if(res_mul[0][24:21]==outadd[11:8])
		 begin
			 res_mul[0][20:13] = outadd[7:0];
			 data21 = 1'b1;			
		 end
	    	 if(res_mul[0][24:21]==outfetch[11:8])
		 begin
			 res_mul[0][20:13] = outfetch[7:0];
			 data21 = 1'b1;			
		 end
		
	    end
	    if(data21 == 1'b1 && data22 == 1'b1 && count2 == 1'b0 && m0_free == 1'b1) // COUNT NEEDS WORK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    begin
		sum = res_mul[0][20:13] * res_mul[0][8:1];
		data21 = 1'b0;
		data22 = 1'b0;
		donemul_0 = 1'b1; 
		// WHAT ABOUT COUNT?????????????????
	    end

	  end
  end
  end
  end
always@(clk)
begin
if(clk == 1'b0)
begin


	if(count3 == 4) //CHECKKKKKKKKKKKK
	begin
	m1_free=1'b1; // m1 is free to get filled
	donemul_1=1'b1; // Multiplication completed
	outmul={4'b0011,mul[7:0]}; // WHAT IS MUL? 
	res_mul[1][0]=1'b0; // reservation station is not being used
	count3 = 0; //!!!!!!!!!!
	end
	
	if(((inst1[15:12]==4'b0011) || (inst2[15:12]==4'b0011)) && ((res_mul[1][0]!=1'b1) || (donemul_1!=1'b0))) // checks if it's m1
	begin
	donemul_1=1'b0;
	  if(inst1[15:12]==4'b0011)
	  begin
	    inst_m1=inst1;
  	    stag_m1=status_tag1;//[1]-s1 tag; [0]-s2 tag; is equal to 1 - virtual tag; 0 -real tag
	  end
	  else
          begin
            inst_m1=inst2;		  
	    stag_m1=status_tag2;
          end
	  if(m1_free ==1'b1)
	  begin
	  res_mul[1][12:9]=inst_m1[3:0]; // s2 tag 
	  res_mul[1][24:21]=inst_m1[7:4]; // s1 tag
	  res_mul[1][0]=1'b1;// m0 reservation status is being used
	    if(((res_mul[1][12:9]==reg1[11:8]) || (res_mul[1][12:9]==reg2[11:8])) && (stag_m1[0]!=1)) 
		    //check if res station m1's s2tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
	    	 if(res_mul[1][12:9]==reg1[11:8])
		 begin
			 res_mul[1][8:1] = reg1[7:0];
			 data32 = 1'b1; // M1 S2 data present
		 end

	    	 if(res_mul[1][12:9]==reg2[11:8])
		 begin
			 res_mul[1][8:1] = reg2[7:0];
			 data32 = 1'b1;
		 end
	    end

	    if(((res_mul[1][24:21]==reg1[11:8]) || (res_mul[1][24:21]==reg2[11:8])) && (stag_m1[1]!=1)) 
		    //check if res station M0's s1tag is equal to either of the reg bus's tag and if it's a real tag. 
	    begin 
	    	 if(res_mul[1][24:21]==reg1[11:8])
		 begin
			 res_mul[1][20:13] = reg1[7:0];
			 data31 = 1'b1;
		 end

	    	 if(res_mul[1][24:21]==reg2[11:8])
		 begin
			 res_mul[1][20:13] = reg2[7:0];
			 data31 = 1'b1; 
		 end	
	    end	 	
	    if(stag_a1[0]==1'b1) // If tag is virtual ie from other reservation stations' outputs
	    begin
	    	 if(res_add[1][12:9]==outadd[11:8])
		 begin
			 res_add[1][8:1] = outadd[7:0];
			 data12 = 1'b1;			
		 end
	    	 if(res_add[1][12:9]==outmul[11:8])
		 begin
			 res_add[1][8:1] = outmul[7:0];
			 data12 = 1'b1;			
		 end
	    	 if(res_add[1][12:9]==outfetch[11:8])
		 begin
			 res_add[1][8:1] = outfetch[7:0];
			 data12 = 1'b1;			
		 end
	    	 
		 if(res_mul[1][24:21]==outmul[11:8])
		 begin
			 res_mul[1][20:13] = outmul[7:0];
			 data31 = 1'b1;			
		 end
	    	 if(res_mul[1][24:21]==outadd[11:8])
		 begin
			 res_mul[1][20:13] = outadd[7:0];
			 data31 = 1'b1;			
		 end
	    	 if(res_mul[1][24:21]==outfetch[11:8])
		 begin
			 res_mul[1][20:13] = outfetch[7:0];
			 data31 = 1'b1;			
		 end
		
	    end
	    if(data31 == 1'b1 && data32 == 1'b1 && count3 == 1'b0 && m1_free == 1'b1) // COUNT NEEDS WORK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		    // WHAT ABOUT M1 free? Should it be M0 free?
	    begin
		sum = res_mul[1][20:13] * res_mul[1][8:1];
		data31 = 1'b0;
		data32 = 1'b0;
		donemul_1 = 1'b1; 
		// WHAT ABOUT COUNT?????????????????
	    end

	  end
  end
end
end
endmodule
