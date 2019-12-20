library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HazardDetection is
	generic(N : integer := 5);
	port(
	ID_EX_Register_Rd : in std_logic_vector((N-1) downto 0);
	ID_EX_AluSrc : in std_logic;
	IF_ID_MemRead, ID_EX_MemRead, EX_MEM_MemRead : in std_logic;
	IF_ID_RegWrite, ID_EX_RegWrite : in std_logic;
	IF_ID_MemWrite, ID_EX_MemWrite, EX_MEM_MemWrite : in std_logic;
	ID_EX_Register_Rt, EX_MEM_Register_Rt : in std_logic_vector((N-1) downto 0); -- Decode/memory pipeline	
	IF_ID_Register_Rs : in std_logic_vector((N-1) downto 0); -- Decode/execution pipeline
	IF_ID_Register_Rt : in std_logic_vector((N-1) downto 0); -- Decode/memory pipeline	
	BranchControl, Branch, Jump : in std_logic_vector(1 downto 0); -- -- Branch = "00": (PC+4), Branch = "01": beq, Branch = "10": bne
	-- chooose between Jump="00": (PC+4)/(branch output), Jump="01": R[rs], Jump="10": {(PC + 4)[31:28], address, 00}
	JalS : in std_logic; -- jump and link instruction
	Stall : out std_logic;
	Flush : out std_logic
	);			   
end HazardDetection;

	architecture behavioral of HazardDetection is
	constant allzero : std_logic_vector((N-1) downto 0):= (others => '0');
	signal ID_EX_Register_Rdst : std_logic_vector((N-1) downto 0);
	begin
	
	ID_EX_Register_Rdst <= ID_EX_Register_Rt when (ID_EX_AluSrc = '1') else  ID_EX_Register_Rd;	
	process(JalS, Branch, Jump, BranchControl, IF_ID_RegWrite, ID_EX_RegWrite, ID_EX_Register_Rdst, EX_MEM_MemRead, EX_Mem_Register_Rt, ID_EX_MemRead, IF_ID_Register_Rs, IF_ID_Register_Rt, ID_EX_Register_Rt)
	begin

	Stall <= '0';
	Flush <= '0';
	if ((JalS/='0') or (Branch /= "00") or (Jump /= "00")) then
	Flush <= '1';
	else null;
	end if;
	if ((ID_EX_MemRead = '1') and ((BranchControl /= "00") or (Jump = "01") or (IF_ID_MemWrite = '1') or (IF_ID_RegWrite = '1')) and ((ID_EX_Register_Rdst = IF_ID_Register_Rs) or (ID_EX_Register_Rdst = IF_ID_Register_Rt))) then
	Stall <= '1'; --  for sw, branches, jr, r-type/i-type after lw 
	Flush <= '0';
	elsif ((EX_MEM_MemRead = '1') and ((BranchControl /= "00") or (Jump = "01")) and ((EX_MEM_Register_Rt = IF_ID_Register_Rs) or (EX_MEM_Register_Rt = IF_ID_Register_Rt))) then
	Stall <= '1'; --  for branches and jr after lw
	Flush <= '0';
	elsif ((ID_EX_RegWrite = '1') and ((BranchControl /= "00") or (Jump = "01")) and ((ID_EX_Register_Rdst = IF_ID_Register_Rs) or (ID_EX_Register_Rdst = IF_ID_Register_Rt))) then
	Stall <= '1'; --  for branches and jr after lw
	Flush <= '0';
	else null;
	end if;	

	end process;

	-- process(JalS, Branch, Jump, Stall)
	-- begin
	-- Flush <= '0';
	-- --(ID_EX_Register_Rt = IF_ID_Register_Rs) or 
	-- if ((JalS/='0') or ((Branch /= "00") and (Stall /= '1')) or (Jump /= "00")) then
	-- Flush <= '1';
	-- null;
	-- end if;	
	-- end process;
	
	end behavioral;