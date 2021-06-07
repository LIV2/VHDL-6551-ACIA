----------------------------------------------------------------------------------
-- Engineer: Matt Harlum <Matt@cactuar.net>
--
-- Create Date:    13:10:55 07/10/2018
-- Design Name: 6551 ACIA
-- Module Name:    ACIA - rtl
-- Description: Sythensizable 6551 ACIA
--
--
-- Revision 0.01 - File Created
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity ACIA is
  port (
    RESET   : in     std_logic;
    PHI2    : in     std_logic;
    CS      : in     std_logic;
    RWN     : in     std_logic;
    RS      : in     std_logic_vector(1 downto 0);
    DATAIN  : in     std_logic_vector(7 downto 0);
    DATAOUT : out    std_logic_vector(7 downto 0);
    XTLI    : in     std_logic;
    RTSB    : out    std_logic;
    CTSB    : in     std_logic;
    DTRB    : out    std_logic;
    RXD     : in     std_logic;
    TXD     : buffer std_logic;
    IRQn    : buffer std_logic
   );
end ACIA;

architecture rtl of ACIA is
component ACIA_RX
  port (
    RESET     : in     std_logic;
    BCLK      : in     std_logic;
    PHI2      : in     std_logic;
    RX        : in     std_logic;
    RXDATA    : out    std_logic_vector(7 downto 0);
    RXFULL    : buffer std_logic;
    FRAME     : out    std_logic;
    OVERFLOW  : out    std_logic;
    RXTAKEN   : in     std_logic;
    PARITY    : out    std_logic;
    R_PMC     : in     std_logic_vector(1 downto 0);
    R_PME     : in     std_logic;
    R_SBN     : in     std_logic
    );
end component;

component ACIA_TX is
  port (
    RESET     : in     std_logic;
    BCLK      : in     std_logic;
    PHI2      : in     std_logic;
    CTSB      : in     std_logic;
    TX        : buffer std_logic;
    TXDATA    : in     std_logic_vector(7 downto 0);
    R_PME     : in     std_logic;
    R_PMC     : in     std_logic_vector(1 downto 0);
    R_SBN     : in     std_logic;
    TXLATCH   : in     std_logic;
    TXFULL    : out    std_logic
    );
end component;

component ACIA_BRGEN is
  port (
    RESET     : in     std_logic;
    XTLI      : in     std_logic;
    BCLK      : buffer std_logic;
    R_SBR     : in     std_logic_vector
    );
end component;

signal RXDATA:   std_logic_vector(7 downto 0) := "00000000";
signal TXDATA:   std_logic_vector(7 downto 0) := "00000000";
signal R_SBR:    std_logic_vector(3 downto 0) := "0000";
signal R_WDL:    std_logic_vector(1 downto 0) := "00";
signal R_PMC:    std_logic_vector(1 downto 0) := "00";
signal R_TIC:    std_logic_vector(1 downto 0) := "00";
signal BCLK:     std_logic := '0';
signal RXFULL:   std_logic := '0';
signal FRAME:    std_logic := '0';
signal OVERFLOW: std_logic := '0';
signal PARITY:   std_logic := '0';
signal RXTAKEN:  std_logic := '0';
signal TXLATCH:  std_logic := '0';
signal TXFULL:   std_logic := '0';
signal R_SBN:    std_logic := '0';
signal R_PME:    std_logic := '0';
signal R_REM:    std_logic := '0';
signal R_IRD:    std_logic := '0';
signal R_DTR:    std_logic := '0';
signal R_RCS:    std_logic := '0';

begin

C_RX : ACIA_RX port map (
  RESET => RESET,
  BCLK => BCLK,
  PHI2 => PHI2,
  RX => RXD,
  RXDATA => RXDATA,
  RXFULL => RXFULL,
  FRAME => FRAME,
  OVERFLOW => OVERFLOW,
  RXTAKEN => RXTAKEN,
  PARITY => PARITY,
  R_PMC => R_PMC,
  R_PME => R_PME,
  R_SBN => R_SBN
);

C_TX : ACIA_TX port map (
  RESET => RESET,
  BCLK => BCLK,
  PHI2 => PHI2,
  CTSB => CTSB,
  TX => TXD,
  TXDATA => TXDATA,
  R_PME => R_PME,
  R_PMC => R_PMC,
  TXLATCH => TXLATCH,
  TXFULL => TXFULL,
  R_SBN => R_SBN
);

C_BRGEN : ACIA_BRGEN port map (
  RESET => RESET,
  XTLI => XTLI,
  BCLK => BCLK,
  R_SBR => R_SBR
);
DTRB <= NOT R_DTR;

proc_bus : process (RESET,PHI2,CS)
begin
  if RESET = '0' then
    RXTAKEN <= '0';
  elsif rising_edge(PHI2) then
    if (CS = '0' and RWN = '1') then
      if (rs = "00") then
        DATAOUT <= RXDATA;
        RXTAKEN <= '1';
      elsif (rs = "01") then
      DATAOUT(7) <= NOT IRQn;
      DATAOUT(6) <= '0';
      DATAOUT(5) <= '0';
      DATAOUT(4) <= NOT TXFULL;
      DATAOUT(3) <= RXFULL;
      DATAOUT(2) <= OVERFLOW;
      DATAOUT(1) <= FRAME;
      DATAOUT(0) <= PARITY;
    elsif (rs = "10") then
      DATAOUT(7 downto 6) <= R_PMC;
      DATAOUT(5) <= R_PME;
      DATAOUT(4) <= R_REM;
      DATAOUT(3 downto 2) <= R_TIC;
      DATAOUT(1) <= R_IRD;
      DATAOUT(0) <= R_DTR;
    elsif (rs = "11") then
      DATAOUT(7) <= R_SBN;
      DATAOUT(6 downto 5) <= R_WDL;
      DATAOUT(4) <= R_RCS;
      DATAOUT(3 downto 0) <= R_SBR;
    end if;
    else
      RXTAKEN <= '0';
    end if;
  end if;

  if (RESET = '0') then
    TXLATCH <= '0';
    R_REM <= '0';
    R_TIC <= (others => '0');
    R_IRD <= '0';
    R_DTR <= '0';
    R_SBN <= '0';
    R_WDL <= (others => '0');
    R_RCS <= '0';
    R_SBR <= (others => '0');
    RTSB <= '1';
  elsif falling_edge(PHI2) then
    if (CS = '0' and RWN = '0') then
      if (rs = "00") then
        TXDATA <= DATAIN;
        TXLATCH <= '1';
      elsif (rs = "01") then
        --- RESET ---
      elsif (rs = "10") then
        R_PMC <= DATAIN(7 downto 6);
        R_PME <= DATAIN(5);
        R_REM <= DATAIN(4);
        R_TIC <= DATAIN(3 downto 2);
        R_IRD <= DATAIN(1);
        R_DTR <= DATAIN(0);
        if DATAIN(3 downto 2) = "00" then
        RTSB <= '1';
      else
        RTSB <= '0';
      end if;
      elsif (rs = "11") then
        R_SBN <= DATAIN(7);
        R_WDL <= DATAIN(6 downto 5);
        R_RCS <= DATAIN(4);
        R_SBR <= DATAIN(3 downto 0);
      end if;
    else
      TXLATCH <= '0';
    end if;
  end if;
end process;

IRQn <= '0' WHEN (((TXFULL = '0' AND R_TIC = "01") OR (RXFULL = '1' AND R_IRD = '0')) AND R_DTR = '1') else '1';
end rtl;
