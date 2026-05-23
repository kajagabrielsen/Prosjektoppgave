--top_with_activation_buffer_tb_ff_row_wise_3x8
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.pkg.all;

entity top_with_activation_buffer_tb is
end entity top_with_activation_buffer_tb;

architecture tb of top_with_activation_buffer_tb is

  constant IMG_W : integer := 28;
  constant IMG_H : integer := 28;
  constant K     : integer := 3;

  constant OUT_W : integer := IMG_W - K + 1;
  constant OUT_H : integer := IMG_H - K + 1;

  type image_t is array (0 to IMG_H-1, 0 to IMG_W-1)
    of signed(X_W_WIDTH-1 downto 0);

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';

  signal mem_we   : std_logic := '0';
  signal mem_addr : unsigned(0 downto 0) := (others => '0');
  signal mem_din  : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');

  signal valid_in    : std_logic := '0';
  signal load_full   : std_logic := '0';
  signal shift_horiz : std_logic := '0';

  signal x_full : x_w_array(0 to N-1);

  signal x_col0 : signed(X_W_WIDTH-1 downto 0) := (others => '0');
  signal x_col1 : signed(X_W_WIDTH-1 downto 0) := (others => '0');
  signal x_col2 : signed(X_W_WIDTH-1 downto 0) := (others => '0');

  signal valid_out : std_logic;
  signal y         : signed(Y_WIDTH_TRUNC-1 downto 0);

  signal exp_q : exp_q_t := (others => (others => '0'));
  signal wptr  : integer := 0;
  signal rptr  : integer := 0;

  signal sent_count   : integer := 0;
  signal recv_count   : integer := 0;
  signal sending_done : std_logic := '0';

  file fweights : text open read_mode is "weights.txt";
  file fin      : text open read_mode is "input_image.txt";
  file fout     : text open read_mode is "expected_out.txt";

begin

  dut : entity work.top_with_activation_buffer
    port map (
      clk         => clk,
      rst         => rst,
      mem_we      => mem_we,
      mem_addr    => mem_addr,
      mem_din     => mem_din,
      valid_in    => valid_in,
      load_full   => load_full,
      shift_horiz => shift_horiz,
      x_full      => x_full,
      x_col0      => x_col0,
      x_col1      => x_col1,
      x_col2      => x_col2,
      valid_out   => valid_out,
      y           => y
    );

  clk <= not clk after 0.5 ns;

  --------------------------------------------------------------------
  -- Output checker
  --------------------------------------------------------------------
  checker : process
  begin
    wait until falling_edge(clk);
    wait for 1 ps;

    if rst = '1' then
      rptr       <= 0;
      recv_count <= 0;

    elsif valid_out = '1' then

      if y /= exp_q(rptr) then
        report "MISMATCH: recv_count=" &
          integer'image(recv_count) &
          " rptr=" &
          integer'image(rptr) &
          " sent_count=" &
          integer'image(sent_count) &
          " got " &
          integer'image(to_integer(y)) &
          " expected " &
          integer'image(to_integer(exp_q(rptr)))
          severity error;
      end if;

      rptr       <= (rptr + 1) mod QDEPTH;
      recv_count <= recv_count + 1;

    end if;
  end process;

  --------------------------------------------------------------------
  -- Stimulus
  --------------------------------------------------------------------
  stim : process
    variable Lw     : line;
    variable Lin    : line;
    variable Lout   : line;

    variable vi     : integer;
    variable expi   : integer;
    variable w_word : std_logic_vector(N*X_W_WIDTH-1 downto 0);

    variable img    : image_t;
  begin

    ------------------------------------------------------------------
    -- Initial values
    ------------------------------------------------------------------
    for i in 0 to N-1 loop
      x_full(i) <= (others => '0');
    end loop;

    x_col0 <= (others => '0');
    x_col1 <= (others => '0');
    x_col2 <= (others => '0');

    mem_we      <= '0';
    mem_addr    <= (others => '0');
    mem_din     <= (others => '0');

    valid_in    <= '0';
    load_full   <= '0';
    shift_horiz <= '0';

    wait for 2 ns;

    ------------------------------------------------------------------
    -- Read weights
    ------------------------------------------------------------------
    if endfile(fweights) then
      report "weights.txt is empty" severity failure;
    end if;

    readline(fweights, Lw);

    w_word := (others => '0');

    for i in 0 to N-1 loop
      read(Lw, vi);
      w_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH) :=
        std_logic_vector(to_signed(vi, X_W_WIDTH));
    end loop;

    ------------------------------------------------------------------
    -- Program weight SRAM
    ------------------------------------------------------------------
    wait until falling_edge(clk);

    mem_addr <= (others => '0');
    mem_din  <= w_word;
    mem_we   <= '1';

    wait until rising_edge(clk);
    wait until falling_edge(clk);

    mem_we  <= '0';
    mem_din <= (others => '0');

    ------------------------------------------------------------------
    -- Read full input image into TB memory
    ------------------------------------------------------------------
    for r in 0 to IMG_H-1 loop
      if endfile(fin) then
        report "input_image.txt ended too early" severity failure;
      end if;

      readline(fin, Lin);

      for c in 0 to IMG_W-1 loop
        read(Lin, vi);
        img(r, c) := to_signed(vi, X_W_WIDTH);
      end loop;
    end loop;

    ------------------------------------------------------------------
    -- Release reset
    ------------------------------------------------------------------
    wait until falling_edge(clk);
    rst <= '0';

    wait until falling_edge(clk);
    wait until falling_edge(clk);

    valid_in <= '1';

    ------------------------------------------------------------------
    -- Generate sliding-window inputs
    --
    -- For each output row:
    --   first output column: load_full = 1, send full 3x3 window
    --   next 25 columns:    shift_horiz = 1, send new right column
    ------------------------------------------------------------------
    for out_r in 0 to OUT_H-1 loop
      for out_c in 0 to OUT_W-1 loop

        wait until falling_edge(clk);

        load_full   <= '0';
        shift_horiz <= '0';

        if out_c = 0 then

          ------------------------------------------------------------
          -- Start of new output row: reload complete 3x3 window
          ------------------------------------------------------------
          x_full(0) <= img(out_r,     0);
          x_full(1) <= img(out_r,     1);
          x_full(2) <= img(out_r,     2);

          x_full(3) <= img(out_r + 1, 0);
          x_full(4) <= img(out_r + 1, 1);
          x_full(5) <= img(out_r + 1, 2);

          x_full(6) <= img(out_r + 2, 0);
          x_full(7) <= img(out_r + 2, 1);
          x_full(8) <= img(out_r + 2, 2);

          x_col0 <= (others => '0');
          x_col1 <= (others => '0');
          x_col2 <= (others => '0');

          load_full <= '1';

        else

          ------------------------------------------------------------
          -- Horizontal shift: send new rightmost column
          ------------------------------------------------------------
          x_col0 <= img(out_r,     out_c + 2);
          x_col1 <= img(out_r + 1, out_c + 2);
          x_col2 <= img(out_r + 2, out_c + 2);

          shift_horiz <= '1';

        end if;

        --------------------------------------------------------------
        -- Store expected output for this input window
        --------------------------------------------------------------
        if endfile(fout) then
          report "expected_out.txt ended too early" severity failure;
        end if;

        readline(fout, Lout);
        read(Lout, expi);

        exp_q(wptr) <= to_signed(expi, Y_WIDTH_TRUNC);
        wptr <= (wptr + 1) mod QDEPTH;
        sent_count <= sent_count + 1;

        --------------------------------------------------------------
        -- Hold inputs/control for one clock cycle
        --------------------------------------------------------------
        wait until rising_edge(clk);
        wait until falling_edge(clk);

        load_full   <= '0';
        shift_horiz <= '0';

      end loop;
    end loop;

    ------------------------------------------------------------------
    -- Finish
    ------------------------------------------------------------------
    wait until falling_edge(clk);

    valid_in <= '0';
    sending_done <= '1';

    wait for 20 ns;

    report "Sent vectors     = " & integer'image(sent_count);
    report "Received outputs = " & integer'image(recv_count);

    assert false report "TB DONE" severity failure;

  end process;

end architecture;