module modem_tb;

  string message = "ABCC";
  logic [7:0] message_length;
  logic [256*8-1:0] binary_message;

  int idx;

  initial begin
    message_length = message.len();
    binary_message = '0;

    $display("\nmessage = %s", message);
    $display("length  = %0d", message_length);
    $display("binary  =");

    for (int i = 0; i < message_length; i++) begin
      idx = (message_length-1-i)*8;
      binary_message[idx +: 8] = message[i];
      $display("(%s) %08b",message[i], binary_message[idx +: 8]);
    end
    $display("");
  end
  
endmodule
