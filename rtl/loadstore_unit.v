

module loadstore_unit(
    input clk,
    input [31:0] pc_i,
    input [1:0] ls_ctrl_i,
    input [2:0] funct3,

    input [31:0] rs1_i,
    input [31:0] rs2_i,
    input [31:0] immediate_i,

    output reg mem_valid,


    output reg i2c_scl,
    output reg i2c_sda,

    output reg [31:0] gpio_out,



    output reg [31:0] value_o // başka isim gelmedi aklıma. son değeri atıyor dışarı

);



// isimlendirme konusunda korkuncum
reg [31:0] addr; // alignment kısmını ram hallediyor
reg [31:0] wdata;

reg [3:0] byte_enable;





// ls_ctrl_i
// 00 fetch
// 01 load
// 10 store
// 11 boş geçsin bari

always @(*) begin
    mem_req = 0;
    byte_enable = 0;
    value_o = 32'd0;
    addr = 32'd0;
    wdata = 32'd0;

    case (ls_ctrl_i)
    2'd0: begin
        addr = pc_i;
        mem_req = 1;
        value_o = rdata_o;
    end
    2'd1: begin
        // ayrı bir address generator yerine aluya almayı düşünüyorum.
        // eğer üşenmezsem
        addr = rs1_i + immediate_i; //addr_i;
        // buradaki hesaplamanın aşağıda gecikmesi var mıdır d:
        mem_req = 1;


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

        addr = rs1_i + immediate_i;
        mem_req = 1;

        // store için de kaydırmaçlı desteği


        // geçici i2c için
        if (addr == 32'h4000000) begin
        	i2c_scl = rs2_i[0];
        	byte_enable = 4'b0000;
        end else if (addr == 32'h4000004)begin
       		i2c_sda = rs2_i[0];
         	byte_enable = 4'b0000;

        end else if (addr == 32'h4000008)begin
       		byte_enable = 4'b0000;
         	gpio_out = rs2_i;


        end else begin

	        case (funct3)
	            3'b000: begin
	            	byte_enable = 4'b0001;
	             	case (addr[1:0])
	              		2'b00: begin wdata = rs2_i; 					byte_enable = 4'b0001; end
	                	2'b01: begin wdata = {16'b0, rs2_i[7:0], 8'b0}; byte_enable = 4'b0010; end
	                	2'b10: begin wdata = {8'b0, rs2_i[7:0], 16'b0}; byte_enable = 4'b0100; end
	                	2'b11: begin wdata = {rs2_i[7:0], 24'b0}; 		byte_enable = 4'b1000; end
	              	endcase
	            end
	            3'b001: begin
	            	byte_enable = 4'b0011;
	            	case (addr[1])
	             		1'b0: begin wdata = rs2_i; 				  	byte_enable = 4'b0011; end
	               		1'b1: begin wdata = {rs2_i[15:0], 16'b0};	 byte_enable = 4'b1100; end
	             	endcase
	            end
	            3'b010: begin wdata = rs2_i; byte_enable = 4'b1111; end
	            default byte_enable = 4'b0000;
	        endcase


    	end


    end
    2'd3: begin end
    endcase
end



reg mem_req;

wire [31:0] rdata_o;


// böyle dursun. ram anında veriyor bu durumda
always @(posedge clk) begin
    mem_valid <= mem_req;
end

mem memory (
    .clk(clk),
    .addr_i(addr),
    .wdata_i(wdata),
    .byte_enable_i(byte_enable),

    .rdata_o(rdata_o)
);




endmodule
