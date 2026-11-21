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
		DATA_ADDR	: out std_logic_vector(12 downto 0);
		DATA_RDATA	: in std_logic_vector(7 downto 0);
		DATA_WDATA	: out std_logic_vector(7 downto 0);
		DATA_RDWR	: out std_logic;
		DATA_EN		: out std_logic;

		-- input inteface signals
		IN_REQ		: out std_logic;
		IN_VLD		: in std_logic;
		IN_DATA		: in std_logic_vector(7 downto 0);

		-- output inteface signals
		OUT_BUSY	: in std_logic;
		OUT_DATA	: out std_logic_vector(7 downto 0);
		OUT_WE		: out std_logic;
		OUT_INV		: out std_logic;

		-- state signals
		READY		: out std_logic;
		DONE		: out std_logic

	);
end CPU;

architecture behavioral of CPU is

-- register signals inside CPU
signal cnt		: std_logic_vector(7 downto 0) := (others => '0');
signal ptr		: std_logic_vector(12 downto 0) := (others => '0');
signal pc		: std_logic_vector(12 downto 0) := (others => '0');

-- return adress stack
type t_ras is array(0 to 15) of std_logic_vector(12 downto 0);
signal ras		: t_ras := (others => (others => '0'));
signal ras_top	: integer range 0 to 15 := 0;

-- states of the cpu
type t_state is (STATE_IDLE,
				STATE_INIT,
				STATE_FIND_START,
				STATE_FETCH,
				STATE_DECODE, 
				STATE_INC_MEM, 
				STATE_DEC_MEM, 
				STATE_OUTPUT, 
				STATE_INPUT,
				STATE_WHILE_START,
				STATE_WHILE_LOOP,
				STATE_CYCLE_END,
				STATE_STOP
);
signal state	: t_state := STATE_IDLE;
signal await_data 	: std_logic := '0';
begin

process(CLK, RESET)
begin
	if RESET = '1' then
		DONE <= '0';
		READY <= '0';
		DATA_EN <= '0';
		DATA_RDWR <= '0';
		DATA_ADDR <= (others => '0');
		DATA_WDATA <= (others => '0');
		IN_REQ <= '0';
		OUT_DATA <= (others => '0');
		OUT_WE <= '0';
		OUT_INV <= '0';
		ras_top <= 0;
		cnt <= (others => '0');
		ptr <= (others => '0');
		pc <= (others => '0');
		state <= STATE_IDLE;
	elsif rising_edge(CLK) then
		if EN = '1' then
			DATA_EN <= '0';
			DATA_RDWR <= '0';
			OUT_WE <= '0';
			case state is
				when STATE_IDLE =>
					state <= STATE_INIT;
				when STATE_INIT =>
					DATA_EN <= '1';
					DATA_RDWR <= '1';
					DATA_ADDR <= pc;
					state <= STATE_FIND_START;
					await_data <= '1';
				when STATE_FIND_START =>
					if await_data = '0' then
						if (DATA_RDATA = X"40") then
							ptr <= pc + 1;
							pc <= (others => '0');
							READY <= '1';
							state <= STATE_FETCH;
						else
							pc <= pc + 1;
							DATA_EN <= '1';
							DATA_RDWR <= '1';
							DATA_ADDR <= pc + 1;
							await_data <= '1';
						end if;
					else
						await_data <= '0';
					end if;
				when STATE_FETCH =>
					if await_data = '0' then
						DATA_EN <= '1';
						DATA_RDWR <= '1';
						DATA_ADDR <= pc;
						await_data <= '1';
						state <= STATE_DECODE;
					else
						await_data <= '0';
					end if;
				when STATE_DECODE =>
					if await_data = '0' then
						case DATA_RDATA is
							when X"3E" => -- Incrementing of pointer
								if ptr = "1111111111111" then
									ptr <= (others => '0');
								else
									ptr <= ptr + 1;
								end if;
								pc <= pc + 1;
								state <= STATE_FETCH;
							when X"3C" => -- Decrementing of pointer
								if ptr = "0000000000000" then
									ptr <= "1111111111111";
								else
									ptr <= ptr - 1;
								end if;
								pc <= pc + 1;
								state <= STATE_FETCH;
							when X"2B" => -- Incrementing in adressed memory cell
								DATA_EN <= '1';
								DATA_RDWR <= '1';
								DATA_ADDR <= ptr;
								await_data <= '1';
								state <= STATE_INC_MEM;
							when X"2D" => -- Decrementing in adressed memory cell
								DATA_EN <= '1';
								DATA_RDWR <= '1';
								DATA_ADDR <= ptr;
								await_data <= '1';
								state <= STATE_DEC_MEM;
							when X"2E" => -- Outputting a character from memory
								DATA_EN <= '1';
								DATA_RDWR <= '1';
								DATA_ADDR <= ptr;
								await_data <= '1';
								state <= STATE_OUTPUT;
							when X"2C" => -- Loading character into memory
								IN_REQ <= '1';
								state <= STATE_INPUT;
							when X"5B" =>
								DATA_EN <= '1';
								DATA_RDWR <= '1';
								DATA_ADDR <= ptr;
								pc <= pc + 1;
								await_data <= '1';
								state <= STATE_WHILE_START;
							when X"5D" =>
								DATA_EN <= '1';
								DATA_RDWR <= '1';
								DATA_ADDR <= ptr;
								await_data <= '1';
								state <= STATE_CYCLE_END;
							when X"28" =>
								if ras_top < 15 then
									ras(ras_top) <= pc + 1;
									ras_top <= ras_top + 1;
								end if;
								pc <= pc + 1;
								state <= STATE_FETCH;
							when X"29" =>
								DATA_EN <= '1';
								DATA_RDWR <= '1';
								DATA_ADDR <= ptr;
								await_data <= '1';
								state <= STATE_CYCLE_END;
							when X"40" =>
								DONE <= '1';
								state <= STATE_STOP;
							when others =>
								pc <= pc + 1;
								state <= STATE_FETCH;
						end case;
					else
						await_data <= '0';
					end if;
				when STATE_INC_MEM =>
					if await_data = '0' then
						DATA_EN <= '1';
						DATA_RDWR <= '0';
						DATA_ADDR <= ptr;
						DATA_WDATA <= DATA_RDATA + 1;
						pc <= pc + 1;
						state <= STATE_FETCH;
					else
						await_data <= '0';
					end if;
				when STATE_DEC_MEM =>
					if await_data = '0' then
						DATA_EN <= '1';
						DATA_RDWR <= '0';
						DATA_ADDR <= ptr;
						DATA_WDATA <= DATA_RDATA - 1;
						pc <= pc + 1;
						state <= STATE_FETCH;
					else
						await_data <= '0';
					end if;
				when STATE_OUTPUT =>
					if await_data = '0' then
						if OUT_BUSY = '1' then
							DATA_EN <= '1';
							DATA_RDWR <= '1';
							DATA_ADDR <= ptr;
						else
							OUT_WE <= '1';
							OUT_DATA <= DATA_RDATA;
							pc <= pc + 1;
							state <= STATE_FETCH;
						end if;
					else
						await_data <= '0';
					end if;
				when STATE_INPUT =>
					if IN_VLD = '1' then
						DATA_EN <= '1';
						DATA_RDWR <= '0';
						DATA_ADDR <= ptr;
						DATA_WDATA <= IN_DATA;
						IN_REQ <= '0';
						pc <= pc + 1;
						state <= STATE_FETCH;
					end if;
				when STATE_WHILE_START =>
					if await_data = '0' then
						if DATA_RDATA = X"00" then
							cnt <= X"01";
							DATA_EN <= '1';
							DATA_RDWR <= '1';
							DATA_ADDR <= pc;
							await_data <= '1';
							state <= STATE_WHILE_LOOP;
						else
							if ras_top < 15 then
								ras(ras_top) <= pc;
								ras_top <= ras_top + 1;
							end if;
							state <= STATE_FETCH;
						end if;
					else
						await_data <= '0';
					end if;
				when STATE_WHILE_LOOP =>
					if await_data = '0' then
						if cnt /= 0 then
							if DATA_RDATA = X"5B" then
								cnt <= cnt + 1;
							elsif DATA_RDATA = X"5D" then
								cnt <= cnt - 1;
							end if;
							DATA_EN <= '1';
							DATA_RDWR <= '1';
							DATA_ADDR <= pc;
							await_data <= '1';
							pc <= pc + 1;
						else
							state <= STATE_FETCH;
						end if;
					else
						await_data <= '0';
					end if;
				when STATE_CYCLE_END =>
					if await_data = '0' then
						if DATA_RDATA = X"00" then
							pc <= pc + 1;
							if ras_top > 0 then
								ras_top <= ras_top - 1;
							end if;
						else
							if ras_top > 0 then
								pc <= ras(ras_top-1);
							end if;
						end if;
						state <= STATE_FETCH;
					else
						await_data <= '0';
					end if;
				when STATE_STOP =>
					DONE <= '1';
			end case;
		end if;
	end if;
end process;
end architecture;