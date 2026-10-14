%% Figuras por participante

run('configuracion.m');
D = readtable(fullfile(cfg.dir.procesados, 'datos_fase.csv'),'TextType','string');
colPend = ['Pend' cfg.pendulo.canal '_p2p_uV'];
etqDesp = {'Antes','Despues luz', 'Despues oscuridad'};
etqDur = {'Durante luz','Durante oscuridad'};

%% Figura 1: Después (ojos cerrados y péndulo)
fig = figure('Visible','off','Position',[100 100 950 700]);
grafica_pareada(subplot(2,2,1), D, 'AlphaRel', 'Valido_EEG', 'OjosCerrados', cfg.momentosDespues, etqDesp, 'Alfa relativa (ojos cerrados)');
grafica_pareada(subplot(2,2,2), D, 'ThetaRel', 'Valido_EEG', 'OjosCerrados', cfg.momentosDespues, etqDesp, 'Theta relativa (ojos cerrados)');
grafica_pareada(subplot(2,2,3), D, 'BetaRel',  'Valido_EEG', 'OjosCerrados', cfg.momentosDespues, etqDesp, 'Beta relativa (ojos cerrados)');
grafica_pareada(subplot(2,2,4), D, colPend,    'Valido_Pendulo', 'Pendulo', cfg.momentosDespues, etqDesp, sprintf('Amplitud pendulo, EOG %s (\\muV)', cfg.pendulo.canal));
guardar_figura(fig, fullfile(cfg.dir.figuras, 'fig1_antes_vs_despues.png')); close(fig);

%% Figura 2: exposición, luz vs. oscuridad
%{
paneles = {
    'Parpadeos_min', 'Valido_EOG', 'Parpadeos por minuto', 'parpadeos';
    'AlphaRel',     'Valido_EEG', 'Alfa relativa',        'alfa';
    'ThetaRel',     'Valido_EEG', 'Theta relativa',       'theta';
    'BetaRel',      'Valido_EEG', 'Beta relativa',        'beta'
    };

imagenes = cell(4,1);

for k = 1:4
    fig = figure('Visible','off','Position',[100 100 475 350]);

    grafica_pareada(gca, D, paneles{k,1}, paneles{k,2}, ...
        'Exposicion', cfg.momentosDurante, etqDur, paneles{k,3});

    rutaPanel = fullfile(cfg.dir.figuras, ...
        ['fig2_' paneles{k,4} '.png']);
    saveas(fig, rutaPanel);
    close(fig);

    imagenes{k} = imread(rutaPanel);
end

figura2 = [imagenes{1}, imagenes{2}; ...
    imagenes{3}, imagenes{4}];

imwrite(figura2, fullfile(cfg.dir.figuras, ...
    'fig2_durante_luz_vs_oscuridad.png'));
%}
carpeta = cfg.dir.figuras;

P = imread(fullfile(carpeta, 'prueba_parpadeos.png'));
A = imread(fullfile(carpeta, 'prueba_AlphaRel.png'));
T = imread(fullfile(carpeta, 'prueba_ThetaRel.png'));
B = imread(fullfile(carpeta, 'prueba_BetaRel.png'));

imwrite([P A; T B], ...
    fullfile(carpeta, 'fig2_durante_luz_vs_oscuridad.png'));

%% Figura 3: un PDF por banda
momentos = {'antes','durante_luz','despues_luz', ...
    'durante_oscuridad','despues_oscuridad'};

etiquetas = {'Antes','Durante luz','Despues luz', ...
    'Durante oscuridad','Despues oscuridad'};

bandas = {'ThetaRel','AlphaRel','BetaRel'};
titulos = {'Theta relativa','Alfa relativa','Beta relativa'};

S = D(D.Valido_EEG == 1 & ...
    ismember(D.Fase, ["OjosCerrados","Exposicion"]), :);

for b = 1:numel(bandas)
    fig = figure('Visible','off','Units','pixels', ...
        'Position',[100 100 600 450],'Color','w');

    ax = axes('Parent',fig);
    hold(ax,'on');

    for m = 1:numel(momentos)
        y = S.(bandas{b})(S.Momento == string(momentos{m}));
        y = y(isfinite(y));

        if isempty(y)
            continue
        end

        scatter(ax, m + 0.07*randn(size(y)), y, 25, 'filled');
        plot(ax, m + [-0.2 0.2], median(y)*[1 1], ...
            'k-', 'LineWidth',2);
    end

    set(ax,'XTick',1:numel(momentos), ...
        'XTickLabel',etiquetas,'XTickLabelRotation',30);
    xlim(ax,[0.5 numel(momentos)+0.5]);
    ylabel(ax,titulos{b});
    box(ax,'on');

    rutaPDF = fullfile(cfg.dir.figuras, ...
        ['fig3_' bandas{b} '.pdf']);

    exportgraphics(ax, rutaPDF, 'ContentType','vector');

    if ~isfile(rutaPDF)
        error('No se creó el archivo: %s', rutaPDF);
    end

    fprintf('PDF creado: %s\n', rutaPDF);
    close(fig);
end