library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity mac_csa is
  port(
    clk      : in  std_logic;
    rst      : in  std_logic;

    valid_in : in  std_logic;
    x        : in  x_w_array(0 to N-1);
    w        : in  x_w_array(0 to N-1);

    valid_out : out std_logic;
    y         : out signed(Y_WIDTH_TRUNC-1 downto 0)
  );
end entity mac_csa;

architecture rtl of mac_csa is
  signal x_reg     : x_w_array(0 to N-1) := (others => (others => '0'));
  signal products  : p_array_trunc(0 to N-1);
  signal valid_reg : std_logic := '0';
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        x_reg <= (others => (others => '0'));
        valid_reg <= '0';
      else
        valid_reg <= valid_in;
        if valid_in = '1' then
          x_reg <= x;
        end if;
      end if;
    end if;
  end process;

  gen_mul : for i in 0 to N-1 generate
    signal full_prod_i : signed(P_WIDTH-1 downto 0);
  begin
    full_prod_i <= x_reg(i) * w(i);
    products(i) <= full_prod_i(P_WIDTH-1 downto TRUNC_BITS);
  end generate;

  U_CSA : entity work.csa_tree
    port map(
      clk       => clk,
      rst       => rst,
      valid_in  => valid_reg,
      p         => products,
      valid_out => valid_out,
      sum       => y
    );
end architecture rtl;