`timescale 1ns/10ps
//+++++++++++++++++++++++++++++++++++++++++++++++
//   Testbench
//+++++++++++++++++++++++++++++++++++++++++++++++
module pico_cpu_tb();

reg clk = 0;
reg rst = 0;
wire [3:0] flags_t;
wire [7:0] output_t;
reg [7:0] InstrAdd_t; //pc //instruction address
reg [13:0] Instr_t;

int error_count = 0;
int test_iterations = 200;

always #5 clk ++;

/*--------------------------------------------
-	CLASS Instruction
--------------------------------------------*/
class Instruction;
	//Variable Definitions
	bit [5:0] opcode;
	rand bit [7:0] operand;
 
	/*----------------tasks-----------------*/
	task Add_A_Dir;
		opcode = 6'b000010;
		Instr_t = {opcode, operand};
		@ InstrAdd_t;
	endtask;	

	task Load_A_Mem;
		opcode = 6'b011111;
		Instr_t = {opcode, operand};
		@ InstrAdd_t;
	endtask;

	task Store_A_Mem;
		opcode = 6'b100000;
		Instr_t = {opcode, operand};
		@ InstrAdd_t;
	endtask;

	task ClearACC;
		opcode = 6'b011100;
		Instr_t = {opcode, operand};
		@ InstrAdd_t;
	endtask;

	task Load_R0_Dir;
		opcode = 6'b100001;
		Instr_t = {opcode, operand};
		@ InstrAdd_t;
	endtask;

	task Load_A_R;
		opcode = 6'b100011;
		Instr_t = {opcode, operand};
		@ InstrAdd_t;
	endtask;

	task NOP;
		opcode = 6'b111110;
		Instr_t = {opcode, operand};
		@ InstrAdd_t;
	endtask;
	
	/*---------------reset---------------*/
	task reset;
		//$display("Resetting the cpu...");
		@ (posedge clk);
		rst<= 1;
		repeat (4) @ (posedge clk);
		//@ (negedge clk);
		rst<= 0;
	endtask
endclass: Instruction
/*--------------------------------------------
-	CLASS Sub_A_Mem
--------------------------------------------*/
class Sub_A_Mem extends Instruction;
	/*--Test classes have 'test' task's that will check CPU status  */
	rand bit [7:0] operand1;
	rand bit [7:0] operand2;
	rand bit [7:0] address;
	/*---------------execute---------------*/
	task test;
	/*--seting up environment and asserting the result*/
	operand = operand1;
	Add_A_Dir();

	operand = address;
	Store_A_Mem();

	operand = operand2;
	Load_R0_Dir();

	operand = 8'b00000000;

	Load_A_R();

	operand = address;
	opcode = 6'b000100;

        Instr_t = {opcode, operand};
        @ InstrAdd_t;
        assert_Sub_A_Mem : assert (output_t == (operand2 - operand1)) begin
		$display ("Sub_A_Mem assert success");
        end else begin
		error_count++;
		#1 $error ("Sub_A_Mem assert failed %d", error_count);
        end
	ClearACC();
	endtask;
endclass: Sub_A_Mem
/*--------------------------------------------
-	CLASS RRC
--------------------------------------------*/
class RRC extends Instruction;
	/*--Test classes have 'test' task's that will check CPU status  */
	rand bit [7:0] operand1;
    	reg [8:0] C_A;
	/*---------------execute---------------*/
	task test;
	/*--seting up environment and asserting the result*/
	operand = operand1;
	Add_A_Dir();

        C_A = {flags_t[3], output_t};
	opcode = 6'b001100;

	Instr_t = {opcode, operand};
	
	@ InstrAdd_t;
        assert_RRC : assert ({output_t, flags_t[3]} == C_A) begin
		$display ("RRC assert success");
        end else begin
		error_count++;
		#1 $error ("RRC assert failure %d", error_count);
        end
	endtask;
endclass: RRC
/*--------------------------------------------
-	CLASS NegA
--------------------------------------------*/
class NegA extends Instruction;
	/*--Test classes have 'test' task's that will check CPU status  */
	rand bit [7:0] operand1;
	/*---------------execute---------------*/
	task test;
	/*--seting up environment and asserting the result*/
	operand = operand1;
	Add_A_Dir();

	opcode = 6'b010010;
	
        Instr_t = {opcode, operand};
	
        @ InstrAdd_t
        assert_NegA : assert (output_t == -operand1) begin
		$display ("NegA assert success");
        end else begin
		error_count++;
		#1 $error ("NegA assert failure %d", error_count);
        end
	ClearACC();
	endtask;
endclass: NegA
/*--------------------------------------------
-	CLASS Jmp_rel
--------------------------------------------*/
class Jmp_rel extends Instruction;
	/*--Test classes have 'test' task's that will check CPU status  */
	rand bit [7:0] operand1;
	reg [7:0] PC;
	/*---------------execute---------------*/
	task test;
	/*--seting up environment and asserting the result*/
	PC = InstrAdd_t;
	operand = operand1;

	opcode = 6'b010111;

	Instr_t = {opcode, operand};
	@ InstrAdd_t
	assert_Jmp_rel : assert (InstrAdd_t == PC + operand1) begin
		$display ("Jmp_rel assert success");
        end else begin
		error_count++;
		#1 $error ("Jmp_rel assert failure %d", error_count);
        end
	endtask;
endclass: Jmp_rel
/*--------------------------------------------
-	CLASS SavePC
--------------------------------------------*/
class SavePC extends Instruction;
	/*--Test classes have 'test' task's that will check CPU status  */
	reg [7:0] PC;
	/*---------------execute---------------*/
	task test;
	/*--seting up environment and asserting the result*/
	PC = InstrAdd_t;
	opcode = 6'b011110;

	Instr_t = {opcode, operand};
	@ InstrAdd_t
	assert_SavePC : assert (output_t == PC) begin
		$display ("SavePC assert success");
        end else begin
		error_count++;
		#1 $error ("SavePC assert failure %d", error_count);
	end
	endtask;
endclass: SavePC
/*--------------------------------------------
-	CLASS Load_Ind_A
--------------------------------------------*/

class Load_Ind_A extends Instruction;
	/*--Test classes have 'test' task's that will check CPU status  */
	rand bit [7:0] operand1;
	rand bit [7:0] address;
	/*---------------execute---------------*/
	task test;
	/*--seting up environment and asserting the result*/
	operand = operand1;
	Add_A_Dir();

	operand = address;
	Store_A_Mem();
	
	ClearACC();
	operand = address;
	Add_A_Dir();

	opcode = 6'b100101;

        Instr_t = {opcode, operand};
        @ InstrAdd_t
	assert_Load_Ind_A : assert (output_t == operand1) begin
		$display ("Load_Ind_A assert success");
        end else begin
		error_count++;
		#1 $error ("Load_Ind_A assert failure %d", error_count);
	end
	ClearACC();
	endtask;
endclass: Load_Ind_A

/*--------------------------------------------
-    CREATING OBJECTS
--------------------------------------------*/
	
	Sub_A_Mem sub= new;
	RRC rrc= new;
	NegA neg= new;
	Jmp_rel jmp= new;
	SavePC save= new;
	Load_Ind_A load= new;
	
PicoCPU my_cpu(rst, clk, flags_t, output_t, InstrAdd_t, Instr_t);

	covergroup _cg_sub;
	coverpoint sub.operand;
	endgroup
	_cg_sub cg_sub= new;

	covergroup _cg_rrc;
        coverpoint rrc.operand;
   	endgroup
    	_cg_rrc cg_rrc= new;

	covergroup _cg_neg;
        coverpoint neg.operand;
    	endgroup
    	_cg_neg cg_neg= new;

	covergroup _cg_jmp;
        coverpoint jmp.operand;
    	endgroup
    	_cg_jmp cg_jmp= new;	

	covergroup _cg_save;
        coverpoint save.operand;
    	endgroup
    	_cg_save cg_save= new;

	covergroup _cg_load;
        coverpoint load.operand;
    	endgroup
    	_cg_load cg_load= new;

initial begin

// All above was for seting up classes to be used in the actual test below.
/*--------------------------------------------
-	TEST Sub_A_Mem
--------------------------------------------*/
    sub.reset();	
	for (int i= 0; i< test_iterations; i++) begin
		sub.randomize();
		sub.test();
		cg_sub.sample();
	end
	$info ("Sub_A_Mem test done");

/*--------------------------------------------
-	TEST RRC
--------------------------------------------*/
    rrc.reset();	
	for (int i= 0; i< test_iterations; i++) begin
		rrc.randomize();
		rrc.test();
		cg_rrc.sample();
	end
	$info ("RRC test done");
/*--------------------------------------------
-	TEST NegA
--------------------------------------------*/
    neg.reset();	
	for (int i= 0; i< test_iterations; i++) begin
		neg.randomize();
		neg.test();
		cg_neg.sample();
	end
	$info ("NegA test done");
/*--------------------------------------------
-	TEST Jmp_rel
--------------------------------------------*/
    jmp.reset();	
	for (int i= 0; i< test_iterations; i++) begin
		jmp.randomize();
		jmp.test();
		cg_jmp.sample();
	end
	$info ("Jmp_rel test done");
/*--------------------------------------------
-	TEST SavePC
--------------------------------------------*/
    save.reset();	
	for (int i= 0; i< test_iterations; i++) begin
		save.randomize();
		save.test();
		cg_save.sample();
	end
	$info ("SavePC test done");
/*--------------------------------------------
-	TEST Load_Ind_A
--------------------------------------------*/
    load.reset();	
	for (int i= 0; i< test_iterations; i++) begin
		load.randomize();
		load.test();
		cg_load.sample();
	end
	$info ("Load_Ind_A test done");
/*--------------------------------------------
-    ERRORS
--------------------------------------------*/
	if (error_count == 0)
		$info ("%d errors", error_count);
	else
		$info ("%d errors", error_count);
	end

endmodule