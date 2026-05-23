library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity csa_tree is
  port(
    clk     : in  std_logic;
    rst     : in  std_logic;

    valid_in : in  std_logic;
    p        : in  p_array_trunc(0 to N-1);

    valid_out : out std_logic;
    sum       : out signed(Y_WIDTH_TRUNC-1 downto 0)
  );
end entity csa_tree;

architecture rtl of csa_tree is
  -- CSA 3:2 primitive
  procedure csa3(
    a, b, c : in  signed;
    signal s  : out signed;
    signal co : out signed
  ) is
    variable a_ext, b_ext, c_ext : signed(s'range);
    variable carry               : signed(s'range);
  begin
    a_ext := resize(a, s'length);
    b_ext := resize(b, s'length);
    c_ext := resize(c, s'length);

    s <= a_ext xor b_ext xor c_ext;
    carry := (a_ext and b_ext) or (a_ext and c_ext) or (b_ext and c_ext);
    co <= carry(carry'high-1 downto carry'low) & '0'; -- <<1
  end procedure;

  -- Stage 0: 9 -> 6 (3 CSAs)
  signal s10, c10, s11, c11, s12, c12 : signed(Y_WIDTH_TRUNC-1 downto 0);
  signal s10_r, c10_r, s11_r, c11_r, s12_r, c12_r : signed(Y_WIDTH_TRUNC-1 downto 0);

  -- Stage 1: 6 -> 4 (2 CSAs)
  signal t20, t21, t22, t23 : signed(Y_WIDTH_TRUNC-1 downto 0);
  signal t20_r, t21_r, t22_r, t23_r : signed(Y_WIDTH_TRUNC-1 downto 0);

  -- Stage 2: 4 -> 3 (1 CSA + passthrough)
  signal u30, u31 : signed(Y_WIDTH_TRUNC-1 downto 0);
  signal u30_r, u31_r, t23_r2 : signed(Y_WIDTH_TRUNC-1 downto 0);

  -- Stage 3: 3 -> 2 (1 CSA)
  signal v40, v41 : signed(Y_WIDTH_TRUNC-1 downto 0);

  -- Final CPA register
  signal sum_r : signed(Y_WIDTH_TRUNC-1 downto 0) := (others => '0');

  -- Valid pipeline (S0 regs, S1 regs, S2 regs, CPA reg)
  signal v : std_logic_vector(3 downto 0) := (others => '0');
begin
  -- combinational CSA network
  csa3(p(0), p(1), p(2), s10, c10);
  csa3(p(3), p(4), p(5), s11, c11);
  csa3(p(6), p(7), p(8), s12, c12);

  csa3(s10_r, c10_r, s11_r, t20, t21);
  csa3(c11_r, s12_r, c12_r, t22, t23);

  csa3(t20_r, t21_r, t22_r, u30, u31);

  csa3(u30_r, u31_r, t23_r2, v40, v41);

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        v <= (others => '0');

        s10_r <= (others => '0'); c10_r <= (others => '0');
        s11_r <= (others => '0'); c11_r <= (others => '0');
        s12_r <= (others => '0'); c12_r <= (others => '0');

        t20_r <= (others => '0'); t21_r <= (others => '0');
        t22_r <= (others => '0'); t23_r <= (others => '0');

        u30_r <= (others => '0'); u31_r <= (others => '0');
        t23_r2 <= (others => '0');

        sum_r <= (others => '0');
      else
        -- shift valid
        v <= v(2 downto 0) & valid_in;

        -- stage 0 regs
        if valid_in = '1' then
          s10_r <= s10;  c10_r <= c10;
          s11_r <= s11;  c11_r <= c11;
          s12_r <= s12;  c12_r <= c12;
        end if;

        -- stage 1 regs
        if v(0) = '1' then
          t20_r <= t20;  t21_r <= t21;
          t22_r <= t22;  t23_r <= t23;
        end if;

        -- stage 2 regs
        if v(1) = '1' then
          u30_r <= u30;
          u31_r <= u31;
          t23_r2 <= t23_r;
        end if;

        -- final CPA reg
        if v(2) = '1' then
          sum_r <= v40 + v41;
        end if;
      end if;
    end if;
  end process;

  sum <= sum_r;
  valid_out <= v(3);
end architecture rtl;
