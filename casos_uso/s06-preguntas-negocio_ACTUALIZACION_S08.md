
---

# Actualización Semana 8 — Preguntas de negocio resueltas con filtros y agregación

> **Instrucción de uso:** pega este bloque AL FINAL de `casos_uso/s06-preguntas-negocio.md`. No reemplaces el contenido anterior.
> Las líneas marcadas con `⟵ PEGAR` deben llenarse con la salida real que obtengas en SSMS (copiar la tabla de resultados), porque dependen de tus datos semilla.
> Consultas ejecutadas desde: `scripts/consultas/s08-filtros-orden-agregacion.sql`

---

## Actividad 16 — Pregunta de la Semana 6 retomada

**Pregunta:**
¿Cuál es el desempeño promedio de cada tipo de métrica y cuáles superan un umbral de calidad de 0.8?

**Objetivo:**
Resumir en una sola consulta cientos de mediciones de `metrica` por tipo (accuracy, f1, etc.) y detectar cuáles tipos tienen un desempeño promedio aceptable. En la Semana 6 esto obligaba a revisar fila por fila o calcular a mano; ahora lo hacen `GROUP BY`, `AVG()` y `HAVING`.

**Consulta SQL:**
```sql
SELECT nombre_metrica, AVG(valor) AS promedio
FROM metrica
GROUP BY nombre_metrica
HAVING AVG(valor) > 0.8
ORDER BY promedio DESC;
```

**Resultado:**
```text
⟵ PEGAR la tabla de resultados de SSMS aquí
```

**Interpretación:**
Cada fila es un tipo de métrica cuyo promedio supera 0.8. Los tipos que no aparecen tienen promedio ≤ 0.8 (o no tienen filas). Se usa `HAVING` y no `WHERE` porque la condición es sobre el promedio del grupo, que no existe hasta después de agrupar. Si el resultado sale vacío, significa que ningún tipo supera el umbral con los datos actuales, no que la consulta esté mal.

---

## Actividad 17 — Preguntas de negocio

### Pregunta de negocio 1 — Datasets por fuente
**Objetivo:** conocer cuántos datasets son internos y cuántos externos (dependencia de datos de terceros).
**Requisito:** `GROUP BY + COUNT`
```sql
SELECT fuente, COUNT(*) AS cantidad
FROM dataset
GROUP BY fuente;
```
**Resultado:** `⟵ PEGAR`
**Interpretación:** la suma de la columna `cantidad` debe ser igual a `SELECT COUNT(*) FROM dataset`. Solo existen dos valores posibles por la restricción `chk_dataset_fuente` (`interna`, `externa`).

### Pregunta de negocio 2 — Experimentos por estado
**Objetivo:** ver el avance del trabajo del laboratorio (cuántos están planificados, en ejecución, exitosos o fallidos).
**Requisito:** `GROUP BY estado + COUNT`
```sql
SELECT estado, COUNT(*) AS cantidad
FROM experimento
GROUP BY estado;
```
**Resultado:** `⟵ PEGAR`
**Interpretación:** si aparece una fila con `estado` vacío (NULL), son experimentos a los que no se les asignó estado; `GROUP BY` agrupa los NULL en un solo grupo.

### Pregunta de negocio 3 — Promedio por tipo de métrica
**Objetivo:** comparar el desempeño medio de cada tipo de métrica.
**Requisito:** `GROUP BY + AVG`
```sql
SELECT nombre_metrica, AVG(valor) AS promedio
FROM metrica
GROUP BY nombre_metrica;
```
**Resultado:** `⟵ PEGAR`
**Interpretación:** como `valor` está restringido entre 0 y 1 (`chk_metrica_valor`), todos los promedios están en ese rango; más cercano a 1 = mejor desempeño medio.

### Pregunta de negocio 4 — Métricas con promedio > 0.8
**Objetivo:** identificar los tipos de métrica con alto desempeño.
**Requisito:** `GROUP BY + AVG + HAVING`
```sql
SELECT nombre_metrica, AVG(valor) AS promedio
FROM metrica
GROUP BY nombre_metrica
HAVING AVG(valor) > 0.8;
```
**Resultado:** `⟵ PEGAR`
**Interpretación:** es un subconjunto del resultado de la PN3 (solo los grupos que pasan el filtro).

### Pregunta de negocio 5 — Dataset más reciente de cada fuente
**Objetivo:** saber cuál es la carga más actual por origen de datos.
**Requisito:** filtro + ordenamiento (con documentación de la limitación)

**Limitación:** obtener el *nombre* y la fecha del dataset más reciente de **cada** fuente en una sola consulta requiere subconsultas, `JOIN` o funciones de ventana (`ROW_NUMBER() OVER (PARTITION BY fuente ...)`), temas posteriores. Con lo visto esta semana hay dos aproximaciones:

```sql
-- Aproximación A: solo la FECHA más reciente por fuente (agregación)
SELECT fuente, MAX(fecha_carga) AS fecha_mas_reciente
FROM dataset
GROUP BY fuente;

-- Aproximación B: nombre y fecha, una fuente por consulta (filtro + orden)
SELECT TOP 1 nombre, fuente, fecha_carga
FROM dataset
WHERE fuente = 'interna'
ORDER BY fecha_carga DESC;

SELECT TOP 1 nombre, fuente, fecha_carga
FROM dataset
WHERE fuente = 'externa'
ORDER BY fecha_carga DESC;
```
**Resultado:** `⟵ PEGAR (A y B)`
**Interpretación:** A responde "¿cuándo?" pero no "¿cuál?"; B responde ambas, pero hay que repetir la consulta por fuente y, ante empates de fecha, `TOP 1` devuelve solo una fila.

### Pregunta de negocio 6 — Experimentos exitosos o fallidos
**Requisito:** `IN`
```sql
SELECT id_experimento, id_proyecto, estado
FROM experimento
WHERE estado IN ('exitoso', 'fallido');
```
**Resultado:** `⟵ PEGAR`
**Interpretación:** son los experimentos ya *concluidos* (con desenlace conocido); los planificados o en ejecución quedan fuera.

### Pregunta de negocio 7 — Datasets con notas
**Requisito:** `IS NOT NULL`
```sql
SELECT id_dataset, nombre, notas
FROM dataset
WHERE notas IS NOT NULL;
```
**Resultado:** `⟵ PEGAR`
**Interpretación:** son los datasets documentados; los que no aparecen no tienen observaciones registradas.

### Pregunta de negocio 8 — Métricas entre 0.70 y 0.90
**Requisito:** `BETWEEN`
```sql
SELECT id_metrica, nombre_metrica, valor
FROM metrica
WHERE valor BETWEEN 0.70 AND 0.90;
```
**Resultado:** `⟵ PEGAR`
**Interpretación:** `BETWEEN` incluye los extremos (0.70 y 0.90 sí aparecen). Es la franja de desempeño "aceptable pero mejorable".

---

## Actividad 18 — Pregunta de negocio propia del equipo

**Pregunta de negocio:**
¿Qué fuentes de datos aportan más de un millón de filas en total y cuántos datasets componen cada una?

**¿Por qué es importante?**
El volumen de datos condiciona el costo de almacenamiento y el tiempo de entrenamiento. Si una fuente concentra gran parte de las filas, el laboratorio depende de ella y debe cuidar su calidad y disponibilidad.

**Tablas utilizadas:** `dataset`

**Consulta SQL:**
```sql
SELECT fuente,
       COUNT(*)           AS datasets,
       SUM(tamanio_filas) AS filas_totales
FROM dataset
GROUP BY fuente
HAVING SUM(tamanio_filas) > 1000000
ORDER BY filas_totales DESC;
```

**Resultado:**
```text
⟵ PEGAR la tabla de resultados de SSMS aquí
(si queda vacía, ajusta el umbral 1000000 a uno acorde con tus datos semilla)
```

**Interpretación:**
Cada fila es una fuente con más de un millón de filas acumuladas. Cumple los cuatro requisitos: tiene contexto de negocio, es verificable contra los datos, usa SQL y su respuesta (qué fuente pesa más) es interpretable. Usa solo conceptos hasta la Semana 8 (sin `JOIN`). Nota: `SUM` ignora los `tamanio_filas` NULL.
