function encoded_bits = hamming74_encode_stream(data_bits)
    % data_bits deve ser linha com múltiplo de 4 bits
    data_bits = data_bits(:).';  

    if mod(length(data_bits),4) ~= 0
        error("Número de bits não múltiplo de 4.");
    end

    nBlocks = length(data_bits) / 4;
    encoded_bits = zeros(1, nBlocks * 7);

    idx = 1;

    for k = 1:nBlocks
        d = data_bits((k-1)*4 + (1:4));      % d1 d2 d3 d4

        % Montagem do código Hamming (p1 p2 d1 p3 d2 d3 d4)
        cw = zeros(1,7);
        cw(3) = d(1); % d1
        cw(5) = d(2); % d2
        cw(6) = d(3); % d3
        cw(7) = d(4); % d4

        % Calcular paridades (agora correto)
        p1 = mod(sum(cw([3 5 7])),2);   % p1 cobre bits 3,5,7
        p2 = mod(sum(cw([3 6 7])),2);   % p2 cobre bits 3,6,7
        p3 = mod(sum(cw([5 6 7])),2);   % p3 cobre bits 5,6,7

        cw(1) = p1;
        cw(2) = p2;
        cw(4) = p3;

        encoded_bits(idx:idx+6) = cw;
        idx = idx + 7;
    end
end
