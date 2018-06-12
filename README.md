# PicoCPU Instruction verification

Testbench by Tónis Lusmägi, TTÜ

PicoCPU modified by Tónis Lusmägi, TTÜ

## Build

	Build the project in QuestaSim
	Simulate picoCPU_TB.sv

## Bugfix

	In file Controller.vhd, line 240, change "CommandToDPU <= "00000001100";" to 
	"CommandToDPU <= "00000001110";"
	This is a known bug in PicoCPU load_A_R instruction, where wrong DPU command interferes with normal operation. This repo contains the bugfix.

## Credits

1. **PicoCPU** by Siavoosh Payandeh Azad, TTÜ
https://ati.ttu.ee/wiki/e/index.php/Non-Pipelined_Version