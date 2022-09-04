`timescale 1ns/1ns
//AD7888 SPI DRIVE

    module ADC_drive(
    input  i_sclk,               //ADC clock 10KHz
    input  i_rst_n,

    input  i_spi_din,           //ADC DOUT
    output o_spi_cs,            //ADC CS
    output o_spi_dout,          //ADC DIN
    output o_sclk,              //ADC sclk

    input  i_wr_en,             //write enable pluse
    output o_wr_done,           //write done

    input  i_rd_en,             //read enable pluse
    output o_rd_done,           //read done
    output [15:0] o_rd_data     //ADC readout data
    );

assign o_sclk = i_sclk;
/////////////////   AD7888 ADC drive     ///////////////////
    reg r_cs_n;
    reg r_wr_en;
    reg [4:0] r_cnt;
    reg [16:0] r_channel;
    reg [15:0] r_data_buffer;
    reg [15:0] r_data;
    reg r_rd_en_d1;
    reg r_rd_en_d2;
    //each conversation is 16 clock, so count 0 - 15
    //due to the delay, in simulation, counter 1-16 is the valid conversation
    always @(posedge i_sclk or negedge i_rst_n)begin
        if(!i_rst_n)
            r_wr_en <= 1'b0;
        else if(i_wr_en)
            r_wr_en <= 1'b1;
        else if(r_cnt == 5'd15)
            r_wr_en <= 1'b0;
        else
            r_wr_en <= r_wr_en;
    end

    //the 0 clock cycle's CS
    always @(negedge i_sclk or negedge i_rst_n)begin
        if(!i_rst_n)
            r_cs_n <= 1'b1;
        else if(r_wr_en && (r_cnt == 5'd0))
            r_cs_n <= 1'b0;
        else if(!r_wr_en && (r_cnt == 5'd16))
            r_cs_n <= 1'b1;
        else
            r_cs_n <= r_cs_n;
    end
    assign o_spi_cs = r_cs_n;

    //cnt count to 16, which means the conversion is done, done signal goes high
    always @(posedge i_sclk or negedge i_rst_n)begin
        if(!i_rst_n)
            r_cnt <= 5'd0;
        else if(r_wr_en)
            r_cnt <= r_cnt + 1'b1;
        else if(r_cnt == 5'd16)
            r_cnt <= 5'd0;
    end
    assign o_wr_done = (r_cnt == 5'd16) ? 1'b1 : 1'b0;

    //DIN channel for ADC, output data in the falling edge
    reg [4:0]r_cnt_n;
    always @(negedge i_sclk or negedge i_rst_n)begin
        if(!i_rst_n)
            r_cnt_n <= 5'd0;
        else if(r_wr_en)
            r_cnt_n <= r_cnt_n + 1'b1;
        else if(r_cnt_n == 5'd16)
            r_cnt_n <= 5'd0;
    end

    always @(posedge i_sclk or negedge i_rst_n)begin
        if(!i_rst_n)
            r_channel <= 17'd0;
        else
            r_channel <= {8'b00000100,9'b0}; //when r_cnt=0, no data transimssion.
    end
    assign o_spi_dout = (r_cnt_n >= 1) ? r_channel[17-r_cnt_n] : 1'b0;

    //DOUT channel for ADC, receive data on the rising edge 
    always @(posedge i_sclk or negedge i_rst_n)begin
        if(!i_rst_n)
            r_data_buffer <= 16'd0;
        else if(r_wr_en)
            r_data_buffer <= {r_data_buffer[14:0],i_spi_din};
        else
            r_data_buffer <= r_data_buffer;
    end

    always @(posedge i_sclk or negedge i_rst_n)begin    //in the 16bit, the low 12bit is valid data
        if(!i_rst_n)
            r_data <= 16'd0;
        else if(i_rd_en)
            r_data <= r_data_buffer;
        else
            r_data <= r_data;
    end
    assign o_rd_data = r_data;

    //read done signal is delayed by 1 clock compared to the read enable signal.
    always @(posedge i_sclk or negedge i_rst_n)begin
        if(!i_rst_n)begin
            r_rd_en_d1 <= 1'b0;
            r_rd_en_d2 <= 1'b0;
        end
        else begin
            r_rd_en_d1 <= i_rd_en;
            r_rd_en_d2 <= r_rd_en_d1;
        end
    end
    assign o_rd_done = r_rd_en_d2;

    endmodule