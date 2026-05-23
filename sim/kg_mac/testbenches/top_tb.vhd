library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.pkg.all;

entity top_mac_with_weight_sram_tb is
end entity top_mac_with_weight_sram_tb;

architecture tb of top_mac_with_weight_sram_tb is

  constant IMG_W : integer := 28;
  constant IMG_H : integer := 28;
  constant K     : integer := 3;

  constant NUM_WINDOWS : integer := (IMG_H-K+1) * (IMG_W-K+1);

  type image_t is array (0 to IMG_H-1, 0 to IMG_W-1)
    of signed(X_W_WIDTH-1 downto 0);

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';

  signal mem_we    : std_logic := '0';
  signal mem_addr  : unsigned(0 downto 0) := (others => '0');
  signal mem_din   : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');

  signal valid_in  : std_logic := '0';
  signal valid_out : std_logic;
  signal x         : x_w_array(0 to N-1);
  signal y         : signed(Y_WIDTH_TRUNC-1 downto 0);

  signal exp_q : exp_q_t := (others => (others => '0'));
  signal rptr  : integer := 0;

  signal sent_count    : integer := 0;
  signal recv_count    : integer := 0;
  signal sending_done  : std_logic := '0';

  signal t_start       : time := 0 ns;
  signal t_end         : time := 0 ns;
  signal measurement_finished : std_logic := '0';

  file fweights : text open read_mode is "weights.txt";
  file fin      : text open read_mode is "input_image.txt";
  file fout     : text open read_mode is "expected_out.txt";

begin

  dut : entity work.top_mac_with_weight_sram
    port map (
      clk       => clk,
      rst       => rst,
      mem_we    => mem_we,
      mem_addr  => mem_addr,
      mem_din   => mem_din,
      valid_in  => valid_in,
      x         => x,
      valid_out => valid_out,
      y         => y
    );

  clk <= not clk after 0.5 ns;

  checker : process(clk)
  begin
    if rising_edge(clk) then

      if rst = '1' then
        rptr       <= 0;
        recv_count <= 0;
        measurement_finished <= '0';

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

        if sending_done = '1' and
           (recv_count + 1 = sent_count) and
           measurement_finished = '0' then

          t_end <= now;
          measurement_finished <= '1';

          report "Measured hardware time = " & time'image(now - t_start);
        end if;

      end if;
    end if;
  end process;

  stim : process
    variable Lw     : line;
    variable Lin    : line;
    variable Lout   : line;

    variable vi     : integer;
    variable wi     : integer;
    variable exp_i  : integer;

    variable w_word : std_logic_vector(N*X_W_WIDTH-1 downto 0);
    variable img    : image_t;

    variable idx    : integer;
  begin

    report "TB sees TRUNC_BITS = " & integer'image(TRUNC_BITS);

    mem_we   <= '0';
    mem_addr <= (others => '0');
    mem_din  <= (others => '0');

    valid_in <= '0';
    sending_done <= '0';

    for i in 0 to N-1 loop
      x(i) <= (others => '0');
    end loop;

    wait for 2 ns;

    ------------------------------------------------------------------------
    -- Read weights
    ------------------------------------------------------------------------
    if endfile(fweights) then
      report "weights.txt is empty" severity failure;
    end if;

    readline(fweights, Lw);

    w_word := (others => '0');

    for i in 0 to N-1 loop
      read(Lw, wi);

      w_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH) :=
        std_logic_vector(to_signed(wi, X_W_WIDTH));
    end loop;

    ------------------------------------------------------------------------
    -- Read full image
    ------------------------------------------------------------------------
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

    ------------------------------------------------------------------------
    -- Read expected outputs
    ------------------------------------------------------------------------
    for i in 0 to NUM_WINDOWS-1 loop

      if endfile(fout) then
        report "expected_out.txt ended too early" severity failure;
      end if;

      readline(fout, Lout);
      read(Lout, exp_i);

      exp_q(i) <= to_signed(exp_i, Y_WIDTH_TRUNC);

    end loop;

    ------------------------------------------------------------------------
    -- Program weight memory
    ------------------------------------------------------------------------
    t_start <= now;
    wait until rising_edge(clk);

    mem_addr <= (others => '0');
    mem_din  <= w_word;
    mem_we   <= '1';

    wait until rising_edge(clk);

    mem_we  <= '0';
    mem_din <= (others => '0');

    ------------------------------------------------------------------------
    -- Release reset
    ------------------------------------------------------------------------
    wait for 2 ns;
    rst <= '0';

    wait until rising_edge(clk);
    wait until rising_edge(clk);


    
    valid_in <= '1';

    for r in 0 to IMG_H-K loop
      for c in 0 to IMG_W-K loop

        idx := 0;

        for kr in 0 to K-1 loop
          for kc in 0 to K-1 loop
            x(idx) <= img(r+kr, c+kc);
            idx := idx + 1;
          end loop;
        end loop;

        wait until rising_edge(clk);

        sent_count <= sent_count + 1;

      end loop;
    end loop;

    valid_in <= '0';

    for i in 0 to N-1 loop
      x(i) <= (others => '0');
    end loop;

    sending_done <= '1';

    wait until measurement_finished = '1';

    report "Expected outputs = " & integer'image(NUM_WINDOWS);
    report "Sent windows     = " & integer'image(sent_count);
    report "Received outputs = " & integer'image(recv_count);

    assert false report "TB DONE" severity failure;

  end process;

end architecture;