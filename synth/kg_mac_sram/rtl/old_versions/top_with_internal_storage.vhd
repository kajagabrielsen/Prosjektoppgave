library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity top_mac_with_weight_sram is
  port (
    clk  : in std_logic;
    rst  : in std_logic;

    -- SRAM programming interface (from TB)
    mem_we   : in std_logic; --write enable
    mem_addr : in unsigned(0 downto 0);
    mem_din  : in std_logic_vector(N*X_W_WIDTH-1 downto 0); --9 weights på 8 bits = 72 bits

    -- streaming activations
    valid_in : in std_logic;
    x        : in x_w_array(0 to N-1);

    -- output
    valid_out : out std_logic;
    y         : out signed(Y_WIDTH_TRUNC-1 downto 0)
  );
end entity top_mac_with_weight_sram;

architecture rtl of top_mac_with_weight_sram is
  -- SRAM interface
  signal mem_word  : std_logic_vector(N*X_W_WIDTH-1 downto 0);
  signal mem_reg_word : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');

  -- unpacked weights to MAC
  signal mem_reg : x_w_array(0 to N-1);

  -- simple control: load once after reset
  signal loaded : std_logic := '0';

  --logic for valid_in and loaded
  signal valid_in_gated : std_logic;

begin

  U_SRAM : entity work.weight_sram
    generic map (
      DEPTH => 1,
      ADDR_WIDTH => 1
    )
    port map (
      clk  => clk,
      we   => mem_we,                 -- we, addr, din kommer fra TB
      addr => mem_addr,
      din  => mem_din,
      dout => mem_word
    );

  
  valid_in_gated <= valid_in and loaded;

  -- capture the SRAM output once (after it becomes valid)
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        loaded <= '0';
        mem_reg_word <= (others => '0');
      else
        if loaded = '0' then
          -- after 1 cycle, mem_word holds mem[0]; latch it
          mem_reg_word <= mem_word;
          loaded <= '1';
        end if;
      end if;
    end if;
  end process;

  -- unpack latched word into signed weights
  gen_unpack : for i in 0 to N-1 generate
  begin
    mem_reg(i) <= signed(mem_reg_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH));
  end generate;

  -- MAC
  U_MAC : entity work.mac_csa
    port map (
      clk       => clk,
      rst       => rst,
      valid_in  => valid_in_gated,
      x         => x,
      w         => mem_reg,
      valid_out => valid_out,
      y         => y
    );

end architecture rtl;



