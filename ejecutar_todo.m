function ejecutar_todo()

ejec_t0 = tic;
ejec_scripts = {'inventario.m', 'datos_procesados', 'estadistica', 'figuras'};
for ejec_k = 1:numel(ejec_scripts)
    fprintf('\n===== %s =====\n', ejec_scripts{ejec_k});
    run(ejec_scripts{ejec_k});
end
fprintf('\nListo en %.1f min. \n', toc(ejec_t0) / 60);
end