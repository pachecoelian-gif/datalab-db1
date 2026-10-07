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

## Política de integridad referencial — Semana 4

### participa.id_cientifico → cientifico_datos.id_cientifico
**Política:** RESTRICT
**Justificación:** un científico no debe eliminarse si aún tiene participaciones activas en proyectos.

### participa.id_proyecto → proyecto.id_proyecto
**Política:** CASCADE
**Justificación:** la participación no tiene sentido sin el proyecto al que pertenece.

### experimento.id_proyecto → proyecto.id_proyecto
**Política:** RESTRICT
**Justificación:** un proyecto no debe eliminarse si tiene experimentos registrados, para no perder evidencia de trabajo real.

### usar.id_experimento → experimento.id_experimento
**Política:** CASCADE
**Justificación:** el registro de uso de un dataset no tiene sentido sin el experimento que lo generó.

### usar.id_dataset → dataset.id_dataset
**Política:** RESTRICT
**Justificación:** un dataset no debe eliminarse mientras algún experimento dependa de él, para conservar trazabilidad.

### modelo.id_experimento → experimento.id_experimento
**Política:** RESTRICT
**Justificación:** un modelo entrenado es un resultado valioso; no debe desaparecer solo porque se borra el experimento que lo originó.

### metrica.id_modelo → modelo.id_modelo
**Política:** CASCADE
**Justificación:** una métrica no tiene significado independiente del modelo que evalúa.

## Auditoría de normalización — Semana 4

Se revisaron las 8 tablas del esquema. Todas cumplen 1FN (valores atómicos,
sin listas ni datos concatenados en una sola columna). Las tablas puente
(`participa`, `usar`) tienen llave primaria compuesta pero, al no tener
atributos propios además de las FK, no presentan dependencias parciales
(2FN se cumple trivialmente). Ninguna tabla presenta dependencias
transitivas (3FN), ya que los atributos descriptivos permanecen en la
entidad a la que pertenecen conceptualmente y las relaciones se resuelven
mediante llaves foráneas, sin duplicar información entre tablas.

---

## Semana 6/7 — Decisiones sobre operaciones DML

> **Cómo usar este archivo:** pega este bloque **al final** de tu `documentacion/decisiones.md` existente (no reemplaces lo que ya tienes). Si el archivo aún no existe, créalo con este contenido.

### DML-01 — SELECT antes de UPDATE y DELETE

**Decisión:**
Se utiliza `SELECT` antes de `UPDATE` y `DELETE`.

**Justificación:**
Permite verificar previamente qué registros serán afectados y reducir el riesgo de modificar o eliminar información incorrecta. El `SELECT` usa exactamente la misma condición `WHERE` que la operación posterior.

### DML-02 — SELECT de verificación después de cada modificación

**Decisión:**
Toda operación `INSERT`, `UPDATE` o `DELETE` va seguida de un `SELECT` que comprueba su efecto.

**Justificación:**
Convierte `SELECT` en herramienta de validación y deja evidencia del proceso en el script, no solo del resultado final (ciclo `SELECT → INSERT → SELECT → UPDATE → SELECT → DELETE → SELECT`).

### DML-03 — Nunca `UPDATE` ni `DELETE` sin `WHERE`

**Decisión:**
Ningún `UPDATE` ni `DELETE` del proyecto se escribe sin cláusula `WHERE`.

**Justificación:**
Sin `WHERE` la instrucción afecta todas las filas de la tabla (por ejemplo, todos los proyectos). El `WHERE` limita la operación a los registros de práctica.

### DML-04 — No insertar valores en columnas `IDENTITY`

**Decisión:**
En los `INSERT` no se incluyen `id_proyecto`, `id_cientifico`, `id_dataset` ni `id_experimento`; los genera `IDENTITY(1,1)`.

**Justificación:**
Evita conflictos de PK y respeta el diseño del modelo: el identificador es responsabilidad del motor, no de quien inserta.

### DML-05 — Resolver las FK por clave natural, no por ID escrito a mano

**Decisión:**
Para crear un `experimento`, `id_proyecto` e `id_cientifico` se obtienen con una consulta por nombre del proyecto y correo del científico (`INSERT ... SELECT`).

**Justificación:**
Hace el script reproducible aunque `IDENTITY` genere otros números, y garantiza que las referencias existan antes de insertar.

### DML-06 — Orden de inserción según las claves foráneas

**Decisión:**
Los datos relacionados se insertan en el orden `cientifico_datos → proyecto → dataset → experimento`, y se eliminan en orden inverso (hijos antes que padres).

**Justificación:**
`experimento` depende de `proyecto` y de `cientifico_datos`; un hijo no puede existir sin su padre. El orden inverso en `DELETE` evita violar la integridad referencial.

### DML-07 — Transacciones con `ROLLBACK` para pruebas riesgosas

**Decisión:**
Las pruebas con riesgo (`UPDATE` de prueba y `DELETE` de un proyecto con experimentos) se ejecutan dentro de `BEGIN TRANSACTION` y terminan en `ROLLBACK`; los cambios que se desean conservar se confirman con `COMMIT`.

**Justificación:**
Permite observar el efecto de una operación sin perder datos, y la política `ON DELETE` puede probarse sin importar si es `NO ACTION` o `CASCADE`.

### DML-08 — Datos de práctica identificables y errores capturados con `TRY/CATCH`

**Decisión:**
Los registros de práctica llevan nombres reconocibles (`(practica S06)`, `Proyecto Temporal DELETE S06`, `Proyecto CRUD DataLab`) y las pruebas de integridad se envuelven en `BEGIN TRY ... BEGIN CATCH`.

**Justificación:**
Los registros de práctica no se confunden con datos semilla ni con datos reales del equipo, y se pueden limpiar con seguridad. `TRY/CATCH` muestra el número y mensaje del error (547 FK, 2627 UNIQUE) sin interrumpir el script, lo que documenta qué restricción intervino.
