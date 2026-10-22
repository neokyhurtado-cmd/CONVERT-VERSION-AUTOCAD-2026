# Evidencia de pruebas reales · DWG Version Switch

<small>Prueba interna ejecutada el 21 de octubre de 2026 (hora de Colombia) · Informe público anonimizado el 22 de octubre de 2026</small>

## Resumen verificable

La aplicación se probó con **un único archivo DWG auténtico de ingeniería**. El dibujo contiene información privada; no se distribuye, publica ni adjunta. La prueba utilizó la instalación legítima de **AutoCAD 2027 Core Console** en Windows.

| Control independiente | Resultado |
| --- | --- |
| Conversiones completas y reapertura | **7 de 7** |
| Inventarios nativos de AutoCAD (origen + 7 copias) | **8 de 8** |
| Entidades contadas en el origen y todas las copias | **3.043** |
| Cantidad por tipo de entidad, capa utilizada y presentación | **Iguales en todas las copias** |
| Unidades y límites generales del dibujo | **Sin cambios** |
| Pruebas con archivos DWG reales en la página HTTPS | **10 de 10** |
| Archivo original | **Idéntico por SHA-256** antes y después |

### Pruebas de conversión

| Archivo de entrada | Salida solicitada | Cabecera DWG comprobada | Reabierto con AutoCAD |
| --- | --- | --- | --- |
| DWG 2013 / AC1027 | DWG 2010 | AC1024 | Sí |
| DWG 2013 / AC1027 | DWG 2007 | AC1021 | Sí |
| DWG 2013 / AC1027 | DWG 2004 | AC1018 | Sí |
| DWG 2013 / AC1027 | DWG 2000 | AC1015 | Sí |
| DWG 2013 / AC1027 | DWG R14 | AC1014 | Sí |
| DWG 2013 / AC1027 | DWG 2018 | AC1032 | Sí |
| DWG 2007 previamente convertido | DWG 2018 | AC1032 | Sí |

Cada ejecución comprobó que la fuente no cambiara, guardó una salida DWG nueva, comprobó los primeros 6 bytes del archivo resultante, intentó su reapertura en AutoCAD y registró el hash de salida. Las copias se generaron en un directorio privado de pruebas; el público no puede acceder a ellas.

### Auditoría adicional de geometría y metadatos

Se volvió a abrir con AutoCAD el DWG de origen y las siete salidas. Una rutina independiente recorrió y contabilizó entidades y tablas por tipo, capa utilizada y presentación. También comparó las unidades y los límites generales.

**Hallazgos positivos:** 3.043 entidades en todos los archivos; los conteos de tipos y de capas utilizadas no cambiaron; las unidades, presentaciones y el cuadro de límites se conservaron en los valores registrados.

**Cambios detectados:** cuatro identificadores internos de bloques anónimos fueron renumerados en cada versión; algunas conversiones añadieron registros APPID. **No se interpretan como pérdida probada ni como garantía de integridad**: los objetos complejos necesitan pruebas adicionales.

### Prueba de la web con archivos reales

En la URL pública se seleccionó el DWG original y copias 2007/2018 desde el navegador, sin formularios de carga remota. El analizador reconoció las cabeceras AC1027, AC1021 y AC1032 y mostró correctamente advertencias de descenso, compatibilidad de destino y exportación local de diagnóstico. Resultado: **10/10 PASS** sin errores JavaScript observados.

### Coincidencia entre código y descarga

En la auditoría privada también se comprobó que el **Convertir-DWG.ps1** utilizado en las conversiones fuese byte por byte el que se distribuye dentro del ZIP oficial de Windows. Este repositorio publica ese mismo script, cuya procedencia se verifica por hash en el lanzamiento inicial.

## Lo que estas pruebas NO demuestran

- No prueban todos los archivos DWG ni todas las versiones/productos de AutoCAD.
- No demuestran conservación 1:1 de geometría, atributos, cotas asociativas, bloques dinámicos, XREF, proxies AEC/Civil 3D, presentación visual, impresión ni fuentes.
- El número de entidades podría seguir siendo 3.043 aunque un atributo individual hubiera cambiado.
- El acceso al motor de AutoCAD requiere los derechos de licencia del operador. No equivale a una aprobación oficial de Autodesk.

Este informe presenta datos agregados de **una sola muestra**. Para trabajos de ingeniería, el resultado debe abrirse y revisarse visualmente y por métodos específicos de QA antes de entregarlo.

## Datos públicos

La representación estructurada del resultado está en [qa-results-public.json](qa-results-public.json). Para preservar la confidencialidad de clientes, **no publicamos** el plano, los listados de entidades individuales, rutas de usuario, nombres de proyectos ni archivos de AutoCAD propietarios.

Código libre: [repositorio GitHub](https://github.com/neokyhurtado-cmd/CONVERT-VERSION-AUTOCAD-2026) · [descarga oficial MIT](https://trafficlab-panorama.com/downloads/dwg-version-switch-community-v1.0.0.zip) · Herramienta: [PANORAMA LAB](https://trafficlab-panorama.com/dwg-versiones.html).

## Referencias de compatibilidad

- [Autodesk: Drawing file format compatibility](https://help.autodesk.com/view/ACADWEB/ENU/?caas=caas%2Fsfdcarticles%2Fsfdcarticles%2FAutoCAD-drawing-file-format.html)
- [Autodesk: About Drawing (DWG) File Changes](https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Customization/files/GUID-D029509F-A2A0-4A7E-BDD5-FE95E7235C5C.htm)
- [Autodesk: DWG TrueView](https://www.autodesk.com/products/dwg-trueview/overview)
