library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_test_slave_stream_v1_0_S_AXIS is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- AXI4Stream sink: Data Width
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
        fifo_din       : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
        fifo_wr_en     : out std_logic;
        fifo_full      : in  std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		--S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		-- Byte qualifier
		--S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- Indicates boundary of last packet
		--S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic
	);
end fifo_test_slave_stream_v1_0_S_AXIS;

architecture arch_imp of fifo_test_slave_stream_v1_0_S_AXIS is
	signal tready_i : std_logic;
    signal wr_en_i  : std_logic;
begin
	---------------------------------------------------------------------
    -- Backpressure: ready only when not in reset and FIFO is not full
    --------------------------------------------------------------------
    --tready_i <= '1' when (S_AXIS_ARESETN = '1' and fifo_full = '0') else '0';
    tready_i <= '1';
    --S_AXIS_TREADY <= tready_i;

    --------------------------------------------------------------------
    -- Data path into FIFO is just the stream data
    --------------------------------------------------------------------
    fifo_din <= S_AXIS_TDATA;

    --------------------------------------------------------------------
    -- Generate a one-cycle fifo_wr_en when a word is accepted
    --------------------------------------------------------------------
    process (S_AXIS_ACLK)
    begin
        if rising_edge(S_AXIS_ACLK) then
            if S_AXIS_ARESETN = '0' then
                wr_en_i <= '0';
            else
                if (S_AXIS_TVALID = '1' and tready_i = '1') then
                    wr_en_i <= '1';
                else
                    wr_en_i <= '0';
                end if;
            end if;
        end if;
    end process;

    fifo_wr_en <= wr_en_i;

end arch_imp;
