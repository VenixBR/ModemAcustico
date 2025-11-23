function [y,msg] = transmissor(msg, RB, Fp, Fa)

%%%%%%%%%%%%%%%%%%%%%%  Entrada do transmissor   %%%%%%%%%%%%%%%%
%   msg -- Dados a serem transmitidos
%   RB  -- Taxa de bits
%   Fp  -- Frequencia da portadora
%   Fa  -- Frequencia de amostragem da placa de som
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global OCTAVE;
if isempty(OCTAVE)
    OCTAVE = 0; 
    disp('Variável OCTAVE não definida, assumindo MATLAB (OCTAVE=0)');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Pacotes de software
if OCTAVE == 1
pkg load communications;
end

% --- INÍCIO DA MODIFICAÇÃO (CORREÇÃO DE ERROS) ---
% REMOVIDO: hHammingEnc = comm.HammingEncoder;
% (Não precisamos de um objeto para a função 'encode')
% --- FIM DA MODIFICAÇÃO ---

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inicio
% converte o texto para um vetor de bits

if isstring(msg)
    msg = char(msg);
end
l = length(msg);
msg_decimal = double(msg);

% --- INÍCIO DA MODIFICAÇÃO (LÓGICA FEC) ---
% 1. Pega os bits da MENSAGEM (ex: "OLA" = 24 bits)
msg_bits = reshape(de2bi(msg_decimal, 8)', 1, 8*l);

% 2. Codifica a MENSAGEM com Hamming(7,4)
% A entrada deve ser uma coluna
% SINTAXE: encode(dados, n, k, 'tipo')
% (n=7, k=4)


%encoded_msg_bits_col = encode(msg_bits', 7, 4, 'hamming');
%encoded_msg_bits = encoded_msg_bits_col'; % Transpõe para linha
encoded_msg_bits = hamming74_encode_stream(msg_bits);



% 3. Pega os bits de TAMANHO (ex: l=3 -> [00000011])
length_bits = reshape(de2bi(l, 8)', 1, 8);

% 4. Monta o payload final
payload = [length_bits encoded_msg_bits];
% --- FIM DA MODIFICAÇÃO ---


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Preambulo do quadro                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preambulo: 40 bits
% 1111111111  101010101010101010101010101010
PRE = [ones(1,10) upsample(ones(1,15),2)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Marcador de inicio do quadro  (SFD)           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SFD = [1 1 0 0 1 1 1 0 0 0 1 1 1 1 0 0 0 0 1 1 1 0 0 0 1 1 0 0 1 0 1 0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Enquadramento                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
msg = [PRE SFD payload PRE]; % Linha modificada com FEC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Codificacao polar em banda base             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [-1,1];
y = s(msg+1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Numero de simbolos                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(['Tamanho do quadro: ' num2str(length(y)) ' simbolos'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Filtragem para formatacao de pulso          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r = 0.5;
if OCTAVE == 1
RB_f = Fa/floor(Fa/RB);
num = rcosine(RB_f,Fa,'default',r);
y = rcosflt(y,RB_f,Fa,'filter',num)';
else % MATLAB
sps = floor(Fa/RB);
h = rcosdesign(r, 6, sps);
y = upfirdn(y, h, sps);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Modulacao em Banda Passante                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = (0:length(y) - 1)/Fa;
y = y.*cos(2*pi*Fp*t);

end