# EEG-EOG-MATLAB
Código para análisis de datos de la caracterización fisiológica de la fatiga visual y carga cognitiva inducida por la exposición prolongada a pantallas en estudiantes de la Universidad del Valle de Guatemala

**Descripción**\
Este código procesa los registros de EEG (1 canal) y EOG (2 canales) adquiridos con el BIOPAC, y compara indicadores fisiológicos entre momentos de la sesión y entre las condiciones de iluminación (luz y oscuridad) durante la exposición a pantallas. 

*Indicadores calculados*
* EEG (potencia relativa 1-30 Hz): Theta (4-8 Hz), Alfa (8-13 Hz) y Beta (13-30 Hz)
* EOG vertical: Parpadeos por minuto durante la exposición
* EOG horizontal: Amplitud del movimiento ocular

*Diseño de cada sesión:*\
antes -> durante_luz -> después_luz -> durante_oscuridad -> después_oscuridad
* Se compara siempre la misma prueba entre momentos, para no mezclar ojos abiertos y cerrados.
* Luz y oscuridad son mediciones repetidas de la misma persona.
* Oscuridad siempre ocurrió después de luz: la comparación es exploratoria y no permite atribuir la diferencia solo a la iluminación


**Estructura de carpetas**\
'Datos .mat' = Datos crudos del BIOPAC, un archivo por participante\
'Inventario' = Excel con segmentos seleccionados manualmente\
'Calidad' = Matriz de calidad y exclusiones\
'Datos_procesados' = bases procesadas (segmentos, ventanas EEG, parpadeos...)\
'Codigo_MATLAB' = código \
'Tablas' = tablas descriptivas y de cambios\
'Figuras' = figuras de resultados\
'Resultados' = comparaciones, asociación y modelos


**Entradas**
* Archivos .mat: Son exportados de BIOPAC. Nombre = código del participante
* Tabla de segmentos (Segmentos_proyecto.xlsx)\
Se utilizan las siguientes columnas (Participante | momento | fase | inicio_seg | fin_seg)\
Un mismo momento y fase puede tener varias filas. Las filas sin tiempos se descartan y se listan en segmentos descartados.


**Ejecución**
1. Copiar los .mat a datos_originales/
2. Abrir MATLAB y poner la carpeta actual en 'codigo_MATLAB'
3. Revisar 'configuración.m'
4. Correr la función 'ejecutar_todo'\
Una sesión nueva reconstruye todas las salidas sin edición manual


**Archivos del código**\
*Scripts* \
configuracion.m = Parámetros del análisis\
inventario.m = Contiene el excel, lee archivos y códigos\
datos_procesados.m = Filtrado, control de calidad y métricas por segmento\
estadistica.m = Datos por participante y momento\
figuras.m = Figuras\
ejecutar_todo.m = Ejecución en orden\


*Funciones auxiliares*\
cargar_biopac = Lee el .mat, calcula fs\
leer_mapa = Lee y normaliza excel de segmentos\
leer_excluciones = Lee exclusiones manuales\
normalizar_texto = Limpia texto para comparar nombres\
preprocesar_señales = Diezmado, saturación, filtros y corrección ocular\
mascara_calidad = Marca muestras válidas e inválidas\
ventanas_eeg = Potencia theta/alfa/beta\
detectar_parpadeos = Detección de parpadeos en el EOG vertical\
amplitud_pendulo = Amplitud del EOG durante péndulo\
agregar_por_momento = Una fila por participante x momento x prueba\
cambio_entre_momentos = Diferencia pareada entre dos momentos\
ajustar_modelo = Modelo mixto\
descriptivos = n, media, DE, mediana y cuartiles por grupo\
grafica_pareada = Gráfica de líneas por participante\
guardar_figura = Guarda figuras en PNG\


**Salidas**\
Inventario\
  inventario_participantes.csv = archivos, canales, fs, duración, estado y problemas\
  segmentos_descartados.csv = filas del Excel sin tiempos válidos\

Calidad\
  matriz_calidad.csv = fila por ID, canal, momento y prueba\
  resumen_calidad_por_archivo.csv = calidad media por archivo\
  archivos_para_revision.csv = candidatos a revisión\

Datos_procesados'\
  mapa_segmentos.csv = excel normalizado\
  datos_segmento.csv = una fila por segmento\
  ventanas_EEG.csv = una fila por ventana EEG\
  eventos_EOG.csv = una fila por parpadeo detectado\
  datos_fase.csv = una fila por participante x momento x prueba\
  parametros_utilizados.mat = copia de configuración\

Tablas\
  tabla_muestra.csv = n planificado\
  EEG_bandas_por_archivo_y_momento.csv = bandas theta/beta/alfa y predominante\
  descriptivos_por_momento.csv = n, media, DE, mediana, cuartiles\
  cambio_*.csv = diferencias pareadas por participante\

Figuras\
  fig1_antes_vs_despues.png = ojos cerrados (bandas) y péndulo \
  fig2_durante_luz_vs_oscuridad.png = parpadeos y bandas durante exposición\
  fig3_bandas_por_momento.png = bandas relativas en 5 momentos\

Resultados\
  comparaciones_pareadas.csv = Wilcoxon por contraste\
  asociacion_parpadeos_cambio_alfa.csv = correlaciones de Spearman\
  modelos_coeficientes.csv = estimaciones, IC 95% y valores p\
