library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ACIA_TX is
  port (
    RESET   : in     std_logic;
    PHI2    : in     std_logic;
    BCLK    : in     std_logic;
    CTSB    : in     std_logic;
    TX      : buffer std_logic;
    TXDATA  : in     std_logic_vector(7 downto 0);
    R_PME   : in     std_logic;
    R_PMC   : in     std_logic_vector(1 downto 0);
    R_SBN   : in     std_logic;
    TXLATCH : in     std_logic;
    TXFULL  : out    std_logic
    );
end ACIA_TX;


architecture rtl of ACIA_TX is
type t_tx_fsm is (state_Idle, state_Start, state_Data, state_Parity, state_Stop, state_Stop2);
signal r_tx_fsm      : t_tx_fsm := state_Idle;
signal r_clk         : integer range 0 to 15 := 0;
signal r_bitcnt      : integer range 0 to 7 := 0;
signal r_tx_shiftreg : std_logic_vector (7 downto 0) := "00000000";
signal r_tx_parity   : std_logic;
signal r_txdata      : std_logic_vector (7 downto 0) := "00000000";
signal r_txready     : std_logic := '0';
signal r_txtaken     : std_logic := '0';
signal r_txready_s   : std_logic := '0';
signal r_txtaken_s   : std_logic := '0';

begin

proc_r_txdata : process (PHI2,RESET)
begin
  if RESET = '0' then
    r_txdata <= (others => '0');
    TXFULL <= '0';
  elsif rising_edge(PHI2) then
    r_txtaken_s <= r_txtaken;
    if TXLATCH = '1' then
      r_txdata <= TXDATA;
      r_txready <= '1';
      TXFULL <= '1';
    else
      if (r_txready = '1' and r_txtaken_s = '1') then
        r_txready <= '0';
        TXFULL <= '0';
      end if;
    end if;
  end if;
end process;

proc_ACIA_TX : process (BCLK,RESET)
begin
  if RESET = '0' then
    r_clk <= 0;
    r_bitcnt <= 0;
    r_tx_fsm <= state_Idle;
    r_txtaken <= '0';
    r_tx_parity <= '0';
  elsif rising_edge(BCLK) then
    r_txready_s <= r_txready;
    case r_tx_fsm is
      when state_Idle =>
        TX <= '1';
        r_clk <= 0;
        r_tx_parity <= '0';
        if r_txready_s = '1' and CTSB = '0' then
          r_tx_shiftreg <= r_TXDATA;
          r_tx_fsm <= state_Start;
          r_txtaken <= '1';
        end if;

      when state_Start =>
        TX <= '0';
        r_txtaken <= '0';
        if r_clk = 15 then
          r_tx_fsm <= state_Data;
          r_clk <= 0;
        else
          r_clk <= r_clk + 1;
        end if;

      when state_Data =>
        TX <= r_tx_shiftreg (0);
        if r_clk < 15 then
          r_clk <= r_clk + 1;
          r_tx_fsm <= state_Data;
        else
          r_tx_parity <= r_tx_parity XOR r_tx_shiftreg (0);
          r_clk <= 0;
          if r_bitcnt < 7 then
            r_tx_shiftreg (6 downto 0) <= r_tx_shiftreg (7 downto 1);
            r_tx_shiftreg (7) <= '0';
            r_bitcnt <= r_bitcnt + 1;
            r_tx_fsm <= state_Data;
          else
            r_bitcnt <= 0;
            if R_PME = '1' then
              r_tx_fsm <= state_Parity;
            else
              r_tx_fsm <= state_Stop;
            end if;
          end if;
        end if;

      when state_Parity =>
        case R_PMC is
          when "00" =>
            -- Odd Parity
            TX <= NOT r_tx_parity;

          when "01" =>
            -- Even Parity
            TX <= r_tx_parity;

          when "10" =>
            -- Mark Parity
            TX <= '1';

          when "11" =>
            -- Space Parity
            TX <= '0';

          when others =>
            TX <= r_tx_parity;

        end case;
        if r_clk < 15 then
          r_tx_fsm <= state_Parity;
          r_clk <= r_clk + 1;
        else
          r_clk <= 0;
          r_tx_fsm <= state_Stop;
        end if;

      when state_Stop =>
        TX <= '1';
        if r_clk = 15 then
          r_clk <= 0;
          if (R_SBN = '1') AND (R_PME = '0') then
            r_tx_fsm <= state_Stop2;
          else
            r_tx_fsm <= state_Idle;
          end if;
        else
          r_clk <= r_clk + 1;
        end if;

      when state_Stop2 =>
        if r_clk = 15 then
          r_clk <= 0;
          r_tx_fsm <= state_Idle;
        else
          r_clk <= r_clk + 1;
          r_tx_fsm <= state_Stop2;
        end if;

      when others =>
        r_tx_fsm <= state_Idle;
    end case;
  end if;
end process;
end rtl;
