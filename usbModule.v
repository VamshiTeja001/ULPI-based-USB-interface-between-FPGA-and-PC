`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2024 01:42:08 PM
// Design Name: 
// Module Name: usbModule
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module usbModule (
    output STP,
    output USB_RST,
    inout [7:0] DATA_OUT_PORT,
    input CLK_USB,
    input DIR,
    input NXT,
    input SYS_RST,
    input SYSTEM_READY
);

  // Write Registers
  localparam FunctionControlWrite = {2'b10, 6'h04, 8'b01000001};
  localparam InterfaceControlWrite = {2'b10, 6'h07, 8'b00000000};
  localparam OTGControlWrite = {2'b10, 6'h0A, 8'b00000110};
  localparam USBInterruptEnableRising = {2'b10, 6'h0D, 8'b00011111};
  localparam USBInterruptEnableFalling = {2'b10, 6'h10, 8'b00011111};
  localparam USBInterruptStatusRegister = {2'b10, 6'h13, 8'b00000000};

  // ULPI IDLE  
  localparam IDLE_DATA = {2'b00, 6'h00};
  //Read Registers
  localparam USBInterruptStatus_RD = {
    2'b11, 6'h14, 8'b00000000
  };  // Used only for Reading Interrupt status
  localparam DebugRegister = {2'b11, 6'h15, 8'b00000000};  // debugging using Linestate status


  //States

  localparam  BOOT_UP=                           10, 
              IDLE =                             11, 
              SET_FUNCTION_CONTROL=              12,  
              SET_INTERFACE_CONTROL =            13, 
              SET_OTG_CONTROL =                  14,
              SET_USB_INTERRUPT_EN_R =           15, 
              SET_USB_INTERRUPT_F=               16, 
              SET_USB_INTERRUPT_STATUS_REGISTER= 17,
              CONFIGURATION_COMPLETE=            18,
              TRANSMIT_DATA=                     19;

  localparam SEND_DATA = 31;
  localparam RX_MODE =1, TX_MODE =0; 

  reg TXD_CMD_USB_TX={01000011};
  //DATA FRAME Section
  reg [31:0]Data_trx;
  
  // Port registers
  reg [7:0] TX_DATA = 8'd0;
  reg [15:0] RX_DATA = 16'd0;
  reg STP_R = 1'b0;
  //reg DIR_R =1'b0;
  //reg NXT_R = 1'b0;
  reg USB_RST_R = 1'b0;
  // Logic Registers
  reg [7:0] SYS_STATE = 8'd10;

  reg INITIATE_BOOT = 1'b1;
  reg [15:0] BOOTUP_COUNTER = 16'd0;
  reg BOOT_UP_DONE = 1'b0;
  reg [15:0] data_counter = 4'b0; 
  reg [1:0] NXT_VALID = 2'd0;
  reg  READY_GO=1'b0;
  reg TRX_STATE =TX_MODE; 
  reg DATA_VALID;
  
  reg [7:0]DATA_OUT;
    assign DATA_OUT_PORT= DATA_OUT;
    //assign DATA_OUT = TX_DATA;
    assign STP = STP_R;
    assign USB_RST = USB_RST_R;
    
  
  always @(posedge CLK_USB) begin
    if (INITIATE_BOOT && BOOTUP_COUNTER <= 16'd25) begin
      BOOTUP_COUNTER <= BOOTUP_COUNTER + 1;
      BOOT_UP_DONE   <= 1'b0;
    end else begin
      BOOT_UP_DONE   <= 1'b1;
      BOOTUP_COUNTER <= 16'd0;
    end



  end
  
  always@(posedge CLK_USB)
  begin
  if(SYSTEM_READY)READY_GO= 1'b1;
   
   else if(SYS_RST)READY_GO=1'b0;
  end

   
   always@(posedge CLK_USB)
   begin
   
       if(DIR) TRX_STATE <= RX_MODE;
       else    TRX_STATE <= TX_MODE;
   
   end
   
   
  //State Machine for Confguration of registers
  always @(negedge CLK_USB or posedge SYS_RST) begin
  
  
    if (SYS_RST) begin
      SYS_STATE = BOOT_UP;
      TX_DATA   = 8'b0;
      USB_RST_R = 1'b1;
     
    end 
    else begin

      case (SYS_STATE)

        BOOT_UP: begin
            INITIATE_BOOT <= 1'b1;
          if (BOOT_UP_DONE) begin
            INITIATE_BOOT <= 1'b0;
            SYS_STATE <= SET_FUNCTION_CONTROL;
            USB_RST_R <= 1'b0;
            //data_counter <= 16'd0;
          end
        end

        SET_FUNCTION_CONTROL: begin
         
          if (DIR == 0) begin
            case (data_counter)
            
              16'd0: begin
                TX_DATA <= FunctionControlWrite[15:8];
              end

              16'd1: begin
                TX_DATA <= FunctionControlWrite[15:8];
              end

              16'd2: begin
                TX_DATA <= FunctionControlWrite[15:8];
                if (NXT) NXT_VALID = 2'b01;
              end

              16'd3: begin
                if (NXT) begin
                  NXT_VALID <= 2'b10;
                  TX_DATA   <= FunctionControlWrite[7:0];
                end
              end
              16'd4: begin
                STP_R   <= 1'b1;
                TX_DATA <= IDLE_DATA;
              end

              16'd5: begin
                STP_R   <= 1'b0;
                TX_DATA <= IDLE_DATA;
              end
              
               16'd6: begin
                STP_R   <= 1'b0;
                TX_DATA <= IDLE_DATA;
              end
              
              16'd7: begin
                TX_DATA <= IDLE_DATA;
                SYS_STATE <= SET_INTERFACE_CONTROL ;  // State Transition
                data_counter <= 16'd0;
                
              end 
             default: begin data_counter<= 16'b0;end
            endcase
            end  end
            
            
          SET_INTERFACE_CONTROL: begin
          
                  if (DIR == 0) begin
                    case (data_counter)
                      16'd0: begin
                        TX_DATA <= InterfaceControlWrite[15:8];
                      end
        
                      16'd1: begin
                        TX_DATA <= InterfaceControlWrite[15:8];
                      end
        
                      16'd2: begin
                        TX_DATA <= InterfaceControlWrite[15:8];
                        if (NXT) NXT_VALID = 2'b01;
                      end
        
                      16'd3: begin
                        if (NXT) begin
                          NXT_VALID <= 2'b10;
                          TX_DATA   <= InterfaceControlWrite[7:0];
                        end
                      end
                      16'd4: begin
                        STP_R   <= 1'b1;
                        TX_DATA <= IDLE_DATA;
                      end
        
                      16'd5: begin
                        STP_R   <= 1'b0;
                        TX_DATA <= IDLE_DATA;
                      end
                      
                      16'd7: begin
                        TX_DATA <= IDLE_DATA;
                        SYS_STATE <= SET_OTG_CONTROL ;  // State Transition
                        data_counter <= 16'd0;
                      end 
                      default: begin data_counter<= 16'b0;end
                    endcase
             end end
            
            
              
          SET_OTG_CONTROL: begin
          
                  if (DIR == 0) begin
                    case (data_counter)
                      16'd0: begin
                        TX_DATA <= OTGControlWrite[15:8];
                      end
        
                      16'd1: begin
                        TX_DATA <= OTGControlWrite[15:8];
                      end
        
                      16'd2: begin
                        TX_DATA <= OTGControlWrite[15:8];
                        if (NXT) NXT_VALID = 2'b01;
                      end
        
                      16'd3: begin
                        if (NXT) begin
                          NXT_VALID <= 2'b10;
                          TX_DATA   <= OTGControlWrite[7:0];
                        end
                      end
                      16'd4: begin
                        STP_R   <= 1'b1;
                        TX_DATA <= IDLE_DATA;
                      end
        
                      16'd5: begin
                        STP_R   <= 1'b0;
                        TX_DATA <= IDLE_DATA;
                      end
                      
                      16'd7: begin
                        TX_DATA <= IDLE_DATA;
                        SYS_STATE <= SET_USB_INTERRUPT_EN_R ;  // State Transition
                        data_counter <= 16'd0;
                      end 
                      default: begin data_counter<= 16'b0;end
                    endcase
             end end
            
            
              
          SET_USB_INTERRUPT_EN_R: begin
                  
                  if (DIR == 0) begin
                    case (data_counter)
                      16'd0: begin
                        TX_DATA <= USBInterruptEnableRising[15:8];
                      end
        
                      16'd1: begin
                        TX_DATA <= USBInterruptEnableRising[15:8]; 
                        if (NXT) NXT_VALID = 2'b01;
                      end
        
                      16'd3: begin
                        if (NXT) begin
                          NXT_VALID <= 2'b10;
                          TX_DATA   <= USBInterruptEnableRising[7:0];
                        end
                      end
                      16'd4: begin
                        STP_R   <= 1'b1;
                        TX_DATA <= IDLE_DATA;
                      end
        
                      16'd5: begin
                        STP_R   <= 1'b0;
                        TX_DATA <= IDLE_DATA;
                      end
                      
                      16'd7: begin
                        TX_DATA <= IDLE_DATA;
                        SYS_STATE <= SET_USB_INTERRUPT_F ;  // State Transition
                        data_counter <= 16'd0;
                      end 
                      default: begin data_counter<= 16'b0;end
                    endcase
             end end
            
            SET_USB_INTERRUPT_F: begin
          
                  if (DIR == 0) begin
                    case (data_counter)
                      16'd0: begin
                        TX_DATA <= USBInterruptEnableFalling[15:8];
                      end
        
                      16'd1: begin
                        TX_DATA <= USBInterruptEnableFalling[15:8];
                        if (NXT) NXT_VALID = 2'b01;
                      end
        
                      16'd3: begin
                        if (NXT) begin
                          NXT_VALID <= 2'b10;
                          TX_DATA   <= USBInterruptEnableFalling[7:0];
                        end
                      end
                      16'd4: begin
                        STP_R   <= 1'b1;
                        TX_DATA <= IDLE_DATA;
                      end
        
                      16'd5: begin
                        STP_R   <= 1'b0;
                        TX_DATA <= IDLE_DATA;
                      end
                      
                      16'd7: begin
                        TX_DATA <= IDLE_DATA;
                        SYS_STATE <= SET_USB_INTERRUPT_STATUS_REGISTER ;  // State Transition
                        data_counter <= 16'd0;
                      end 
                      default: begin data_counter<= 16'b0;end
                    endcase
             end end
            
            
             SET_USB_INTERRUPT_STATUS_REGISTER: begin
          
                  if (DIR == 0) begin
                    case (data_counter)
                      16'd0: begin
                        TX_DATA <= USBInterruptStatusRegister[15:8];
                      end
        
                      16'd1: begin
                        TX_DATA <= USBInterruptStatusRegister[15:8];
                        if (NXT) NXT_VALID = 2'b01;
                      end
        
                      16'd3: begin
                        if (NXT) begin
                          NXT_VALID <= 2'b10;
                          TX_DATA   <= USBInterruptStatusRegister[7:0];
                        end
                      end
                      16'd4: begin
                        STP_R   <= 1'b1;
                        TX_DATA <= IDLE_DATA;
                      end
        
                      16'd5: begin
                        STP_R   <= 1'b0;
                        TX_DATA <= IDLE_DATA;
                      end
                      
                      16'd7: begin
                        TX_DATA <= IDLE_DATA;
                        SYS_STATE <= CONFIGURATION_COMPLETE ;  // State Transition
                        data_counter <= 16'd0;
                      end 
                      default: begin data_counter<= 16'b0;end
                    endcase
             end end
            
          CONFIGURATION_COMPLETE: begin
          data_counter <= 16'd0;
          TX_DATA <= IDLE_DATA;
          SYS_STATE <= TRANSMIT_DATA;
          end
 
//        SET_INTERFACE_CONTROL:begin

//        end
          TRANSMIT_DATA: begin
          
         if(READY_GO) begin
            
            case(TRX_STATE)
                RX_MODE: begin
                case (data_counter)
                
                16'd1: begin
                
                    STP_R= 1'b0;
                    RX_DATA[7:0] = DATA_OUT;
                    DATA_VALID = 1'b0;
                end
                
                16'd4:begin
                
                if(NXT) begin
                    RX_DATA[7:0] = DATA_OUT;
                end
                
                end
                
                16'd6:begin
                
                if(NXT) begin
                    RX_DATA[15:8] = DATA_OUT;
                    DATA_VALID=1'b1;
                    
                    
                end
                
                
                end
                
                16'd7: begin
                if(NXT)SYS_STATE<= IDLE;
                end
                
                
                endcase
                end
                
             TX_MODE: begin   
                 
                 if(!DIR)begin 
                 case(data_counter)
                 
                 16'd1:  begin
                 DATA_OUT<= TXD_CMD_USB_TX;
                data_counter<=data_counter+1;
                 end
             
             
                16'd2: begin
                data_counter=data_counter+1;
                end
                
                16'd3: begin
                data_counter=data_counter+1;
                end
                
                16'd4: begin
                if(NXT) DATA_OUT<= Data_trx[7:0]; 
                data_counter<=data_counter+1;
                end
                
                16'd5: begin
                if(NXT) DATA_OUT<= Data_trx[15:8]; 
                data_counter<=data_counter+1;
                end
                
                16'd6: begin
                //if(NXT)
                 DATA_OUT<= Data_trx[23:16]; 
                data_counter<=data_counter+1;
                end
            
               16'd7: begin
                //if(NXT) DATA_OUT<= Data_trx[23:16]; 
                data_counter<=data_counter+1;
                end
                
                16'd8: begin
                if(NXT) DATA_OUT<= Data_trx[31:24]; 
                data_counter<=data_counter+1;
                end
                
                16'd9: begin
                 if(NXT) SYS_STATE<=IDLE; 
                data_counter<=0;
                end
                
            endcase
            end
    
         end

          
 


      endcase
      //data_counter=data_counter+1;
    end
end
endcase

 end 
end

  //State Machine to Communicate data


endmodule
