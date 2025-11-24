function [x,l] = receptor_2(yrx, TB, Fp, Fa)
%%%%%%%%%%%%%%%%%%%%%%  Entrada do receptor   %%%%%%%%%%%%%%%%
%   yrx -- sinal de audio capturado
%   TB  -- Taxa de bits
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
pkg load signal;
pkg load communications;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Sincronizacao com Costas Loop   	    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y = yrx;
t = (0:length(y) - 1)/Fa;
fle=64;
h=fir1(fle,0.001);
mu=0.03;
theta=zeros(1,length(t));
theta(1) = 0;
zs=zeros(1,fle+1);zc=zeros(1,fle+1);
for k=1:length(t)-1
  zs=[zs(2:fle+1), 2*y(k)*sin(2*pi*Fp*t(k)+theta(k))];
  zc=[zc(2:fle+1), 2*y(k)*cos(2*pi*Fp*t(k)+theta(k))];
  lpfs=fliplr(h)*zs';
  lpfc=fliplr(h)*zc';
  theta(k+1)=theta(k)-mu*lpfs*lpfc;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               Demodulacao                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y = y.*cos(2*pi*Fp*t + theta)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Sincronizacao de simbolo                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yf = y;
st = ceil((Fa/TB)); t = st;
d = 1;
err = 0.01;
si = ones(1,ceil(length(yf)/(st-1)));
for ix = 1:length(si)
    dif=abs(yf(t-d))-abs(yf(t+d));
    if dif > err
        t = t - 1;
    elseif dif < -err
        t = t + 1;
    end
    si(ix) = t;
    t = t + st;
    if t > length(yf) - st + 1, break, end
end
si = si(~(si > length(yf)));
y = yf(si);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Decodificacao                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = y > 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Sincronizacao do quadro                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SFD = [1 1 0 0 1 1 1 0 0 0 1 1 1 1 0 0 0 0 1 1 1 0 0 0 1 1 0 0 1 0 1 0];
xc = xcorr(SFD*2 -1,double(x)*2 - 1);
[a,b] = max(abs(xc));
if a < length(SFD)*0.9
  disp('Muitos erros para decodificar os dados');
end
if xc(b) < 0
    x = ~x;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Remover cabecalho SFD                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
b = length(x) - b + length(SFD);
x_payload = x(b+1:end);

% 1. Pega o tamanho da mensagem (1º byte, NÃO codificado)
try
    length_bits = x_payload(1:8);
    l = bi2de(length_bits');
catch
    disp('Erro ao ler o tamanho da mensagem. Sincronização falhou.');
    x = [];
    l = 0;
    return;
end

% 2. Calcula o tamanho esperado do payload codificado
encoded_length = (l * 8 / 4) * 7;

if length(x_payload) < (8 + encoded_length)
    disp('Erro: Quadro recebido mais curto que o esperado.');
    x = [];
    l = 0;
    return;
end

% 3. Extrai o payload codificado
encoded_msg_bits = x_payload(9 : 8 + encoded_length);

% 4. Decodifica e CORRIGE a mensagem
% A entrada deve ser uma coluna
try
    % SINTAXE: decode(dados, n, k, 'tipo')
    % (n=7, k=4)
    decoded_msg_bits = hamming74_decode_stream(encoded_msg_bits);
    decoded_msg_bits_col = decoded_msg_bits;


    disp('***********************************');
    disp('*** MENSAGEM DECODIFICADA (HAMMING) ***');
    disp('*** (Erros de 1 bit por bloco foram corrigidos) ***');
    disp('***********************************');
catch ME
    disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    disp('!!! ERRO NA DECODIFICAÇÃO !!!');
    disp(ME.message);
    disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    x = [];
    l = 0;
    return;
end


% A saida 'x' da função deve ser *apenas* os bits da MENSAGEM
x = decoded_msg_bits_col';

% A outra saída da função, 'l', já foi calculada.
end
