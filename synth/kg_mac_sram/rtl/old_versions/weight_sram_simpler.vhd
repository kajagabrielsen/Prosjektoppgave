--only one register without the addressing logic
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity weight_sram is
  port (
    clk  : in  std_logic;
    we   : in  std_logic;
    din  : in  std_logic_vector(N*X_W_WIDTH-1 downto 0);
    dout : out std_logic_vector(N*X_W_WIDTH-1 downto 0)
  );
end entity weight_sram;

architecture rtl of weight_sram is
  signal weight_reg : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        weight_reg <= din;
      end if;
    end if;
  end process;

  dout <= weight_reg;

end architecture;