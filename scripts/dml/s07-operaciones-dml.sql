/*
    DataLab
    Semana 6 / 7
    Operaciones DML

    INSERT
    SELECT
    UPDATE
    DELETE

    SGBD: SQL Server  |  Herramienta: SSMS
    Autor: Elian Santiago Pacheco Vanegas

    IMPORTANTE - AJUSTAR SI ES NECESARIO:
    Los nombres de columnas se tomaron de la guia de la actividad.
    Si en tu DDL (s05-creacion-tablas.sql) se llaman distinto, cambialos aqui:
      cientifico_datos : id_cientifico, nombre, correo
      proyecto         : id_proyecto, nombre, descripcion
      dataset          : id_dataset, nombre, fuente, fecha_carga, tamano_filas
      experimento      : id_experimento, id_proyecto, id_cientifico,
                         fecha_ejecucion, configuracion

    Estrategia: ningun ID se escribe "a mano". Cada registro se busca por una
    clave natural (correo, nombre) para que el script funcione sin importar
    el valor que genere IDENTITY.
*/

USE DataLab;
GO

SET NOCOUNT ON;

-- =====================================================================
-- 0. PRE-LIMPIEZA (permite re-ejecutar el script sin duplicar datos)
--    Solo borra filas creadas por esta practica, en orden de FK
--    (hijos primero, padres despues).
-- =====================================================================
DELETE FROM experimento
WHERE id_proyecto IN (SELECT id_proyecto FROM proyecto
                      WHERE nombre IN ('Prediccion de demanda (practica S06)',
                                       'Proyecto CRUD DataLab',
                                       'Proyecto Temporal DELETE S06'));

DELETE FROM proyecto
WHERE nombre IN ('Prediccion de demanda (practica S06)',
                 'Proyecto CRUD DataLab',
                 'Proyecto Temporal DELETE S06');

DELETE FROM dataset
WHERE nombre IN ('Historial de demanda 2025');

DELETE FROM cientifico_datos
WHERE correo IN ('elian.pacheco@datalab.com');

PRINT '--- Pre-limpieza terminada ---';

-- =====================================================================
-- 1. SELECT  (estado inicial)
-- =====================================================================
SELECT * FROM cientifico_datos;
SELECT * FROM proyecto;
SELECT * FROM dataset;
SELECT * FROM experimento;
SELECT * FROM modelo;
SELECT * FROM metrica;

-- Conteo por tabla (las 8 tablas del modelo)
SELECT 'cientifico_datos' AS tabla, COUNT(*) AS filas FROM cientifico_datos
UNION ALL SELECT 'proyecto',      COUNT(*) FROM proyecto
UNION ALL SELECT 'dataset',       COUNT(*) FROM dataset
UNION ALL SELECT 'experimento',   COUNT(*) FROM experimento
UNION ALL SELECT 'modelo',        COUNT(*) FROM modelo
UNION ALL SELECT 'metrica',       COUNT(*) FROM metrica
UNION ALL SELECT 'participacion', COUNT(*) FROM participacion
UNION ALL SELECT 'uso_dataset',   COUNT(*) FROM uso_dataset;

-- =====================================================================
-- 2. INSERT  (orden obligado por las FK:
--    cientifico_datos -> proyecto -> dataset -> experimento)
-- =====================================================================

-- 2.1 Cientifico
INSERT INTO cientifico_datos (nombre, correo)
VALUES ('Elian Pacheco', 'elian.pacheco@datalab.com');

-- 3.1 SELECT DE VERIFICACION
SELECT * FROM cientifico_datos
WHERE correo = 'elian.pacheco@datalab.com';

-- 2.2 Proyecto
INSERT INTO proyecto (nombre, descripcion)
VALUES ('Prediccion de demanda (practica S06)',
        'Proyecto para analizar y predecir la demanda de servicios.');

-- 3.2 SELECT DE VERIFICACION
SELECT * FROM proyecto
WHERE nombre = 'Prediccion de demanda (practica S06)';

-- 2.3 Dataset
INSERT INTO dataset (nombre, fuente, fecha_carga, tamano_filas)
VALUES ('Historial de demanda 2025',
        'Sistema interno de facturacion',
        '20261007',
        15000);

-- 3.3 SELECT DE VERIFICACION
SELECT * FROM dataset
WHERE nombre = 'Historial de demanda 2025';

-- 2.4 Experimento (FK a proyecto y cientifico_datos, resueltas por busqueda)
INSERT INTO experimento (id_proyecto, id_cientifico, fecha_ejecucion, configuracion)
SELECT p.id_proyecto, c.id_cientifico, '20261007',
       'Configuracion inicial del experimento'
FROM proyecto p
CROSS JOIN cientifico_datos c
WHERE p.nombre = 'Prediccion de demanda (practica S06)'
  AND c.correo = 'elian.pacheco@datalab.com';

-- 3.4 SELECT DE VERIFICACION (JOIN para ver las referencias resueltas)
SELECT e.*, p.nombre AS proyecto, c.nombre AS cientifico
FROM experimento e
JOIN proyecto p         ON p.id_proyecto   = e.id_proyecto
JOIN cientifico_datos c ON c.id_cientifico = e.id_cientifico
WHERE p.nombre = 'Prediccion de demanda (practica S06)';

-- 2.5 Prueba de restriccion UNIQUE en correo (debe fallar si existe UNIQUE)
BEGIN TRY
    INSERT INTO cientifico_datos (nombre, correo)
    VALUES ('Elian Duplicado', 'elian.pacheco@datalab.com');
    PRINT 'AVISO: no hubo error -> revisa si correo tiene restriccion UNIQUE.';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS numero_error,   -- 2627 / 2601 = violacion UNIQUE
           ERROR_MESSAGE() AS mensaje_error;
END CATCH;

-- =====================================================================
-- 4. UPDATE  (regla: SELECT con la misma condicion ANTES de cada UPDATE)
-- =====================================================================

-- 4.1 Descripcion de un proyecto
SELECT * FROM proyecto
WHERE nombre = 'Prediccion de demanda (practica S06)';          -- 1 fila esperada

UPDATE proyecto
SET descripcion = 'Proyecto para predecir la demanda mensual de servicios con series de tiempo.'
WHERE nombre = 'Prediccion de demanda (practica S06)';

-- 5.1 SELECT DE VERIFICACION
SELECT * FROM proyecto
WHERE nombre = 'Prediccion de demanda (practica S06)';

-- 4.2 Nombre de un cientifico
SELECT * FROM cientifico_datos
WHERE correo = 'elian.pacheco@datalab.com';                     -- 1 fila esperada

UPDATE cientifico_datos
SET nombre = 'Elian Santiago Pacheco'
WHERE correo = 'elian.pacheco@datalab.com';

-- 5.2 SELECT DE VERIFICACION
SELECT * FROM cientifico_datos
WHERE correo = 'elian.pacheco@datalab.com';

-- 4.3 Fuente de un dataset
SELECT * FROM dataset
WHERE nombre = 'Historial de demanda 2025';                     -- 1 fila esperada

UPDATE dataset
SET fuente = 'Data warehouse corporativo'
WHERE nombre = 'Historial de demanda 2025';

-- 5.3 SELECT DE VERIFICACION
SELECT * FROM dataset
WHERE nombre = 'Historial de demanda 2025';

-- 4.4 Configuracion de un experimento
SELECT e.* FROM experimento e
JOIN proyecto p ON p.id_proyecto = e.id_proyecto
WHERE p.nombre = 'Prediccion de demanda (practica S06)';        -- 1 fila esperada

UPDATE e
SET e.configuracion = 'Modelo ARIMA, ventana de 12 meses, semilla 42'
FROM experimento e
JOIN proyecto p ON p.id_proyecto = e.id_proyecto
WHERE p.nombre = 'Prediccion de demanda (practica S06)';

-- 5.4 SELECT DE VERIFICACION
SELECT e.* FROM experimento e
JOIN proyecto p ON p.id_proyecto = e.id_proyecto
WHERE p.nombre = 'Prediccion de demanda (practica S06)';

-- =====================================================================
-- 5. TRANSACCIONES
-- =====================================================================

-- 5.5 ROLLBACK: el cambio se ve dentro de la transaccion y luego se deshace
BEGIN TRANSACTION;

    UPDATE proyecto
    SET descripcion = 'Prueba temporal'
    WHERE nombre = 'Prediccion de demanda (practica S06)';

    SELECT 'DENTRO de la transaccion' AS momento, nombre, descripcion
    FROM proyecto
    WHERE nombre = 'Prediccion de demanda (practica S06)';       -- 'Prueba temporal'

ROLLBACK TRANSACTION;

SELECT 'DESPUES del ROLLBACK' AS momento, nombre, descripcion
FROM proyecto
WHERE nombre = 'Prediccion de demanda (practica S06)';           -- valor anterior

-- 5.6 COMMIT: el cambio se confirma
BEGIN TRANSACTION;

    UPDATE proyecto
    SET descripcion = 'Proyecto de prediccion de demanda (version confirmada con COMMIT).'
    WHERE nombre = 'Prediccion de demanda (practica S06)';

    SELECT 'DENTRO de la transaccion' AS momento, nombre, descripcion
    FROM proyecto
    WHERE nombre = 'Prediccion de demanda (practica S06)';

COMMIT TRANSACTION;

SELECT 'DESPUES del COMMIT' AS momento, nombre, descripcion
FROM proyecto
WHERE nombre = 'Prediccion de demanda (practica S06)';           -- queda guardado

-- =====================================================================
-- 6. EXPERIMENTO DE INTEGRIDAD REFERENCIAL
-- =====================================================================

-- 6.1 INSERT con id_proyecto inexistente (9999): debe ser rechazado
BEGIN TRY
    INSERT INTO experimento (id_proyecto, id_cientifico, fecha_ejecucion, configuracion)
    SELECT 9999, c.id_cientifico, '20260924', 'Prueba de integridad'
    FROM cientifico_datos c
    WHERE c.correo = 'elian.pacheco@datalab.com';
    PRINT 'AVISO: el INSERT NO fue rechazado -> revisar la FK de experimento.';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS numero_error,   -- 547 = conflicto con FOREIGN KEY
           ERROR_SEVERITY() AS severidad,
           ERROR_MESSAGE() AS mensaje_error;
END CATCH;

-- 6.2 Comprobar que NO se creo nada
SELECT * FROM experimento WHERE id_proyecto = 9999;              -- 0 filas

-- 6.3 DELETE del padre con hijos (proyecto con experimento).
--     Se hace dentro de una transaccion que SIEMPRE termina en ROLLBACK
--     para no perder los datos de la practica, sea cual sea la politica ON DELETE.
BEGIN TRANSACTION;
BEGIN TRY
    DELETE FROM proyecto
    WHERE nombre = 'Prediccion de demanda (practica S06)';
    PRINT 'El DELETE se permitio (politica CASCADE o SET NULL). Se deshace con ROLLBACK.';

    SELECT COUNT(*) AS experimentos_restantes
    FROM experimento e
    JOIN proyecto p ON p.id_proyecto = e.id_proyecto
    WHERE p.nombre = 'Prediccion de demanda (practica S06)';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS numero_error,   -- 547 si la politica es NO ACTION/RESTRICT
           ERROR_MESSAGE() AS mensaje_error;
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

SELECT * FROM proyecto
WHERE nombre = 'Prediccion de demanda (practica S06)';           -- sigue existiendo

-- =====================================================================
-- 7. DELETE CONTROLADO (registro creado solo para la practica, sin hijos)
-- =====================================================================
INSERT INTO proyecto (nombre, descripcion)
VALUES ('Proyecto Temporal DELETE S06',
        'Proyecto creado unicamente para practicar DELETE controlado.');

-- 7.1 SELECT previo: confirma que la condicion identifica EXACTAMENTE 1 fila
SELECT * FROM proyecto
WHERE nombre = 'Proyecto Temporal DELETE S06';

-- 7.2 Verificar que no tiene registros relacionados
SELECT COUNT(*) AS experimentos_relacionados
FROM experimento e
JOIN proyecto p ON p.id_proyecto = e.id_proyecto
WHERE p.nombre = 'Proyecto Temporal DELETE S06';                 -- 0

-- 7.3 DELETE
DELETE FROM proyecto
WHERE nombre = 'Proyecto Temporal DELETE S06';

-- 7.4 SELECT DE VERIFICACION
SELECT * FROM proyecto
WHERE nombre = 'Proyecto Temporal DELETE S06';                   -- 0 filas

-- =====================================================================
-- 8. CICLO CRUD COMPLETO (practica integrada, secciones 21 a 29)
-- =====================================================================

-- Paso 1 - READ (estado previo)
SELECT * FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';                          -- 0 filas

-- Paso 2 - CREATE
INSERT INTO proyecto (nombre, descripcion)
VALUES ('Proyecto CRUD DataLab',
        'Proyecto creado para practicar operaciones DML.');

-- Paso 3 - READ
SELECT id_proyecto, nombre, descripcion
FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';

-- Paso 4 - UPDATE
UPDATE proyecto
SET descripcion = 'Proyecto actualizado durante la practica DML.'
WHERE nombre = 'Proyecto CRUD DataLab';

-- Paso 5 - READ (verificar actualizacion)
SELECT id_proyecto, nombre, descripcion
FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';

-- Paso 6 - DELETE
DELETE FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';

-- Paso 7 - READ (verificar eliminacion)
SELECT * FROM proyecto
WHERE nombre = 'Proyecto CRUD DataLab';                          -- 0 filas

-- =====================================================================
-- 9. SELECT FINAL - estado en que queda la base
--    (quedan: 1 cientifico, 1 proyecto, 1 dataset, 1 experimento de practica)
-- =====================================================================
SELECT 'cientifico_datos' AS tabla, COUNT(*) AS filas FROM cientifico_datos
UNION ALL SELECT 'proyecto',    COUNT(*) FROM proyecto
UNION ALL SELECT 'dataset',     COUNT(*) FROM dataset
UNION ALL SELECT 'experimento', COUNT(*) FROM experimento;

/*
    LIMPIEZA OPCIONAL (descomentar para dejar la BD como estaba).
    Orden: hijos primero, padres despues.

    DELETE FROM experimento WHERE id_proyecto IN
        (SELECT id_proyecto FROM proyecto
         WHERE nombre = 'Prediccion de demanda (practica S06)');
    DELETE FROM proyecto WHERE nombre = 'Prediccion de demanda (practica S06)';
    DELETE FROM dataset  WHERE nombre = 'Historial de demanda 2025';
    DELETE FROM cientifico_datos WHERE correo = 'elian.pacheco@datalab.com';
*/
