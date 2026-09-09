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
* **`EXPERIMENTO` ↔ `MODELO` (1:0..1)**: La participación es parcial del lado del modelo, debido a que un experimento fallido o cancelado no produce un artefacto de modelo entrenado.
