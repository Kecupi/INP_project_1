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
		DATA_ADDR	: out std_logic;
		DATA_RDATA	: in std_logic;
		DATA_WDATA	: out std_logic;
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