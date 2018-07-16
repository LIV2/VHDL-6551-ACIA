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
    TXLATCH : in     std_logic;
    TXFULL  : out    std_logic
    );
end ACIA_TX;


architecture rtl of ACIA_TX is
type t_tx_fsm is (state_Idle, state_Start, state_Data, state_Stop);
signal r_tx_fsm      : t_tx_fsm := state_Idle;
signal r_clk         : integer range 0 to 15 := 0;
signal r_bitcnt      : integer range 0 to 7 := 0;
signal r_tx_shiftreg : std_logic_vector (7 downto 0) := "00000000";
signal r_txdata      : std_logic_vector (7 downto 0) := "00000000";
signal r_txready     : std_logic := '0';
signal r_txtaken     : std_logic := '0';

begin

proc_r_txdata : process (PHI2,RESET)
begin
  if RESET = '0' then
    r_txdata <= (others => '0');
    TXFULL <= '0';
  elsif rising_edge(PHI2) then
    if TXLATCH = '1' then
      r_txdata <= TXDATA;
      r_txready <= '1';
      TXFULL <= '1';
    else
      if (r_txready = '1' and r_txtaken = '1') then
        r_txready <= '0';
        --elsif (r_txready='0' and r_txtaken ='0') then
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
  elsif rising_edge(BCLK) then
    case r_tx_fsm is
      when state_Idle =>
        TX <= '1';
        r_clk <= 0;

        if r_txready = '1' and CTSB = '0' then
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
          r_clk <= 0;
          if r_bitcnt < 7 then
            r_tx_shiftreg (6 downto 0) <= r_tx_shiftreg (7 downto 1);
            r_tx_shiftreg (7) <= '0';
            r_bitcnt <= r_bitcnt + 1;
            r_tx_fsm <= state_Data;
          else
            r_bitcnt <= 0;
            r_tx_fsm <= state_Stop;
          end if;
        end if;

      when state_Stop =>
        TX <= '1';
        if r_clk = 15 then
          r_tx_fsm <= state_Idle;
          r_clk <= 0;
        else
          r_clk <= r_clk + 1;
        end if;

      when others =>
        r_tx_fsm <= state_Idle;
    end case;
  end if;
end process;
end rtl;