%% Configuración de los parámetros y datos
cfg = struct();

cfg.raiz = fileparts(mfilename('fullpath'));

cfg.carpetaDatos = fullfile(cfg.raiz, 'Datos .mat');
cfg.archivoMapa = fullfile(cfg.raiz, 'Segmentos proyecto.xlsx');
cfg.hojaMapa = 1;
cfg.patronArchivo = '%s.mat';

cfg.archivoExcl = fullfile(cfg.raiz, 'calidad', 'exclusiones');
cfg.dir.inventario = fullfile(cfg.raiz, 'inventario');
cfg.dir.calidad = fullfile(cfg.raiz, 'calidad');
cfg.dir.procesados = fullfile(cfg.raiz, 'datos_procesados');
cfg.dir.tablas = fullfile(cfg.raiz, 'tablas');
cfg.dir.figuras = fullfile(cfg.raiz, 'figuras');
cfg.dir.resultados = fullfile(cfg.raiz, 'resultados');

carpetas = struct2cell(cfg.dir);
for ii = 1:numel(carpetas)
    if ~isfolder(carpetas{ii})
        mkdir(carpetas{ii});
    end
end
clear carpetas ii

cfg.nPlanificado = 20; %Participantes planificados en la metodología

%Canales del archivo BIOPAC
cfg.idxEEG = 1;
cfg.idxEOG_V = 2;
cfg.idxEOG_H = 3;
cfg.fsObjetivo = 250; %Información útil abajo de 35Hz

%Filtros
cfg.eeg.bandpass = [1 30]; %Rango potencial 
cfg.eeg.corregirOcular = true; %Resta de parpadeo del EEG por regresión
cfg.eog.bpParpadeo = [0.5 20]; %Hz - detección de parpadeos
cfg.eog.bpPendulo = [0.1 10]; %Hz - amplitud del péndulo

%EEG: ventanas y bandas
cfg.eeg.durVentana_s = 4;
cfg.eeg.solape = 0.5;
cfg.eeg.theta = [4 8];
cfg.eeg.alpha = [8 13];
cfg.eeg.beta = [13 30];
cfg.eeg.bandaTotal = [1 30];

%Parpadeos (EOG_V)
cfg.parpadeo.kMAD = 4;
cfg.papadeo.distMin_s = 0.25; %Separación mínima entre parpadeos
cfg.parpadeo.polaridad = 1; %1=pico positivo y -1=pico negativo

%Control de calidad
cfg.cal.bloque_s = 1;
cfg.cal.flatStd_uV.EEG = 0.5;
cfg.cal.flatStd_uV.EOG = 0.2;
cfg.cal.ptpMaxEEG_uV = 150;
cfg.cal.satMin_ms = 5;
cfg.cal.minValidoSegmento = 0.5;
cfg.cal.minVentanasEEG = 1;
cfg.cal.minVentanasMomento = 4;
cfg.cal.minDuracionParpadeo_s = 30;
cfg.cal.minDuracionPendulo_s = 5;
cfg.cal.alertaPctValido = 70;
cfg.cal.motivos = {'ok','no_finito','saturacion','plano','amplitud','manual'};


%Momentos del experimento
cfg.mapaPruebas = {
    'ojoscerrados', 'OjosCerrados';
    'arribaabajo', 'ArribaAbajo';
    'lados', 'Lados';
    'pendulo', 'Pendulo';
    'exposicion', 'Exposicion'};
cfg.fasesEEG = {'OjosCerrados','Exposicion'};
cfg.fasesParpadeo = {'Exposicion'};
cfg.Pendulo = 'Pendulo';
cfg.pendulo.canal = 'H';
%Momentos que se comparan
cfg.momentosDespues = {'antes','despues_luz','despues_oscuridad'};
cfg.momentosDurante = {'durante_luz','durante_oscuridad'};

%Exclusiones y sensibilidad
cfg.archivosExcluir = {};
cfg.idsExcluir = {};
cfg.idsSensibilidad = {'/MATLAB Drive/Datos .mat/3A26.mat'};

