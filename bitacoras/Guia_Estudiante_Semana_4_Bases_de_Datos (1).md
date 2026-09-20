# Semana 4 --- Guía del Estudiante

## Integridad Referencial y Normalización Básica (3.5--3.6)

### Caso hilo conductor: DataLab

------------------------------------------------------------------------

## 1. Propósito de la semana

Durante las semanas anteriores construyeron progresivamente el modelo de
datos de **DataLab**:

-   Semana 1: modelo conceptual E-R.
-   Semana 2: transformación del modelo E-R al modelo relacional.
-   Semana 3: tablas, columnas, dominios, tipos de datos, restricciones
    y llaves.

En esta semana el objetivo es verificar que el esquema no solamente
tenga tablas y relaciones, sino que además **mantenga la consistencia de
los datos y reduzca problemas de redundancia y dependencia**.

Se trabajarán dos temas centrales:

1.  **Integridad referencial:** garantiza que las relaciones entre
    tablas sean coherentes.
2.  **Normalización:** permite analizar la estructura de las tablas y
    detectar problemas de organización de los datos.

La semana combina formalización conceptual y trabajo práctico sobre el
esquema real de DataLab.

------------------------------------------------------------------------

# 2. Objetivos de aprendizaje

Al finalizar la semana estarán en capacidad de:

-   Explicar qué es la integridad referencial y qué política aplicar
    ante un `DELETE` o `UPDATE` sobre una fila referenciada.
-   Elegir y justificar, para cada llave foránea de DataLab, una
    política `ON DELETE`.
-   Diagnosticar violaciones de 1FN, 2FN y 3FN en un diseño dado y
    corregirlas.
-   Auditar su propio esquema de DataLab y confirmar o corregir que
    cumple con la normalización básica.
-   Documentar decisiones técnicas relacionadas con integridad y
    normalización.
-   Relacionar las decisiones tomadas durante la transformación E-R →
    relacional con las propiedades de un esquema normalizado.

------------------------------------------------------------------------

# 3. Caso hilo conductor: DataLab

DataLab es una plataforma interna para gestionar información relacionada
con proyectos de ciencia de datos e inteligencia artificial.

El esquema trabajado durante el semestre contiene ocho tablas:

1.  `cientifico_datos`
2.  `proyecto`
3.  `dataset`
4.  `experimento`
5.  `modelo`
6.  `metrica`
7.  `participacion`
8.  `uso_dataset`

En esta semana no se parte de un modelo nuevo. **Se audita y mejora el
modelo construido durante las semanas anteriores.**

> **Regla de trabajo:** antes de modificar una tabla, revisen qué
> decisión tomaron en las semanas 1, 2 y 3 y por qué.

------------------------------------------------------------------------

# BLOQUE 1 --- FORMALIZACIÓN

## 4. Integridad referencial

### 4.1 ¿Qué es la integridad de los datos?

La integridad de los datos es el conjunto de condiciones que permiten
mantener los datos **correctos, consistentes y relacionados de manera
válida**.

En una base de datos relacional no basta con almacenar información.
También es necesario controlar qué valores pueden aparecer y cómo pueden
relacionarse unas filas con otras.

Por ejemplo, en DataLab, un experimento puede estar asociado con un
proyecto. Si `experimento.id_proyecto = 15`, debe existir un proyecto
cuyo `id_proyecto` sea `15`.

Esto evita situaciones como:

``` text
EXPERIMENTO
id_experimento | id_proyecto
---------------|------------
101            | 15
```

cuando en `proyecto` no existe:

``` text
id_proyecto = 15
```

Ese registro tendría una referencia inválida.

------------------------------------------------------------------------

## 4.2 Integridad referencial

La **integridad referencial** es la regla que garantiza que una llave
foránea (`FK`) haga referencia a una fila válida de la tabla
referenciada.

Una relación típica es:

``` text
PROYECTO
   |
   | 1:N
   |
   v
EXPERIMENTO
```

En el modelo relacional:

``` text
proyecto
---------
id_proyecto PK
nombre
descripcion
```

``` text
experimento
-----------
id_experimento PK
id_proyecto FK
fecha_ejecucion
configuracion
```

La restricción indica:

``` text
experimento.id_proyecto
        ↓
proyecto.id_proyecto
```

Por lo tanto, no debería ser posible insertar un experimento que haga
referencia a un proyecto inexistente.

------------------------------------------------------------------------

## 4.3 Retomar la Semana 3

Recuerden su respuesta escrita de la semana pasada:

> **¿Qué debería pasar si se intenta insertar un experimento con un
> `id_proyecto` que no existe?**

Expliquen qué debería hacer el sistema y por qué.

"La inserción debería rechazarse. Esto es responsabilidad de la restricción de llave foránea (FK): no debe permitirse una fila en `experimento` que referencie un proyecto inexistente, para mantener la integridad referencia"

# 5. ¿Qué ocurre cuando se elimina una fila referenciada?

Una situación importante aparece cuando existe una relación entre dos
tablas y alguien intenta eliminar una fila de la tabla padre.

Por ejemplo:

``` text
PROYECTO
   |
   |---- EXPERIMENTO
   |---- PARTICIPACION
```

¿Qué debería ocurrir si se elimina un proyecto?

Hay varias posibilidades:

-   impedir la eliminación;
-   eliminar también los registros dependientes;
-   establecer la llave foránea como `NULL`.

La decisión depende del significado de los datos y de las reglas del
negocio.

Por eso, una llave foránea no es solamente una cuestión técnica. También
representa una **decisión sobre el ciclo de vida de la información**.

------------------------------------------------------------------------

# 6. Políticas `ON DELETE`

Las políticas de eliminación determinan qué ocurre con los registros
relacionados cuando se elimina una fila referenciada.

Las tres políticas estudiadas en esta semana son:

  -----------------------------------------------------------------------
  Política                Qué hace                Cuándo puede tener
                                                  sentido
  ----------------------- ----------------------- -----------------------
  `RESTRICT`              Impide eliminar la fila Cuando los datos
                          padre si existen        dependientes deben
                          registros relacionados. impedir la eliminación
                                                  del padre.

  `CASCADE`               Elimina automáticamente Cuando los registros
                          los registros           hijos no tienen sentido
                          dependientes.           sin el padre.

  `SET NULL`              Coloca la FK en `NULL`  Cuando la relación
                          cuando se elimina el    puede quedar sin
                          padre.                  referencia y la FK
                                                  permite `NULL`.
  -----------------------------------------------------------------------

> **Importante:** no existe una política universalmente correcta. La
> política debe justificarse según el significado de la relación y las
> reglas del sistema.

------------------------------------------------------------------------

## 6.1 `RESTRICT`

Con `RESTRICT`, la base de datos evita eliminar el registro padre si
existen registros hijos relacionados.

Ejemplo:

``` text
PROYECTO
id_proyecto = 10
```

tiene:

``` text
EXPERIMENTO
id_experimento | id_proyecto
---------------|------------
101            | 10
102            | 10
```

Si se intenta:

``` sql
DELETE FROM proyecto
WHERE id_proyecto = 10;
```

la operación será rechazada porque existen experimentos que dependen de
ese proyecto.

### Pregunta para analizar

¿Por qué podría ser importante impedir que se elimine un proyecto que
todavía tiene experimentos?

Porque los experimentos son evidencia real de trabajo realizado — borrar el proyecto y arrastrar sus experimentos en cascada implicaría perder configuraciones, fechas de ejecución y todo el historial de ese trabajo sin que nadie lo decida explícitamente. RESTRICT obliga a que alguien tome una decisión consciente (archivar, reasignar o confirmar el borrado en cascada) antes de perder esa información.

## 6.2 `CASCADE`

Con `CASCADE`, cuando se elimina la fila padre, también se eliminan
automáticamente las filas relacionadas.

Ejemplo:

``` text
MODELO
id_modelo = 25
```

tiene métricas:

``` text
METRICA
id_metrica | id_modelo
-----------|----------
1          | 25
2          | 25
3          | 25
```

Si se elimina el modelo y la FK tiene `ON DELETE CASCADE`, las métricas
asociadas también serán eliminadas.

Conceptualmente:

``` text
DELETE MODELO
      |
      +----> DELETE METRICAS RELACIONADAS
```

Esta política puede ser apropiada cuando el registro hijo no tiene
significado independiente.

------------------------------------------------------------------------

## 6.3 `SET NULL`

Con `SET NULL`, al eliminar el registro padre, la FK de los registros
hijos pasa a tener valor `NULL`.

Ejemplo:

``` text
PROYECTO
id_proyecto = 10
```

y:

``` text
EXPERIMENTO
id_experimento | id_proyecto
---------------|------------
101            | 10
```

Después de eliminar el proyecto:

``` text
EXPERIMENTO
id_experimento | id_proyecto
---------------|------------
101            | NULL
```

Para utilizar esta estrategia, la columna FK debe permitir `NULL`.

### Pregunta para analizar

¿Qué información se perdería y qué información se conservaría en este
escenario?

Se conserva la fila hija (por ejemplo, el experimento sigue existiendo con su fecha_ejecucion y configuracion), pero se pierde el vínculo con su padre: ya no se puede saber a qué proyecto pertenecía ese experimento. Es útil solo cuando esa pérdida de vínculo es aceptable para el negocio — en DataLab no lo es para experimento-proyecto, por eso se usa RESTRICT en vez de SET NULL.

# 7. Ejercicio: política para cada FK de DataLab

Para cada llave foránea de su esquema, elijan una política `ON DELETE` y
justifíquenla.

  Llave foránea                                      Política elegida   Justificación
  -------------------------------------------------- ------------------ ---------------
  `experimento.id_proyecto → proyecto`                  RESTRIC          Un experimento es evidencia de trabajo real; no debería desaparecer accidentalmente solo porque alguien borra el proyecto. Se impide el borrado del proyecto mientras tenga experimentos.                           
  `modelo.id_experimento → experimento`                 RESTRIC         Un modelo entrenado es un resultado importante; no tiene sentido que desaparezca silenciosamente solo por borrar el experimento que lo originó. Se impide el borrado       
  `metrica.id_modelo → modelo`                          CASCADE         Una métrica no tiene significado independiente del modelo que evalúa — si el modelo se elimina, no hay razón para conservar sus métricas sueltas.       
  `participacion.id_cientifico → cientifico_datos`      RESTRIC         Un científico no debería poder borrarse si todavía tiene participaciones activas registradas en proyectos — primero hay que resolver esa participación.           
  `participacion.id_proyecto → proyecto`                CASCADE         Si se elimina un proyecto, las filas de participa asociadas a ese proyecto ya no tienen sentido por sí solas (no representan nada sin el proyecto), así que se eliminan junto con él.           
  `uso_dataset.id_dataset → dataset`                    RESTRIC         Un dataset puede reutilizarse en varios experimentos; no debería poder borrarse mientras algún experimento dependa de él, para no perder trazabilidad de qué datos se usaron.       
  `uso_dataset.id_experimento → experimento`            CASCADE         La fila de usar solo representa el hecho de "este experimento usó este dataset"; si el experimento desaparece, ese hecho deja de tener sentido.       

### Pregunta de análisis

> **Si borramos un `MODELO`, ¿qué debería pasar con sus filas en
> `METRICA`?**

No respondan solamente `CASCADE`, `RESTRICT` o `SET NULL`. Expliquen la
razón desde el punto de vista del negocio.

Si borramos un MODELO, ¿qué pasa con sus filas en METRICA?
Se eliminan en cascada. Una métrica (accuracy, F1, etc.) no tiene significado por sí sola — solo existe como una medición de un modelo específico. Conservar métricas sin el modelo al que describen no aportaría nada útil, así que CASCADE es coherente con el negocio.

# 8. ¿Qué es la normalización?

La **normalización** es un proceso de análisis y organización de los
datos de un modelo relacional para reducir problemas como:

-   redundancia innecesaria;
-   inconsistencias;
-   dependencias incorrectas;
-   dificultades para actualizar información;
-   anomalías de inserción;
-   anomalías de actualización;
-   anomalías de eliminación.

La normalización se apoya en el concepto de **dependencia funcional**.

------------------------------------------------------------------------

## 8.1 Dependencia funcional

Decimos que un atributo depende funcionalmente de otro cuando un valor
determina de manera única otro valor.

Por ejemplo:

``` text
id_proyecto → nombre_proyecto
```

significa:

> Conociendo `id_proyecto`, podemos determinar cuál es el
> `nombre_proyecto`.

En una tabla:

``` text
id_proyecto | nombre
------------|------------------
10          | Sistema Predictivo
11          | Detección de Fraude
```

El identificador determina el nombre.

La normalización busca que los atributos estén ubicados en la tabla que
corresponde a sus dependencias.

------------------------------------------------------------------------

# 9. Primera Forma Normal --- 1FN

## 9.1 Idea fundamental

Una relación está en **Primera Forma Normal (1FN)** cuando sus atributos
contienen valores atómicos y no se utilizan columnas para almacenar
conjuntos o listas de valores que deberían gestionarse como datos
separados.

En términos prácticos:

> **Una celda debe representar un valor indivisible dentro del contexto
> del modelo.**

Esto facilita:

-   búsquedas;
-   filtros;
-   ordenamientos;
-   agregaciones;
-   restricciones;
-   índices;
-   consultas SQL.

------------------------------------------------------------------------

## 9.2 Ejemplo planteado en DataLab

Analicen este diseño:

``` text
metrica_mala(
    id_metrica,
    id_modelo,
    metricas_registradas
)
```

donde:

``` text
metricas_registradas =
"accuracy:0.95, f1:0.89, precision:0.91"
```

Toda esa información está almacenada en una sola columna de texto.

------------------------------------------------------------------------

## 9.3 ¿Cuál es el problema?

Supongamos que necesitamos responder:

> **¿Cuáles son todos los modelos con `accuracy` mayor a 0.90?**

Con el diseño anterior, el valor `accuracy` está mezclado dentro de una
cadena de texto.

La base de datos no dispone de una columna claramente definida:

``` text
accuracy
```

sobre la cual aplicar:

``` sql
WHERE accuracy > 0.90
```

Esto dificulta:

-   consultar;
-   validar;
-   comparar;
-   indexar;
-   agregar;
-   mantener los valores.

------------------------------------------------------------------------

## 9.4 Preguntas para el estudiante

**c)** ¿Qué problema tiene este diseño si quisieran buscar todos los
modelos con `accuracy` mayor a `0.90`?

El motor no tiene una columna accuracy sobre la cual aplicar WHERE accuracy > 0.90 — todo el valor está mezclado dentro de una cadena de texto. Para filtrar tendrían que extraer manualmente ese fragmento del texto (con funciones de string), lo cual es lento, propenso a errores y no puede indexarse.

**d)** ¿Cómo lo corregirían?

> **Pista:** ya tienen la respuesta en su propio esquema de la Semana 2.

Separando cada métrica en su propia fila, con columnas independientes nombre_metrica y valor — que es exactamente como ya está diseñada la tabla metrica desde la Semana 2. Así, WHERE nombre_metrica = 'accuracy' AND valor > 0.90 es una consulta directa y eficiente.

## 9.5 Relación con el esquema DataLab

El diseño normalizado separa los datos de manera que cada valor pueda
ser manejado por el motor relacional.

Por ejemplo, una métrica puede representarse como:

``` text
metrica
-------
id_metrica
id_modelo
nombre_metrica
valor
fecha_calculo
```

Así:

``` text
id_metrica | id_modelo | nombre_metrica | valor
-----------|-----------|----------------|------
1          | 25        | accuracy       | 0.95
2          | 25        | f1             | 0.89
3          | 25        | precision      | 0.91
```

Ahora es posible consultar directamente:

``` sql
SELECT *
FROM metrica
WHERE nombre_metrica = 'accuracy'
  AND valor > 0.90;
```

------------------------------------------------------------------------

# 10. Segunda Forma Normal --- 2FN

## 10.1 Idea fundamental

La **Segunda Forma Normal (2FN)** exige que una tabla:

1.  cumpla 1FN; y
2.  todos los atributos no clave dependan de **toda la llave primaria**,
    no solamente de una parte de ella.

Este concepto es especialmente importante cuando existe una **llave
primaria compuesta**.

------------------------------------------------------------------------

## 10.2 Llave primaria compuesta

Una llave primaria compuesta utiliza dos o más columnas para identificar
de manera única una fila.

Por ejemplo:

``` text
uso_dataset(
    id_dataset,
    id_experimento
)
```

La combinación:

``` text
(id_dataset, id_experimento)
```

puede identificar una asociación específica entre un dataset y un
experimento.

Ninguna de las columnas, por sí sola, necesariamente identifica la
asociación.

------------------------------------------------------------------------

## 10.3 Dependencia parcial

Existe una **dependencia parcial** cuando un atributo no clave depende
solamente de una parte de una llave primaria compuesta.

Analicen:

``` text
uso_dataset_malo(
    id_dataset,
    id_experimento,
    nombre_dataset,
    fecha_ejecucion
)
```

con llave primaria:

``` text
(id_dataset, id_experimento)
```

Preguntamos:

``` text
¿nombre_dataset depende de id_dataset?
¿fecha_ejecucion depende de id_experimento?
```

Si la respuesta es sí, entonces esos atributos no dependen de toda la
llave compuesta.

------------------------------------------------------------------------

## 10.4 Análisis del ejemplo

Tenemos:

``` text
id_dataset → nombre_dataset
```

porque el nombre corresponde al dataset.

Y:

``` text
id_experimento → fecha_ejecucion
```

porque la fecha corresponde al experimento.

Pero la llave de la tabla es:

``` text
(id_dataset, id_experimento)
```

Por tanto:

``` text
(id_dataset, id_experimento) → nombre_dataset
```

es una dependencia que puede determinarse realmente mediante una sola
parte de la llave.

Eso constituye una dependencia parcial.

------------------------------------------------------------------------

## 10.5 Preguntas para el estudiante

**e)** `nombre_dataset`, ¿depende de las dos columnas de la llave o de
solo una?

¿Y `fecha_ejecucion`?

nombre_dataset depende solo de id_dataset (no necesita id_experimento para determinarse). fecha_ejecucion depende solo de id_experimento (no necesita id_dataset). Ninguno de los dos depende realmente de la llave compuesta completa — eso es justamente la dependencia parcial.

**f)** ¿Cómo se corrige esta dependencia parcial?

Sacando esos atributos de la tabla puente y devolviéndolos a la entidad a la que pertenecen: nombre_dataset se queda en dataset, fecha_ejecucion se queda en experimento. La tabla puente (usar en su caso) queda solo con las dos llaves foráneas, representando exclusivamente la asociación.

## 10.6 Idea práctica para DataLab

La solución consiste en mantener cada atributo en la entidad a la que
realmente pertenece.

Conceptualmente:

``` text
DATASET
-------
id_dataset
nombre_dataset
...

EXPERIMENTO
-----------
id_experimento
fecha_ejecucion
...

USO_DATASET
-----------
id_dataset
id_experimento
```

La tabla `uso_dataset` representa la asociación.

Los datos propios del dataset permanecen en `dataset`.

Los datos propios del experimento permanecen en `experimento`.

------------------------------------------------------------------------

# 11. Tercera Forma Normal --- 3FN

## 11.1 Idea fundamental

La **Tercera Forma Normal (3FN)** busca eliminar las dependencias
transitivas entre atributos no clave.

Una forma práctica de pensarlo es:

> Un atributo debe depender de la llave de su propia tabla y no de otro
> atributo no clave.

------------------------------------------------------------------------

## 11.2 Dependencia transitiva

Existe una cadena como:

``` text
A → B
B → C
```

por lo que:

``` text
A → C
```

de manera transitiva.

En un diseño relacional, esto puede indicar que `C` pertenece
conceptualmente a otra entidad.

------------------------------------------------------------------------

## 11.3 Ejemplo planteado en DataLab

Analicen:

``` text
experimento_malo(
    id_experimento,
    id_proyecto,
    nombre_proyecto,
    fecha_ejecucion
)
```

Tenemos:

``` text
id_experimento → id_proyecto
```

y:

``` text
id_proyecto → nombre_proyecto
```

Por tanto:

``` text
id_experimento → id_proyecto → nombre_proyecto
```

`nombre_proyecto` no depende directamente del experimento; pertenece al
proyecto.

------------------------------------------------------------------------

## 11.4 Preguntas para el estudiante

**g)** `nombre_proyecto`, ¿depende directamente de `id_experimento`, o
depende de `id_proyecto`?

¿Cómo se llama esa cadena de dependencia?

Depende de id_proyecto, no directamente de id_experimento. La cadena id_experimento → id_proyecto → nombre_proyecto es una dependencia transitiva.

**h)** ¿Cómo se corrige?

Quitando nombre_proyecto de experimento — ese atributo pertenece conceptualmente a proyecto y ya está disponible ahí. experimento solo necesita conservar la FK id_proyecto para poder consultarlo cuando se necesite (mediante un JOIN), sin duplicar el dato.

## 11.5 Corrección conceptual

Una posible organización es:

``` text
PROYECTO
--------
id_proyecto
nombre
descripcion
```

y:

``` text
EXPERIMENTO
-----------
id_experimento
id_proyecto
fecha_ejecucion
configuracion
```

El experimento conserva la referencia al proyecto:

``` text
experimento.id_proyecto → proyecto.id_proyecto
```

pero no necesita repetir:

``` text
nombre_proyecto
```

------------------------------------------------------------------------

# 12. ¿Por qué un buen modelo E-R puede conducir a 3FN?

Esta pregunta conecta las semanas anteriores con la normalización.

**i)** Si construyeron correctamente su esquema desde la Semana 2,
siguiendo las reglas de conversión E-R → relacional:

> **¿Por qué sería esperable que ya esté en 3FN?**

Porque las reglas de conversión E-R → relacional ya obligan a que cada atributo quede en la tabla de la entidad a la que pertenece semánticamente, y a que las relaciones se resuelvan mediante llaves foráneas en vez de copiar datos descriptivos de una tabla en otra. Si respetaron esas reglas desde el inicio, nunca se introdujo la oportunidad de crear una dependencia transitiva — aunque igual vale la pena auditarlo, porque "esperable" no es lo mismo que "garantizado".

### Pista conceptual

En un modelo E-R correctamente construido:

-   cada entidad tiene sus propios atributos;
-   los atributos pertenecen a la entidad correspondiente;
-   las relaciones se representan mediante llaves foráneas o tablas
    puente;
-   no es necesario copiar atributos descriptivos de una entidad dentro
    de otra.

Por ello, una correcta separación de entidades y relaciones reduce la
posibilidad de introducir dependencias parciales o transitivas.

> **Importante:** que un esquema haya sido construido a partir de un E-R
> no significa que la normalización deba darse por supuesta. La
> estructura debe ser auditada y justificada.

------------------------------------------------------------------------

# 13. Resumen comparativo: 1FN, 2FN y 3FN

Forma normal | Pregunta principal | Problema que busca evitar|
-----------|-----------|----------------|
**1FN**    | ¿Cada atributo contiene valores atómicos? | Listas o grupos de valores dentro de una celda.|
**2FN**    | ¿Cada atributo no clave depende de toda la PK? | Dependencias parciales respecto de una PK compuesta.|
**3FN**    | ¿Los atributos no clave dependen directamente de la PK? | Dependencias transitivas.|


Una estrategia sencilla para analizar una tabla es preguntar:

``` text
1. ¿Hay valores no atómicos?
          ↓
        1FN

2. Si la PK es compuesta:
   ¿hay atributos que dependan solo de una parte?
          ↓
        2FN

3. ¿Hay atributos no clave que dependan de otros
   atributos no clave?
          ↓
        3FN
```

------------------------------------------------------------------------

# BLOQUE 2 --- LABORATORIO

## 14. Retomar --- 20 minutos

Antes de modificar el modelo, revisen los ejemplos de la formalización.

### Pregunta

> ¿Alguno de los tres ejemplos "malos" de la formalización les recordó
> algo de un borrador anterior de su propio esquema?

------------------------------------------------------------------------

------------------------------------------------------------------------

Si encuentran una situación similar:

1.  identifiquen el problema;
2.  expliquen por qué es un problema;
3.  indiquen qué tabla debería contener la información;
4.  registren la decisión tomada.

------------------------------------------------------------------------

# 15. Auditoría de normalización del propio esquema --- 50 minutos

Revisen **tabla por tabla** su esquema real de DataLab de la Semana 3.

Utilicen la siguiente matriz:

Tabla | ¿Valores atómicos? (1FN) | ¿Sin dependencia parcial? (2FN, solo si aplica) | ¿Sin dependencia transitiva? (3FN)|
-----------|-----------|----------------|----------------|
`cientifico_datos`| Si | PK Simple, no aplica| Si |
`proyecto`|  Si | PK Simple, no aplica| Si |                        
`dataset`| Si | PK Simple, no aplica| Si |                                
`experimento`| Si | PK Simple, no aplica| Si |                                 
`modelo`| Si | PK Simple, no aplica| Si |                             
`metrica`| Si | PK Simple, no aplica| Si |                                  
`participacion`| Si | PK compuesta, cumple trivialmente| Si |                                 
`uso_dataset`| Si | PK compuesta, cumple trivialmente | Si |                           


### Para cada tabla deben preguntarse:

#### 1FN

-   ¿Cada celda contiene un solo valor?
-   ¿Existe alguna lista almacenada en una columna?
-   ¿Hay información concatenada mediante comas?
-   ¿Una columna contiene diferentes tipos de información?

#### 2FN

-   ¿La tabla tiene una PK compuesta?
-   Si la tiene, ¿cada atributo no clave depende de toda la PK?
-   ¿Existe algún atributo que realmente pertenezca a una de las
    entidades relacionadas?

#### 3FN

-   ¿Existe un atributo no clave que determine otro atributo no clave?
-   ¿Se está repitiendo información de otra entidad?
-   ¿Hay un atributo descriptivo que debería estar en otra tabla?

------------------------------------------------------------------------

# 16. Ejemplo de auditoría

Supongamos:

``` text
metrica
-------
id_metrica PK
id_modelo FK
nombre_metrica
valor
fecha_calculo
```

### 1FN

Preguntar:

> ¿`nombre_metrica` y `valor` contienen valores individuales?

Si la respuesta es sí, no se observa el problema planteado en el ejemplo
`metrica_mala`.

### 2FN

Si la PK es únicamente:

``` text
id_metrica
```

no existe una PK compuesta y, por tanto, no se presenta el problema de
dependencia parcial planteado para 2FN.

### 3FN

Preguntar:

> ¿Algún atributo de `metrica` depende de otro atributo no clave?

Si no existe esa dependencia, la tabla cumple el criterio analizado para
3FN.

------------------------------------------------------------------------

# 17. Aplicar las políticas de integridad referencial --- 50 minutos

Actualicen su archivo `.dbml` o el modelo en MySQL Workbench agregando
las políticas `ON DELETE` decididas en el Bloque 1.

En DBML pueden encontrar una representación como:

``` dbml
Ref: metrica.id_modelo > modelo.id_modelo [delete: cascade]

Ref: experimento.id_proyecto > proyecto.id_proyecto [delete: restrict]
```

La sintaxis concreta dependerá de la herramienta utilizada, pero el
concepto es el mismo:

``` text
Tabla hija
    |
    | FK
    v
Tabla padre
    |
    | DELETE
    v
Política definida
```

------------------------------------------------------------------------

# 18. Documentar las decisiones --- 30 minutos

Actualicen:

``` text
documentacion/decisiones.md
```

Deben registrar la política `ON DELETE` de cada una de las ocho FK.

Se recomienda utilizar una estructura como:

``` markdown
## Política de integridad referencial

### experimento.id_proyecto → proyecto.id_proyecto

**Política:** RESTRICT

**Justificación:**
Se impide eliminar un proyecto mientras existan experimentos
que dependan de él, debido a que el experimento conserva una
relación necesaria con el proyecto.
```

La justificación debe explicar **por qué la política tiene sentido para
DataLab**, no solamente definir la palabra `CASCADE` o `RESTRICT`.

También deben registrar:

-   qué revisaron durante la auditoría;
-   qué tablas confirmaron;
-   qué problemas encontraron;
-   qué cambios realizaron;
-   por qué realizaron cada cambio.

------------------------------------------------------------------------

# 19. Actualización del repositorio

Exporten el esquema actualizado como:

``` text
diagramas/
└── relacional/
    └── s04-esquema-integridad.png
```

o actualicen el archivo `.dbml`, según la herramienta utilizada.

Realicen el commit:

``` bash
git add .
git commit -m "modelo: políticas de integridad referencial y auditoría de normalización de DataLab"
git push
```

El commit debe dejar evidencia de la evolución del modelo.

------------------------------------------------------------------------

# 20. Verificación de comprensión --- antes de salir

### 1. ¿Cuál es la diferencia entre `RESTRICT` y `CASCADE`?

RESTRICT impide el borrado del padre mientras existan hijos relacionados. CASCADE permite el borrado del padre y elimina automáticamente los hijos relacionados.

### 2. ¿Por qué 2FN solo importa cuando la llave primaria es compuesta?

Porque la dependencia parcial es "un atributo que depende de solo una parte de la llave primaria". Si la PK es una sola columna, no existe "una parte" de ella — cualquier atributo no clave depende automáticamente de toda la llave.

### 3. Si su esquema fue construido correctamente a partir del modelo E-R, ¿por qué es esperable que ya esté en 3FN?

Porque la transformación E-R → relacional bien hecha ya deja cada atributo en su entidad correspondiente y resuelve las relaciones con FK, sin arrastrar datos descriptivos de otras entidades.

# 21. Lista de verificación del estudiante

Antes de finalizar la sesión, verifiquen:

-   [ ] Entiendo qué es integridad referencial.
-   [ ] Puedo explicar la diferencia entre `RESTRICT`, `CASCADE` y
    `SET NULL`.
-   [ ] Puedo justificar una política `ON DELETE`.
-   [ ] Revisé las 8 llaves foráneas de DataLab.
-   [ ] Entiendo qué significa 1FN.
-   [ ] Puedo identificar una dependencia parcial.
-   [ ] Entiendo por qué 2FN se relaciona especialmente con PK
    compuestas.
-   [ ] Puedo identificar una dependencia transitiva.
-   [ ] Entiendo el objetivo de 3FN.
-   [ ] Audité las 8 tablas de DataLab.
-   [ ] Documenté las decisiones.
-   [ ] Actualicé el diagrama o `.dbml`.
-   [ ] Realicé el commit.
-   [ ] Mi contribución individual puede identificarse en Git.

------------------------------------------------------------------------

# 22. Errores frecuentes que deben evitar

### Error 1 --- Elegir `CASCADE` automáticamente

`CASCADE` no significa "mejor". Debe existir una razón para que los
registros dependientes desaparezcan junto con el padre.

### Error 2 --- Confundir FK con PK

Una FK establece una referencia hacia otra tabla. Una PK identifica de
manera única una fila de su propia tabla.

### Error 3 --- Pensar que 2FN siempre requiere dividir una tabla

Primero se debe analizar la PK. La situación de dependencia parcial está
asociada a una llave compuesta.

### Error 4 --- Confundir dependencia transitiva con relación entre tablas

Que dos tablas estén relacionadas mediante una FK no constituye por sí
mismo una violación de 3FN. El problema aparece cuando se almacenan
atributos que dependen de otro atributo no clave dentro de la misma
relación.

### Error 5 --- Normalizar sin comprender el dominio

La normalización no consiste simplemente en "crear más tablas". Cada
separación debe representar una dependencia y una decisión semántica
coherente.

### Error 6 --- Modificar el modelo sin documentar

Una decisión técnica debe quedar registrada para que otro integrante del
equipo pueda entender qué se cambió y por qué.

------------------------------------------------------------------------

# 23. Preguntas de profundización

Estas preguntas pueden utilizarse para discusión en clase o como
ejercicio adicional.

### Pregunta 1

Si `metrica.id_modelo` utiliza `ON DELETE CASCADE`, ¿qué riesgo existe
si un usuario elimina accidentalmente un modelo?

Si metrica.id_modelo usa ON DELETE CASCADE, ¿qué riesgo existe si alguien elimina accidentalmente un modelo? Se perderían automáticamente todas las métricas asociadas a ese modelo, sin posibilidad fácil de deshacerlo — todo el historial de evaluación desaparecería junto con el modelo borrado por error.

### Pregunta 2

¿Por qué podría ser preferible `RESTRICT` para una relación entre
`proyecto` y `experimento`?

Porque un experimento representa trabajo real; borrar un proyecto no debería arrastrar silenciosamente todos sus experimentos. RESTRICT obliga a decidir explícitamente qué hacer con ellos antes de poder eliminar el proyecto.

### Pregunta 3

¿Por qué guardar `"accuracy:0.95, f1:0.89"` como texto dificulta el
trabajo analítico?

Porque el motor no puede tratar esos valores como datos estructurados: no se pueden filtrar, ordenar, promediar ni indexar directamente sin antes parsear el texto.

### Pregunta 4

¿Por qué `nombre_dataset` pertenece conceptualmente a `dataset` y no a
`uso_dataset`?

Porque es una característica propia del dataset, que existe independientemente de si se usa o no en algún experimento; uso_dataset solo representa el hecho puntual de un uso, no debería cargar información que ya vive en otra parte.

### Pregunta 5

¿Qué anomalía de actualización podría aparecer si `nombre_proyecto`
estuviera repetido en muchos registros de `experimento`?

Si el nombre del proyecto cambia, habría que actualizarlo en todas las filas donde aparece repetido; si se olvida alguna, la base de datos queda con información inconsistente.

### Pregunta 6

¿Cuál es la relación entre una correcta transformación E-R → relacional
y la normalización?

Ambas persiguen lo mismo: que cada atributo quede en la entidad a la que pertenece y que las relaciones se resuelvan vía FK sin duplicar datos. Una transformación E-R correcta tiende a llegar naturalmente a 3FN.

# 24. Relación con el Hito 2

Esta semana prepara el cierre del **Hito 2**.

Al finalizar la Semana 4 deben tener:

-   [ ] Políticas `ON DELETE` definidas y aplicadas en el diagrama para
    las 8 FK.
-   [ ] Auditoría de normalización completa: 1FN, 2FN y 3FN.
-   [ ] Decisiones documentadas en `documentacion/decisiones.md`.
-   [ ] Diagrama relacional actualizado.
-   [ ] Commit realizado con el mensaje sugerido.

El **Hito 2 completo** se cierra en la Semana 5, cuando el diseño físico
se lleve a un motor relacional real y se realice la creación de las
tablas mediante DDL.

------------------------------------------------------------------------

# 25. Reto de cierre --- explicar con Feynman

Sin consultar apuntes, expliquen a un compañero:

> **"¿Cómo sé si mi tabla de DataLab está correctamente normalizada y
> qué debería pasar si elimino un registro que tiene otras tablas
> relacionadas?"**

La explicación debe incluir:

1.  integridad referencial;
2.  FK;
3.  `RESTRICT`;
4.  `CASCADE`;
5.  `SET NULL`;
6.  1FN;
7.  2FN;
8.  3FN;
9.  un ejemplo de DataLab.

Después, el compañero debe formular una pregunta sobre la explicación.

------------------------------------------------------------------------

# 26. Evidencias esperadas en GitHub

Al revisar el repositorio debe ser posible identificar:

``` text
datalab-<equipo>/
├── diagramas/
│   └── relacional/
│       └── s04-esquema-integridad.png
├── documentacion/
│   └── decisiones.md
└── ...
```

Además, debe existir un commit relacionado con:

``` text
modelo: políticas de integridad referencial y auditoría de normalización de DataLab
```

La evidencia de Git debe permitir observar la evolución del modelo y,
cuando corresponda, la contribución individual de cada integrante.

------------------------------------------------------------------------

# 27. Conexión con la Semana 5

En la próxima semana el modelo pasará de una representación
lógica/documental a una implementación física en un motor de base de
datos.

La secuencia será:

``` text
Modelo E-R
    ↓
Modelo relacional
    ↓
Tablas + columnas + tipos
    ↓
Integridad referencial
    ↓
Normalización
    ↓
Diseño físico
    ↓
CREATE TABLE
    ↓
Base de datos ejecutada en un motor real
```

Por esta razón, las decisiones tomadas esta semana deben quedar
suficientemente claras para que puedan convertirse posteriormente en
sentencias DDL.

------------------------------------------------------------------------

## Fuente de trabajo

Esta guía conserva como base la estructura, preguntas, ejemplos, ocho
llaves foráneas, actividades de laboratorio, evidencias y avance hacia
el Hito 2 planteados en el documento **Semana 4 --- Guía del
Estudiante**, y amplía la explicación teórica de los conceptos allí
definidos.
