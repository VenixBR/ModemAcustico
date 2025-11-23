clear all; clc;
% --- MODIFICAÇÃO ---
% Declarar 'OCTAVE' como global ANTES de usá-la
global OCTAVE;
OCTAVE = 0; % 0 para MATLAB, 1 para Octave
% --- FIM DA MODIFICAÇÃO ---
if OCTAVE == 1
  pkg load signal;
pkg load communications;
end
RB = 100; % taxa de bits (bps)
Fp = 2000;
Fa = 8000;
on = 1; % controle se opera ou nao em tempo real
filename = 'sinal/sinal_rx10.wav';

if on == 1
    % captura do sinal de audio
    NS = 0;             % nivel de sinal

    % --- MODIFICAÇÃO (Sensibilidade) ---
    NS_min = 0.01;      % Nível ajustado para 0.02
    % --- FIM DA MODIFICAÇÃO ---

    t_captura = 7;      % tempo de captura do sinal

    % --- INÍCIO DA MODIFICAÇÃO (MATLAB vs Octave) ---
    % 1. Criar o objeto de gravação (FORA do loop)
    % Usa 'Fa' (8000 Hz), 16 bits, 1 canal (mono)
    r = audiorecorder(Fa, 16, 1);

    disp('Iniciando captura de áudio...');

    while NS < NS_min
        % 2. Gravar o áudio
        disp(['Aguardando som... Nível mínimo: ' num2str(NS_min)]);
        recordblocking(r, t_captura); % Grava por 4 segundos
        disp('Gravação concluída, analisando sinal...');

        % 3. Obter os dados gravados
        y = getaudiodata(r, 'double');

        % --- INÍCIO DA MODIFICAÇÃO (Forçar Mono) ---
        % Verifica se a gravação 'y' é estéreo (tem 2 colunas)
        if size(y, 2) > 1
            disp('Áudio estéreo detectado. Convertendo para mono.');
            % Pega apenas o primeiro canal (ex: o esquerdo)
            y = y(:, 1);
        end
        % --- FIM DA MODIFICAÇÃO ---

        % --- FIM DA MODIFICAÇÃO ---

        if ~isempty(y)
          % Mede o pico de amplitude (valor absoluto)
          NS = max(abs(y));
        else
          y = []; % Garante que 'y' exista se a gravação falhar
          NS = 0;
        end
        disp(['Nível de sinal detectado: ' num2str(NS)]);
    end

    disp('Sinal forte detectado! Salvando arquivo...');
    % salva arquivo com sinal para usar no receptor
    % audiowrite (filename, y, Fa);
else
    [y, fs] = audioread(filename);

    % --- INÍCIO DA MODIFICAÇÃO (Forçar Mono na Leitura) ---
    % Garante que o arquivo lido também seja forçado para mono
    if size(y, 2) > 1
        disp('Arquivo de áudio estéreo detectado. Convertendo para mono.');
        y = y(:, 1);
    end
    % --- FIM DA MODIFICAÇÃO ---

    plot(y);
end % <-- MODIFICAÇÃO (Era 'endif')

% retorna a mensagem em bits e o tamanho dela
[m,l] = receptor_2(y, RB, Fp, Fa);

% conversao de bits para texto
% --- MODIFICAÇÃO (Robustez) ---
if isempty(m) || isempty(l) || l == 0
    disp('Receptor não retornou dados. Mensagem vazia.');
    msg = "";
    l = 0;
else
    try
        x = bi2de(reshape(m,8,l)')';
        msg = char(x);
    catch
        disp('Erro ao converter bits para texto. Bits recebidos podem estar corrompidos.');
        msg = "ERRO DE DECODIFICAÇÃO";
    end
end
% --- FIM DA MODIFICAÇÃO ---

disp(["Tamanho da mensagem recebida: " num2str(l) " bytes"]);
disp(["Mensagem recebida: " msg]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   GERAÇÃO DOS 3 GRÁFICOS (ANTES, COM RUÍDO E DEPOIS DO FEC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if l > 0   % só plota se recebeu algo válido

    % === 1. Sinal ideal transmitido (modelo teórico) ===
    [ytx_ideal, ~] = transmissor(msg, RB, Fp, Fa);
    t1 = (0:length(ytx_ideal)-1)/Fa;

    % === 2. Sinal recebido com ruído ===
    t2 = (0:length(y)-1)/Fa;

    % === 3. Sinal reconstruído após Hamming FEC ===
    [ytx_reconstruido, ~] = transmissor(msg, RB, Fp, Fa);
    t3 = (0:length(ytx_reconstruido)-1)/Fa;

    % --- PLOTS ---
    figure;

    subplot(3,1,1);
    plot(t1, ytx_ideal);
    title('1 — Sinal Ideal Transmitido (Sem Ruído)');
    xlabel('Tempo (s)');
    ylabel('Amplitude');
    grid on;

    subplot(3,1,2);
    plot(t2, y);
    title('2 — Sinal Recebido (Com Ruído / Microfone)');
    xlabel('Tempo (s)');
    ylabel('Amplitude');
    grid on;

    subplot(3,1,3);
    plot(t3, ytx_reconstruido);
    title('3 — Sinal Reconstruído Após Correção (Hamming FEC)');
    xlabel('Tempo (s)');
    ylabel('Amplitude');
    grid on;

else
    disp('Erro: nada a plotar (mensagem vazia ou erro de FEC).');
end