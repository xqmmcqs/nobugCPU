-- --------------------------------------------------------------------
-- 本文件名                 nobugCPU-pipe
-- --------------------------------------------------------------------
-- 描述
-- 		第二个任务：自选题目一
--			在必选题目基础上，完成流水硬连线控制器的设计根据设计方案，
--			在TEC-8上进行组装、调试运行  。
-- --------------------------------------------------------------------
-- 版本日期	v1.0 	2021.7.4
-- --------------------------------------------------------------------



-- --------------------------------------------------------------------
--                          库引用
-- --------------------------------------------------------------------
-- library 库名;
-- use 库名,库中程序包,程序包中的项;
-- --------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- --------------------------------------------------------------------




-- --------------------------------------------------------------------
--      实体声明
-- --------------------------------------------------------------------
-- port(端口名 : 端口模式 数据类型);
-- 输入模式in  : 操作模式，指令
-- 输出模式out : 控制各个部件信号
-- --------------------------------------------------------------------
----      输入in std_logic
-- CLR  #CLR
-- Z,C  状态寄存器
-- --------------------------------------------------------------------
----      输入in std_logic_vector
-- IR   指令高四位
-- SW   操作模式
-- W    三个节拍
-- --------------------------------------------------------------------
----      输出out std_logic 
-- SELCTL,              R0~3选择
-- DRW,                 R0~3控制
-- LPC, PCINC, PCADD,   PC 控制
-- LAR, ARINC,          AR 控制
-- STOP,                停机控制
-- LIR,                 IR 控制
-- LDZ, LDC,            状态控制
-- CIN, M,              运算控制
-- MEMW,                内存控制
-- ABUS, SBUS, MBUS,    总线控制
-- SHORT, LONG,         拍数控制
-- --------------------------------------------------------------------
----      输出out std_logic_vector 
-- S                    选择ALU、
-- SEL                  选择R和MUX
-- --------------------------------------------------------------------
entity nobugCPU is
	port(
	CLR, T3, C, Z: in std_logic;
	IR: in std_logic_vector(7 downto 4);
	SW, W: in std_logic_vector(3 downto 1);
	
	SELCTL, 
	DRW, 
	LPC, PCINC, PCADD, 
	LAR, ARINC, 
	LIR, 
	LDZ, LDC, 
	CIN, M, 
	MEMW, 
	ABUS, SBUS, MBUS, 
	STOP, 
	SHORT, LONG: out std_logic;
	S, SEL: out std_logic_vector(3 downto 0)
	);
end nobugCPU;
-- --------------------------------------------------------------------






-- --------------------------------------------------------------------
--                          工程体
-- --------------------------------------------------------------------
--      结构体描述方式
-- 数据流描述      dataflow      使用布尔代数式描述，以门信号赋值操作为主
-- --------------------------------------------------------------------
---- 结构体的声明
architecture arch of nobugCPU is
---- 中间信号的声明
	signal WRITE_REG, READ_REG, INS_FETCH, WRITE_MEM, READ_MEM, ST0: std_logic;
	signal ADD, SUB, AND_I, INC, LD, ST, JC, JZ, JMP, STP: std_logic;
	signal NOP, OUT_I, OR_I, CMP, MOV: std_logic;
begin
-- --------------------------------------------------------------------
---- 结构体描述语句
-- --------------------------------------------------------------------
-- 操作模式
	WRITE_REG <= '1' when SW = "100" else '0';
	READ_REG <= '1' when SW = "011" else '0';
	INS_FETCH <= '1' when SW = "000" else '0';
	READ_MEM <= '1' when SW = "010" else '0';
	WRITE_MEM <= '1' when SW = "001" else '0';

-- --------------------------------------------------------------------
-- 操作码
	ADD <= '1' when IR = "0001" and INS_FETCH = '1' and ST0 = '1' else '0';
	SUB <= '1' when IR = "0010" and INS_FETCH = '1' and ST0 = '1' else '0';
	AND_I <= '1' when IR = "0011" and INS_FETCH = '1' and ST0 = '1' else '0';
	INC <= '1' when IR = "0100" and INS_FETCH = '1' and ST0 = '1' else '0';
	LD <= '1' when IR = "0101" and INS_FETCH = '1' and ST0 = '1' else '0';
	ST <= '1' when IR = "0110" and INS_FETCH = '1' and ST0 = '1' else '0';
	JC <= '1' when IR = "0111" and INS_FETCH = '1' and ST0 = '1' else '0';
	JZ <= '1' when IR = "1000" and INS_FETCH = '1' and ST0 = '1' else '0';
	JMP <= '1' when IR = "1001" and INS_FETCH = '1' and ST0 = '1' else '0';
	STP <= '1' when IR = "1110" and INS_FETCH = '1' and ST0 = '1' else '0';

	NOP <= '1' when IR = "0000" and INS_FETCH = '1' and ST0 = '1' else '0';
	OUT_I <= '1' when IR = "1010" and INS_FETCH = '1' and ST0 = '1' else '0';
	OR_I <= '1' when IR = "1011" and INS_FETCH = '1' and ST0 = '1' else '0';
	CMP <= '1' when IR = "1100" and INS_FETCH = '1' and ST0 = '1' else '0';
	MOV <= '1' when IR = "1101" and INS_FETCH = '1' and ST0 = '1' else '0';

-- --------------------------------------------------------------------
-- ST0 状态
	process(CLR, T3, W)
	begin
		if (CLR = '0') then
			ST0 <= '0';
		elsif (T3'event and T3 = '0') then
			if (ST0 = '0' and ((WRITE_REG = '1' and W(2) = '1') or (READ_MEM = '1' and W(1) = '1') or (WRITE_MEM = '1' and W(1) = '1') or (INS_FETCH = '1' and W(2) = '1'))) then
				ST0 <= '1';
			elsif (ST0 = '1' and (WRITE_REG = '1' and W(2) = '1')) then
				ST0 <= '0';
			end if;
		end if;
	end process;

-- --------------------------------------------------------------------
-- PCINC LIR， T3上升执行
	process(T3, W)
	begin
		if (T3'event and T3 = '1') then
			PCINC <= (INS_FETCH and not ST0 and W(2)) or ((NOP or ADD or SUB or AND_I or INC or (JC and not C) or (JZ and not Z) or OUT_I or OR_I or CMP or MOV) and W(1)) or ((LD or ST or (JC and C) or (JZ and Z) or JMP) and W(2));
			LIR <= (INS_FETCH and not ST0 and W(2)) or ((NOP or ADD or SUB or AND_I or INC or (JC and not C) or (JZ and not Z) or OUT_I or OR_I or CMP or MOV) and W(1)) or ((LD or ST or (JC and C) or (JZ and Z) or JMP) and W(2));
		end if;
	end process;


-- --------------------------------------------------------------------
-- 控制信号合成
	SBUS <= ((WRITE_REG or (READ_MEM and not ST0) or WRITE_MEM or (INS_FETCH and not ST0)) and W(1)) or (WRITE_REG and W(2));

	SEL(3) <= (WRITE_REG and (W(1) or W(2)) and ST0) or (READ_REG and W(2));
	SEL(2) <= (WRITE_REG and W(2));
	SEL(1) <= (WRITE_REG and ((W(1) and not ST0) or (W(2) and ST0))) or (READ_REG and W(2));
	SEL(0) <= (WRITE_REG and W(1)) or (READ_REG and (W(1) or W(2)));

	SELCTL <= ((WRITE_REG or READ_REG) and (W(1) or W(2))) or ((READ_MEM or WRITE_MEM) and W(1));

	DRW <= (WRITE_REG and (W(1) or W(2))) or ((ADD or SUB or AND_I or INC or OR_I or MOV) and W(1)) or (LD and W(2));

	STOP <= ((WRITE_REG or READ_REG) and (W(1) or W(2))) or ((READ_MEM or WRITE_MEM) and W(1)) or (STP and W(1)) or (INS_FETCH and not ST0 and W(1));

	LAR <= ((READ_MEM or WRITE_MEM) and W(1) and not ST0) or ((ST or LD) and W(1));

	SHORT <= ((READ_MEM or WRITE_MEM) and W(1)) or ((NOP or ADD or SUB or AND_I or INC or (JC and not C) or (JZ and not Z) or OUT_I or OR_I or CMP or MOV) and W(1));

	MBUS <= (READ_MEM and W(1) and ST0) or (LD and W(2));

	ARINC <= (WRITE_MEM or READ_MEM) and W(1) and ST0;

	MEMW <= (WRITE_MEM and W(1) and ST0) or (ST and W(2));

	CIN <= ADD and W(1);

	ABUS <= ((ADD or SUB or AND_I or INC or LD or ST or JMP) and W(1)) or (ST and W(2)) or ((OR_I or MOV or OUT_I) and W(1));

	LDZ <= (ADD or SUB or AND_I or INC or OR_I or CMP) and W(1);
	LDC <= (ADD or SUB or INC or CMP) and W(1);

	M <= ((AND_I or LD or ST or JMP) and W(1)) or (ST and W(2)) or ((OR_I or MOV or OUT_I) and W(1));

	S(3) <= ((ADD or AND_I or LD or ST or JMP) and W(1)) or (ST and W(2)) or ((OR_I or MOV or OUT_I) and W(1));
	--S(3) <= ((W(2) or W(3)) and ST) or (W(2) and JMP) or (W(2) and ADD) or (W(2) and AND_I) or (W(2) and LD);
	S(2) <= ((SUB or ST or JMP) and W(1)) or ((OR_I or CMP) and W(1));
	--S(2) <= (W(2) and (ST or JMP)) or (W(2) and SUB);
	S(1) <= ((SUB or AND_I or LD or ST or JMP) and W(1)) or (ST and W(2)) or ((OR_I or MOV or OUT_I or CMP) and W(1));
	--S(1) <= ((W(2) or W(3)) and ST) or (W(2) and JMP) or (W(2) and SUB) or (W(2) and AND_I) or (W(2) and LD);
	S(0) <= (ADD or AND_I or ST or JMP) and W(1);

	LPC <= (JMP and W(1)) or (INS_FETCH and not ST0 and W(1));

	LONG <= '0';

	PCADD <= ((C and JC) or (Z and JZ)) and W(1);
end architecture arch;
-- --------------------------------------------------------------------
