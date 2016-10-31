CREATE EXTENSION "uuid-ossp";
CREATE TYPE enum_familia AS ENUM
        ('Sumergible', 'Centrifuga', 'Turbina', 'Autobebante');

CREATE TABLE bien (
        codigo         INTEGER PRIMARY KEY,
                /*El codigo debe ser un numero de 10 digitos*/
                CONSTRAINT bien_codigo_valido CHECK (codigo > 0
                  AND codigo <= 9999999999),
        modelo         TEXT NOT NULL,
        cantidad       INTEGER NOT NULL,
                CONSTRAINT bien_cantidad_valida CHECK (cantidad >= 0),
        unidad         TEXT,
        medida         DECIMAL (8,2),
        costo_promedio DECIMAL (8,2) NOT NULL
);

CREATE TABLE producto (
        codigo  INTEGER PRIMARY KEY,
                CONSTRAINT producto_fk FOREIGN KEY (codigo)
                  REFERENCES bien(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        familia enum_familia NOT NULL
);

CREATE TABLE componente (
        codigo  INTEGER PRIMARY KEY,
                CONSTRAINT componente_fk FOREIGN KEY (codigo)
                  REFERENCES bien(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE materia_prima (
        codigo INTEGER PRIMARY KEY,
                CONSTRAINT materia_fk FOREIGN KEY (codigo)
                  REFERENCES bien(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE
);

/*Faltan restriccion:
  Todo bien debe participar una vez y solo una vez en una de las relaciones
  producto, componente o materia_prima*/

CREATE TABLE tiene (
        codigo_producto   INTEGER NOT NULL,
                CONSTRAINT tiene_fk_producto FOREIGN KEY (codigo_producto)
                  REFERENCES producto(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        codigo_componente INTEGER NOT NULL,
                CONSTRAINT tiene_fk_componente FOREIGN KEY (codigo_componente)
                  REFERENCES componente(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT tiene_pk PRIMARY KEY (codigo_producto, codigo_componente),
        cantidad          INTEGER NOT NULL,
                CONSTRAINT tiene_cantidad_valida CHECK (cantidad > 0)
);

/* Falta restriccion:
  Todo producto y componente participan en tiene*/

CREATE TABLE facturado (
        codigo_producto   INTEGER,
                CONSTRAINT facturado_fk_producto FOREIGN KEY (codigo_producto)
                  REFERENCES producto(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        codigo_componente INTEGER,
                CONSTRAINT facturado_fk_componente FOREIGN KEY
                  (codigo_componente) REFERENCES componente(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT facturado_pk PRIMARY KEY
          (codigo_producto, codigo_componente),
                CONSTRAINT facturado_clave_valida CHECK (
                  (codigo_producto IS NOT NULL AND codigo_componente IS NULL) OR
                  (codigo_componente IS NOT NULL AND codigo_producto IS NULL)),
        precio            DECIMAL (8, 2) NOT NULL,
                CONSTRAINT facturado_precio_valido CHECK (precio > 0)
);

CREATE TABLE pieza (
        codigo_componente INTEGER,
                CONSTRAINT pieza_fk_componente FOREIGN KEY (codigo_componente)
                  REFERENCES componente(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        codigo_materia    INTEGER,
                CONSTRAINT pieza_fk_materia FOREIGN KEY (codigo_materia)
                  REFERENCES materia_prima(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT pieza_pk PRIMARY KEY (codigo_componente, codigo_materia),
          CONSTRAINT pieza_clave_valida CHECK (
                  (codigo_componente IS NOT NULL AND codigo_materia IS NULL) OR
                  (codigo_materia IS NOT NULL AND codigo_componente IS NULL))
);

CREATE TABLE ente (
        codigo    UUID PRIMARY KEY,
        nombre    TEXT NOT NULL,
        contacto  TEXT NOT NULL,
        rif       TEXT NOT NULL,
                CONSTRAINT ente_rif_unico UNIQUE (rif),
        direccion TEXT NOT NULL
);

CREATE TABLE telefono (
        codigo UUID NOT NULL,
                CONSTRAINT telefono_fk FOREIGN KEY (codigo)
                  REFERENCES ente(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        valor  INTEGER NOT NULL,
        CONSTRAINT telefono_pk PRIMARY KEY (codigo, valor)
);

CREATE TABLE distribuidor (
        codigo UUID PRIMARY KEY,
                CONSTRAINT distribuidor_fk FOREIGN KEY (codigo)
                  REFERENCES ente (codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE proveedor (
        codigo      UUID PRIMARY KEY,
              CONSTRAINT proveedor_fk FOREIGN KEY (codigo)
                REFERENCES ente (codigo)
                ON DELETE CASCADE ON UPDATE CASCADE,
        email       TEXT NOT NULL,
        es_nacional BOOLEAN NOT NULL
);

/* Falta restriccion:
  Todo ente participa una y solo una vez en una de las relaciones
  distribuidor y proveedor*/

CREATE TABLE factura (
        numero              UUID PRIMARY KEY,
        credito             INTEGER DEFAULT NULL,
                CONSTRAINT factura_credito_valido CHECK (credito = NULL OR
                        credito = 15 OR credito = 30 OR
                        credito = 45 OR credito = 60),
        fecha_vencimiento   DATE NOT NULL,
        total               DECIMAL (8,2) NOT NULL,
                CONSTRAINT factura_total_valido CHECK (total > 0),
        impuesto            DECIMAL (2,1) NOT NULL,
                CONSTRAINT factura_impuesto_valido CHECK (impuesto >= 0),
        monto_global        DECIMAL (20,2),
                CONSTRAINT factura_monto_global_valido CHECK (
                        monto_global = (total + total * (impuesto / 100))),
        codigo_distribuidor UUID,
                CONSTRAINT factura_fk FOREIGN KEY (codigo_distribuidor)
                  REFERENCES distribuidor(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE
);

/* Falta restriccion:
  Todo distribuidor participa en la relacion factura*/

CREATE TABLE contiene (
        numero            UUID NOT NULL,
                CONSTRAINT contiene_fk_factura FOREIGN KEY (numero)
                  REFERENCES factura(numero)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        codigo_producto   INTEGER,
        codigo_componente INTEGER,
        CONSTRAINT contiene_fk_facturado FOREIGN KEY
          (codigo_producto, codigo_componente)
          REFERENCES facturado(codigo_producto, codigo_componente)
          ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT contiene_pk PRIMARY KEY
          (numero, codigo_producto, codigo_componente),
        cantidad          INTEGER NOT NULL,
                CONSTRAINT contiene_cantidad_valida CHECK (cantidad > 0)
);

/* Falta restriccion:
  Todo facturado participa en contiene*/

CREATE TABLE garantia (
        serial          UUID PRIMARY KEY,
        duracion        INTEGER NOT NULL,
                CONSTRAINT garantia_duracion_valida CHECK (duracion > 0),
        numero          UUID NOT NULL,
                  CONSTRAINT garantia_fk_factura FOREIGN KEY (numero)
                    REFERENCES factura(numero)
                    ON DELETE CASCADE ON UPDATE CASCADE,
        codigo_producto INTEGER NOT NULL,
                CONSTRAINT garantia_fk_producto FOREIGN KEY (codigo_producto)
                  REFERENCES producto(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE orden_de_ensamblaje (
        numero UUID PRIMARY KEY,
        fecha  DATE NOT NULL
);

CREATE TABLE produce (
        numero          UUID NOT NULL,
                CONSTRAINT produce_fk_orden_de_ensamblaje FOREIGN KEY (numero)
                  REFERENCES orden_de_ensamblaje(numero)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        codigo_producto INTEGER NOT NULL,
                CONSTRAINT produce_fk_producto FOREIGN KEY (codigo_producto)
                  REFERENCES producto(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT produce_pk PRIMARY KEY (numero, codigo_producto),
        cantidad        INTEGER NOT NULL,
                CONSTRAINT produce_cantidad_valida CHECK (cantidad > 0),
        aprobados       INTEGER NOT NULL,
                CONSTRAINT produce_aprobados_valida CHECK (aprobados > 0),
        CONSTRAINT cantidad_mayor_igual_aprovados CHECK (cantidad >= aprobados)
);

/* Falta restriccion:
  Toda orden de ensamblaje participa en produce*/

CREATE TABLE orden_de_compra (
        numero                 UUID PRIMARY KEY,
        fecha                  DATE NOT NULL,
        fecha_entrega_completa DATE DEFAULT NULL,
        codigo_proveedor       UUID NOT NULL,
                CONSTRAINT orden_de_compra_fk FOREIGN KEY (codigo_proveedor)
                  REFERENCES proveedor(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE posee (
        numero            UUID,
                CONSTRAINT posee_fk_orden_de_compra FOREIGN KEY (numero)
                  REFERENCES orden_de_compra(numero)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        codigo_componente INTEGER,
        codigo_materia    INTEGER,
        CONSTRAINT posee_fk_pieza FOREIGN KEY (codigo_componente,codigo_materia)
          REFERENCES pieza(codigo_componente,codigo_materia)
          ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT posee_pk PRIMARY KEY
          (numero,codigo_componente,codigo_materia),
        pedidos           INTEGER NOT NULL,
                CONSTRAINT posee_pedidos_valido CHECK (pedidos > 0),
        recibidos         INTEGER NOT NULL,
                CONSTRAINT posee_recibidos_valido CHECK (recibidos >= 0),
        CONSTRAINT posee_pedidos_mayor_igual_recibidos
          CHECK (pedidos>=recibidos)
);

/* Falta restriccion:
  Toda orden de compra y toda pieza participa en posee*/

CREATE TABLE orden_de_taller (
        numero            UUID PRIMARY KEY,
        fecha             DATE NOT NULL,
        codigo_componente INTEGER NOT NULL,
                CONSTRAINT orden_de_taller_fk FOREIGN KEY (codigo_componente)
                  REFERENCES componente(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        cantidad          INTEGER NOT NULL,
                CONSTRAINT orden_de_taller_cantidad_valida
                  CHECK (cantidad > 0),
        aprobados         INTEGER NOT NULL,
                CONSTRAINT orden_de_taller_aprobados_valido
                  CHECK (aprobados > 0),
        CONSTRAINT orden_de_taller_cantidad_mayor_igual_aprovados
          CHECK (cantidad >= aprobados)
);

CREATE TABLE requiere(
        numero         UUID NOT NULL,
                CONSTRAINT requiere_fk_orden_de_taller FOREIGN KEY (numero)
                  REFERENCES orden_de_taller(numero)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        codigo_materia INTEGER NOT NULL,
                CONSTRAINT requiere_fk_materia FOREIGN KEY (codigo_materia)
                  REFERENCES materia_prima(codigo)
                  ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT requiere_pk PRIMARY KEY (numero,codigo_materia),
        cantidad       INTEGER NOT NULL,
                CONSTRAINT requiere_cantidad_valida CHECK (cantidad > 0)
);

/* Falta restriccion:
  Toda orden de taller participa en requiere*/
