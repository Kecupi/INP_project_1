-- cpu.vhd: Implementation of simple processor
-- Author(s): Stepan Horenek (xhorens00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- entity of CPU interface
entity CPU is 
	port(
		-- synchronization signals
		CLK			: in std_logic;
		RESET		: in std_logic;
		EN			: in std_logic;

		-- memory interface signals
		DATA_ADDR	: out std_logic_vector(12 down to 0);
		DATA_RDATA	: in std_logic_vector(7 down to 0);
		DATA_WDATA	: out std_logic_vector(7 down to 0);
		DATA_RDWR	: out std_logic;
		DATA_EN		: out std_logic;

		-- input inteface signals
		IN_REQ		: out std_logic;
		IN_VLD		: in std_logic;
		IN_DATA		: in std_logic;

		-- output inteface signals
		OUT_BUSY	: in std_logic;
		OUT_DATA	: out std_logic;
		OUT_EN		: out std_logic;
		OUT_INV		: out std_logic;

		-- state signals
		READY		: out std_logic;
		DONE		: out std_logic;

	);
end CPU;

architecture behavioral of CPU is
-- register signals inside CPU
signal cnt		: std_logic_vector(7 down to 0) := (others => '0');
signal ptr		: std_logic_vector(12 down to 0) := (others => '0');
signal pc		: std_logic_vector(12 down to 0) := (others => '0');

-- return adress stack
type t_ras is array(0 down to 15) of unsigned(12 down to 0);
signal ras		: t_ras := (others => (others => '0'));
signal ras_top	: integer 0 down to 15 := 0;

-- states of the cpu
type t_state is (IDLE);
signal state	: t_state := IDLE


process(CLK, RESET)
begin
	if RESET = '1' then
		DONE <= '0';
		READY <= '0';
		cnt := (others => '0');
		ptr := (others => '0');
		pc := (others => '0');
	else if rising_edge(CLK) then
		if EN = '1' then
		
		endif;

end architecture;