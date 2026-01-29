module modem_tb;

string message = "ABC";
int message_length;
logic [n*8-1:0] binary_message;

initial begin
  message_length = message.len();
  binary_message = '0;

  for (int i = 0; i < message_length; i++) begin
    bits[(message_length-1-i)*8 +: 8] = message[i];
  end

  $display("s    = %s", message);
  $display("n    = %0d", message_length);
  $display("bits = %b", binary_message);
end


endmodule