# Decisiones de Diseño del Modelo E-R — DataLab

Este documento justifica las decisiones técnicas y conceptuales adoptadas para la construcción del modelo Entidad-Relación (E-R) del sistema DataLab.

## 1. Justificación de Entidades y Atributos

* **`CIENTIFICO_DATOS`**: Se define como entidad independiente para registrar el personal que interactúa con la plataforma. Atributos como `especialidad` permiten perfilar las capacidades del equipo.
* **`PROYECTO`**: Representa el contenedor de alto nivel para los problemas de negocio. Funciona como entidad principal para agrupar experimentos y científicos.
* **`DATASET`**: Se modela como una entidad fuerte e independiente debido a que los conjuntos de datos se almacenan y versionan de forma centralizada antes de ser consumidos por múltiples experimentos.
* **`EXPERIMENTO`**: Es la entidad central de ejecución. Se separa de `PROYECTO` mediante una relación 1:N para registrar de forma granular cada corrida o prueba técnica realizada.
* **`MODELO`**: Representa el artefacto entrenado resultante. Se relaciona de forma exclusiva con un `EXPERIMENTO` exitoso.
* **`METRICA`**: Se diseñó como entidad independiente (en lugar de atributos múltiples en `MODELO`) para permitir flexibilidad al registrar múltiples criterios de evaluación (*Accuracy*, *F1-Score*, *RMSE*) por cada modelo entrenado.

## 2. Decisiones sobre Atributos vs. Entidades

* **Algoritmo**: Se decidió mantener el algoritmo (ej. *Random Forest*, *XGBoost*) como un **atributo** de la entidad `MODELO` y no como una entidad separada, ya que en esta fase del diseño el alcance funcional se limita a registrar el tipo de técnica utilizada sin requerir un catálogo relacional independiente de algoritmos.

## 3. Justificación de Relaciones y Cardinalidades

* **`CIENTIFICO_DATOS` ↔ `PROYECTO` (N:M)**: Un científico de datos puede participar en varios proyectos de manera simultánea, y un proyecto requiere la colaboración de múltiples investigadores. Esto generará una tabla intermedia (puente) en el modelo relacional.
* **`PROYECTO` ↔ `EXPERIMENTO` (1:N)**: Un proyecto agrupa múltiples experimentos a lo largo de su ciclo de vida, pero cada experimento pertenece estrictamente a una única iniciativa.
* **`DATASET` ↔ `EXPERIMENTO` (1:N)**: Un mismo dataset puede ser reutilizado como insumo en distintas pruebas, mientras que cada experimento evalúa un dataset principal específico.
* **`EXPERIMENTO` ↔ `
*
*
## Decisiones del Modelo Relacional

* **Creación de la tabla puente `cientifico_proyecto`:** 
Al pasar el diagrama a MySQL Workbench, me di cuenta de un detalle clave: la relación entre los científicos y los proyectos es de "muchos a muchos". Es decir, un científico de datos puede estar trabajando en varios proyectos al mismo tiempo, y un proyecto casi siempre requiere del trabajo de varios científicos. Para que la base de datos soporte esto sin romperse, tuve que crear una tabla intermedia que los conectara. Decidí nombrarla simplemente `cientifico_proyecto` porque me pareció la forma más lógica, directa y fácil de recordar para todo el equipo.

* **Atributos de la tabla puente:**
Para esta nueva tabla decidí mantener las cosas lo más simples posible. Solamente le asigné las dos columnas obligatorias: `id_cientifico` e `id_proyecto`. Llegué a pensar en agregarle más detalles, como la fecha de ingreso al proyecto o el rol específico de la persona, pero la verdad es que por ahora el sistema solo necesita registrar quién está trabajando en qué. Preferí no saturar el diseño con atributos extra que nadie nos ha pedido todavía y mantener el modelo limpio y funcional.
* **Errores en la subida de archivos:**
Para subir el diagrama de MySQL WorkBench tuve algunas complicaciones ya que me confundi a la hora de crear la carpeta y de subir en el lugar corrrecto el png, de igual manera logre solucionarlo pero quedo en el registro que borre una carpeta fallida y la imagen que quedo en medio de las carpetas flotando
*
* MODELO` (1:0..1)**: La participación es parcial del lado del modelo, debido a que un experimento fallido o cancelado no produce un artefacto de modelo entrenado.
