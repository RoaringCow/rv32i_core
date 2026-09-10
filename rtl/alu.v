


// R type veya I type oluşu / immediate veya rs3 gelişi
// tamamen dışarıdan kontrol ediliyor. ALU immediate değeri de
// rs2 gibi alıyor.
//
// küçük bir llm alışverişi sonucunda ileride bunu birkaç buyrk alacak şekilde
// yaparsam hazardlı bir şey demişti de sohbeti kaybettim

module alu (
    input   [31:0]  rs1_i,
    input   [31:0]  rs2_i,
    input   [2:0]   funct3_i,
    input   [6:0]   funct7_i,
    input 	alu_control_override,
    input 	[2:0]	override_funct,
    input 	branch_mode_flag,

    output reg  [31:0]  alu_result_o
);



//000 0000 is add
//010 0000 is sub
wire mode_flag = alu_control_override ? branch_mode_flag : funct7_i[5] | manual_flag_set;
// mode_flag is also used in shift logical or arithmetic
// 000 0000 is logical
// 010 0000 is arithmetic
wire [31:0] sum;
wire carry_out;


reg manual_flag_set; // yani aklıma başka bir şey gelmedi :DD


wire [2:0] control_select = alu_control_override ? override_funct : funct3_i;


adder_32bit adder (
    .rs1_i          (rs1_i),
    .rs2_i          (rs2_i),
    .mode_flag_i      (mode_flag),
    .adder_result_o (sum),
    .carry_out_o    (carry_out)
);


 // unsigned -> carry: A>=B 1 A<B 0
 // signed ->




 // Barrel shifter varmış tek cycle direkt max 31 kaydırmalı.
 //


always @(*) begin
    alu_result_o = 32'd0;
    manual_flag_set = 1'd0;

    case(control_select)
        3'b000: begin
            alu_result_o = sum;
        end
        3'b001: begin
            // shift left logical
            alu_result_o = rs1_i << rs2_i[4:0]; // max 31 sağa olduğundan ilk 5 bit

        end
        3'b010: begin
            // set less than    (signed)
            manual_flag_set = 1;

            // çaldım
            alu_result_o = {31'b0, (rs1_i[31] ^ rs2_i[31]) ? rs1_i[31] : sum[31]};
            // eğer sign bit 1 ise negatif yani less than.
            // eğer sign bit 0 ise ve overflow varsa sıkınıtı ondan yine less than
            // tamamen ona bakıyor :))


        end
        3'b011: begin
            // set less than    (unsigned)
            manual_flag_set = 1;
            alu_result_o = {31'b0, carry_out};

        end
        3'b100: begin   //xor
            alu_result_o = rs1_i ^ rs2_i;
        end
        3'b101: begin
            // shift right logical
            //
            // ***** Bu verilog içindeki Shiftin aritmetik olması için
            // signed olması gerekmiş (zaten signed için yapılıyor.)
            // donanım için signed olması hiçbir şey değiştirmiyor
            if (!mode_flag)  alu_result_o = rs1_i >> rs2_i[4:0];
            else alu_result_o = $signed(rs1_i) >>> rs2_i[4:0];


        end
        3'b110: begin
            alu_result_o = rs1_i | rs2_i;

        end
        3'b111: begin
            alu_result_o = rs1_i & rs2_i;
        end
        default: begin
            alu_result_o = 32'dx; // bug görmelik böyle bir şey gördüydüm.
        end

    endcase

end

endmodule





// Brent–Kung ve diğer adderlar çok havalıymış
// O(n) derinlik yerine O(log n) deniyor.
// ondan deneyecem. (tabii ki sonra :D)

module adder_32bit(
    input   [31:0]  rs1_i,
    input   [31:0]  rs2_i,
    input   mode_flag_i,
    output reg [31:0]  adder_result_o,
    output reg carry_out_o
);

// adder'ı veriloga kitlediğim için carry'yi bu şekilde çıkartıyom
wire [32:0] rs1_extended = {1'b0, rs1_i};
wire [32:0] rs2_extended = {1'b0, rs2_i};

reg [32:0] result_extended;

//000 0000 is add
//010 0000 is sub
always @(*) begin
    if (!mode_flag_i)  result_extended = rs1_extended + rs2_extended; // bunları aynı devreden mi yapıyor.??
    else            result_extended = rs1_extended - rs2_extended;     // peki elimilen yapmadan nasıl aynıdan yaptırırım?


    adder_result_o = result_extended[31:0];
    carry_out_o = result_extended[32];

end

endmodule
