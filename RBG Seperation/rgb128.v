module rgb128 (clk,databus1,addressbus2,we,ce,lsb,msb,oe,led,reset);
input clk,reset;
inout [15:0]databus1;
output [17:0] addressbus2;
output ce,we,lsb,msb,oe,led;
// regiter decleration 
reg cnt_rw,cnt_wr,cnt_oe,led;
reg [1:0] cnt_id;
reg [7:0] byte_counter;
reg [7:0] state,sfc_counter;
//reg [7:0] ram [256:1]; 
reg [15:0]  coloum_data1,row_data1,row_counter,row_data,pixelcounter,accumlator,
			hid_data,totalbyte,hid_data1,jumpaddress,nextaddress;
reg [17:0] addcount,addcount1,addcount2,addcount3,rowstack,pixelcounter1,rowinc,stack1;
reg [31:0]coloum_data;
//integer coloum_counter;
//memory decleration
reg [15:0] acc [6:1];
reg [15:0] secreat [2:1];
reg [15:0] green [2:1];
reg [15:0] red [2:1];
// parameter  decleration
parameter imageaddress=1;  
parameter pixelbase=18'h1a;
parameter dataaddress=18'hc500;//for 252*252 image (data starting address )95283; //for 128 * 128 image 0 - 601c;
parameter dataaddress1=18'he500;
parameter dataaddress2=18'h10500;//till 12500

//state machine state address
parameter filesize=0,file_size=1,coloumsize=2,coloum_size=3,rowsize=4,
row_size=5,padcheck=6,secreat_data=7,secreat_data1=8,pixel_start=9,pixel_bg=10,
process=11,hide_process=12,write=13,write_1=14,	secondrow=15,next_pixelround=16,pad_test=17,steg_end=18,write_green=19,write_green1=20,write_red=21,write_red1=22;
initial
begin
	addcount=0;
	addcount1=0;	
	addcount2=0;
	addcount3=0;
	cnt_rw=0;
	cnt_oe=1;
	cnt_wr=1;
	cnt_id=1;
	led=1'b0;
	pixelcounter=0;
	pixelcounter1=0;
	row_counter=0;	
	sfc_counter=0;
	rowstack=0;
	end
always @(posedge clk or posedge reset)
     begin
           if (reset)
               state =  filesize;
          else          
               begin
					 case (state)
					 filesize:begin
								cnt_rw=1'b0;//control bit for databus1 if cnt_r/w=0 databus1 act as inport					
								cnt_oe=1'b0;//output enable control signal zer0 to one transition  
								cnt_wr=1'b1;//write enable control signal make as active high for read operation 
								cnt_id=1'b1;//1 image address or 0 data address
								state=file_size;			        
								end					        					    						
					 file_size:begin
								cnt_oe=1'b1;
								totalbyte=databus1;
								addcount=addcount+8;
								state=coloumsize; 
								end	   
						       
					 coloumsize:begin		 						
								cnt_oe=1'b0;						  					      
								state=coloum_size;	  						  
								end			              						    						
					 coloum_size:begin				
								cnt_oe=1'b1;
								coloum_data1=databus1;
								coloum_data=databus1;
								coloum_data=coloum_data*3;
						        jumpaddress=coloum_data/2;      																																				
								addcount=addcount+2;
								state=rowsize;								
								end		   	                                 
					 rowsize:	begin						  					     						     
								cnt_oe=1'b0;
								state=row_size;							  						  
								end
				
				     row_size:	begin
						        cnt_oe=1'b1;
								row_data=databus1;       						
								addcount=addcount+16; //after 16 address location rgb will strart
								state=pixel_start; //padcheck;
								end              
							
					pixel_start:begin
								cnt_wr=1'b1;								
								cnt_rw=1'b0;  //if read rw=0;				 						
								cnt_oe=1'b0;
								cnt_id=1;//1'b1;  //if image id=1  																 					  					      
								state=pixel_bg;					          						  
								end 
					pixel_bg:	begin
								cnt_oe=1'b1;								
								byte_counter 		= byte_counter+1;				
								acc[byte_counter] 	= databus1;								
								
								if(byte_counter>=6)//if(byte_counter>=6)
								begin
								sfc_counter = sfc_counter+1;
								byte_counter=0;
								state=process;								
								end	
								else
								begin						 
									addcount=addcount+1;	
									state=pixel_start;					 							
								end
								end
										  
process:begin
										secreat[1][7:0]=acc[1][7:0];	
										secreat[1][15:8]=acc[2][15:8];	
										secreat[2][7:0]=acc[4][7:0];		
										secreat[2][15:8]=acc[5][15:8];   //b plain	 
										
										green[1][7:0]=acc[1][15:8];//g 
										green[1][15:8]=acc[3][7:0];//g	//g data
										green[2][7:0]=acc[4][15:8];//g
										green[2][15:8]=acc[6][7:0];//g 	//g data
										
										red[1][7:0]=acc[2][7:0];  //r
										red[1][15:8]=acc[3][15:8];//r 
										red[2][7:0]=acc[5][7:0];//r	
										red[2][15:8]=acc[6][15:8];//r								
										
										stack1=addcount;       
										cnt_rw=1'b1;  //here  write rw=0;
										cnt_id=2;//1'b0;  //here  data id=0  																 					  					      
										state = write;  //change all control to data memory                     
                              end
                              
                 										
write:		
								begin		
									byte_counter = byte_counter+1;												
									if(byte_counter<=2)
										begin	
										accumlator=secreat[byte_counter]; //load first data
										cnt_wr =1'b0;
										state = write_1;				              				
										end	
									else
										begin							
										byte_counter=0;	
										cnt_id=3;									
										//cnt_wr=1'b1;	
										//pixelcounter=pixelcounter+4;									
										state=write_green;			
										end
										end
									    
write_1:	begin	
								cnt_wr=1'b1;
								addcount1=addcount1+1;				            
								state=write;							
								end
				
																  
write_green:		
								begin		
									byte_counter = byte_counter+1;												
									if(byte_counter<=2)
										begin	
										accumlator=green[byte_counter]; //load first data
										cnt_wr =1'b0;
										state = write_green1;				              				
										end	
									else
										begin							
										byte_counter=0;	
										cnt_id=0;									
										//cnt_wr=1'b1;	
										//pixelcounter=pixelcounter+4;									
										state=write_red;			
										end
										end
									    
write_green1:	begin	
								cnt_wr=1'b1;
								addcount2=addcount2+1;				            
								state=write_green;							
								end
							
										
write_red:		
								begin		
									byte_counter = byte_counter+1;												
									if(byte_counter<=2)
										begin	
										accumlator=red[byte_counter]; //load first data
										cnt_wr =1'b0;
										state = write_red1;				              				
										end	
									else
										begin							
										byte_counter=0;										
										cnt_wr=1'b1;	
										pixelcounter=pixelcounter+4;									
										state=next_pixelround;			
										end
										end
									    
write_red1:	begin	
								cnt_wr=1'b1;
								addcount3=addcount3+1;				            
								state=write_red;							
								end				
										
										
										
										
next_pixelround:begin			    
									if(pixelcounter==16384)
											state=steg_end;	
									else
										begin
										addcount=stack1;										
										addcount=addcount+1;  // load previous value
										//addcount2=addcount2+1;
										//addcount3=addcount3+1;
										state=pixel_start;										
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
assign addressbus2 = (cnt_id==1)? imageaddress+addcount:(cnt_id ==2)?dataaddress+addcount1:(cnt_id ==3)?dataaddress1+addcount2:dataaddress2+addcount3;	         
assign lsb =1'b0;
assign msb  =1'b0;
assign ce = 1'b0; 
assign oe = cnt_oe ? 1'b1:1'b0;
assign we = cnt_wr ? 1'b1 : 1'b0;
endmodule
