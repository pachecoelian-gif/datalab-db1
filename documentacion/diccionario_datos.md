# Diccionario de datos — DataLab

## Nivel conceptual (Hito 1)

### Entidad: CIENTIFICO_DATOS

| Atributo | Tipo de atributo | Llave |
|---|---|---|
| id_cientifico | Numérico | Primaria |
| nombre | Texto | — |

### Entidad: PROYECTO

| Atributo | Tipo de atributo | Llave |
|---|---|---|
| id_proyecto | Numérico | Primaria |
| nombre_problema | Texto | — |

### Entidad: DATASET

| Atributo | Tipo de atributo | Llave |
|---|---|---|
| id_dataset | Numérico | Primaria |
| nombre | Texto | — |
| fuente | Texto (interna/externa) | — |
| fecha_carga | Fecha | — |
| tamanio_filas | Numérico | — |

### Entidad: EXPERIMENTO

| Atributo | Tipo de atributo | Llave |
|---|---|---|
| id_experimento | Numérico | Primaria |
| nombre_experimento | Texto | Candidata (descartada) |
| fecha_ejecucion | Fecha | — |
| configuracion | Texto largo | — |

### Entidad: MODELO

| Atributo | Tipo de atributo | Llave |
|---|---|---|
| id_modelo | Numérico | Primaria |
| nombre | Texto | Candidata (compuesta con version, descartada) |
| version | Texto | Candidata (compuesta con nombre, descartada) |
| algoritmo | Texto | — |

### Entidad: METRICA

| Atributo | Tipo de atributo | Llave |
|---|---|---|
| id_metrica | Numérico | Primaria |
| nombre_metrica | Texto | — |
| valor | Decimal | — |
| fecha_calculo | Fecha | — |

## Justificación de llaves primarias

- **CIENTIFICO_DATOS**: no hay identificador natural único mencionado en el enunciado (cédula, correo), así que se usa `id_cientifico` autogenerado.
- **PROYECTO**: `nombre_problema` podría repetirse o reformularse en el tiempo; se usa `id_proyecto` autogenerado.
- **DATASET**: `nombre` podría repetirse entre datasets de fuentes distintas; se usa `id_dataset` autogenerado.
- **EXPERIMENTO**: `nombre_experimento` no es único entre científicos ni entre corridas del mismo científico; se usa `id_experimento` autogenerado.
- **MODELO**: la combinación (`nombre`, `version`) sería candidata pero complica las referencias desde METRICA al ser compuesta; se usa `id_modelo` autogenerado.


## Actualización: Nivel Lógico (Esquema Relacional)
En esta etapa ya pasé nuestro modelo conceptual inicial a tablas reales de base de datos. Para lograr esto, tuve que definir el tipo de dato específico para cada atributo. Por ejemplo, le asigné `INT` a todos los identificadores numéricos (como los IDs) y usé `VARCHAR` para los textos, como los nombres de los científicos, los correos electrónicos o los estados de un proyecto. 

Además, ya dejé definido cómo se van a conectar las tablas entre sí utilizando llaves foráneas (FK). Un ejemplo claro de esto es la tabla `experimento`, a la cual le tuve que agregar el `id_proyecto` como FK para poder saber rápidamente a qué iniciativa pertenece cada prueba. También le agregué el `id_dataset` para tener claro qué conjunto de datos exacto se utilizó. Siento que estructurándolo así, la base de datos queda súper bien conectada y nos va a facilitar mucho la vida cuando tengamos que hacerle consultas.
- **METRICA**: la combinación (`id_modelo`, `nombre_metrica`) no es única porque una métrica puede recalcularse en fechas distintas; se usa `id_metrica` autogenerado.

# Diccionario de datos — DataLab (nivel relacional, Semana 3)

| Tabla | Columna | Tipo de dato | Restricciones | Referencia |
|---|---|---|---|---|
| cientifico_datos | id_cientifico | INT | PK | — |
| cientifico_datos | nombre | VARCHAR(100) | NOT NULL | — |
| proyecto | id_proyecto | INT | PK | — |
| proyecto | nombre_problema | VARCHAR(150) | NOT NULL | — |
| participacion | id_cientifico | INT | PK, FK | cientifico_datos.id_cientifico |
| participacion | id_proyecto | INT | PK, FK | proyecto.id_proyecto |
| dataset | id_dataset | INT | PK | — |
| dataset | nombre | VARCHAR(100) | NOT NULL | — |
| dataset | fuente | VARCHAR(20) | NOT NULL, CHECK fuente IN ('interna','externa') | — |
| dataset | fecha_carga | DATE | NOT NULL | — |
| dataset | tamanio_filas | INT | NOT NULL, CHECK tamanio_filas > 0 | — |
| experimento | id_experimento | INT | PK | — |
| experimento | id_proyecto | INT | NOT NULL, FK | proyecto.id_proyecto |
| experimento | id_dataset | INT | NOT NULL, FK | dataset.id_dataset |
| experimento | id_cientifico | INT | NOT NULL, FK | cientifico_datos.id_cientifico |
| experimento | fecha_ejecucion | DATE | NOT NULL | — |
| experimento | configuracion | TEXT | — | — |
| modelo | id_modelo | INT | PK | — |
| modelo | id_experimento | INT | UNIQUE, NOT NULL, FK | experimento.id_experimento |
| modelo | nombre | VARCHAR(100) | NOT NULL | — |
| modelo | version | VARCHAR(20) | NOT NULL | — |
| modelo | algoritmo | VARCHAR(100) | NOT NULL | — |
| metrica | id_metrica | INT | PK | — |
| metrica | id_modelo | INT | NOT NULL, FK | modelo.id_modelo |
| metrica | nombre_metrica | VARCHAR(50) | NOT NULL | — |
| metrica | valor | DECIMAL(5,4) | NOT NULL, CHECK valor BETWEEN 0 AND 1 | — |
| metrica | fecha_calculo | DATE | NOT NULL | — |
