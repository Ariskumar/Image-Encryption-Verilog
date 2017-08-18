module logistic(clk,reset,led,databus1,addressbus2,ce,we,lsb,msb,oe);
input clk,reset;
output [15:0]databus1;
output [17:0] addressbus2;
output ce,we,lsb,msb,oe;
output reg led;
reg [7:0]byte_counter, state; 
reg [31:0] logistic_result;
reg sub_aclr,subclk_en,mult_clr,mulclk_en,count_clr,clk_en,count_enble,cnt_wr;
reg [31:0] sub_in1,sub_in2,sub_result,x_n,r_n,mull_acc,sub_acc,addcount;
reg [15:0] accumlator;
wire[31:0]  c1,c2,count;
parameter read=1,load=2,delay_loop=3,process=4,wait_process=5,loop=6,write=7,write_1=8, 
process_complete=10;
sub_fun u1 (.clock(clk),.aclr(sub_aclr),.clk_en(subclk_en),.dataa(sub_in1),.datab(sub_in2),.result(c1));
mult_fun u2(.clock(clk),.aclr(mult_clr),.clk_en(mulclk_en),.dataa(x_n),.datab(r_n),.result(c2));
counter1 u3 (.clock(clk),.aclr(count_clr),.clk_en(clk_en),.cnt_en(count_enble),.q(count));

reg [15:0] rand_counter,temp,temp1;
reg [15:0] rand_no[32:1];
reg [15:0] array1[32:1];
parameter store_rand=11,gen_array=12,rearrange=13;


always@(posedge clk)
if(reset)
state=read;
else
begin
case (state)
read:	begin
		sub_in1=32'h3f800000; //1
		sub_in2=32'h3dcccccd; // xn
		addcount=0;			
		r_n=32'h40733333;     //u
		x_n=32'h3dcccccd;     // xn 
		subclk_en=1'b0;
		sub_aclr=1'b1;		
		
		mult_clr=1'b1;
		mulclk_en=1'b0;	
		
		count_clr=1'b1;
		clk_en=1'b0;
		count_enble=1'b0;
		
		rand_counter = 0;		
		
		led=1'b0;	
		cnt_wr =1'b1; 										
		state =load;
		end
load	:begin
		subclk_en=1'b1;
		sub_aclr=1'b0;
		mult_clr=1'b0;
		mulclk_en=1'b1;
		clk_en=1'b1;
		count_enble=1'b1;
		count_clr=1'b0;
		state=delay_loop;
		end
		
delay_loop:begin
			if(count>=10)
			begin
		    clk_en=1'b0;
		    count_enble=1'b0;
		    count_clr=1'b1;  
		    mull_acc=c1;
			sub_acc =c2; 
            state=process;
		    end
		    else
		    state=delay_loop;
		    end
		    
process:begin        
        r_n=mull_acc;     //u
		x_n=sub_acc;     // b 
		mulclk_en=1'b1;
        mult_clr=1'b0;
        clk_en=1'b1;
		count_enble=1'b1;
		count_clr=1'b0;
		state=wait_process;
        end

wait_process :begin  
        if(count>=10)
			begin
		    clk_en=1'b0;
		    count_enble=1'b0;
		    count_clr=1'b1;    
		    logistic_result=c2;
		    state=loop;
		    end
		    else
		    state=wait_process;
		    end
        
loop:begin
        sub_in1=32'h3f800000;
		sub_in2=logistic_result;
		r_n=32'h40733333;	
		x_n=logistic_result;	
		
		//acc[1]=loop_logistic[15:0]; // 754 standard split into 16/16 for store the ram
		//acc[2]=loop_logistic[31:16];
		
		sub_aclr=1'b1;		
		subclk_en=1'b0;
		
		mult_clr=1'b1;
		mulclk_en=1'b0;	
		
		count_enble=1'b0;		
		count_clr=1'b1;
		clk_en=1'b0;
		byte_counter=0;
		state=store_rand;
		end
store_rand:	begin
					rand_counter = rand_counter + 1;
					if(rand_counter > 32)
					begin
						rand_counter = 0;
						state = gen_array;
					end
					else
					begin
						rand_no[rand_counter][15:0] = logistic_result[15:0];
						state = load;
					end
			end
gen_array: 	begin
				rand_counter = rand_counter + 1;
				if(rand_counter > 32)
					begin
						rand_counter = 0;
						state = rearrange;
					end
					else
					begin
						array1[rand_counter] = rand_counter;
						state = gen_array;
					end
			end
        
rearrange: 	begin
				rand_counter = rand_counter + 1;
				if(rand_counter > 32)
					begin
						rand_counter = 0;
						state = write;
					end
					else
					begin
						temp = array1[rand_counter];
						temp1 = (rand_no[rand_counter] % 32) + 1;
						array1[rand_counter] = array1[temp1];
						array1[temp1] = temp;
						state = rearrange;
					end
			end
						
        
        
write:	begin		
		byte_counter = byte_counter+1;												
		if(byte_counter<=32)
		begin	
										addcount=addcount+1;			
										accumlator=array1[byte_counter]; //load first data
										cnt_wr =1'b0;
										state = write_1;				              				
										end	
									else
										begin							
										byte_counter=0;
        								cnt_wr=1'b1;
										state = process_complete;
										end
										end
									    
write_1:	begin	
								cnt_wr=1'b1;												            
								state=write;							
								end
				
process_complete:begin
                led=1'b1;
				state=process_complete;        
				end
		
        endcase
        end
        
assign databus1 =  accumlator;			
assign addressbus2 = addcount;	         
assign lsb =1'b0;
assign msb  =1'b0;
assign ce = 1'b0; 
assign oe =  1'b1;
assign we = cnt_wr ? 1'b1 : 1'b0;

endmodule




