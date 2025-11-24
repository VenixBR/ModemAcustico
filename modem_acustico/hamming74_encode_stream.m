function encoded_bits = hamming74_encode_stream(data_bits)
    % Converte data_bits em linha
    data_bits = data_bits(:).';  

    % Testa se data_bits é múltiplo de 4
    if mod(length(data_bits),4) ~= 0
        error("Número de bits não múltiplo de 4.");
    end

    % Obtém o número de blocos
    nBlocks = length(data_bits) / 4;
    % Aloca um vetor para abrigar toda a mensagem codificada
    encoded_bits = zeros(1, nBlocks * 7);
    idx = 1;

    % Laço de repetição que varre todos os blocos
    for k = 1:nBlocks
        % Extrai os bits de dados do bloco
        d = data_bits((k-1)*4 + (1:4));

        % Posiciona os bits de dados no bloco codificado
        % p1 p2 d1 p3 d2 d3 d4
        cw = zeros(1,7);
        cw(3) = d(1); % d1
        cw(5) = d(2); % d2
        cw(6) = d(3); % d3
        cw(7) = d(4); % d4

        % Calcula os bits de paridade
        p1 = mod(sum(cw([3 5 7])),2);
        p2 = mod(sum(cw([3 6 7])),2);
        p3 = mod(sum(cw([5 6 7])),2);

        % Posiciona os bits de paridade no bloco codificado
        cw(1) = p1;
        cw(2) = p2;
        cw(4) = p3;

        % Concatena o bloco codificado à mensagem codificada
        encoded_bits(idx:idx+6) = cw;
        idx = idx + 7;
    end
end


