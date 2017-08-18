module row128 (clk,databus1,addressbus2,we,ce,lsb,msb,oe,led,reset);
input clk,reset;
inout [15:0]databus1;
output [17:0] addressbus2;
output ce,we,lsb,msb,oe,led;
// regiter decleration 
reg cnt_rw,cnt_wr,cnt_oe,led;
reg [1:0] cnt_id;
reg [7:0] byte_counter;
reg [7:0] state;
//reg [7:0] ram [256:1]; 
reg [15:0]  row_counter,accumlator,random_reg,chaotic_address;
reg [17:0] addcount,addcount1,stack1;

//integer coloum_counter;
//memory decleration
reg [15:0] acc [64:1];
// parameter  decleration
//parameter imageaddress=18'hc9;  
parameter dataaddress=18'hc600;//18'h1f5;//for 252*252 image (data starting address )95283; //for 128 * 128 image24604;

//state machine state address
parameter filesize=0,pixel_start=1,pixel_bg=2,chaotic_read=3,chaotic_read1=4,
		  load_randomaddress=5,write=6,write_1=7,next_pixelround=8,steg_end=9,writ=10;
initial
begin
	addcount=0;
	addcount1=0;
	byte_counter=0;	
	cnt_rw=0;
	cnt_oe=1;
	cnt_wr=1;
	cnt_id=1;
	led=1'b0;
	row_counter=0;	
	end
always @(posedge clk or posedge reset)
     begin
           if (reset)
               state =  filesize;
          else          
               begin
					 case (state)
													
filesize:begin
								//addcount=18'h385; //d-901
								chaotic_address=18'hc100;
								state=chaotic_read;			        
								end	
								
chaotic_read:begin
								cnt_wr=1'b1;								
								cnt_rw=1'b0;  //if read rw=0;				 						
								cnt_oe=1'b0;
								cnt_id=0;    //1'b1;  //if image id=1  																 					  					      
								state=chaotic_read1;					          						  
								end 
chaotic_read1:	begin
								cnt_oe=1'b1;								
								random_reg	 = databus1;	
								row_counter  = row_counter+1;
								state=load_randomaddress;								
                end
                              
 load_randomaddress: begin
                             // random_reg=random_stack[row_counter][7:0];
                              random_reg=random_reg*64; 
                              addcount1=random_reg-64; 	
							  chaotic_address=chaotic_address+1;	
                              state = pixel_start;
                              end
												
 pixel_start:	begin
								cnt_wr=1'b1;								
								cnt_rw=1'b0;  //if read rw=0;				 						
								cnt_oe=1'b0;
								cnt_id=1;     //1'b1;  //if image id=1  																 					  					      
								state=pixel_bg;					          						  
								end 
pixel_bg:	begin
								cnt_oe=1'b1;								
								byte_counter 		= byte_counter+1;				
								acc[byte_counter] 	= databus1;								
								if(byte_counter>=64)//if(byte_counter>=6)
								begin
								byte_counter=0;
								//random_stack[row_counter][7:0]=row_counter; 
								state=writ;								
								end	
								else
								begin						 
									addcount1=addcount1+1;	
									state=pixel_start;					 							
								end
								end
										  

                              

writ:	begin
                              cnt_rw=1'b1;  //here  write rw=0;	
                              cnt_id=2; 													 					  					      
					    	  state = write;  //change all control to data memory                     
                              end                        
                 										
write:		
								begin		
									byte_counter = byte_counter+1;												
									if(byte_counter<=64)
										begin	
										accumlator=acc[byte_counter][15:0]; //load first data
										cnt_wr =1'b0;
										state = write_1;				              				
										end	
									else
										begin							
										byte_counter=0;	
										cnt_wr=1'b1;	
										stack1 = addcount;
										state=next_pixelround;			
										end
										end
									    
write_1:	begin	
								cnt_wr=1'b1;
								addcount=addcount+1;				            
								state=write;							
								end
				
								
next_pixelround:begin			    
									if(row_counter==384)
											state=steg_end;	
									else
										begin
										addcount=stack1;										
										//addcount=addcount+1;  // load previous value
										state=chaotic_read;										
										end								
										end   //
					  				
steg_end: begin     
					           state = steg_end;
					           led=1'b1;				           
					           end  
                              endcase
                              end
                              end
                           
assign databus1 = cnt_rw ? accumlator :16'hzzzz;			
assign addressbus2 = (cnt_id==1)? addcount1:(cnt_id ==2)?dataaddress+addcount:chaotic_address;	         
assign lsb =1'b0;
assign msb  =1'b0;
assign ce = 1'b0; 
assign oe = cnt_oe ? 1'b1:1'b0;
assign we = cnt_wr ? 1'b1 : 1'b0;
endmodule
