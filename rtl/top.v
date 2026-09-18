
module top (
    input clk_i,
    input rst_i,

    output wire i2c_scl,
    output wire i2c_sda, // şimdilik sadece output

    output wire [31:0] gpio_out,
);



//reg clk_i;
// reg rst_i;    // TODO: bunu negatif yapsana. isimlendirme olarak




// control unit wires
wire        cu_clk_o;
wire        cu_rst_o;
wire [31:0] cu_instr_o;
wire        cu_is_imm;
wire        cu_rf_write_enable;
wire [1:0]  cu_rf_input_select;
wire [1:0]  cu_ls_ctrl_o;
wire        cu_mem_req;
wire [31:0] cu_pc_o;
wire        cu_alu_control_override;
wire [2:0]  cu_override_funct;
wire        cu_branch_mode_flag;
wire [31:0] cu_u_type_value;


// bunların sırası karışık oldu da belki düzeltirim sonra
control_unit cu (
	.clk_i      			(clk_i),
	.rst_i      			(rst_i),

	.clk_o      			(cu_clk_o),
	.rst_o      			(cu_rst_o),

	.funct3_i     			(dec_funct3),
	.instr_type_i 			(dec_instr_type),
	.instr_i    			(ls_value),
	.instr_o    			(cu_instr_o),

	.rs1_i 					(rf_rs1_o),

	.is_imm_o         		(cu_is_imm),
	.rf_write_enable_o		(cu_rf_write_enable),
	.rf_input_select_o		(cu_rf_input_select),
	.ls_ctrl_o      		(cu_ls_ctrl_o),

	.mem_valid_i  			(ls_mem_valid),
	.mem_req_o    			(cu_mem_req),

    .imm_i        			(dec_immediate),
    .alu_result_i 			(alu_result),

    .alu_control_override_o (cu_alu_control_override),
    .override_funct_o       (cu_override_funct),
    .branch_mode_flag_o     (cu_branch_mode_flag),
    .u_type_value_o(cu_u_type_value),




	.pc_o       			(cu_pc_o)
);


// -------------------------------------------------
//   __ _| |_   _
//  / _` | | | | |
// | (_| | | |_| |
//  \__,_|_|\__,_|
// -------------------------------------------------


wire [31:0] alu_rs2;
assign alu_rs2 = cu_is_imm ? dec_immediate : rf_rs2_o;


wire [31:0] alu_result;

alu alu_i ( // isim bulamadım
	// input
    .rs1_i(rf_rs1_o),
    .rs2_i(alu_rs2),
    .funct3_i(dec_funct3),
    .funct7_i(dec_funct7),
    .alu_control_override(cu_alu_control_override),
    .override_funct(cu_override_funct),
    .branch_mode_flag(cu_branch_mode_flag),

    // output
    .alu_result_o(alu_result)
);

// -------------------------------------------------------
//                 _     _             __ _ _
//  _ __ ___  __ _(_)___| |_ ___ _ __ / _(_| | ___
//  | '__/ _ \/ _` | / __| __/ _ | '__| |_| | |/ _ \
//  | | |  __| (_| | \__ | ||  __| |  |  _| | |  __/
//  |_|  \___|\__, |_|___/\__\___|_|  |_| |_|_|\___|
//            |___/
// -------------------------------------------------------




reg [31:0] rf_rd_input;
// en son koşulların doğruluğuna bak
always @(*) begin
	rf_rd_input = alu_result;
	case (cu_rf_input_select)
		2'b00: rf_rd_input = alu_result;
		2'b01: rf_rd_input = ls_value;
		2'b10: rf_rd_input = cu_pc_o; 	// clocklu olduğundan herhalde değer değişmesi sorun yaratmaz
		2'b11: rf_rd_input = cu_u_type_value;
	endcase
end

wire [31:0] rf_rs1_o;
wire [31:0] rf_rs2_o;

register_file reg_file(
	// input
	.clk(clk_i),
	.rst_n(rst_i), // en son reset negatif zart zurt kontrol et
    .rs1_select_i(dec_rs1_select),
    .rs2_select_i(dec_rs2_select),
    .rd_select_i(dec_rd_select),
    .write_enable_i(cu_rf_write_enable),
    .rd_i(rf_rd_input),

    // output
    .rs1_o(rf_rs1_o),
    .rs2_o(rf_rs2_o)
);





// -------------------------------------------------------------------------------
//       ____  _____ ____ ___  ____  _____ ____  _   _ _   _ ___ _____
//      |  _ \| ____/ ___/ _ \|  _ \| ____|  _ \| | | | \ | |_ _|_   _|
//      | | | |  _|| |  | | | | | | |  _| | |_) | | | |  \| || |  | |
//      | |_| | |__| |__| |_| | |_| | |___|  _ <| |_| | |\  || |  | |
//      |____/|_____\____\___/|____/|_____|_| \_ \___/|_| \_|___| |_|
// -------------------------------------------------------------------------------


// decode wires
wire [4:0] 	dec_opcode; // THIS IS STRIPPED TO 5 bits
wire [4:0]	dec_rs1_select; //just connected these to rs1_select
wire [4:0]	dec_rs2_select;
wire [4:0]	dec_rd_select;
wire [2:0]	dec_funct3;
wire [6:0]	dec_funct7;
wire [31:0]	dec_immediate;
wire [3:0]  dec_instr_type;




// zaten hepsinde var
instr_decode decoder (
	// input
    .instr_i(cu_instr_o),

    // output
    .opcode_o(dec_opcode),
    .rs1_o(dec_rs1_select),
    .rs2_o(dec_rs2_select),
    .rd_o(dec_rd_select),
    .funct3_o(dec_funct3),
    .funct7_o(dec_funct7),
    .imm_o(dec_immediate),
    .instr_type_o(dec_instr_type)
);



wire ls_mem_valid;
wire [31:0] ls_value;

loadstore_unit ls (
	// input
    .clk(clk_i),
    .pc_i(cu_pc_o),
    .ls_ctrl_i(cu_ls_ctrl_o),
    .funct3(dec_funct3),

    .rs1_i(rf_rs1_o),
    .rs2_i(rf_rs2_o),
    .immediate_i(dec_immediate),


    // output
    .mem_valid(ls_mem_valid),


    // i2c geçici
    .i2c_scl(i2c_scl),
    .i2c_sda(i2c_sda),
    .gpio_out(gpio_out),


    .value_o(ls_value)


);




endmodule
