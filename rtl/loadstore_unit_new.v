
// ls unit rewrite
module loadstore_unit_new(
    input clk,
    input [31:0] pc_i,
    input [1:0] ls_ctrl_i,
    input [2:0] funct3,

    input [31:0] rs1_i,
    input [31:0] rs2_i,
    input [31:0] immediate_i,
    input mem_we_i,

    input mem_req,
    output reg mem_valid,



    output reg i2c_scl,
    output reg i2c_sda,

    output reg [31:0] gpio_out,



    output reg [31:0] value_o // başka isim gelmedi aklıma. son değeri atıyor dışarı

);




// ls_ctrl_i
// 00 fetch
// 01 load
// 10 store
// 11 boş geçsin bari


// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------


    // BYTE ENABLE BOZUK HER YERE VERİ YAZIYO

// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------


reg [31:0] addr;
// address control
// bu şekilde clocklu yapıyorum sonra aluya yaptırma ihtimaline karşı
always @(posedge clk)begin
    case (ls_ctrl_i)
    2'd0: begin
        //addr <= pc_i; artık aşağıda
    end
    2'd1: begin
    	// ayrı bir address generator yerine aluya almayı düşünüyorum.
     	// eğer üşenmezsem
        addr <= rs1_i + immediate_i; //addr_i;
    end
    2'd2: begin
        addr <= rs1_i + immediate_i;
    end
    2'd3: begin
    	addr <= 32'hDEADBEEF;
    end
    endcase
end




always@(*) begin
	mem_valid = mem_valid_o;

	case (ls_ctrl_i)
	2'd0: begin
		if (mem_valid_o) begin
			value_o = rdata_o; // bağlı gibi olsun da.
		end

	end
	2'd1:begin

		/*
        // video ram okumaca
        if (addr >= 50000000) begin
            value_o = video_rdata_o;

        end else
        */

        if (mem_valid_o) begin

        //rv32i byte adressed olduğundan
        case (funct3)
        	// lb
        	3'b000: case(addr[1:0])
         		2'b00: value_o = {{24{rdata_o[7]}},  rdata_o[7:0]};
         		2'b01: value_o = {{24{rdata_o[15]}},  rdata_o[15:8]};
         		2'b10: value_o = {{24{rdata_o[23]}},  rdata_o[23:16]};
         		2'b11: value_o = {{24{rdata_o[31]}},  rdata_o[31:24]};
           	endcase

            //lbu
           	// bunlar birleşirdi de böyle daha güzel
           	3'b100: case(addr[1:0])
          		2'b00: value_o = {{24'b0},  rdata_o[7:0]};
          		2'b01: value_o = {{24'b0},  rdata_o[15:8]};
          		2'b10: value_o = {{24'b0},  rdata_o[23:16]};
          		2'b11: value_o = {{24'b0},  rdata_o[31:24]};
         	endcase

          //lh
         	3'b001: case(addr[1])
          		1'b0: value_o = {{16{rdata_o[15]}},  rdata_o[15:0]};
          		1'b1: value_o = {{16{rdata_o[31]}},  rdata_o[31:16]};
            	endcase

            //lhu
           	3'b101: case(addr[1])
          		1'b0: value_o = {{16'b0},  rdata_o[15:0]};
          		1'b1: value_o = {{16'b0},  rdata_o[31:16]};
          	endcase

           // lw
           	3'b010: begin
            	value_o = rdata_o;                              // lw
            end

            default $finish;

        endcase

        end

	end
	default: begin end
	endcase

end




always @(posedge clk) begin
    byte_enable <= 4'b0000; // bilim için

    case (ls_ctrl_i)
    2'd0: begin
    	/*
    	if (mem_req) begin
     		value_o <= rdata_o;
       		mem_valid <= 1;
     	end
      	*/
    end
    2'd1: begin
        // buradaki hesaplamanın aşağıda gecikmesi var mıdır d:
        //


        /*
        // riscv-testsde sorun çıkardı
        case (funct3)
            3'b000: value_o = {{24{rdata_o[7]}},  rdata_o[7:0]};    // lb
            3'b001: value_o = {{16{rdata_o[15]}},  rdata_o[15:0]};  // lh
            3'b010: value_o = rdata_o;                              // lw
            3'b100: value_o = {24'b0, rdata_o[7:0]};                // lbu
            3'b101: value_o = {16'b0, rdata_o[15:0]};               // lhu
            default $finish;
        endcase
        */


    end
    2'd2: begin


        // store için de kaydırmaçlı desteği
        //

        if (mem_we_i) begin
        	//$display("write op | addr: %x,  byte_enable: %b, wdata: %x", addr, byte_enable, wdata);


        // geçici i2c için
        if (addr == 32'h4000000) begin
        	i2c_scl <= rs2_i[0];
        	byte_enable <= 4'b0000;
        end else if (addr == 32'h4000004)begin
       		i2c_sda <= rs2_i[0];
         	byte_enable <= 4'b0000;

        end else if (addr == 32'h4000008)begin
       		byte_enable <= 4'b0000;
         	gpio_out <= rs2_i;


        end else begin

	        case (funct3)
	            3'b000: begin
	            	byte_enable <= 4'b0001;
	             	case (addr[1:0])
	              		2'b00: begin wdata <= rs2_i; 					byte_enable <= 4'b0001; end
	                	2'b01: begin wdata <= {16'b0, rs2_i[7:0], 8'b0}; byte_enable <= 4'b0010; end
	                	2'b10: begin wdata <= {8'b0, rs2_i[7:0], 16'b0}; byte_enable <= 4'b0100; end
	                	2'b11: begin wdata <= {rs2_i[7:0], 24'b0}; 		byte_enable <= 4'b1000; end
	              	endcase
	            end
	            3'b001: begin
	            	byte_enable <= 4'b0011;
	            	case (addr[1])
	             		1'b0: begin wdata <= rs2_i; 				byte_enable <= 4'b0011; end
	               		1'b1: begin wdata <= {rs2_i[15:0], 16'b0};	byte_enable <= 4'b1100; end
	             	endcase
	            end
	            3'b010: begin wdata <= rs2_i; 	byte_enable <= 4'b1111; end
	            default byte_enable <= 4'b0000;
	        endcase
			//$display("funct3: %b,   byte_e: %b", funct3, byte_enable);


    	end

        end


    end
    2'd3: begin end
    endcase
end








// fetch için
wire [31:0] mem_addr;
assign mem_addr = (ls_ctrl_i == 2'b00) ? pc_i : addr;

reg [31:0] wdata;
reg [3:0] byte_enable;


wire [31:0] rdata_o;

wire mem_valid_o;

mem memory (
    .clk(clk),
    .addr_i(mem_addr),
    .wdata_i(wdata),
    .byte_enable_i(byte_enable),
    .mem_req(mem_req),

    .mem_valid(mem_valid_o),

    .rdata_o(rdata_o)
);



/*
wire [31:0] video_rdata_o;

video_mem video_memory (
    .clk(clk),
    .addr_i(mem_addr),
    .wdata_i(wdata),
    .byte_enable_i(byte_enable),

    .rdata_o(video_rdata_o)
);
*/




endmodule
