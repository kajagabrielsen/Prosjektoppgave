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
  signal products  : p_array_trunc(0 to N-1);
  signal valid_reg : std_logic := '0';
  signal products_reg : p_array_trunc(0 to N-1);
  signal sum_reg : signed(Y_WIDTH_TRUNC-1 downto 0);
begin


  gen_mul : for i in 0 to N-1 generate
    signal full_prod_i : signed(P_WIDTH-1 downto 0);
  begin
    full_prod_i <= x(i) * w(i);
    products(i) <= full_prod_i(P_WIDTH-1 downto TRUNC_BITS);
  end generate;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        products_reg <= (others => (others => '0'));
        valid_reg <= '0';
      else
        valid_reg <= valid_in;
        if valid_in = '1' then
          products_reg <= products;
        end if;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
            sum_reg   <= (others => '0');
            valid_out <= '0';

      else
            valid_out <= valid_reg;

        if valid_reg = '1' then
            sum_reg <=
            resize(products_reg(0), Y_WIDTH_TRUNC) +
            resize(products_reg(1), Y_WIDTH_TRUNC) +
            resize(products_reg(2), Y_WIDTH_TRUNC) +
            resize(products_reg(3), Y_WIDTH_TRUNC) +
            resize(products_reg(4), Y_WIDTH_TRUNC) +
            resize(products_reg(5), Y_WIDTH_TRUNC) +
            resize(products_reg(6), Y_WIDTH_TRUNC) +
            resize(products_reg(7), Y_WIDTH_TRUNC) +
            resize(products_reg(8), Y_WIDTH_TRUNC);
        end if;
      end if;
    end if;
  end process;

y <= sum_reg;

    
end architecture rtl;