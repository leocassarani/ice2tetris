`default_nettype none

module CPU (
  input clk, reset,
  input [15:0] instruction,
  input mem_busy,
  input [15:0] mem_rdata,
  output mem_load,
  output [15:0] mem_address,
  output [15:0] mem_wdata,
  output reg [15:0] prog_counter,
);

reg [15:0] a_reg;
reg [15:0] d_reg;
reg [15:0] memory;

assign mem_address = a_reg;
assign mem_load = state == write_back && d3;
assign mem_wdata = alu_out;

// If the memory address is pointing to any region outside of VRAM (i.e.
// outside of 0x4000-0x5fff), then we don't have to wait for the mem_busy
// signal to go low, and we can complete reads and writes in a single cycle.
wire fast_mem = !mem_address[14] || mem_address[13];

reg [1:0] mem_wait;

wire i = instruction[15];
wire a = instruction[12];

reg c1, c2, c3, c4, c5, c6;
wire d1, d2, d3;
wire j1, j2, j3;

assign { d1, d2, d3 } = instruction[5:3];
assign { j1, j2, j3 } = instruction[2:0];

reg [15:0] alu_x, alu_y;
wire [15:0] alu_out;
wire alu_zero, alu_neg;
wire alu_pos = !(alu_neg || alu_zero);

wire jump = (j1 && alu_neg) || (j2 && alu_zero) || (j3 && alu_pos);

localparam [2:0] inst_fetch  = 3'd0,
                 inst_decode = 3'd1,
                 write_back  = 3'd2,
                 mem_read    = 3'd3,
                 mem_fetch   = 3'd4;

reg [2:0] state = inst_fetch;

ALU alu (
  .x(alu_x),
  .y(alu_y),
  .zx(c1),
  .nx(c2),
  .zy(c3),
  .ny(c4),
  .f(c5),
  .no(c6),
  .out(alu_out),
  .zero(alu_zero),
  .neg(alu_neg),
);

always @(posedge clk) begin
  if (reset) begin
    a_reg <= 0;
    d_reg <= 0;
    memory <= 0;
    mem_wait <= 0;
    prog_counter <= 0;
    state <= inst_fetch;
  end else begin
    case (state)
      inst_fetch: begin
        state <= inst_decode;
      end

      inst_decode: begin
        if (i) begin // C-instruction
          { c1, c2, c3, c4, c5, c6 } <= instruction[11:6];
          alu_x <= d_reg;
          alu_y <= a ? memory : a_reg;
          state <= write_back;
        end else begin // A-instruction
          a_reg <= instruction;
          prog_counter <= prog_counter + 1;
          state <= mem_read;
        end
      end

      write_back: begin
        // We are ready to execute the logic in this state if one of the
        // following is true: we are not writing the ALU output back to memory
        // (!d3); or we are writing to non-VRAM memory, to which we have fast,
        // exclusive access (fast_mem); or we are writing to VRAM, and no one
        // else is currently reading from it (!mem_busy).
        if (!d3 || fast_mem || !mem_busy) begin
          if (d1) begin // Write to A register?
            a_reg <= alu_out;
          end

          if (d2) begin // Write to D register?
            d_reg <= alu_out;
          end

          if (d3) begin // Write to Memory[A]?
            memory <= alu_out;
          end

          if (jump) begin
            prog_counter <= a_reg;
          end else begin
            prog_counter <= prog_counter + 1;
          end

          // If we've changed the memory address that we're accessing (d1),
          // then we need to fetch the new data from memory before moving on
          // to the next instruction.
          state <= d1 ? mem_read : inst_fetch;
        end
      end

      mem_read: begin
        if (fast_mem) begin
          state <= mem_fetch;
        end else begin
          // If we are reading from VRAM, we need to wait for mem_busy to go
          // low, then count up to 2 clock cycles to deal with the delay.
          case (mem_wait)
            0: mem_wait <= mem_busy ? 0 : mem_wait + 1;
            1: mem_wait <= mem_wait + 1;
            2: state <= mem_fetch;
          endcase
        end
      end

      mem_fetch: begin
        mem_wait <= 0;
        memory <= mem_rdata;

        // If we have got this far, then there's no need to wait a further
        // cycle to fetch the next instruction from ROM, so instead of jumping
        // back to inst_fetch, we can go straight into the inst_decode stage.
        state <= inst_decode;
      end
    endcase
  end
end

endmodule
