# Semana 8 — Actividades y Ejercicios (RESUELTO)

## DML completo, filtros, operadores, orden y funciones de agregación

**Caso hilo conductor:** DataLab
**Motor usado:** SQL Server (SSMS). Equivalencias MySQL en la Actividad 21.

> **Nota sobre los resultados:** las consultas están listas para ejecutar. Donde dice `⟵ PEGAR` debes copiar la salida real de tu SSMS, porque depende de tus datos semilla. Las respuestas conceptuales sí están completas.
>
> **Nota sobre nombres de columnas:** en el DDL de DataLab la tabla `proyecto` tiene la columna `nombre_proyecto` (las guías usan `nombre`). Aquí se usa `nombre_proyecto`.

---

# 1. Objetivo

Aplicar de manera práctica: `INSERT`, `SELECT`, `UPDATE`, `DELETE`, `WHERE`, operadores de comparación, `BETWEEN`, `IN`, `LIKE`, `IS NULL`, `IS NOT NULL`, `AND`, `OR`, `NOT`, `ORDER BY`, `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`, y resolver preguntas de negocio con los datos de DataLab.

---

# 2. Entorno de trabajo

Base de datos: `datalab`.
Archivo principal de consultas: `scripts/consultas/s08-filtros-orden-agregacion.sql`
Preguntas de negocio: `casos_uso/s06-preguntas-negocio.md`

---

# BLOQUE 1 — Actividades conceptuales

## Actividad 1 — Los cuatro comandos DML

| Comando | ¿Qué hace? | Tabla DataLab donde lo aplicarías |
|---|---|---|
| `INSERT` | Agrega filas nuevas a una tabla. | `dataset`: registrar un dataset recién cargado. |
| `SELECT` | Consulta datos sin modificarlos. | `metrica`: ver las métricas de un modelo. |
| `UPDATE` | Cambia valores de filas que ya existen. | `experimento`: cambiar `estado` de `en_ejecucion` a `exitoso`. |
| `DELETE` | Elimina filas completas (la tabla sigue existiendo). | `proyecto`: borrar el proyecto de prueba `FILA_DE_PRUEBA_BORRAR`. |

### Pregunta Feynman
**Diferencia entre `UPDATE` y `ALTER TABLE`:**

- `UPDATE` es **DML**: cambia **datos**. Es como corregir lo que está escrito dentro de las casillas de una hoja de cálculo. Ejemplo: `UPDATE experimento SET estado = 'exitoso' WHERE id_experimento = 1;`
- `ALTER TABLE` es **DDL**: cambia la **estructura**. Es como agregar, quitar o cambiar de tipo una *columna* completa de la hoja. Ejemplo: `ALTER TABLE experimento ADD estado VARCHAR(20);`

Regla corta: *ALTER cambia la forma de la tabla; UPDATE cambia lo que contiene.*

---

# Actividad 2 — UPDATE y DELETE sin WHERE

```sql
UPDATE experimento
SET estado = 'fallido';
```

1. **¿Es válida?** Sí. La sintaxis es correcta y SQL Server la ejecuta sin advertencia.
2. **¿Qué filas modifica?** **Todas** las filas de `experimento`, porque sin `WHERE` no hay condición que limite el conjunto.
3. **¿Por qué es peligrosa?** Sobrescribe el estado de todos los experimentos (también los exitosos) y, fuera de una transacción, no hay "deshacer". Los valores originales se pierden salvo que exista un respaldo.
4. **¿Cómo comprobar primero qué filas se afectan?** Con el `SELECT` equivalente (misma condición):
   ```sql
   SELECT COUNT(*) FROM experimento;   -- cuántas filas afectaría
   SELECT * FROM experimento;          -- cuáles (aquí: todas)
   ```
   Si la intención era un solo experimento, el `SELECT` debe devolver 1 fila: `SELECT * FROM experimento WHERE id_experimento = 1;`. Y tras el `UPDATE`, SSMS muestra `(N rows affected)`: ese N debe coincidir con lo esperado.

```sql
DELETE FROM experimento;
```

**Diferencia entre eliminar las filas y eliminar la tabla:**

| | `DELETE FROM experimento;` | `DROP TABLE experimento;` |
|---|---|---|
| Tipo | DML | DDL |
| Qué borra | Los datos (las filas) | La tabla completa: estructura, restricciones, índices y datos |
| ¿Existe la tabla después? | **Sí**, vacía, con sus columnas y restricciones | **No** |

**Advertencia específica de DataLab (por el DDL de la Semana 5):** `modelo` y `uso_dataset` tienen `FOREIGN KEY ... ON DELETE CASCADE` hacia `experimento`, y `metrica` lo tiene hacia `modelo`. Por eso `DELETE FROM experimento;` **borraría en cascada** todos los modelos, métricas y usos de dataset. Una instrucción sin `WHERE` puede vaciar cuatro tablas, no una.

---

# Actividad 3 — Operadores

| Operador | Ejemplo (DataLab) | ¿Qué busca? |
|---|---|---|
| `=` | `SELECT * FROM experimento WHERE estado = 'exitoso';` | Experimentos cuyo estado es exactamente `exitoso`. |
| `<>` | `SELECT * FROM metrica WHERE valor <> 0;` | Métricas con valor distinto de cero. |
| `>` | `SELECT * FROM metrica WHERE valor > 0.80;` | Métricas estrictamente mayores a 0.80 (el 0.80 no entra). |
| `<` | `SELECT * FROM metrica WHERE valor < 0.50;` | Métricas estrictamente menores a 0.50. |
| `>=` | `SELECT * FROM dataset WHERE tamanio_filas >= 1000000;` | Datasets con un millón de filas o más. |
| `<=` | `SELECT * FROM metrica WHERE valor <= 0.50;` | Métricas de 0.50 o menos. |
| `BETWEEN` | `SELECT * FROM metrica WHERE valor BETWEEN 0.70 AND 0.90;` | Valores en el intervalo 0.70 a 0.90, **incluyendo ambos extremos**. |
| `IN` | `SELECT * FROM experimento WHERE estado IN ('exitoso','fallido');` | Estado igual a cualquiera de los valores de la lista. |
| `LIKE` | `SELECT * FROM dataset WHERE nombre LIKE 'EEG%';` | Nombres que empiezan por `EEG` (`%` = cero o más caracteres). |
| `IS NULL` | `SELECT * FROM dataset WHERE notas IS NULL;` | Datasets cuyo campo `notas` está vacío (sin valor). |
| `IS NOT NULL` | `SELECT * FROM dataset WHERE notas IS NOT NULL;` | Datasets que sí tienen algo en `notas`. |

---

# Actividad 4 — NULL

```sql
SELECT *
FROM dataset
WHERE notas = NULL;
```

**¿Por qué no es correcta?**
`NULL` significa "valor desconocido/ausente". Comparar algo desconocido con `=` da como resultado *desconocido* (`UNKNOWN`), no *verdadero*. `WHERE` solo deja pasar las filas cuya condición es verdadera, así que **nunca devuelve filas**, ni siquiera las que sí tienen `notas` nulo. Además no genera error, lo que la hace engañosa: parece funcionar y devuelve "0 filas".

**Consulta correcta:**
```sql
SELECT *
FROM dataset
WHERE notas IS NULL;
```

---

# Actividad 5 — AND, OR y NOT

### a) Experimentos exitosos
```sql
SELECT * FROM experimento WHERE estado = 'exitoso';
```
### b) Experimentos exitosos o fallidos
```sql
SELECT * FROM experimento
WHERE estado = 'exitoso' OR estado = 'fallido';
```
### c) Métricas entre 0.70 y 0.90
```sql
SELECT * FROM metrica
WHERE valor >= 0.70 AND valor <= 0.90;
-- equivalente: WHERE valor BETWEEN 0.70 AND 0.90
```
### d) Experimentos cuyo estado no sea `fallido`
```sql
SELECT * FROM experimento WHERE NOT estado = 'fallido';
-- equivalente: WHERE estado <> 'fallido'
```
(Los experimentos con `estado` NULL tampoco aparecen: `NOT UNKNOWN` sigue siendo `UNKNOWN`.)

### e) `AND` y `OR` con paréntesis
```sql
SELECT * FROM experimento
WHERE (estado = 'exitoso' OR estado = 'fallido')
  AND id_proyecto > 1;
```
**¿Por qué los paréntesis?** `AND` se evalúa **antes** que `OR`. Sin paréntesis:
```sql
WHERE estado = 'exitoso' OR estado = 'fallido' AND id_proyecto > 1
```
SQL lo lee como `estado = 'exitoso' OR (estado = 'fallido' AND id_proyecto > 1)`, es decir, trae **todos** los exitosos (de cualquier proyecto) y solo los fallidos del proyecto > 1. Con paréntesis se obliga a evaluar primero "exitoso o fallido" y luego aplicar el filtro de proyecto a ambos. Los paréntesis hacen explícita la intención.

---

# BLOQUE 2 — Laboratorio de filtros

## Actividad 6 — Filtros básicos

```sql
-- 1. Proyecto por nombre
SELECT * FROM proyecto WHERE nombre_proyecto = 'Proyecto IA';

-- 2. Métricas mayores a 0.80
SELECT * FROM metrica WHERE valor > 0.80;

-- 3. Métricas menores o iguales a 0.50
SELECT * FROM metrica WHERE valor <= 0.50;

-- 4. Métricas entre 0.70 y 0.90
SELECT * FROM metrica WHERE valor BETWEEN 0.70 AND 0.90;

-- 5. Experimentos con estado dentro de una lista
SELECT * FROM experimento
WHERE estado IN ('planificado', 'en_ejecucion', 'exitoso');

-- 6. Datasets cuyo nombre comienza por una palabra
SELECT * FROM dataset WHERE nombre LIKE 'EEG%';

-- 7. Datasets sin notas
SELECT * FROM dataset WHERE notas IS NULL;

-- 8. Datasets con notas
SELECT * FROM dataset WHERE notas IS NOT NULL;
```
**Resultados:** `⟵ PEGAR (uno por consulta)`
Guardadas en `scripts/consultas/s08-filtros-orden-agregacion.sql` (secciones 2 a 6).

---

# Actividad 7 — Comparación de operadores

```sql
-- Consulta A → OR
SELECT * FROM experimento
WHERE estado = 'planificado' OR estado = 'en_ejecucion' OR estado = 'exitoso';

-- Consulta B → IN
SELECT * FROM experimento
WHERE estado IN ('planificado', 'en_ejecucion', 'exitoso');

-- Consulta C → NOT IN
SELECT * FROM experimento
WHERE estado NOT IN ('fallido', 'exitoso');
```

**¿Cuándo conviene cada una?**

| Consulta | Cuándo usarla |
|---|---|
| `OR` | Cuando las condiciones son de **columnas distintas** o de tipo distinto (`estado = 'exitoso' OR id_proyecto = 3`), o con operadores diferentes (`>`, `LIKE`). Con muchos valores de una misma columna se vuelve larga y propensa a errores. |
| `IN` | Cuando se compara **una misma columna** con una lista de valores. Es equivalente a varios `OR` pero más corta y legible. |
| `NOT IN` | Cuando es más fácil **listar lo que se excluye** que lo que se incluye (todo menos fallidos y exitosos). Precaución: si la columna tiene `NULL`, esas filas no aparecen, y si la lista contiene un `NULL` el resultado queda vacío. |

*Observación:* A y B devuelven exactamente el mismo resultado; C devuelve los estados restantes (los no listados).

---

# Actividad 8 — LIKE

```sql
-- 1. Comienzan por EEG
SELECT * FROM dataset WHERE nombre LIKE 'EEG%';

-- 2. Terminan en una palabra elegida (ej. 'Clinicos')
SELECT * FROM dataset WHERE nombre LIKE '%Clinicos';

-- 3. Contienen una palabra (ej. 'Ventas')
SELECT * FROM dataset WHERE nombre LIKE '%Ventas%';

-- 4. Patrón con "_" (un solo carácter cualquiera)
SELECT * FROM dataset WHERE nombre LIKE '_EG%';      -- 1 carácter + EG + lo que sea
SELECT * FROM dataset WHERE nombre LIKE 'EEG_%';     -- EEG + al menos 1 carácter más
SELECT nombre, LEN(nombre) AS longitud
FROM dataset WHERE nombre LIKE '______';              -- exactamente 6 caracteres
```
**Documentación del resultado:** `⟵ PEGAR los nombres devueltos por cada patrón`

**Diferencia clave entre comodines:** `%` reemplaza **cero o más** caracteres; `_` reemplaza **exactamente uno**. Por eso `'EEG%'` encuentra `EEG` solo, pero `'EEG_%'` no (exige al menos un carácter después). La sensibilidad a mayúsculas depende de la *collation*; con las predeterminadas de SQL Server y MySQL no distingue.

---

# BLOQUE 3 — Ordenamiento

## Actividad 9 — ORDER BY

```sql
-- a) Nombre ascendente
SELECT nombre, fecha_carga, tamanio_filas FROM dataset ORDER BY nombre ASC;

-- b) Fecha de carga descendente
SELECT nombre, fecha_carga, tamanio_filas FROM dataset ORDER BY fecha_carga DESC;

-- c) Fuente y, en empate, fecha de carga descendente
SELECT nombre, fuente, fecha_carga, tamanio_filas
FROM dataset
ORDER BY fuente ASC, fecha_carga DESC;
```

### Pregunta: si dos datasets tienen la misma fuente, ¿qué criterio decide cuál aparece primero?
La **fecha de carga en orden descendente**: aparece primero el cargado más recientemente. `ORDER BY` evalúa los criterios de izquierda a derecha; el segundo solo se usa para desempatar el primero. Si además coincide la fecha, el orden entre ambos no está garantizado (se necesitaría un tercer criterio, p. ej. `id_dataset`).

---

# BLOQUE 4 — Funciones de agregación

## Actividad 10 — COUNT

```sql
SELECT COUNT(*) AS total_datasets     FROM dataset;       -- 1
SELECT COUNT(*) AS total_experimentos FROM experimento;   -- 2
SELECT COUNT(*) AS total_modelos      FROM modelo;        -- 3
SELECT COUNT(*) AS total_metricas     FROM metrica;       -- 4
```
Los cuatro en un solo resultado:
```sql
SELECT
    (SELECT COUNT(*) FROM dataset)     AS datasets,
    (SELECT COUNT(*) FROM experimento) AS experimentos,
    (SELECT COUNT(*) FROM modelo)      AS modelos,
    (SELECT COUNT(*) FROM metrica)     AS metricas;
```
**Resultado:** `⟵ PEGAR`
`COUNT(*)` cuenta filas; `COUNT(columna)` cuenta solo las filas donde esa columna **no** es NULL.

---

# Actividad 11 — AVG, MIN y MAX

```sql
-- Sobre toda la tabla
SELECT AVG(valor) AS promedio, MIN(valor) AS minimo, MAX(valor) AS maximo
FROM metrica;

-- Agrupado por nombre_metrica
SELECT nombre_metrica,
       AVG(valor) AS promedio,
       MIN(valor) AS minimo,
       MAX(valor) AS maximo
FROM metrica
GROUP BY nombre_metrica;
```
**Resultado:** `⟵ PEGAR (ambas)`
La primera devuelve **una sola fila** (resumen de todo); la segunda, **una fila por tipo de métrica**.

---

# Actividad 12 — GROUP BY

```sql
-- a) Datasets por fuente
SELECT fuente, COUNT(*) AS cantidad FROM dataset GROUP BY fuente;

-- b) Experimentos por estado
SELECT estado, COUNT(*) AS cantidad FROM experimento GROUP BY estado;

-- c) Métricas por tipo
SELECT nombre_metrica, COUNT(*) AS cantidad FROM metrica GROUP BY nombre_metrica;
```
**Resultado:** `⟵ PEGAR (a, b y c)`
**Regla:** toda columna del `SELECT` que no esté dentro de una función de agregación debe aparecer en el `GROUP BY`; si no, SQL Server da error.

---

# Actividad 13 — HAVING

```sql
SELECT nombre_metrica, AVG(valor) AS promedio
FROM metrica
GROUP BY nombre_metrica
HAVING AVG(valor) > 0.8;
```
**Resultado:** `⟵ PEGAR`

**¿Por qué no `WHERE AVG(valor) > 0.8`?**
`WHERE` se ejecuta **antes** de agrupar, cuando solo existen filas individuales; el promedio de un grupo todavía no se ha calculado. Por eso SQL lo rechaza con el error *"An aggregate may not appear in the WHERE clause…"*. `HAVING` se ejecuta **después** de agrupar y calcular las agregaciones, así que puede filtrar grupos.

Orden lógico: `FROM → WHERE → GROUP BY → agregaciones → HAVING → SELECT → ORDER BY`.

---

# BLOQUE 5 — UPDATE seguro

## Actividad 14 — SELECT primero

Registro elegido: dataset con `id_dataset = 1` (columna `notas`). Se identifica por clave primaria, así que solo puede afectar una fila.

### Paso 1 — SELECT
```sql
SELECT id_dataset, nombre, notas
FROM dataset
WHERE id_dataset = 1;
```
### Paso 2 — UPDATE
```sql
UPDATE dataset
SET notas = 'Correccion realizada en Semana 8'
WHERE id_dataset = 1;
```
SSMS debe mostrar `(1 row affected)`.
### Paso 3 — SELECT de verificación
```sql
SELECT id_dataset, nombre, notas
FROM dataset
WHERE id_dataset = 1;
```

### Evidencia
| Elemento | Valor |
|---|---|
| Valor inicial | `⟵ PEGAR el valor de notas del Paso 1 (puede ser NULL)` |
| Valor modificado | `Correccion realizada en Semana 8` |
| Condición en `WHERE` | `id_dataset = 1` (clave primaria → una sola fila) |
| Resultado después del `UPDATE` | `⟵ PEGAR salida del Paso 3` + mensaje `(1 row affected)` |

---

# BLOQUE 6 — DELETE seguro

## Actividad 15 — Registro de prueba

```sql
-- 0. Insertar fila identificable
INSERT INTO proyecto (nombre_proyecto, descripcion)
VALUES ('FILA_DE_PRUEBA_BORRAR', 'Registro creado para practicar DELETE');

-- 1. Comprobar existencia (debe devolver 1 fila)
SELECT * FROM proyecto WHERE nombre_proyecto = 'FILA_DE_PRUEBA_BORRAR';

-- 2. Eliminar
DELETE FROM proyecto WHERE nombre_proyecto = 'FILA_DE_PRUEBA_BORRAR';

-- 3. Comprobar nuevamente (debe devolver 0 filas)
SELECT * FROM proyecto WHERE nombre_proyecto = 'FILA_DE_PRUEBA_BORRAR';
```
**Evidencia:** `⟵ PEGAR el resultado de los pasos 1 (1 fila) y 3 (0 filas)`

### Pregunta: ¿por qué es importante que el registro de prueba sea claramente identificable?
1. Garantiza que el `WHERE` apunte **solo** a esa fila: un nombre único e improbable no coincide con datos reales.
2. Si el `WHERE` se escribe mal, el daño se detecta de inmediato porque el `SELECT` previo mostraría más de una fila.
3. Evita que quede basura en la base: el nombre deja claro que debe borrarse.
4. No tiene filas hijas en `experimento`, así que el `ON DELETE CASCADE` de `proyecto → experimento` no arrastra datos reales. Practicar sobre datos reales sería irreversible.

---

# BLOQUE 7 — Preguntas de negocio

## Actividad 16 — Retomar las preguntas de la Semana 6

```text
Pregunta:
¿Cuál es el desempeño promedio de cada tipo de métrica y cuáles superan un umbral de 0.8?

Objetivo:
Resumir las mediciones de la tabla metrica por tipo y detectar los tipos con desempeño medio alto, sin revisar fila por fila.

Consulta SQL:
SELECT nombre_metrica, AVG(valor) AS promedio
FROM metrica
GROUP BY nombre_metrica
HAVING AVG(valor) > 0.8
ORDER BY promedio DESC;

Resultado:
⟵ PEGAR la tabla de SSMS

Interpretación:
Cada fila es un tipo de métrica con promedio mayor a 0.8. Se usa HAVING porque la condición se aplica al promedio del grupo. Si no hay filas, ningún tipo supera el umbral con los datos actuales.
```
(Versión completa también en `s06-preguntas-negocio_ACTUALIZACION_S08.md`.)

---

## Actividad 17 — Nuevas preguntas de negocio

**PN1 — ¿Cuántos datasets existen por fuente?** (`GROUP BY + COUNT`)
```sql
SELECT fuente, COUNT(*) AS cantidad FROM dataset GROUP BY fuente;
```
Resultado: `⟵ PEGAR`

**PN2 — ¿Cuántos experimentos hay en cada estado?** (`GROUP BY estado + COUNT`)
```sql
SELECT estado, COUNT(*) AS cantidad FROM experimento GROUP BY estado;
```
Resultado: `⟵ PEGAR`

**PN3 — ¿Cuál es el promedio de cada tipo de métrica?** (`GROUP BY + AVG`)
```sql
SELECT nombre_metrica, AVG(valor) AS promedio FROM metrica GROUP BY nombre_metrica;
```
Resultado: `⟵ PEGAR`

**PN4 — ¿Qué tipos de métrica tienen promedio superior a 0.8?** (`GROUP BY + AVG + HAVING`)
```sql
SELECT nombre_metrica, AVG(valor) AS promedio
FROM metrica
GROUP BY nombre_metrica
HAVING AVG(valor) > 0.8;
```
Resultado: `⟵ PEGAR`

**PN5 — ¿Cuál es el dataset más reciente de cada fuente?** (filtro + ordenamiento)

*Limitación documentada:* mostrar nombre y fecha del más reciente de **cada** fuente en una sola consulta exige subconsultas, `JOIN` o funciones de ventana (`ROW_NUMBER() OVER (PARTITION BY fuente ORDER BY fecha_carga DESC)`), aún no vistas.

*Aproximación A (solo la fecha, con agregación):*
```sql
SELECT fuente, MAX(fecha_carga) AS fecha_mas_reciente
FROM dataset
GROUP BY fuente;
```
*Aproximación B (nombre y fecha, una fuente por consulta):*
```sql
SELECT TOP 1 nombre, fuente, fecha_carga FROM dataset
WHERE fuente = 'interna' ORDER BY fecha_carga DESC;

SELECT TOP 1 nombre, fuente, fecha_carga FROM dataset
WHERE fuente = 'externa' ORDER BY fecha_carga DESC;
```
Resultado: `⟵ PEGAR (A y B)`
Limitación de B: hay que repetirla por fuente, y ante empate de fecha `TOP 1` devuelve solo una fila.

**PN6 — ¿Qué experimentos tienen estado exitoso o fallido?** (`IN`)
```sql
SELECT id_experimento, id_proyecto, estado
FROM experimento WHERE estado IN ('exitoso', 'fallido');
```
Resultado: `⟵ PEGAR`

**PN7 — ¿Qué datasets tienen información en `notas`?** (`IS NOT NULL`)
```sql
SELECT id_dataset, nombre, notas FROM dataset WHERE notas IS NOT NULL;
```
Resultado: `⟵ PEGAR`

**PN8 — ¿Qué métricas tienen valores entre 0.70 y 0.90?** (`BETWEEN`)
```sql
SELECT id_metrica, nombre_metrica, valor FROM metrica WHERE valor BETWEEN 0.70 AND 0.90;
```
Resultado: `⟵ PEGAR`

---

## Actividad 18 — Pregunta de negocio propia

```text
Pregunta de negocio:
¿Qué fuentes de datos aportan más de un millón de filas en total y cuántos datasets componen cada una?

¿Por qué es importante?
El volumen condiciona el costo de almacenamiento y el tiempo de entrenamiento. Si una fuente concentra la mayoría de las filas, el laboratorio depende de ella y debe cuidar su calidad y disponibilidad.

Tablas utilizadas:
dataset

Consulta SQL:
SELECT fuente,
       COUNT(*)           AS datasets,
       SUM(tamanio_filas) AS filas_totales
FROM dataset
GROUP BY fuente
HAVING SUM(tamanio_filas) > 1000000
ORDER BY filas_totales DESC;

Resultado:
⟵ PEGAR (si sale vacío, ajusta el umbral a tus datos)

Interpretación:
Cada fila es una fuente con más de un millón de filas acumuladas, ordenadas de mayor a menor. Usa solo conceptos hasta la Semana 8 (sin JOIN). SUM ignora los tamanio_filas NULL.
```

---

# BLOQUE 8 — Desafío Feynman

## Actividad 19 — Explícalo sin SQL: ¿diferencia entre WHERE y HAVING?

Imagina que tienes una caja con las fichas de todos los datasets.

- **WHERE** es el filtro que aplicas **antes** de hacer montones. Revisas ficha por ficha y descartas las que no sirven ("solo me quedo con las fichas de este año"). Mira **cada ficha individual**.
- Luego agrupas las fichas que sobrevivieron en montones (por ejemplo, uno por fuente) y calculas algo de cada montón (cuántas fichas tiene, su promedio).
- **HAVING** es el filtro que aplicas **después** de tener los montones. Ya no miras fichas sueltas, sino **montones completos** ("solo me quedo con los montones que tienen más de 10 fichas" o "con promedio mayor a 0.8").

En una frase: *WHERE decide qué filas entran a los grupos; HAVING decide qué grupos se quedan.* Por eso no puedes usar el promedio de un montón para descartar fichas antes de formar los montones: el promedio aún no existe.

---

## Actividad 20 — Explícalo con un ejemplo: `WHERE notas = NULL`

**Ejemplo cotidiano:** en una lista de invitados, la casilla "teléfono" de Ana está en blanco porque **no sabemos** su teléfono. Si preguntas "¿el teléfono de Ana es igual al teléfono de Luis?" y ambos están en blanco, la respuesta honesta es "no puedo saberlo", no "sí". Dos desconocidos no son necesariamente iguales.

SQL funciona igual: `NULL = NULL` no da verdadero, da *desconocido*, y `WHERE` solo conserva las filas verdaderas. Por eso `WHERE notas = NULL` devuelve **0 filas siempre**, aunque haya datasets sin notas.

**Solución:** no se pregunta "¿es igual a NULL?", sino "¿está ausente?":
```sql
WHERE notas IS NULL        -- datasets sin notas
WHERE notas IS NOT NULL    -- datasets con notas
```

---

# BLOQUE 9 — Comparación SQL Server / MySQL

## Actividad 21

**SQL Server**
```sql
SELECT TOP 5 *
FROM dataset
ORDER BY fecha_carga DESC;
```
**MySQL**
```sql
SELECT *
FROM dataset
ORDER BY fecha_carga DESC
LIMIT 5;
```

**Qué parte es idéntica:** `SELECT *`, `FROM dataset`, `ORDER BY fecha_carga DESC`. El ordenamiento (de más reciente a más antiguo) y el objetivo (los 5 datasets más recientes) son los mismos.

**Qué parte cambia:** la forma de limitar filas.

| | SQL Server | MySQL |
|---|---|---|
| Palabra clave | `TOP 5` | `LIMIT 5` |
| Posición | Justo después de `SELECT` | Al final de la consulta |

**Por qué cambia:** SQL estándar no definió originalmente cómo limitar filas, y cada fabricante implementó su propia sintaxis (T-SQL usa `TOP`; MySQL usa `LIMIT`). El estándar posterior `FETCH FIRST n ROWS ONLY` (y `OFFSET ... FETCH` en SQL Server) es la alternativa portable. En ambos casos el `ORDER BY` es imprescindible: sin él, "los 5 primeros" no tiene un orden definido.

Otras diferencias del esquema: fecha actual `GETDATE()` vs `NOW()`; longitud de texto `LEN()` vs `CHAR_LENGTH()`; autonumérico `IDENTITY(1,1)` vs `AUTO_INCREMENT`; texto largo `NVARCHAR(MAX)` vs `TEXT`.

---

# BLOQUE 10 — Entregable

El archivo `scripts/consultas/s08-filtros-orden-agregacion.sql` contiene todo lo exigido:

| Requisito | Sección del script |
|---|---|
| Operadores de comparación | 2 |
| `BETWEEN` | 3 |
| `IN` | 4 |
| `LIKE` | 5 |
| `IS NULL` / `IS NOT NULL` | 6 |
| `AND` / `OR` / `NOT` | 7 |
| `ORDER BY` con múltiples criterios | 8 |
| `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` | 9 |
| `GROUP BY` | 10 |
| `HAVING` | 11 |
| `UPDATE` seguro | 12 |
| `DELETE` seguro | 13 |
| Preguntas de negocio | 14 |
| Comparación SQL Server / MySQL | 15 |

Además se actualiza `casos_uso/s06-preguntas-negocio.md`.

---

# BLOQUE 11 — Git

```bash
git pull origin main
git add scripts/consultas/s08-filtros-orden-agregacion.sql
git add casos_uso/s06-preguntas-negocio.md
git commit -m "consulta: filtros, orden y funciones de agregación sobre DataLab"
git push origin main
```

---

# BLOQUE 12 — Checklist

- [x] Practiqué los cuatro comandos DML.
- [x] Comprendí el riesgo de `UPDATE` sin `WHERE`.
- [x] Comprendí el riesgo de `DELETE` sin `WHERE`.
- [x] Utilicé `=`, `<>`, `<`, `>`, `<=`, `>=`.
- [x] Utilicé `BETWEEN`.
- [x] Utilicé `IN`.
- [x] Utilicé `LIKE`.
- [x] Utilicé `IS NULL` e `IS NOT NULL`.
- [x] Combiné condiciones con `AND`, `OR` y `NOT`.
- [x] Utilicé paréntesis en condiciones complejas.
- [x] Utilicé `ORDER BY` con múltiples criterios.
- [x] Utilicé funciones de agregación.
- [x] Utilicé `GROUP BY`.
- [x] Utilicé `HAVING`.
- [x] Apliqué la disciplina de `SELECT` primero.
- [x] Realicé al menos un `UPDATE` controlado.
- [x] Realicé al menos un `DELETE` controlado.
- [x] Resolví preguntas de negocio.
- [x] Actualicé `casos_uso/s06-preguntas-negocio.md`.
- [x] Guardé las consultas en `scripts/consultas/s08-filtros-orden-agregacion.sql`.
- [x] Realicé el commit de la semana.

> Marca los `[x]` solo después de ejecutar realmente cada punto en SSMS.
