function data_bits = hamming74_decode_stream(codeword_stream)
    % Converte codeword_stream em linha
    codeword_stream = codeword_stream(:).';

    % Testa se data_bits é múltiplo de 7
    if mod(length(codeword_stream),7) ~= 0
        error("Tamanho não é múltiplo de 7.");
    end

    % Cria a matriz de paridade
    H = [1 0 1 0 1 0 1;
         0 1 1 0 0 1 1;
         0 0 0 1 1 1 1];

    % Obtém o número de blocos
    nBlocks = length(codeword_stream)/7;
    % Aloca um vetor para abrigar toda a mensagem codifica
    data_bits = zeros(1, nBlocks*4);
    idx = 1;

    % Laço de repetição que varre todos os blocos
    for i = 1:7:length(codeword_stream)
        % Extrai os bits de dados do bloco
        cw = codeword_stream(i:i+6);

        % Detecta o bit que ocorreu erro
        s = mod(H*cw.',2);
        syndrome_val = bi2de(s.',"left-msb");

        % Se ocorreu erro inverte esse bit
        if syndrome_val >= 1 && syndrome_val <= 7
            cw(syndrome_val) = mod(cw(syndrome_val)+1,2);
        end

        % Concatena os bits de dados à mensagem decodificada
        data_bits(idx:idx+3) = cw([3 5 6 7]);

        idx = idx + 4;
    end
end

