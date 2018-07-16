library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ACIA_RX is
  port (
    RESET     : in  std_logic;
    PHI2      : in  std_logic;
    BCLK      : in  std_logic;
    RX        : in std_logic;
    RXDATA    : out std_logic_vector(7 downto 0);
    RXFULL    : buffer std_logic;
    RXTAKEN   : in std_logic;
    FRAME     : out std_logic;
    OVERFLOW  : out std_logic
    );
end ACIA_RX;


architecture rtl of ACIA_RX is
type t_rx_fsm is (state_Idle, state_Start, state_Data, state_Stop);
signal r_rx_fsm      : t_rx_fsm := state_Idle;
signal r_clkdiv      : integer range 0 to 15 := 0;
signal r_bitcnt      : integer range 0 to 7 := 0;
signal r_rx_shiftreg : std_logic_vector (7 downto 0) := "00000000";
signal r_rxdone      : std_logic := '0';
signal r_rxreq       : std_logic := '0';
signal r_rxreceive   : std_logic := '0';

begin
proc_ACIA_RX : process (BCLK,RESET)
begin
  if RESET = '0' then
    r_clkdiv <= 0;
    r_bitcnt <= 0;
    rxdata <= (others => '0');
    r_rx_shiftreg <= (others => '0');
    r_rx_fsm <= state_Idle;
    r_rxdone <= '0';
    FRAME <= '0';
    OVERFLOW <= '0';
    r_rxreceive <= '0';
  elsif rising_edge(BCLK) then
    case r_rx_fsm is
      when state_Idle =>
        r_rxreceive <= '0';
        r_clkdiv <= 0;
        if RX = '0' then
          r_rx_fsm <= state_Start;
        end if;
      when state_Start =>
        if r_clkdiv = 7 then
          if RX = '0' then
            r_rx_fsm <= state_Data;
            r_clkdiv <= 0;
          else
            r_rx_fsm <= state_Idle;
          end if;
        else
          r_clkdiv <= r_clkdiv + 1;
        end if;
      
      when state_Data =>
          r_rxreceive <= '1';
        if r_clkdiv < 15 then
          r_clkdiv <= r_clkdiv + 1;
          r_rx_fsm <= state_Data;
        else
          r_clkdiv <= 0;
          r_rx_shiftreg (6 downto 0) <= r_rx_shiftreg (7 downto 1);
          r_rx_shiftreg (7) <= RX;
          if r_bitcnt < 7 then
            r_bitcnt <= r_bitcnt + 1;
            r_rx_fsm <= state_Data;
          else
            r_bitcnt <= 0;
            r_rx_fsm <= state_Stop;
          end if;
        end if;

      when state_Stop =>
        if r_clkdiv = 15 then
          r_rxreceive <= '0';
          r_rxdone <= '1';
          if RX = '0' then
            FRAME <= '1';
          else
            FRAME <= '0';
          end if;
          if RXFULL = '1' then
            OVERFLOW <= '1';
          else
            RXDATA <= r_rx_shiftreg;
            OVERFLOW <= '0';
          end if;
          r_rx_fsm <= state_Idle;
          r_clkdiv <= 0;
        else
          r_clkdiv <= r_clkdiv + 1;
        end if;

      when others =>
        r_rxreceive <= '0';
        r_rx_fsm <= state_Idle;
    end case;
  end if;
end process;

proc_RXFULL : process (PHI2,RXTAKEN,RESET)
begin
if RESET = '0' then
  RXFULL <= '0';
  r_rxreq <= '0';
elsif rising_edge(PHI2) then
  if RXTAKEN = '1' then
    RXFULL <= '0';
    r_rxreq <= '1';
  elsif r_rxreq = '1' and r_rxreceive = '1' then
    r_rxreq <= '0';
  elsif r_rxreq = '0' and r_rxreceive = '0' then
    RXFULL <= '1';
  end if;
end if;
end process;
end rtl;