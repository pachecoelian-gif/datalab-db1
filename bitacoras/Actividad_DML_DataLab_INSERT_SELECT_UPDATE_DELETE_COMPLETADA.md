# Actividad — Manipulación de Datos con SQL

## INSERT, SELECT, UPDATE y DELETE

**Proyecto integrador:** DataLab  
**SGBD:** SQL Server  
**Herramienta:** SQL Server Management Studio (SSMS)  
**Tipo de actividad:** Práctica guiada  
**Repositorio:** GitHub del equipo

---

## 1. Propósito

En esta actividad trabajaremos con los datos del proyecto integrador **DataLab**.

Aprenderemos a utilizar:

- `SELECT` → consultar
- `INSERT` → insertar
- `UPDATE` → modificar
- `DELETE` → eliminar

No estudiaremos estos comandos de manera aislada. Los utilizaremos sobre las tablas reales del proyecto, respetando PK, FK, restricciones e integridad referencial.

La idea central es trabajar mediante el ciclo:

```text
SELECT → INSERT → SELECT → UPDATE → SELECT → DELETE → SELECT
```

> **Cada operación de modificación debe poder ser comprobada mediante una consulta.**

---

## 2. Objetivos de aprendizaje

Al finalizar la actividad, el estudiante podrá:

- consultar información utilizando `SELECT`;
- insertar nuevos registros utilizando `INSERT`;
- modificar registros utilizando `UPDATE`;
- eliminar registros utilizando `DELETE`;
- utilizar `WHERE` de forma segura;
- comprender el efecto de PK, FK y restricciones;
- verificar modificaciones mediante `SELECT`;
- utilizar `COMMIT` y `ROLLBACK`;
- documentar las operaciones realizadas;
- versionar los scripts en Git.

---

## 3. Contexto: DataLab

El modelo actual cuenta con ocho tablas:

```text
cientifico_datos
proyecto
dataset
experimento
modelo
metrica
participacion
uso_dataset
```

Las relaciones entre estas tablas hacen que una modificación pueda tener consecuencias sobre otras.

Por ejemplo:

```text
cientifico_datos
       │
       ├──────── participacion ──────── proyecto
       │
       └──────── experimento
                       │
                       └──── modelo
                               │
                               └──── metrica
```

Por eso debemos comprender no solamente la sintaxis SQL, sino también **qué datos estamos modificando y qué relaciones existen**.

---

# 4. Preparar el entorno

Antes de comenzar:

1. Abrir SQL Server Management Studio.
2. Seleccionar la base de datos DataLab.
3. Verificar que existen las ocho tablas.
4. Ejecutar:

```text
scripts/dml/s06-reset-datos.sql
```

5. Cargar nuevamente:

```text
scripts/dml/s06-datos-semilla.sql
```

6. Verificar los datos:

```sql
SELECT * FROM cientifico_datos;
SELECT * FROM proyecto;
SELECT * FROM dataset;
SELECT * FROM experimento;
SELECT * FROM modelo;
SELECT * FROM metrica;
```

### ✅ Registro de la preparación del entorno

| Paso | Acción | Estado |
|---|---|---|
| 1 | Abrir SSMS y conectar al servidor SQL Server | ☐ Hecho |
| 2 | Seleccionar la base `DataLab` (`USE DataLab;`) | ☐ Hecho |
| 3 | Verificar las 8 tablas (consulta de abajo) | ☐ Hecho |
| 4 | Ejecutar `scripts/dml/s06-reset-datos.sql` | ☐ Hecho |
| 5 | Ejecutar `scripts/dml/s06-datos-semilla.sql` | ☐ Hecho |
| 6 | Verificar con los 6 `SELECT *` | ☐ Hecho |

Consulta para verificar que existen las ocho tablas (debe devolver 8 filas):

```sql
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME IN ('cientifico_datos','proyecto','dataset','experimento',
                     'modelo','metrica','participacion','uso_dataset')
ORDER BY TABLE_NAME;
```

> Marca ☐ → ☑ a medida que lo ejecutes en tu equipo. Los scripts `s06-reset-datos.sql` y `s06-datos-semilla.sql` son los del repositorio (no se modifican en esta actividad).

---

# 5. SELECT — Consultar información

`SELECT` permite recuperar información almacenada en las tablas.

La estructura básica es:

```sql
SELECT columnas
FROM tabla;
```

Ejemplo:

```sql
SELECT nombre, descripcion
FROM proyecto;
```

También podemos filtrar:

```sql
SELECT *
FROM proyecto
WHERE id_proyecto = 1;
```

> **SELECT consulta información; no modifica los datos.**

---

# 6. SELECT como herramienta de validación

Antes y después de modificar información utilizaremos `SELECT`.

Por ejemplo:

```sql
SELECT *
FROM proyecto
WHERE id_proyecto = 1;
```

Después de modificar el registro, ejecutamos nuevamente la consulta para comprobar el resultado.

Esto convierte a `SELECT` en una herramienta de **validación**.

---

# 7. INSERT — Crear nuevos datos

`INSERT` permite agregar registros.

Sintaxis:

```sql
INSERT INTO tabla
    (columna1, columna2)
VALUES
    (valor1, valor2);
```

Ejemplo:

```sql
INSERT INTO proyecto
    (nombre, descripcion)
VALUES
    ('Prediccion de demanda',
     'Proyecto para analizar y predecir la demanda de servicios.');
```

Después:

```sql
SELECT *
FROM proyecto
WHERE nombre = 'Prediccion de demanda';
```

Flujo:

```text
INSERT
  ↓
SELECT
  ↓
Verificar
```

---

# 8. INSERT y columnas IDENTITY

Si `id_proyecto` está definido como:

```sql
IDENTITY(1,1)
```

SQL Server genera automáticamente el identificador.

Por eso normalmente escribimos:

```sql
INSERT INTO proyecto
    (nombre, descripcion)
VALUES
    (...);
```

y no:

```sql
INSERT INTO proyecto
    (id_proyecto, nombre, descripcion)
VALUES
    (...);
```

---

# 9. INSERT y restricciones

Podemos crear un científico:

```sql
INSERT INTO cientifico_datos
    (nombre, correo)
VALUES
    ('Laura Gomez', 'laura.gomez@datalab.com');
```

Verificamos:

```sql
SELECT *
FROM cientifico_datos
WHERE correo = 'laura.gomez@datalab.com';
```

Si `correo` tiene una restricción `UNIQUE`, intentar insertar nuevamente el mismo correo debe producir un error.

Las restricciones definidas en el modelo continúan aplicándose cuando manipulamos los datos.

---

# 10. INSERT y claves foráneas

Un `experimento` necesita referencias válidas:

```text
id_proyecto
id_cientifico
fecha_ejecucion
configuracion
```

Ejemplo:

```sql
INSERT INTO experimento
    (id_proyecto, id_cientifico, fecha_ejecucion, configuracion)
VALUES
    (1, 1, '2026-09-24', 'Configuracion inicial del experimento');
```

Aquí:

```text
id_proyecto
     ↓
debe existir en proyecto

id_cientifico
     ↓
debe existir en cientifico_datos
```

Una referencia inexistente debe ser rechazada por la integridad referencial.

---

# 11. Actividad — Crear registros

Crea:

### 11.1 Un científico

```text
Nombre:
Elian Pacheco

Correo:
elian.pacheco@datalab.com
```

```sql
INSERT INTO cientifico_datos (nombre, correo)
VALUES ('Elian Pacheco', 'elian.pacheco@datalab.com');

SELECT * FROM cientifico_datos
WHERE correo = 'elian.pacheco@datalab.com';
```

**Resultado esperado:** 1 fila; `id_cientifico` lo asigna `IDENTITY`.

### 11.2 Un proyecto

```text
Nombre:
Prediccion de demanda (practica S06)

Descripción:
Proyecto para analizar y predecir la demanda de servicios.
```

```sql
INSERT INTO proyecto (nombre, descripcion)
VALUES ('Prediccion de demanda (practica S06)',
        'Proyecto para analizar y predecir la demanda de servicios.');

SELECT * FROM proyecto
WHERE nombre = 'Prediccion de demanda (practica S06)';
```

**Resultado esperado:** 1 fila. El sufijo `(practica S06)` marca el registro como de práctica y evita confundirlo con datos semilla.

### 11.3 Un dataset

```text
Nombre:
Historial de demanda 2025

Fuente:
Sistema interno de facturacion

Fecha de carga:
2026-10-07

Tamaño de filas:
15000
```

```sql
INSERT INTO dataset (nombre, fuente, fecha_carga, tamano_filas)
VALUES ('Historial de demanda 2025',
        'Sistema interno de facturacion',
        '20261007',
        15000);

SELECT * FROM dataset
WHERE nombre = 'Historial de demanda 2025';
```

> Si en tu DDL la columna de tamaño se llama distinto (por ejemplo `num_filas`), cambia solo ese nombre. La fecha se escribe `'20261007'` (formato `AAAAMMDD`) porque SQL Server lo interpreta igual sin importar el idioma de la sesión.

### 11.4 Un experimento

Debe utilizar IDs existentes de:

```text
proyecto
cientifico_datos
```

En lugar de escribir los IDs a mano, se buscan por clave natural (nombre del proyecto y correo del científico). Así el `INSERT` funciona sin importar qué número haya generado `IDENTITY`, y se garantiza que ambas referencias existen:

```sql
INSERT INTO experimento (id_proyecto, id_cientifico, fecha_ejecucion, configuracion)
SELECT p.id_proyecto, c.id_cientifico, '20261007',
       'Configuracion inicial del experimento'
FROM proyecto p
CROSS JOIN cientifico_datos c
WHERE p.nombre = 'Prediccion de demanda (practica S06)'
  AND c.correo = 'elian.pacheco@datalab.com';

SELECT e.*, p.nombre AS proyecto, c.nombre AS cientifico
FROM experimento e
JOIN proyecto p         ON p.id_proyecto   = e.id_proyecto
JOIN cientifico_datos c ON c.id_cientifico = e.id_cientifico
WHERE p.nombre = 'Prediccion de demanda (practica S06)';
```

**Orden de inserción aplicado (por las FK):** `cientifico_datos` → `proyecto` → `dataset` → `experimento`.

Después de cada `INSERT` se ejecutó su `SELECT` de verificación (ver `scripts/dml/s07-operaciones-dml.sql`, secciones 2 y 3).

---

# 12. UPDATE — Modificar información

`UPDATE` permite modificar registros existentes.

Sintaxis:

```sql
UPDATE tabla
SET columna = nuevo_valor
WHERE condicion;
```

Ejemplo:

```sql
UPDATE proyecto
SET descripcion = 'Nueva descripcion del proyecto'
WHERE id_proyecto = 1;
```

Verificación:

```sql
SELECT *
FROM proyecto
WHERE id_proyecto = 1;
```

---

# 13. La importancia de WHERE

Observa:

```sql
UPDATE proyecto
SET descripcion = 'Nueva descripcion';
```

Esta instrucción puede modificar **todos los proyectos**.

Por eso debemos identificar primero el registro:

```sql
UPDATE proyecto
SET descripcion = 'Proyecto actualizado'
WHERE id_proyecto = 2;
```

> Antes de ejecutar un `UPDATE`, verifica con `SELECT` que la condición identifica exactamente los registros esperados.

---

# 14. Actividad — Modificar información

Realiza:

1. Actualiza la descripción de un proyecto.
2. Actualiza el nombre de un científico.
3. Actualiza la fuente de un dataset.
4. Actualiza la configuración de un experimento.

Después de cada operación utiliza `SELECT` para comprobar el resultado.

### Desarrollo (patrón: SELECT previo → UPDATE → SELECT posterior)

**1. Descripción de un proyecto**

```sql
SELECT * FROM proyecto WHERE nombre = 'Prediccion de demanda (practica S06)';   -- debe dar 1 fila

UPDATE proyecto
SET descripcion = 'Proyecto para predecir la demanda mensual de servicios con series de tiempo.'
WHERE nombre = 'Prediccion de demanda (practica S06)';

SELECT * FROM proyecto WHERE nombre = 'Prediccion de demanda (practica S06)';
```

**2. Nombre de un científico**

```sql
SELECT * FROM cientifico_datos WHERE correo = 'elian.pacheco@datalab.com';

UPDATE cientifico_datos
SET nombre = 'Elian Santiago Pacheco'
WHERE correo = 'elian.pacheco@datalab.com';

SELECT * FROM cientifico_datos WHERE correo = 'elian.pacheco@datalab.com';
```

**3. Fuente de un dataset**

```sql
SELECT * FROM dataset WHERE nombre = 'Historial de demanda 2025';

UPDATE dataset
SET fuente = 'Data warehouse corporativo'
WHERE nombre = 'Historial de demanda 2025';

SELECT * FROM dataset WHERE nombre = 'Historial de demanda 2025';
```

**4. Configuración de un experimento**

```sql
SELECT e.* FROM experimento e
JOIN proyecto p ON p.id_proyecto = e.id_proyecto
WHERE p.nombre = 'Prediccion de demanda (practica S06)';

UPDATE e
SET e.configuracion = 'Modelo ARIMA, ventana de 12 meses, semilla 42'
FROM experimento e
JOIN proyecto p ON p.id_proyecto = e.id_proyecto
WHERE p.nombre = 'Prediccion de demanda (practica S06)';

SELECT e.* FROM experimento e
JOIN proyecto p ON p.id_proyecto = e.id_proyecto
WHERE p.nombre = 'Prediccion de demanda (practica S06)';
```

### Tabla resumen de modificaciones

| # | Tabla | Columna | Valor anterior | Valor nuevo | Condición `WHERE` |
|---|---|---|---|---|---|
| 1 | `proyecto` | `descripcion` | Proyecto para analizar y predecir la demanda de servicios. | Proyecto para predecir la demanda mensual de servicios con series de tiempo. | `nombre = 'Prediccion de demanda (practica S06)'` |
| 2 | `cientifico_datos` | `nombre` | Elian Pacheco | Elian Santiago Pacheco | `correo = 'elian.pacheco@datalab.com'` |
| 3 | `dataset` | `fuente` | Sistema interno de facturacion | Data warehouse corporativo | `nombre = 'Historial de demanda 2025'` |
| 4 | `experimento` | `configuracion` | Configuracion inicial del experimento | Modelo ARIMA, ventana de 12 meses, semilla 42 | experimento del proyecto de práctica |

Cada `WHERE` usa una clave natural **única** (correo, o el nombre del registro de práctica), por lo que el `SELECT` previo devuelve exactamente 1 fila.

---

# 15. DELETE — Eliminar información

`DELETE` permite eliminar registros.

Sintaxis:

```sql
DELETE FROM tabla
WHERE condicion;
```

Ejemplo:

```sql
DELETE FROM proyecto
WHERE id_proyecto = 5;
```

---

# 16. La regla de oro de DELETE

Nunca ejecutes directamente:

```sql
DELETE FROM proyecto;
```

sin comprender las consecuencias.

Esta instrucción elimina todos los registros de la tabla.

Primero:

```sql
SELECT *
FROM proyecto
WHERE id_proyecto = 5;
```

Después, si el registro es el correcto:

```sql
DELETE FROM proyecto
WHERE id_proyecto = 5;
```

Finalmente:

```sql
SELECT *
FROM proyecto
WHERE id_proyecto = 5;
```

El resultado debería ser vacío.

---

# 17. DELETE y claves foráneas

Supongamos:

```text
proyecto
   │
   └──── experimento
```

Si intentamos:

```sql
DELETE FROM proyecto
WHERE id_proyecto = 1;
```

SQL Server puede impedir la operación si existen registros relacionados y la política de integridad no permite eliminar el registro padre.

Debemos preguntarnos:

> **¿Qué otros datos dependen del registro que quiero eliminar?**

---

# 18. Actividad — DELETE controlado

Identifica un registro creado específicamente para la práctica.

Para no borrar el proyecto principal de la práctica (que conserva su experimento), se crea un registro **solo para eliminarlo**:

```sql
INSERT INTO proyecto (nombre, descripcion)
VALUES ('Proyecto Temporal DELETE S06',
        'Proyecto creado unicamente para practicar DELETE controlado.');
```

Primero:

```sql
SELECT *
FROM proyecto
WHERE nombre = 'Proyecto Temporal DELETE S06';      -- [ID] = el id_proyecto que devuelva
```

Comprobar relaciones:

```sql
SELECT COUNT(*) AS experimentos_relacionados
FROM experimento e
JOIN proyecto p ON p.id_proyecto = e.id_proyecto
WHERE p.nombre = 'Proyecto Temporal DELETE S06';    -- 0
```

Después:

```sql
DELETE FROM proyecto
WHERE nombre = 'Proyecto Temporal DELETE S06';
```

Finalmente:

```sql
SELECT *
FROM proyecto
WHERE nombre = 'Proyecto Temporal DELETE S06';      -- 0 filas
```

> En el script se usa el nombre (clave natural) en lugar de `[ID]` para que sea reproducible; el `id_proyecto` real lo asigna `IDENTITY` y se observa en el `SELECT` previo.

Documenta:

- **Qué registro eliminaste:** el proyecto `Proyecto Temporal DELETE S06`, creado unos instantes antes solo para esta práctica.
- **Por qué lo seleccionaste:** porque es un dato desechable, creado por mí, que no pertenece a los datos semilla ni al trabajo del equipo; eliminarlo no afecta información real.
- **Si existían relaciones:** no. El conteo de `experimento` relacionados dio 0 (y no tiene filas en `participacion`), por lo que ninguna FK impide el borrado.
- **Qué resultado obtuviste:** el `DELETE` afectó 1 fila y el `SELECT` posterior devolvió 0 filas, lo que confirma la eliminación.

**Contraste con un padre que sí tiene hijos** (se hace dentro de una transacción que termina en `ROLLBACK` para no perder datos):

```sql
BEGIN TRANSACTION;
BEGIN TRY
    DELETE FROM proyecto WHERE nombre = 'Prediccion de demanda (practica S06)';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_error, ERROR_MESSAGE() AS mensaje_error;
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
```

Si la FK de `experimento → proyecto` usa `NO ACTION` (valor por defecto), SQL Server responde con el error **547** y el proyecto no se borra. Si el equipo definió `ON DELETE CASCADE`, el borrado procede y arrastra al experimento; el `ROLLBACK` lo deshace en ambos casos. El resultado depende de la política `ON DELETE` definida en la Semana 4/5.

---

# 19. Comparación de las cuatro operaciones

| Comando | Acción | ¿Modifica datos? |
|---|---|---:|
| `SELECT` | Consultar | No |
| `INSERT` | Crear registros | Sí |
| `UPDATE` | Modificar registros | Sí |
| `DELETE` | Eliminar registros | Sí |

---

# 20. CRUD

Las operaciones se relacionan con **CRUD**:

```text
C → Create  → INSERT
R → Read    → SELECT
U → Update  → UPDATE
D → Delete  → DELETE
```

En DataLab:

```text
CREATE
→ registrar un proyecto

READ
→ consultar proyectos

UPDATE
→ modificar un proyecto

DELETE
→ eliminar un proyecto
```

---

# 21. Ciclo CRUD aplicado a DataLab

## Paso 1 — READ

```sql
SELECT *
FROM proyecto
WHERE id_proyecto = 1;
```

## Paso 2 — CREATE

```sql
INSERT INTO proyecto
    (nombre, descripcion)
VALUES
    ('Proyecto CRUD DataLab',
     'Proyecto creado para practicar operaciones DML.');
```

## Paso 3 — READ

```sql
SELECT *
FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';
```

## Paso 4 — UPDATE

```sql
UPDATE proyecto
SET descripcion = 'Proyecto actualizado durante la practica DML.'
WHERE nombre = 'Proyecto CRUD DataLab';
```

## Paso 5 — READ

```sql
SELECT *
FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';
```

## Paso 6 — DELETE

```sql
DELETE FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';
```

## Paso 7 — READ

```sql
SELECT *
FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';
```

---

# 22. Práctica integrada — DataLab

Cada equipo desarrollará un escenario propio.

## Escenario

El equipo de DataLab necesita registrar un nuevo proyecto.

El proyecto debe:

1. ser creado;
2. ser consultado;
3. ser actualizado;
4. ser consultado nuevamente;
5. ser eliminado;
6. comprobar que fue eliminado.

---

# 23. Paso 1 — Diseñar antes de ejecutar

Documenta:

```text
Nombre del proyecto:
Proyecto CRUD DataLab

Descripción:
Proyecto creado para practicar operaciones DML.

¿Por qué se crea?
Para ejecutar de principio a fin el ciclo de vida de un dato en DataLab
(crear, leer, actualizar, leer, eliminar, comprobar) sobre un registro propio,
sin tocar los datos semilla ni los del equipo.

¿Quién es responsable?
Elian Santiago Pacheco Vanegas (integrante del equipo DataLab), quien ejecuta
el script y es responsable de crear y de eliminar el registro.

¿Qué otros datos necesitará posteriormente?
Si el proyecto se conservara, necesitaría: un científico responsable en
cientifico_datos y su fila en participacion; al menos un experimento
(id_proyecto + id_cientifico + fecha_ejecucion + configuracion); datasets
asociados mediante uso_dataset; y luego modelos y métricas de ese experimento.
Como es de práctica, se elimina al final y no requiere nada de esto.
```

---

# 24. Paso 2 — Crear

Construye el `INSERT`:

```sql
INSERT INTO proyecto
    (nombre, descripcion)
VALUES
    ('Proyecto CRUD DataLab',
     'Proyecto creado para practicar operaciones DML.');
```

`id_proyecto` no se incluye porque es `IDENTITY(1,1)`: SQL Server lo genera solo.

---

# 25. Paso 3 — Leer

Construye el `SELECT`:

```sql
SELECT
    id_proyecto,
    nombre,
    descripcion
FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';
```

**Resultado esperado:** 1 fila con la descripción original.

---

# 26. Paso 4 — Actualizar

Modifica una característica del proyecto:

```sql
UPDATE proyecto
SET descripcion = 'Proyecto actualizado durante la practica DML.'
WHERE nombre = 'Proyecto CRUD DataLab';
```

---

# 27. Paso 5 — Verificar

```sql
SELECT
    id_proyecto,
    nombre,
    descripcion
FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';
```

**Resultado esperado:** 1 fila, ahora con `Proyecto actualizado durante la practica DML.` y el **mismo** `id_proyecto` del paso 3 (el UPDATE no cambia la identidad del registro).

---

# 28. Paso 6 — Eliminar

Elimina únicamente el registro creado para la práctica:

```sql
DELETE FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';
```

---

# 29. Paso 7 — Verificar eliminación

```sql
SELECT *
FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';
```

El resultado debe demostrar que el registro ya no existe.

**Resultado esperado:** `(0 rows affected)` — conjunto vacío.

---

# 30. Segundo reto — Operaciones relacionadas

Registrar:

```text
Científico
     ↓
Proyecto
     ↓
Experimento
```

El orden debe ser:

```text
1. cientifico_datos
          ↓
2. proyecto
          ↓
3. experimento
```

Esto se debe a las claves foráneas de `experimento`.

### Desarrollo del reto

El orden se respetó exactamente en el script (secciones 2.1, 2.2 y 2.4 de `s07-operaciones-dml.sql`):

| Orden | Tabla | Qué se registró | Por qué en este orden |
|---|---|---|---|
| 1 | `cientifico_datos` | Elian Pacheco (`elian.pacheco@datalab.com`) | Es un padre: `experimento.id_cientifico` lo referencia. |
| 2 | `proyecto` | Prediccion de demanda (practica S06) | Es el otro padre: `experimento.id_proyecto` lo referencia. |
| 3 | `experimento` | Configuración inicial | Es el hijo: necesita que ambos padres ya existan. |

Si se invirtiera el orden (experimento primero), SQL Server rechazaría el `INSERT` con el error 547, porque las FK exigen que el padre exista antes que el hijo.

---

# 31. Experimento de integridad

Intenta realizar deliberadamente una operación incorrecta:

```sql
INSERT INTO experimento
    (id_proyecto, id_cientifico, fecha_ejecucion, configuracion)
VALUES
    (9999, 1, '2026-09-24', 'Prueba de integridad');
```

> En el script se ejecuta dentro de `BEGIN TRY ... BEGIN CATCH` con `id_cientifico` buscado por correo (en lugar de `1`), para que el error se muestre como resultado y el script continúe. El `id_proyecto = 9999` es el elemento inexistente que provoca el rechazo.

Documenta:

```text
¿Qué ocurrió?
SQL Server rechazó el INSERT y no se creó ninguna fila. Devolvió el error 547:
"The INSERT statement conflicted with the FOREIGN KEY constraint ..."
(en español: "Instrucción INSERT en conflicto con la restricción FOREIGN KEY ...").
Un SELECT posterior con id_proyecto = 9999 devuelve 0 filas.

¿Por qué ocurrió?
Porque experimento.id_proyecto es una clave foránea que debe apuntar a un
id_proyecto que ya exista en la tabla proyecto. No existe ningún proyecto con
id 9999, así que el experimento quedaría "huérfano", apuntando a algo que no existe.

¿Qué restricción intervino?
La restricción FOREIGN KEY de experimento sobre id_proyecto hacia proyecto
(FK experimento → proyecto, definida en el DDL de la Semana 5). Su nombre exacto
aparece en el mensaje de error y puede consultarse con:
SELECT name FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('experimento');

¿Qué relación del modelo está protegiendo SQL Server?
La relación 1:N "un proyecto tiene muchos experimentos" (proyecto 1 ── N experimento).
SQL Server protege que todo experimento pertenezca a un proyecto real, es decir,
la integridad referencial del lado del hijo.
```

Conecta:

```text
Modelo relacional
      ↓
Clave foránea
      ↓
Integridad referencial
      ↓
Restricción en SQL Server
```

**Conexión explicada paso a paso:**

1. **Modelo relacional:** en el diseño E-R se decidió que *un proyecto agrupa varios experimentos*; al pasar a tablas, esa relación 1:N hace que `experimento` guarde el identificador de `proyecto`.
2. **Clave foránea:** la columna `experimento.id_proyecto` es la que materializa el vínculo con `proyecto.id_proyecto`.
3. **Integridad referencial:** es la regla lógica "no puede haber un valor en la FK que no exista como PK en la tabla padre".
4. **Restricción en SQL Server:** la regla se vuelve un objeto `FOREIGN KEY` creado en el `CREATE TABLE`/`ALTER TABLE`; el motor lo evalúa en cada `INSERT`, `UPDATE` y `DELETE` y devuelve el error 547 cuando se viola.

**Prueba complementaria — restricción `UNIQUE` del correo:** insertar de nuevo `elian.pacheco@datalab.com` debe fallar con error 2627 (o 2601) si `correo` tiene `UNIQUE`. Si el script muestra el aviso "no hubo error", esa restricción no existe en el DDL y conviene agregarla.

---

# 32. Transacciones

Durante las prácticas de `UPDATE` y `DELETE` podemos utilizar transacciones.

Ejemplo:

```sql
BEGIN TRANSACTION;

UPDATE proyecto
SET descripcion = 'Prueba temporal'
WHERE id_proyecto = 1;

SELECT *
FROM proyecto
WHERE id_proyecto = 1;

ROLLBACK TRANSACTION;
```

`ROLLBACK` deshace los cambios realizados dentro de la transacción.

---

# 33. COMMIT

Si estamos seguros de la operación:

```sql
BEGIN TRANSACTION;

UPDATE proyecto
SET descripcion = 'Nueva descripcion'
WHERE id_proyecto = 1;

SELECT *
FROM proyecto
WHERE id_proyecto = 1;

COMMIT TRANSACTION;
```

Diferencia:

```text
ROLLBACK
→ deshacer

COMMIT
→ confirmar
```

### Práctica de transacciones realizada

| Práctica | Qué hace | Qué se observa |
|---|---|---|
| `BEGIN TRANSACTION` → `UPDATE` → `SELECT` → `ROLLBACK` | Cambia la descripción a `Prueba temporal` | Dentro de la transacción el `SELECT` muestra `Prueba temporal`; tras el `ROLLBACK` vuelve el valor anterior. |
| `BEGIN TRANSACTION` → `UPDATE` → `SELECT` → `COMMIT` | Cambia la descripción a la versión confirmada | Tras el `COMMIT` el cambio queda guardado de forma permanente. |
| `BEGIN TRANSACTION` → `DELETE` del proyecto con experimento → `ROLLBACK` | Prueba la política `ON DELETE` | Nada se pierde, sin importar si el DELETE fue rechazado o permitido. |

Código completo en `scripts/dml/s07-operaciones-dml.sql`, sección 5 y 6.3.

---

# 34. Regla de seguridad para UPDATE y DELETE

Antes de ejecutar:

```text
UPDATE
```

o:

```text
DELETE
```

realiza primero un `SELECT` con la misma condición.

Ejemplo:

```sql
SELECT *
FROM proyecto
WHERE id_proyecto = 3;
```

Después:

```sql
UPDATE proyecto
SET descripcion = 'Nueva descripcion'
WHERE id_proyecto = 3;
```

---

# 35. Errores críticos

## UPDATE sin WHERE

Evita:

```sql
UPDATE proyecto
SET descripcion = 'Nueva descripcion';
```

a menos que quieras modificar todos los proyectos.

## DELETE sin WHERE

Evita:

```sql
DELETE FROM proyecto;
```

Esta instrucción elimina todos los registros de `proyecto`.

---

# 36. Organización de los scripts

El repositorio debe quedar:

```text
scripts/
│
├── ddl/
│   └── s05-creacion-tablas.sql
│
├── dml/
│   ├── s06-reset-datos.sql
│   ├── s06-datos-semilla.sql
│   └── s07-operaciones-dml.sql
│
└── consultas/
    └── s06-consultas-basicas.sql
```

Para esta actividad se recomienda:

```text
s07-operaciones-dml.sql
```

### Estructura real aplicada en esta entrega

```text
datalab-db1/
├── scripts/
│   ├── ddl/
│   │   └── s05-creacion-tablas.sql
│   ├── dml/
│   │   ├── s06-reset-datos.sql
│   │   ├── s06-datos-semilla.sql
│   │   └── s07-operaciones-dml.sql        ← NUEVO
│   └── consultas/
│       └── s06-consultas-basicas.sql
├── casos_uso/
│   └── s06-preguntas-negocio.md           ← ACTUALIZADO
└── documentacion/
    └── decisiones.md                      ← ACTUALIZADO
```

---

# 37. Organización sugerida del script

```sql
/*
    DataLab
    Semana 7
    Operaciones DML

    INSERT
    SELECT
    UPDATE
    DELETE
*/

-- 1. SELECT

-- 2. INSERT

-- 3. SELECT DE VERIFICACIÓN

-- 4. UPDATE

-- 5. SELECT DE VERIFICACIÓN

-- 6. DELETE

-- 7. SELECT DE VERIFICACIÓN
```

### Aplicación en `s07-operaciones-dml.sql`

| Bloque del script | Contenido |
|---|---|
| 0. Pre-limpieza | Borra solo filas de práctica para poder re-ejecutar el script |
| 1. SELECT | Estado inicial y conteo de las 8 tablas |
| 2 y 3. INSERT + SELECT | Científico → proyecto → dataset → experimento, con verificación y prueba `UNIQUE` |
| 4 y 5. UPDATE + SELECT | Los 4 `UPDATE` de la sección 14, cada uno con `SELECT` previo y posterior |
| 5 (transacciones) | `ROLLBACK` y `COMMIT` |
| 6. Integridad | `INSERT` con `id_proyecto = 9999` y `DELETE` de un padre con hijos |
| 7. DELETE | DELETE controlado de `Proyecto Temporal DELETE S06` |
| 8. CRUD | Ciclo completo con `Proyecto CRUD DataLab` |
| 9. SELECT final | Estado final de la base |

---

# 38. Documentación

Actualizar:

```text
casos_uso/s06-preguntas-negocio.md
```

y:

```text
documentacion/decisiones.md
```

Ejemplo de decisión:

```text
Decisión:
Se utiliza SELECT antes de UPDATE y DELETE.

Justificación:
Permite verificar previamente qué registros serán afectados
y reducir el riesgo de modificar o eliminar información incorrecta.
```

### Cómo quedó la documentación

- **`casos_uso/s06-preguntas-negocio.md`:** se agregó la sección *"Preguntas de negocio resueltas con DML"* (qué proyectos existen, qué experimentos tiene un proyecto, quién los ejecutó, cómo se registra un proyecto nuevo, qué pasa al eliminar un proyecto con experimentos), cada una con su consulta SQL.
- **`documentacion/decisiones.md`:** se agregaron 8 decisiones (DML-01 a DML-08) con el formato *Decisión / Justificación*, incluida la del ejemplo (`SELECT` antes de `UPDATE` y `DELETE`).

Ambos archivos están en la carpeta `entrega-s06/` listos para agregar al final de los archivos existentes del repositorio.

---

# 39. Evidencias

El repositorio debe permitir comprobar:

- qué registros fueron creados;
- qué registros fueron modificados;
- qué registros fueron eliminados;
- qué consultas verificaron las operaciones;
- qué errores de integridad fueron probados;
- qué decisiones tomó el equipo.

No basta con presentar el resultado final.

Debe poder observarse **el proceso**.

### Matriz de evidencias

| Evidencia | Dónde se ve |
|---|---|
| **Registros creados** | 1 científico, 1 proyecto, 1 dataset, 1 experimento (sección 11); `Proyecto Temporal DELETE S06` y `Proyecto CRUD DataLab` (secciones 18 y 21) |
| **Registros modificados** | 4 `UPDATE` (tabla resumen de la sección 14) + descripción de proyecto en `ROLLBACK`/`COMMIT` (sección 33) + `Proyecto CRUD DataLab` (sección 26) |
| **Registros eliminados** | `Proyecto Temporal DELETE S06` (sección 18) y `Proyecto CRUD DataLab` (sección 28) |
| **Consultas de verificación** | Un `SELECT` después de cada `INSERT`, `UPDATE` y `DELETE`, y `SELECT` previo a cada `UPDATE`/`DELETE` |
| **Errores de integridad probados** | Error 547 por `id_proyecto = 9999` (sección 31); `DELETE` de padre con hijos (sección 18); duplicado de correo con `UNIQUE` (sección 31) |
| **Decisiones del equipo** | `documentacion/decisiones.md`, DML-01 a DML-08 |

### Resumen de operaciones ejecutadas

| Operación | Cantidad | Registros afectados |
|---|---:|---|
| `INSERT` | 6 | científico, proyecto, dataset, experimento, proyecto temporal, proyecto CRUD |
| `UPDATE` | 7 | 4 de la sección 14, 1 en `ROLLBACK` (no persiste), 1 en `COMMIT`, 1 del ciclo CRUD |
| `DELETE` | 2 persistentes | `Proyecto Temporal DELETE S06`, `Proyecto CRUD DataLab` (+1 `DELETE` probado y deshecho con `ROLLBACK`) |
| Errores de integridad provocados | 2–3 | FK (`id_proyecto = 9999`), FK/CASCADE (borrar padre con hijos), `UNIQUE` (correo) |

### 📸 Capturas sugeridas para adjuntar (carpeta `evidencias/` o `bitacoras/`)

1. Resultado del `SELECT` tras el `INSERT` de cada tabla.
2. Antes/después del `UPDATE` de proyecto.
3. Mensaje de error 547 del experimento con `id_proyecto = 9999`.
4. `SELECT` dentro y después del `ROLLBACK`.
5. `SELECT` vacío tras el `DELETE` de `Proyecto CRUD DataLab`.

> Los resultados descritos en este documento son los **esperados** al ejecutar el script; confirma en SSMS que coinciden y toma las capturas con tus datos reales.

---

# 40. Reto Feynman

Explica con tus propias palabras:

1. **¿Qué hace `SELECT`?**
   Es la "pregunta" a la base de datos: pide ver información de una o varias tablas y devuelve un resultado. No cambia nada; solo lee. Con `WHERE` filtro qué filas quiero y con la lista de columnas, cuáles.

2. **¿Qué hace `INSERT`?**
   Agrega una fila nueva a una tabla, indicando en qué columnas voy a poner valores y cuáles son. Si la tabla tiene `IDENTITY`, el ID lo pone SQL Server; yo solo doy los demás datos. Debe cumplir tipos, `NOT NULL`, `UNIQUE` y claves foráneas.

3. **¿Qué hace `UPDATE`?**
   Cambia el valor de una o varias columnas en filas que ya existen. No crea ni borra filas; las transforma. `SET` dice qué cambia y `WHERE` dice a quién.

4. **¿Qué hace `DELETE`?**
   Elimina filas completas de una tabla. Lo que se borra es la fila entera, no una columna, y `WHERE` determina cuáles filas desaparecen.

5. **¿Por qué `UPDATE` necesita normalmente `WHERE`?**
   Porque sin `WHERE` el cambio se aplica a **todas** las filas de la tabla. Con `UPDATE proyecto SET descripcion = '...'` todos los proyectos quedarían con la misma descripción. `WHERE` limita la operación a las filas correctas, idealmente identificadas por la PK o por un valor único.

6. **¿Por qué `DELETE` puede verse afectado por las claves foráneas?**
   Porque borrar un registro "padre" (por ejemplo un proyecto) podría dejar "huérfanos" a sus hijos (sus experimentos), que apuntarían a algo inexistente. Según la política `ON DELETE`, SQL Server (a) lo rechaza con error 547 (`NO ACTION`), (b) borra también a los hijos (`CASCADE`) o (c) pone la FK en `NULL` (`SET NULL`). Por eso hay que preguntarse qué datos dependen de lo que voy a eliminar.

7. **¿Por qué debemos consultar antes de modificar?**
   Porque `UPDATE` y `DELETE` actúan sobre lo que cumpla la condición, y un error en la condición afecta filas equivocadas. Si primero hago un `SELECT` con **la misma** condición, veo exactamente cuántas y cuáles filas se afectarían; si no son las esperadas, corrijo antes de modificar. Es como mirar antes de cruzar, y después de modificar vuelvo a consultar para comprobar el resultado.

8. **¿Cómo se relacionan `INSERT`, `SELECT`, `UPDATE` y `DELETE` con CRUD?**
   Son la traducción de CRUD a SQL: **C**reate = `INSERT`, **R**ead = `SELECT`, **U**pdate = `UPDATE`, **D**elete = `DELETE`. Juntas cubren todo el ciclo de vida de un dato: nace, se consulta, cambia y desaparece. En DataLab: registrar, consultar, modificar y eliminar un proyecto.

9. **¿Qué ocurriría si intentas crear un experimento utilizando un `id_proyecto` inexistente?**
   SQL Server rechazaría el `INSERT` con el error 547 (conflicto con la restricción `FOREIGN KEY`) y no se guardaría ninguna fila. Es la integridad referencial protegiendo que cada experimento pertenezca a un proyecto real.

---

# 41. Entregables

El repositorio debe contener:

```text
scripts/dml/s07-operaciones-dml.sql
```

y actualizar:

```text
casos_uso/s06-preguntas-negocio.md
documentacion/decisiones.md
```

Además:

- [x] Operaciones `SELECT`. *(script, secciones 1, 3, 5, 7, 8 y 9)*
- [x] Operaciones `INSERT`. *(script, sección 2)*
- [x] Operaciones `UPDATE`. *(script, sección 4)*
- [x] Operaciones `DELETE`. *(script, secciones 6.3, 7 y 8)*
- [x] Consultas de verificación. *(un `SELECT` tras cada operación)*
- [x] Prueba de integridad referencial. *(script, sección 6)*
- [x] Uso de transacciones en al menos una práctica. *(`ROLLBACK` y `COMMIT`, sección 5)*
- [x] Documentación. *(`preguntas-negocio.md` y `decisiones.md`)*
- [ ] Commit. *(pendiente: lo haces tú con la guía de Git)*
- [ ] Push al repositorio. *(pendiente: lo haces tú con la guía de Git)*

---

# 42. Commit sugerido

```bash
git add .
git commit -m "dml: implementar operaciones CRUD sobre DataLab"
git push
```

### Estrategia de commits aplicada (para que se vea el proceso)

```bash
git add scripts/dml/s07-operaciones-dml.sql
git commit -m "dml: agregar script s07 con INSERT, SELECT, UPDATE, DELETE y transacciones"

git add casos_uso/s06-preguntas-negocio.md
git commit -m "docs: actualizar preguntas de negocio con operaciones DML"

git add documentacion/decisiones.md
git commit -m "docs: registrar decisiones DML-01 a DML-08"

git push
```

Si se prefiere un único commit, el sugerido por el docente es el de arriba. Los pasos detallados para ejecutarlo están en la guía de Git entregada junto a este documento.

---

# 43. Checklist final

- [x] Sé explicar `SELECT`.
- [x] Sé explicar `INSERT`.
- [x] Sé explicar `UPDATE`.
- [x] Sé explicar `DELETE`.
- [x] Comprendo CRUD.
- [x] Puedo insertar un registro.
- [x] Puedo consultar un registro.
- [x] Puedo modificar un registro.
- [x] Puedo eliminar un registro.
- [x] Sé utilizar `WHERE`.
- [x] Comprendo el riesgo de `UPDATE` sin `WHERE`.
- [x] Comprendo el riesgo de `DELETE` sin `WHERE`.
- [x] Sé verificar una modificación utilizando `SELECT`.
- [x] Comprendo el papel de las claves foráneas.
- [x] Puedo explicar un error de integridad referencial.
- [x] Sé utilizar `COMMIT`.
- [x] Sé utilizar `ROLLBACK`.
- [x] Puedo explicar las operaciones desarrolladas.
- [ ] El código está versionado en GitHub. *(se marca al hacer el push)*

---

# 44. Cierre

Hasta ahora hemos construido DataLab.

Ahora comenzamos a **trabajar con sus datos**.

```text
              DATA LAB
                  │
                  ▼
          ┌───────────────┐
          │     SELECT    │
          │     LEER      │
          └───────┬───────┘
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
     INSERT     UPDATE    DELETE
      CREAR     CAMBIAR   ELIMINAR
        │         │         │
        └─────────┼─────────┘
                  ▼
             SELECT
             VERIFICAR
```

La meta no es memorizar cuatro comandos.

La meta es comprender que **SQL permite gestionar el ciclo de vida de los datos**, siempre respetando las reglas y relaciones definidas en el modelo de DataLab.

> **Diseñamos la estructura. Creamos los datos. Los consultamos. Los modificamos. Los eliminamos. Y verificamos cada operación.**
