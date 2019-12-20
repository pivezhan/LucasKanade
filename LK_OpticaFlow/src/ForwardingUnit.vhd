library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	entity ForwardingUnit is
		generic(N : integer := 5);
		port(
		BranchControl, Jump : in std_logic_vector(1 downto 0);
		IF_ID_Opcode : in std_logic_vector(5 downto 0);
		ID_EX_RegWrite, EX_MEM_RegWrite, MEM_WB_RegWrite : in std_logic;
		ID_EX_AluSrc, EX_MEM_AluSrc, MEM_WB_AluSrc : in std_logic;
		EX_MEM_MemRead, MEM_WB_MemRead : in std_logic;
		IF_ID_MemWrite, ID_EX_MemWrite, EX_MEM_MemWrite, MEM_WB_MemWrite : in std_logic;
		ID_EX_Register_Rd, EX_MEM_Register_Rd, MEM_WB_Register_Rd : in std_logic_vector((N-1) downto 0); -- Execution/memory pipeline
		EX_MEM_Register_Rt, MEM_WB_Register_Rt : in std_logic_vector((N-1) downto 0); 
		IF_ID_Register_Rs, ID_EX_Register_Rs : in std_logic_vector((N-1) downto 0); -- Decode/execution pipeline
		IF_ID_Register_Rt, ID_EX_Register_Rt : in std_logic_vector((N-1) downto 0); -- Decode/memory pipeline
		ForwardA, ForwardC : out std_logic_vector(1 downto 0);
		ForwardB, ForwardD : out std_logic_vector(1 downto 0);
		ForwardMem : out std_logic
		);							   
	end ForwardingUnit;

	architecture behavioral of ForwardingUnit is
	constant allzero : std_logic_vector((N-1) downto 0):= (others => '0');
	constant allzeroopcode : std_logic_vector(5 downto 0):= (others => '0');
	signal ID_EX_Register_Rdst, EX_MEM_Register_Rdst, MEM_WB_Register_Rdst : std_logic_vector((N-1) downto 0); -- Execution/memory pipeline
	begin
	ID_EX_Register_Rdst <= ID_EX_Register_Rt when (ID_EX_AluSrc = '1') else  ID_EX_Register_Rd;
	EX_MEM_Register_Rdst <= EX_MEM_Register_Rt when (EX_MEM_AluSrc = '1') else  EX_MEM_Register_Rd;
	MEM_WB_Register_Rdst <= MEM_WB_Register_Rt when (MEM_WB_AluSrc = '1') else  MEM_WB_Register_Rd;

	-- process(EX_MEM_RegWrite, BranchControl, Jump, EX_MEM_Register_Rdst, IF_ID_Register_Rt, IF_ID_Register_Rs)
	-- begin
	-- ForwardBranchA <= "00";
	-- ForwardBranchB <= "00";


	-- if ((BranchControl /= "00") and (MEM_WB_MemRead = '1') and (MEM_WB_Register_Rdst /= allzero) and (IF_ID_Register_Rs = MEM_WB_Register_Rdst)) then
	-- ForwardBranchA <= "10";
	-- else null;
	-- end if;
	-- if ((BranchControl /= "00") and (MEM_WB_MemRead = '1') and (MEM_WB_Register_Rdst /= allzero) and (IF_ID_Register_Rt = MEM_WB_Register_Rdst)) then
	-- ForwardBranchB <= "10";
	-- else null;
	-- end if;
	
	-- if ((BranchControl /= "00") and (EX_MEM_MemRead /= '1') and (EX_MEM_RegWrite = '1') and (EX_MEM_Register_Rdst /= allzero) and (IF_ID_Register_Rs = EX_MEM_Register_Rdst)) then
	-- ForwardBranchA <= "01";
	-- else null;
	-- end if;
	-- if ((BranchControl /= "00") and (EX_MEM_MemRead /= '1') and (EX_MEM_RegWrite = '1') and (EX_MEM_Register_Rdst /= allzero) and (IF_ID_Register_Rt = EX_MEM_Register_Rdst)) then
	-- ForwardBranchB <= "01";
	-- else null;
	-- end if;

	-- if ((Jump /= "00")  and (EX_MEM_MemRead /= '1') and (EX_MEM_RegWrite = '1') and (EX_MEM_Register_Rdst /= allzero) and (IF_ID_Register_Rs = EX_MEM_Register_Rdst)) then
	-- ForwardSw <= '1';
	-- else null;
	-- end if;

	-- end process;	

	-- process(EX_MEM_MemRead, ID_EX_MemWrite, EX_MEM_Register_Rt, ID_EX_Register_Rt)
	-- begin
	-- ForwardMem <= '0';
	-- if ((EX_MEM_MemRead = '1') and (ID_EX_MemWrite = '1') and (EX_MEM_Register_Rt /= allzero) and (EX_MEM_Register_Rt = ID_EX_Register_Rt)) then
	-- ForwardMem <= '1'; -- forward result from MEM/WB section to first output of register file
	-- else 
	-- null;
	-- end if;
	-- end process;	

	process(IF_ID_Opcode, EX_MEM_MemRead, IF_ID_MemWrite, Jump, BranchControl, ID_EX_MemWrite, IF_ID_Register_Rt, IF_ID_Register_Rs, EX_MEM_RegWrite, ID_EX_AluSrc, MEM_WB_RegWrite, ID_EX_Register_Rdst, EX_MEM_Register_Rdst, MEM_WB_Register_Rdst, ID_EX_Register_Rs, ID_EX_Register_Rt)
	begin
	ForwardA <= "00";	
	ForwardB <= "00";	
	ForwardC <= "00";
	ForwardD <= "00";
	-- ForwardSw <= '0';

	if ((MEM_WB_RegWrite = '1') and (MEM_WB_Register_Rdst /= allzero) and (MEM_WB_Register_Rdst = IF_ID_Register_Rs)) then
	ForwardC <= "10"; -- forward result from MEM/WB section to first output of register file 
	-- when r-type or i_type happen two cycle ahead
	else 
	null;
	end if;

	if (((BranchControl /= "00") or (Jump = "01")) and (EX_MEM_MemRead /= '1') and (EX_MEM_RegWrite = '1') and (EX_MEM_Register_Rdst /= allzero) and (EX_MEM_Register_Rdst = IF_ID_Register_Rs)) then
	ForwardC <= "01"; -- forward result from EX/MEM section to first output of register file 
	-- when dependent r-type or i_type happen one cycle ahead
	else 
	null;
	end if;

	if (((IF_ID_Opcode = allzeroopcode) or (IF_ID_MemWrite = '1') or (BranchControl /= "00")) and (MEM_WB_RegWrite = '1') and (MEM_WB_Register_Rdst /= allzero) and (MEM_WB_Register_Rdst = IF_ID_Register_Rt)) then
	ForwardD <= "10"; -- forward result from MEM/WB section to second output of register file when we have r-type, sw, and branch
	else 
	null;
	end if;

	if (((BranchControl /= "00") and (EX_MEM_MemRead /= '1')) and (EX_MEM_RegWrite = '1') and (EX_MEM_Register_Rdst /= allzero) and (EX_MEM_Register_Rdst = IF_ID_Register_Rt)) then
	ForwardD <= "01"; -- forward result from MEM/WB section to first output of register file
	else 
	null;
	end if;




	if ((MEM_WB_RegWrite = '1') and (MEM_WB_Register_Rdst /= allzero) and (MEM_WB_Register_Rdst = ID_EX_Register_Rs)) then
	ForwardA <= "10"; -- forward result from MEM/WB section to the first input of ALU
	else 
	null;	
	end if;
	
	if ((EX_MEM_MemRead /= '1') and (EX_MEM_RegWrite = '1') and (EX_MEM_Register_Rdst /= allzero) and (EX_MEM_Register_Rdst = ID_EX_Register_Rs)) then
	ForwardA <= "01"; -- forward result from EX/MEM section to the first input of ALU
	else 
	null;	
	end if;

	if (((ID_EX_AluSrc /= '1') or (ID_EX_MemWrite = '1')) and (MEM_WB_RegWrite = '1') and (MEM_WB_Register_Rdst /= allzero) and (MEM_WB_Register_Rdst = ID_EX_Register_Rt)) then
	ForwardB <= "10"; -- forward from WB stage to the second input of the ALU
	else 
	null;
	end if;
	if (((ID_EX_AluSrc /= '1') or (ID_EX_MemWrite = '1')) and (EX_MEM_MemRead /= '1') and (EX_MEM_RegWrite = '1') and (EX_MEM_Register_Rdst /= allzero) and (EX_MEM_Register_Rdst = ID_EX_Register_Rt)) then
	ForwardB <= "01"; -- forward from EX stage to the second input of the ALU
	else 
	null;
	end if;
	-- if (((ID_EX_MemWrite = '1')) and (EX_MEM_MemRead /= '1') and (EX_MEM_RegWrite = '1') and (EX_MEM_Register_Rdst /= allzero) and (EX_MEM_Register_Rdst = ID_EX_Register_Rt)) then
	-- ForwardB <= "11"; -- forward from EX stage to the second input of the ALU
	-- else 
	-- null;
	-- end if;

	end process; 

	end behavioral;