

module control_unit (
    input wire 		clk_i,
    input wire 		rst_i,    // TODO: bunu negatif yapsana. isimlendirme olarak



    output reg  clk_o, // control unitten dağılsınn gibi düşündüydüm
    output reg  rst_o,


    input wire [2:0] funct3_i,


    input wire [3:0] instr_type_i,
    input wire [31:0]	instr_i, // ls_unitten
    output reg[31:0]  instr_o, // decodera

    input wire [31:0] rs1_i,

    output reg is_imm_o,
    output reg rf_write_enable_o,
    output reg [1:0] rf_input_select_o, // 0 is alu, 1 is ls, 2 is PC, 3 PC + imm olsun yer var zaten


    input mem_valid_i,
    output reg mem_req_o,



    input [31:0] imm_i,
    input [31:0] alu_result_i,
    // Alu override. branch zart zurt için
    output	reg	alu_control_override_o,
    output 	reg [2:0]	override_funct_o,
    output 	reg 	branch_mode_flag_o,

    output reg [31:0] u_type_value_o, // pc + imm veya imm (<< 12 zaten var)

    output reg [1:0]	ls_ctrl_o,
    output reg [31:0] pc_o
);





// PC ile ilgili şeyler. veya PC unit
reg [31:0] program_counter;
reg [31:0] program_counter_prev; // +4 basmadan korunmak için


reg [31:0] pc_plus_imm;

assign pc_plus_imm = program_counter_prev + imm_i;



reg [31:0] instruction_register; // büyük adam olduğu için adı uzun


//reg     [31:0]  rs1_data;
//reg     [31:0]  rs2_data;



reg [31:0] branch_target;
reg branch_taken; // allta branch için.


// keyfim öyle istediği için bu bir multicycle core AMA pipeline yok D:

localparam [2:0] IF     = 3'h0;
localparam [2:0] ID     = 3'h1;
localparam [2:0] EX     = 3'h2;
localparam [2:0] MEM    = 3'h3;
localparam [2:0] WB     = 3'h4;


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



reg     [2:0]   instr_state;
// IF, ID, EX, MEM, WB
//
// sıradaki iş bu durumlara göre alt tarafı ayarlamak

// reg megli clocklu şeyler
always @(posedge clk_i or negedge rst_i) begin

    if (!rst_i) begin
        instr_state <= IF;

        program_counter <= 0; // şimdilik böyle olsun.


    end
    else begin
        case (instr_state)
        IF: begin
        	// handshake işi bu aşamayı 2 stage falan yapıyor.
         	// olsun bu da kalsın. sram olmadığı durumu halletmek için yaptıydım zaten.
          	// bu gidişle 50 stage core olacak :D
            if (mem_valid_i) begin
                instruction_register <= instr_i;
                instr_state <= ID;
                program_counter_prev <= program_counter;
                program_counter <= program_counter + 4; // diğeri blocking imiş
            end
        end
        ID: begin
            // ya instruction decode kısmını kaldırsam mı diye düşündüm de tutmaya karar verdim.
            // benim yaptığım bu ucube versiyonda gerekmiyor olsa da bunu yapsın bari.
            // çıkarması kolay zaten
            instr_state <= EX;
        end
        EX: begin
        	instr_state <= WB;
            case (instr_type_i)
                R_ALU_TYPE: begin
                end
                I_ALU_TYPE: begin
                end
                STORE_TYPE: begin
               		instr_state <= MEM;
                end
                LOAD_TYPE: begin
                	instr_state <= MEM;
                end
                BRANCH_TYPE: begin
					if (branch_taken == 1) begin
						program_counter <= pc_plus_imm;
					end
					instr_state <= IF;

                end
                // donanıma yakın son tasarım yaparsam bunları tek adderda inputları değiştirerek yapacam.
                JAL_TYPE: begin
                	program_counter <= pc_plus_imm;
                end
                JALR_TYPE: begin
               		program_counter <= rs1_i + imm_i;

                end
                LUI_TYPE: begin

                end
                AUIPC_TYPE: begin

                end
                EBREAK_TYPE: begin

                end
                ECALL_TYPE: begin

                end
                default: begin end
            endcase
        end
        MEM: begin
        	instr_state <= WB;
        end
        WB: begin
      		instr_state <= IF;
        end

        default: begin end

        endcase
    end

end



// kombinasyonel şeyler
always @(*) begin

	ls_ctrl_o = 2'b00;
	rf_input_select_o = 2'b0; // 0 alu, 1 ls
	rf_write_enable_o = 1'b0;
	is_imm_o = 1'b0;
    mem_req_o = 1'b0;
    ls_ctrl_o = 2'b0;

    alu_control_override_o = 1'b0;
    override_funct_o = 3'b0;
    branch_mode_flag_o = 1'b0;
    u_type_value_o = 0;



    instr_o = instruction_register;
    pc_o = program_counter;

    case (instr_state)
    IF: begin
        mem_req_o = 1'b1;
        ls_ctrl_o = 2'b0;
    end
    EX: begin
        rf_write_enable_o = 0;
        is_imm_o = 0;
        case (instr_type_i)
            R_ALU_TYPE: begin
                rf_write_enable_o = 1;
            end
            I_ALU_TYPE: begin
                rf_write_enable_o = 1;
                is_imm_o = 1;
            end
            STORE_TYPE: begin
            	is_imm_o = 1; // aluda adres hesaplamak için rs2 yerine imm
             	rf_input_select_o = 1;
             	ls_ctrl_o = 2'b10;
            end
            LOAD_TYPE: begin
            	is_imm_o = 1;
            	rf_input_select_o = 1;
             	ls_ctrl_o = 2'b01;
             	rf_write_enable_o = 1;
            end
            BRANCH_TYPE: begin
				alu_control_override_o = 1;
				branch_mode_flag_o = 1'b0; // subtract harici önemsiz

				case (funct3_i)
					// equal
					3'b000, 3'b001: begin
					override_funct_o = 3'b000; // subtract
					branch_mode_flag_o = 1'b1; // flag for sub
					end

					// signed  comparison
					3'b100, 3'b101: begin
					override_funct_o = 3'b010; // slt signed
					end

					// unsigned comparison
					3'b110, 3'b111: begin
					override_funct_o = 3'b011; // slt unsigned
					end

					default $finish;

				endcase


            end
            JAL_TYPE: begin
            	rf_input_select_o = 2;
             	rf_write_enable_o = 1;
            end
            JALR_TYPE: begin
           		rf_input_select_o = 2;
            	rf_write_enable_o = 1;
            end
            LUI_TYPE: begin
          		rf_input_select_o = 3;
           		rf_write_enable_o = 1;
            	u_type_value_o = imm_i;
            end
            AUIPC_TYPE: begin
          		rf_input_select_o = 3;
           		rf_write_enable_o = 1;
           		u_type_value_o = pc_plus_imm;
            end
            EBREAK_TYPE: begin

            end
            ECALL_TYPE: begin

            end
            default: begin

            end
        endcase
    end
    MEM: begin end
    WB: begin end


    default: begin end
    endcase



end


always @(*) begin
	branch_taken = 0;
	if (instr_type_i == BRANCH_TYPE) begin
		case (funct3_i)
			// branch if equal
			3'b000: begin
				if (alu_result_i== 0) branch_taken = 1;
				else branch_taken = 0;
			end
			// branch if not
			3'b001: begin
				if (alu_result_i!= 0) branch_taken = 1;
				else branch_taken = 0;
			end

			// branch if less than (signed)
			3'b100: begin
				if (alu_result_i== 1) branch_taken = 1;
				else branch_taken = 0;
			end
			// branch if greater or equal (signed)
			3'b101: begin
				if (alu_result_i == 0) branch_taken = 1;
				else branch_taken = 0;
			end

			// branch if less than (unsigned)
			3'b110: begin
				if (alu_result_i == 1) branch_taken = 1;
				else branch_taken = 0;
			end
			// branch if greater or equal (unsigned)
			3'b111: begin
				if (alu_result_i== 0) branch_taken = 1;
				else branch_taken = 0;
			end
			default $finish;
		endcase
	end
end

endmodule
