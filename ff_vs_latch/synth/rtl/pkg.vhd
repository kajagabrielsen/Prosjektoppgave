library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg is
  constant K    : natural := 3;
  constant N    : natural := K*K;     -- 9

  constant X_W_WIDTH  : natural := 8;
  constant TRUNC_BITS : natural := 0;
  constant P_WIDTH  : natural := 2*(X_W_WIDTH);
  constant P_WIDTH_TRUNC : natural := P_WIDTH - TRUNC_BITS;
  constant Y_WIDTH  : natural := P_WIDTH + 4; -- ceil(log2(9)) ~ 4 => safe
  constant Y_WIDTH_TRUNC  : natural := P_WIDTH_TRUNC + 4; -- ceil(log2(9)) ~ 4 => safe
  
  type x_w_array is array (natural range <>) of signed(X_W_WIDTH-1 downto 0);

  -- array of products to send to CSA (w/wo trunc)
  type p_array is array (natural range <>) of signed(P_WIDTH-1 downto 0);
  type p_array_trunc is array (natural range <>) of signed(P_WIDTH_TRUNC-1 downto 0); --14 bits for each produkt after 8*8= 16 bits - 2

  -- for TB
  constant QDEPTH : natural := 256;
  type exp_q_t is array (0 to QDEPTH-1) of signed(Y_WIDTH_TRUNC-1 downto 0);
  
end package pkg;

package body pkg is
end package body pkg;
