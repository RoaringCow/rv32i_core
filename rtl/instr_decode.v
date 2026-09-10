`timescale 1ns / 1ps

module instr_decode (

	input [31:0]	instr_i,

	output reg [4:0]	opcode_o, // bazı instructionlar arasındaki farklı bu belirliyor.
	output reg [4:0]	rs1_o,
	output reg [4:0]	rs2_o,
	output reg [4:0]	rd_o,
	output reg [2:0]	funct3_o,
	output reg [6:0]	funct7_o,
	output reg [31:0]	imm_o, // not the actual immediate value but rather kind of extended and vb version
	output reg [3:0]    instr_type_o

);





always @(*) begin
    // zaten hepsinde var
    opcode_o = instr_i[6:2];
    imm_o = 32'b0;
    rd_o = 5'b0;
    rs1_o = 5'b0;
    rs2_o = 5'b0;
    funct3_o = 3'b0;
    funct7_o = 7'b0;

	case (instr_i[6:2]) // sonlar hep 11 zaten. 32 bit olduğundan (uzunluğu belirtiyor)
		5'b01100: begin	// R type

    		rd_o = instr_i[11:7];
    		rs1_o = instr_i[19:15];
    		rs2_o = instr_i[24:20];
    		funct3_o = instr_i[14:12];
    		funct7_o = instr_i[31:25];

		 // func 3 ve func 7 işini halledecem sonra

		end
		5'b00100, 5'b00000: begin	// I type aritmetik ve load

			rd_o = instr_i[11:7];
			rs1_o = instr_i[19:15];
			funct3_o = instr_i[14:12];


			imm_o[31:11] = {21{instr_i[31]}}; // bu hepsini ondan yapmalı da kontrol edersin.
			imm_o[10:5] = instr_i[30:25];
			imm_o[4:1] = instr_i[24:21];
			imm_o[0] = instr_i[20];

		end
		5'b01000: begin // S type store

			rs1_o = instr_i[19:15];
			rs2_o = instr_i[24:20];
			funct3_o = instr_i[14:12];

			imm_o[31:11] = {21{instr_i[31]}}; // bu hepsini ondan yapmalı da kontrol edersin.
			imm_o[10:5] = instr_i[30:25];
			imm_o[4:1] = instr_i[11:8];
			imm_o[0] = instr_i[7];

		end
		5'b11000: begin // B type branch

		    rs1_o = instr_i[19:15];
			rs2_o = instr_i[24:20];
			funct3_o = instr_i[14:12];

			imm_o[31:12] = {20{instr_i[31]}}; // bu hepsini ondan yapmalı da kontrol edersin.
			imm_o[11] = instr_i[7];
			imm_o[10:5] = instr_i[30:25];
			imm_o[4:1] = instr_i[11:8];
			imm_o[0] = 1'b0;    // 16 bit alignment için herhalde.


		end
		5'b01101, 5'b00101: begin // U type (lui) & (auipc)

		    rd_o = instr_i[11:7];

			imm_o[31] = instr_i[31];
			imm_o[30:12] = instr_i[30:12];
			imm_o[11:0] = 12'b0;		//bu hepsini ondan yapmalı da kontrol edersin.

		end
		5'b11011: begin // zıplaa jal

			rd_o = instr_i[11:7];
			imm_o[31:20] = {12{instr_i[31]}};
			imm_o[19:12] = instr_i[19:12];
			imm_o[11] = instr_i[20];
			imm_o[10:1] = instr_i[30:21];
			imm_o[0] = 1'b0;

		end
		5'b11001: begin // zıplaa jalr
		    // aslında tepedekiyle birleştirilebilir ama bu şekilde daha belli nerede olduğu

			rd_o = instr_i[11:7];
			rs1_o = instr_i[19:15];
			imm_o[31:11] = {21{instr_i[31]}};
			imm_o[10:5] = instr_i[30:25];
			imm_o[4:1] = instr_i[24:21];
			imm_o[0] = instr_i[20];

		end

		// -------- weird ops --------
		5'b00011: begin // Fence, Fence.TSO, PAUSE
			// diğer bitlerden fark ettiriyor

		end
		5'b11100: begin // ECall EBREAk

			// diğer bitlerden fark ettiriyor
		end

		default: begin end

	endcase


end



// -------- Tip belirleme--------
// ayrı bir yere aldım
// because verilog does not support enums
// ------ instr_type value equivalents --------
localparam [3:0] R_ALU_TYPE =   4'd0;
localparam [3:0] I_ALU_TYPE =   4'd1;
localparam [3:0] STORE_TYPE =   4'd2;
localparam [3:0] LOAD_TYPE =    4'd3;
localparam [3:0] BRANCH_TYPE =  4'd4;
localparam [3:0] JAL_TYPE =     4'd5;
localparam [3:0] JALR_TYPE =    4'd6;
localparam [3:0] LUI_TYPE =     4'd7;
localparam [3:0] AUIPC_TYPE =   4'd8;
localparam [3:0] EBREAK_TYPE =  4'd9;
localparam [3:0] ECALL_TYPE =   4'd10;
localparam [3:0] ILLEGAL_TYPE = 4'd11;

always @(*) begin
    instr_type_o = EBREAK_TYPE;

    if (instr_i[1:0] != 2'b11) instr_type_o = ILLEGAL_TYPE; // uncompressed olduğundan minik check
    else case (instr_i[6:2]) // sonlar hep 11 zaten. 32 bit olduğundan (uzunluğu belirtiyor)
        // R type
		5'b01100:           instr_type_o = R_ALU_TYPE;
		// I type aritmetik
		5'b00100:           instr_type_o = I_ALU_TYPE;
		// I type load
		5'b00000:           instr_type_o = LOAD_TYPE;
		// S type store
		5'b01000:           instr_type_o = STORE_TYPE;
		// B type branch
		5'b11000:           instr_type_o = BRANCH_TYPE;
		// U type lui
		5'b01101:           instr_type_o = LUI_TYPE;
		// U type auipc
		5'b00101:           instr_type_o = AUIPC_TYPE;
		// zıplaa jal
		5'b11011:           instr_type_o = JAL_TYPE;
		// zıplaa jalr
		5'b11001:           instr_type_o = JALR_TYPE;
		// -------- weird ops --------
		5'b00011: begin // Fence, Fence.TSO, PAUSE

			// Dunno

		end
		// ECall EBREAk
		5'b11100:   instr_type_o = instr_i[20] ? EBREAK_TYPE : ECALL_TYPE;

		default begin
		// boş şu an :O
		end

	endcase

end

endmodule
