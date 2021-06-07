library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ACIA_RX is
  port (
    RESET     : in     std_logic;
    PHI2      : in     std_logic;
    BCLK      : in     std_logic;
    RX        : in     std_logic;
    RXDATA    : out    std_logic_vector(7 downto 0);
    RXFULL    : buffer std_logic;
    RXTAKEN   : in     std_logic;
    FRAME     : out    std_logic;
    OVERFLOW  : out    std_logic;
    PARITY    : out    std_logic;
    R_PMC     : in     std_logic_vector(1 downto 0);
    R_PME     : in     std_logic;
    R_SBN     : in     std_logic
    );
end ACIA_RX;


architecture rtl of ACIA_RX is
type t_rx_fsm is (state_Idle, state_Start, state_Data, state_Parity, state_Stop, state_Stop2);
signal r_rx_fsm      : t_rx_fsm := state_Idle;
signal r_clkdiv      : integer range 0 to 15 := 0;
signal r_bitcnt      : integer range 0 to 7 := 0;
signal r_rx_shiftreg : std_logic_vector (7 downto 0) := "00000000";
signal r_rx_parity   : std_logic := '0';
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
    FRAME <= '0';
    OVERFLOW <= '0';
    PARITY <= '0';
    r_rxreceive <= '0';
  elsif rising_edge(BCLK) then
    case r_rx_fsm is
      when state_Idle =>
        r_rx_parity <= '0';
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
          r_rx_parity <= r_rx_parity XOR RX;
          if r_bitcnt < 7 then
            r_bitcnt <= r_bitcnt + 1;
            r_rx_fsm <= state_Data;
          else
            r_bitcnt <= 0;
            if R_PME = '0' then
              r_rx_fsm <= state_Stop;
            else
              r_rx_fsm <= state_Parity;
            end if;
          end if;
        end if;

      when state_Parity =>
        if r_clkdiv = 15 then
          if R_PMC(1) = '1' then
            -- RX Parity ignored
            PARITY <= '0';
          elsif R_PMC(0) = '0' then
            --- Odd Parity
            if r_rx_parity = NOT RX then
              PARITY <= '0';
            else
              PARITY <= '1';
            end if;
          else
            -- Even Parity
            if r_rx_parity = RX then
              PARITY <= '0';
            else
              PARITY <= '1';
            end if;
          end if;
          r_clkdiv <= 0;
          r_rx_fsm <= state_Stop;

        else
          r_clkdiv <= r_clkdiv + 1;
        end if;

      when state_Stop =>
        if r_clkdiv = 15 then
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
          r_clkdiv <= 0;
          if (R_SBN = '1') AND (R_PME = '0') then
            r_rx_fsm <= state_Stop2;
          else
            r_rx_fsm <= state_Idle;
          end if;
          r_clkdiv <= 0;
        else
          r_clkdiv <= r_clkdiv + 1;
        end if;

      when state_Stop2 =>
        if r_clkdiv = 15 then
          r_clkdiv <= 0;
          r_rx_fsm <= state_Idle;
        else
          r_clkdiv <= r_clkdiv + 1;
          r_rx_fsm <= state_Stop2;
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
