`timescale 1ns/1ps

module test_tb;

reg clk;
reg rst;

initial clk = 0;
always #5 clk = ~clk;

top uut (
    .clk_i(clk),
    .rst_i(rst)
);


wire [31:0] pc     = uut.cu.program_counter_prev;
wire [31:0] instr  = uut.cu.instruction_register;
wire [2:0]  state  = uut.cu.instr_state;
wire [3:0]  itype  = uut.dec_instr_type;
wire [4:0]  rd     = uut.dec_rd_select;
wire [31:0] rd_val = uut.rf_rd_input;
wire [31:0] rs1_val = uut.rf_rs1_o;
wire [31:0] rs1= uut.dec_rs1_select;
wire [31:0] rs2_val = uut.rf_rs2_o;
wire [31:0] rs2= uut.dec_rs2_select;
wire [31:0] instr_type = uut.dec_instr_type;


always @(posedge clk) begin
	$display("PC=%08h   type: %2d 	[%08h]  rd: x%02d|%08h  rs1: x%02d|%08h,   rs2: x%02d|%08h, \n", pc ,instr_type , instr, rd, rd_val, rs1, rs1_val, rs2, rs2_val);
end


initial begin
    $dumpfile("test_tb.vcd");
    $dumpvars(0, test_tb);

    rst = 0;
    #12;
    rst = 1;

    #2000;
    $finish;
end

endmodule
