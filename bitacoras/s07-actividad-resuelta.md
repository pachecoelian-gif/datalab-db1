# Semana 7 — Guía de Actividad (resuelta)
## Evolución del esquema de DataLab con ALTER TABLE, restricciones y DROP

**Caso integrador:** DataLab  
**SGBD:** SQL Server  
**Herramienta:** SQL Server Management Studio (SSMS)  
**Modalidad:** Formalización + laboratorio  
**Repositorio:** https://github.com/pachecoelian-gif/datalab-db1  
**Integrante:** Elian Santiago Pacheco Vanegas  
**Fecha:** 2026-10-07

---

# 4. Preparar el entorno

- Paso 1: SSMS abierto y conectado a SQL Server.
- Paso 2: base seleccionada: `datalab`.
- Paso 3: tablas verificadas: `cientifico_datos`, `proyecto`, `dataset`, `experimento`, `modelo`, `metrica`, `participacion`, `uso_dataset`.
- Paso 4: se ejecutaron `SELECT * FROM experimento;` y `SELECT * FROM dataset;` y ambas tablas tienen datos semilla.

---

# 5. BLOQUE 1 — Formalización sin PC

## Paso 1 — Analizar el escenario

```text
Cambio 1
Agregar estado a experimento

Cambio 2
Agregar notas a dataset
```

```text
¿Por qué no sería apropiado volver a ejecutar
CREATE TABLE para resolver estos cambios?

Respuesta:

Porque las tablas ya existen y contienen datos. CREATE TABLE falla si el objeto
ya existe; para repetirlo habría que hacer DROP TABLE, y eso borraría los datos
y obligaría a reconstruir también las llaves foráneas de las tablas que la
referencian (experimento está relacionada con proyecto, modelo, métrica y
uso_dataset). ALTER TABLE modifica solo lo necesario y conserva los datos.
```

---

# 6. Paso 2 — Diseñar el cambio `estado`

```text
Nombre:
estado

Tipo:
VARCHAR(20)

¿Puede ser NULL?
No

DEFAULT:
planificado

CHECK:
planificado
en_ejecucion
exitoso
fallido
```

---

# 7. Paso 3 — Predecir el problema

```sql
ALTER TABLE experimento
ADD estado VARCHAR(20) NOT NULL;
```

```text
¿Qué ocurrirá si experimento ya tiene registros?

La instrucción fallará. SQL Server debe asignar un valor a la nueva columna en
cada fila existente; como es NOT NULL y no hay DEFAULT, no tiene ningún valor
válido que asignar (error 4901: "ALTER TABLE only allows columns to be added
that can contain nulls, or have a DEFAULT definition specified...").
Solo funcionaría si la tabla estuviera vacía.
```

```text
Filas existentes
      +
Nueva columna NOT NULL
      =
Error, salvo que exista un DEFAULT que indique qué valor recibirán.
```

---

# 8. Paso 4 — Diseñar la solución

```sql
ALTER TABLE experimento
ADD estado VARCHAR(20) NOT NULL
    CONSTRAINT df_experimento_estado
    DEFAULT 'planificado'
    WITH VALUES;
```

```text
¿Qué valor recibirán los registros existentes?

'planificado'. WITH VALUES hace que SQL Server aplique el DEFAULT también a las
filas que ya existían; sin esa cláusula, en una columna NOT NULL el DEFAULT
se usa de todas formas, pero en una columna que acepta NULL las filas viejas
quedarían en NULL.
```

---

# 9. Paso 5 — Diseñar el CHECK

```sql
ALTER TABLE experimento
ADD CONSTRAINT chk_experimento_estado
CHECK (estado IN ('planificado', 'en_ejecucion', 'exitoso', 'fallido'));
```

---

# 10. Paso 6 — Cambio en dataset

```text
Nombre:
notas

Tipo:
VARCHAR(MAX)

¿Puede ser NULL?
Sí. Las notas son opcionales y los datasets existentes no tienen ninguna.
```

```sql
ALTER TABLE dataset
ADD notas VARCHAR(MAX) NULL;
```

---

# 11. Paso 7 — Relación con UPDATE

```sql
UPDATE experimento
SET estado = 'exitoso'
WHERE id_experimento = 1;
```

```text
¿Por qué se utiliza WHERE?

Sin WHERE, el UPDATE se aplicaría a todas las filas y todos los experimentos
quedarían como 'exitoso'. WHERE limita el cambio al experimento 1.
```

---

# 12. Paso 8 — Relación con Git

```text
¿Por qué este cambio puede considerarse
una migración de esquema?

Porque lleva el esquema de una versión a la siguiente (experimento sin estado →
experimento con estado y CHECK; dataset sin notas → dataset con notas) mediante
un script incremental. El script queda guardado en Git, por lo que cualquiera
puede ver qué cambió, cuándo y por qué, y repetir la evolución en otra copia de
la base. Git versiona el diseño (los scripts); los backups protegen el contenido.
```

---

# 13. BLOQUE 2 — Laboratorio con PC

## Paso 1 — Verificar nuevamente los datos

```sql
SELECT * FROM experimento;
SELECT * FROM dataset;
```

Estado inicial: `experimento` sin la columna `estado`; `dataset` sin la columna `notas`.
Capturar pantalla de ambos resultados como evidencia "antes".

---

# 14. Paso 2 — Agregar `estado`

```sql
ALTER TABLE experimento
ADD estado VARCHAR(20) NOT NULL
    CONSTRAINT df_experimento_estado
    DEFAULT 'planificado'
    WITH VALUES;

SELECT id_experimento, estado
FROM experimento;
```

Resultado esperado: todas las filas muestran `planificado`.

---

# 15. Paso 3 — Agregar `CHECK`

```sql
ALTER TABLE experimento
ADD CONSTRAINT chk_experimento_estado
CHECK (
    estado IN ('planificado', 'en_ejecucion', 'exitoso', 'fallido')
);

SELECT id_experimento, estado
FROM experimento;
```

Resultado esperado: el comando se completa sin error (los datos ya cumplen la regla) y los valores no cambian.

---

# 16. Paso 4 — Probar el CHECK

```sql
UPDATE experimento
SET estado = 'terminado'
WHERE id_experimento = 1;
```

```text
¿Qué ocurrió?

SQL Server rechazó la operación con el error 547: "The UPDATE statement
conflicted with the CHECK constraint 'chk_experimento_estado'". La fila no
cambió.

¿Por qué SQL Server rechazó o aceptó la operación?

Porque 'terminado' no está en la lista permitida (planificado, en_ejecucion,
exitoso, fallido). SQL Server evalúa el CHECK en cada INSERT o UPDATE y rechaza
cualquier valor que no lo cumpla.
```

---

# 17. Paso 5 — Actualizar un estado válido

```sql
UPDATE experimento
SET estado = 'exitoso'
WHERE id_experimento = 1;

SELECT id_experimento, estado
FROM experimento
WHERE id_experimento = 1;
```

Resultado esperado: `1 | exitoso`.

---

# 18. Paso 6 — Agregar `notas`

```sql
ALTER TABLE dataset
ADD notas VARCHAR(MAX) NULL;

SELECT id_dataset, nombre, notas
FROM dataset;
```

Resultado esperado: la columna `notas` aparece con `NULL` en todas las filas.

---

# 19. Paso 7 — Agregar una restricción adicional

```sql
ALTER TABLE proyecto
ADD CONSTRAINT uq_proyecto_nombre
UNIQUE (nombre);
```

> Antes de ejecutar la restricción se verificó que no existan duplicados (ver Reto 25).

```text
Restricción agregada:

uq_proyecto_nombre — UNIQUE (nombre) sobre la tabla proyecto.

¿Por qué es necesaria?

Dos proyectos con el mismo nombre no se podrían distinguir al consultar,
reportar o asignar científicos y experimentos. La regla de negocio es que el
nombre identifica a cada proyecto; la base de datos debe garantizarla, no
depender de que quien digita no se equivoque.
```

> Si en tu tabla la columna se llama `nombre_proyecto`, usa ese nombre en esta sentencia.

---

# 20. Paso 8 — Practicar modificación de columna

```sql
ALTER TABLE dataset
ALTER COLUMN nombre VARCHAR(200) NOT NULL;
```

```text
¿Qué tamaño tenía?

VARCHAR(100)  (confirmar con INFORMATION_SCHEMA.COLUMNS antes de ejecutar)

¿Qué tamaño tendrá?

VARCHAR(200)

¿Por qué se amplía?

Los nombres de datasets suelen incluir origen, versión y año, y pueden superar
100 caracteres. Ampliar es seguro: todos los datos existentes caben en el nuevo
tamaño. Se repite NOT NULL porque ALTER COLUMN reemplaza toda la definición;
si se omitiera, la columna pasaría a aceptar NULL.
```

---

# 21. Paso 9 — Renombrar una columna

`CHANGE COLUMN` es sintaxis de MySQL. En SQL Server:

```sql
EXEC sp_rename
    'tabla_prueba_drop.dato',
    'dato_renombrado',
    'COLUMN';
```

Se practicó sobre la tabla desechable, no sobre una tabla real de DataLab, porque renombrar una columna real puede romper consultas, vistas, scripts y documentación que usen el nombre anterior. Diferencia de dialectos:

| Operación | MySQL | SQL Server |
|---|---|---|
| Modificar columna | `MODIFY COLUMN` | `ALTER COLUMN` |
| Renombrar columna | `CHANGE COLUMN` | `sp_rename` |

---

# 22. Paso 10 — Practicar DROP de forma segura

```sql
CREATE TABLE tabla_prueba_drop (
    id INT PRIMARY KEY,
    dato VARCHAR(50)
);

INSERT INTO tabla_prueba_drop
VALUES (1, 'prueba');

SELECT *
FROM tabla_prueba_drop;
```

Resultado esperado: `1 | prueba`.

---

# 23. Paso 11 — DROP COLUMN

```sql
ALTER TABLE tabla_prueba_drop
DROP COLUMN dato;   -- en el script se elimina dato_renombrado, ya renombrada en el paso 9
```

Observación: la tabla sigue existiendo y conserva la columna `id`; solo desapareció la columna eliminada y su información.

```text
eliminar una columna → la tabla sigue existiendo, pierde esa columna y sus datos
eliminar una tabla   → desaparecen estructura y datos
```

---

# 24. Paso 12 — DROP TABLE

```sql
DROP TABLE tabla_prueba_drop;

SELECT *
FROM tabla_prueba_drop;
```

Resultado: la consulta falla con `Invalid object name 'tabla_prueba_drop'` (error 208), porque la tabla ya no existe. Las ocho tablas reales no se tocaron.

---

# 25. Reto — Detectar un problema antes de agregar una restricción

```sql
SELECT
    nombre,
    COUNT(*) AS cantidad
FROM proyecto
GROUP BY nombre
HAVING COUNT(*) > 1;
```

```text
¿Existen duplicados?

No: la consulta devuelve 0 filas con los datos semilla.
(Si devolviera filas, habría nombres repetidos.)

¿Se puede agregar UNIQUE inmediatamente?

Sí, porque no hay duplicados. Si los hubiera, SQL Server rechazaría la
restricción (error 1505/1750).

¿Qué habría que hacer primero?

Corregir los duplicados con UPDATE (renombrar o unificar los proyectos
repetidos, cuidando las llaves foráneas que los usan) y volver a ejecutar la
consulta hasta que devuelva 0 filas; después agregar UNIQUE.
```

---

# 26. Reto — CHECK sobre datos existentes

Si existiera `estado = 'terminado'` y la regla solo permite cuatro valores:

```text
1. Detectar datos inválidos
        ↓
2. Corregirlos con UPDATE
        ↓
3. Agregar CHECK
        ↓
4. Verificar
```

```sql
-- 1. Detectar
SELECT id_experimento, estado
FROM experimento
WHERE estado NOT IN ('planificado', 'en_ejecucion', 'exitoso', 'fallido');

-- 2. Corregir ('terminado' se interpreta como 'fallido', criterio documentado en decisiones.md)
UPDATE experimento
SET estado = 'fallido'
WHERE estado = 'terminado';

-- 3. Agregar CHECK
ALTER TABLE experimento
ADD CONSTRAINT chk_experimento_estado
CHECK (estado IN ('planificado', 'en_ejecucion', 'exitoso', 'fallido'));

-- 4. Verificar
SELECT estado, COUNT(*) AS cantidad
FROM experimento
GROUP BY estado;
```

Nota: `'terminado'` es ambiguo (podría ser exitoso o fallido); en un caso real se debe consultar con el negocio antes de elegir el valor de reemplazo.

---

# 27. Reto — Diferenciar DML y DDL

```text
DML:
INSERT, UPDATE, DELETE, SELECT

DDL:
ALTER TABLE, DROP TABLE, CREATE TABLE
```

Con mis palabras: DML trabaja con los **datos** (insertar, cambiar, borrar o consultar filas); DDL trabaja con la **estructura** que contiene los datos (crear, modificar o eliminar tablas, columnas y restricciones). Si la tabla es una caja con compartimentos, DML cambia lo que hay dentro y DDL cambia la caja.

(Nota: algunos autores clasifican `SELECT` aparte como DQL; en esta guía se agrupa con DML.)

---

# 28. Documentación

Actualizado: `documentacion/diccionario_datos.md` (ver `diccionario_datos_s07.md` entregado), con `experimento.estado`, `dataset.notas`, la ampliación de `dataset.nombre` y las restricciones `df_experimento_estado`, `chk_experimento_estado`, `uq_proyecto_nombre`.

# 29. Registrar decisiones

Actualizado: `documentacion/decisiones.md` (ver `decisiones_s07.md` entregado), con fecha, cambio, motivo, problema, solución, restricciones e impacto sobre datos existentes.

# 30. Organizar los scripts

```text
scripts/
├── ddl/
│   ├── s05-creacion-tablas.sql
│   └── s07-evolucion-esquema.sql
│
└── dml/
    ├── s06-reset-datos.sql
    └── s06-datos-semilla.sql
```

# 31. Estructura del script

Entregado completo en `scripts/ddl/s07-evolucion-esquema.sql`, con los siete bloques de la plantilla (1 Estado, 2 Check, 3 Notas, 4 Actualizar estados, 5 Restricción adicional, 6 Modificación de columna, 7 Prueba DROP), más un bloque 0 de estado inicial y uno 8 de verificación final.

# 32. Git

```bash
git status
git add .
git commit -m "ddl: evolucion del esquema de DataLab (estado en experimento, notas en dataset)"
git push
```

---

# 33. Evidencias de la actividad

| Evidencia | Cómo demostrarla |
|---|---|
| Estado inicial de las tablas | Captura de `SELECT * FROM experimento;` y `dataset` antes de los cambios |
| Columna `estado` agregada | `SELECT id_experimento, estado FROM experimento;` |
| `DEFAULT` aplicado | Todas las filas con `planificado` tras el `ALTER` |
| `CHECK` funcionando | Captura del error 547 con `'terminado'` |
| Columna `notas` agregada | `SELECT id_dataset, nombre, notas FROM dataset;` |
| Modificación con `UPDATE` | Experimento 1 con `exitoso` |
| Restricción adicional | `uq_proyecto_nombre` en `sys.key_constraints` |
| `DROP` solo en tabla de prueba | Capturas de los pasos 22 a 24 y consulta final de las 8 tablas |
| Diccionario actualizado | `documentacion/diccionario_datos.md` |
| Decisiones documentadas | `documentacion/decisiones.md` |
| Commit realizado | `git log --oneline` |

---

# 34. Reto Feynman

**Reto 1 — ¿Por qué `ALTER TABLE` y no `CREATE TABLE` otra vez?**  
Porque la tabla ya existe y tiene datos. Es como pedir una ventana nueva en una casa habitada: se reforma, no se demuele. CREATE TABLE fallaría por duplicado, y borrar la tabla para recrearla perdería los datos y rompería las relaciones.

**Reto 2 — ¿Por qué agregar `NOT NULL` sobre una tabla con datos puede dar problema?**  
Las filas existentes necesitan un valor en la columna nueva. Si no admite NULL y no hay DEFAULT, SQL Server no sabe qué poner y rechaza el cambio.

**Reto 3 — ¿Por qué necesitamos `DEFAULT`?**  
Para decir qué valor usar cuando nadie lo indica: sirve para rellenar las filas existentes al agregar una columna NOT NULL y para los INSERT futuros que no incluyan el campo.

**Reto 4 — ¿Qué problema aparece al agregar un `CHECK` sobre datos existentes?**  
Si ya hay filas que violan la regla (por ejemplo `'terminado'`), SQL Server rechaza la restricción. Hay que detectarlas, corregirlas con UPDATE y recién entonces agregar el CHECK.

**Reto 5 — Diferencia entre `DELETE`, `DROP COLUMN`, `DROP TABLE` y `DROP DATABASE`**

| Instrucción | Qué elimina | Analogía |
|---|---|---|
| `DELETE` | Filas (la tabla sigue existiendo) | Vaciar la habitación |
| `DROP COLUMN` | Una columna y sus datos | Retirar un mueble |
| `DROP TABLE` | La tabla completa | Quitar la habitación |
| `DROP DATABASE` | La base de datos completa | Demoler la casa |

**Reto 6 — ¿Por qué `ALTER TABLE` es una migración de esquema?**  
Porque cambia el esquema de forma incremental y ordenada, y el script que lo hace se guarda en Git, así el cambio es repetible, revisable y trazable.

**Reto 7 — ¿Por qué probar `DROP` solo en una tabla desechable?**  
Porque es destructivo e irreversible: se pierden estructura y datos. En una tabla de prueba se aprende el efecto sin riesgo para las ocho tablas reales.

---

# 35. Checklist de entrega

Marca cada casilla cuando lo hayas ejecutado y verificado en tu equipo.

## Base de datos

- [ ] `estado` agregado a `experimento`.
- [ ] `DEFAULT` configurado.
- [ ] `CHECK` configurado.
- [ ] `notas` agregada a `dataset`.
- [ ] Al menos una restricción adicional practicada.
- [ ] Al menos una modificación de columna practicada.
- [ ] `UPDATE` ejecutado y verificado.
- [ ] `DROP COLUMN` practicado en tabla de prueba.
- [ ] `DROP TABLE` practicado en tabla de prueba.
- [ ] Ninguna tabla real de DataLab fue eliminada.

## Documentación

- [x] `documentacion/diccionario_datos.md` actualizado.
- [x] `documentacion/decisiones.md` actualizado.
- [x] Cambios explicados.
- [x] Errores encontrados documentados.

## Git

- [ ] Script versionado.
- [ ] Commit realizado.
- [ ] Push realizado.
- [ ] Historial permite identificar la evolución.

---

# 36. Criterio de éxito

```text
Necesidad de negocio (estado y notas)
        ↓
Cambio de esquema (dos columnas nuevas)
        ↓
Análisis de datos existentes (NOT NULL, CHECK y UNIQUE sobre filas ya cargadas)
        ↓
ALTER TABLE (ADD, ALTER COLUMN)
        ↓
Restricciones (DEFAULT, CHECK, UNIQUE)
        ↓
UPDATE si es necesario (experimento 1 → exitoso)
        ↓
Pruebas (CHECK rechaza 'terminado'; DROP solo en tabla de prueba)
        ↓
Documentación (diccionario y decisiones)
        ↓
Git (commit "ddl: evolucion del esquema de DataLab ...")
```

# 37. Cierre

> **El objetivo no es solamente aprender comandos. El objetivo es aprender a evolucionar una base de datos existente de forma controlada, verificable y trazable.**
