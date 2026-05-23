library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity top_without_mem is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;

    valid_in  : in  std_logic;
    x         : in  x_w_array(0 to N-1);
    w         : in  x_w_array(0 to N-1);

    valid_out : out std_logic;
    y         : out signed(Y_WIDTH_TRUNC-1 downto 0)
  );
end entity top_without_mem;

architecture rtl of top_without_mem is
  signal w_reg : x_w_array(0 to N-1) := (others => (others => '0'));
  signal loaded : std_logic := '0';

  signal valid_in_gated : std_logic;
begin

  -- Load weights once after reset
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        w_reg   <= (others => (others => '0'));
        loaded  <= '0';
      else
        if loaded = '0' then
          w_reg  <= w;
          loaded <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Only allow valid data after weights are loaded
  valid_in_gated <= valid_in and loaded;

  U_MAC : entity work.mac_csa
    port map (
      clk       => clk,
      rst       => rst,
      valid_in  => valid_in_gated,
      x         => x,
      w         => w_reg,
      valid_out => valid_out,
      y         => y
    );

end architecture rtl;