function data_bits = hamming74_decode_stream(codeword_stream)

    codeword_stream = codeword_stream(:).';

    if mod(length(codeword_stream),7) ~= 0
        error("Tamanho não é múltiplo de 7.");
    end

    H = [1 0 1 0 1 0 1;
         0 1 1 0 0 1 1;
         0 0 0 1 1 1 1];

    nBlocks = length(codeword_stream)/7;
    data_bits = zeros(1, nBlocks*4);

    idx = 1;

    for i = 1:7:length(codeword_stream)
        cw = codeword_stream(i:i+6);

        s = mod(H*cw.',2);
        syndrome_val = bi2de(s.',"left-msb");

        if syndrome_val >= 1 && syndrome_val <= 7
            cw(syndrome_val) = mod(cw(syndrome_val)+1,2);
        end

        % Extrair bits d1 d2 d3 d4
        data_bits(idx:idx+3) = cw([3 5 6 7]);

        idx = idx + 4;
    end
end
