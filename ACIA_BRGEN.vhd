library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ACIA_BRGEN is
  port (
    RESET     : in     std_logic;
    XTLI      : in     std_logic;
    BCLK      : buffer std_logic;
    R_SBR     : in     std_logic_vector(3 downto 0)
    );
end ACIA_BRGEN;


architecture rtl of ACIA_BRGEN is
signal r_clk : integer range 0 to (36864-1)/32 := 0;
signal r_bclk : std_logic := '0';
begin

BCLK <= XTLI WHEN (R_SBR = "000") ELSE r_bclk;

proc_ACIA_BRGEN : process (XTLI,RESET)
begin
  if (RESET = '0') then
    r_clk <= 0;
    r_bclk <= '0';
  elsif rising_edge(XTLI) then
    if (r_clk = 0) then
      r_bclk <= NOT r_bclk;
    case R_SBR is
      when "0000" =>
        r_clk <= 0;

      when "0001" =>
        r_clk <= (36864-1)/32;

      when "0010" =>
        r_clk <= (24576-1)/32;

      when "0011" =>
        r_clk <= (16769-1)/32;

      when "0100" =>
        r_clk <= (13704-1)/32;

      when "0101" =>
        r_clk <= (12288-1)/32;

      when "0110" =>
        r_clk <= (6144-1)/32;

      when "0111" =>
        r_clk <= (3072-1)/32;

      when "1000" =>
        r_clk <= (1536-1)/32;

      when "1001" =>
        r_clk <= (1024-1)/32;

      when "1010" =>
        r_clk <= (768-1)/32;

      when "1011" =>
        r_clk <= (512-1)/32;

      when "1100" =>
        r_clk <= (384-1)/32;

      when "1101" =>
        r_clk <= (256-1)/32;

      when "1110" =>
        r_clk <= (192-1)/32;

      when "1111" =>
        r_clk <= (96-1)/32;

    when others =>
      r_clk <= 0;

    end case;
    else
      r_clk <= r_clk - 1;
    end if;
  end if;
end process;
end rtl;
