-- Motor utilizado: PostgreSQL 16
-- Base: Ventas_Tech_DB (creada en M3, sin modificaciones)

-- Consulta 1: Vista base del proyecto (INNER JOIN)
-- Propósito: una fila por venta con cliente, producto, categoría y ciudad, lista para usar como fuente principal en Power BI.
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre                          AS nombre_cliente,
    c.ciudad,
    p.nombre_producto,
    cat.nombre_categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario    AS total_venta
FROM ventas v
INNER JOIN clientes   c   ON c.id_cliente   = v.id_cliente
INNER JOIN productos  p   ON p.id_producto  = v.id_producto
INNER JOIN categorias cat ON cat.id_categoria = p.id_categoria
ORDER BY v.fecha_venta, v.id_venta;
-- Hallazgo: las 10 ventas aparecen con cliente, producto y categoría (el INNER JOIN no perdió ninguna fila).
-- Computación concentra el 76,8% de la facturación ($4.950 de $6.444), así que es la categoría para filtrar primero en el dashboard.


-- Consulta 2: Clientes sin ventas (LEFT JOIN)
-- Propósito: detectar clientes registrados que nunca compraron, para que CRM los contacte.
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v ON v.id_cliente = c.id_cliente
WHERE v.id_venta IS NULL;
-- Hallazgo: 0 clientes sin ventas, los 5 registrados compraron al menos una vez.
-- Para CRM no hay clientes que contactar por falta de primera compra; el esfuerzo se puede dedicar a fidelizar a los que ya compran.


-- Consulta 3: Productos sin ventas (LEFT JOIN)
-- Propósito: identificar artículos del catálogo sin movimiento, para que el área de producto decida si los reactiva o los da de baja.
SELECT
    p.nombre_producto,
    cat.nombre_categoria,
    p.precio
FROM productos p
LEFT JOIN categorias cat ON cat.id_categoria = p.id_categoria
LEFT JOIN ventas v       ON v.id_producto    = p.id_producto
WHERE v.id_venta IS NULL;
-- Hallazgo: 0 productos sin ventas, los 6 artículos del catálogo tuvieron movimiento en el período cargado.
-- Para producto no hay artículos para dar de baja por falta de rotación, al menos con estos datos.


-- Consulta 4: Consolidado por canal (UNION ALL)
-- Propósito: comparar cuánto aportan las ventas altas (total desde $500) frente a las bajas (menos de $500).
-- La columna canal no existe en las tablas: se crea como valor fijo en cada SELECT.
SELECT canal, SUM(total) AS total_canal
FROM (
    SELECT fecha_venta, cantidad * precio_unitario AS total, 'Venta alta' AS canal
    FROM ventas
    WHERE cantidad * precio_unitario >= 500
    UNION ALL
    SELECT fecha_venta, cantidad * precio_unitario AS total, 'Venta baja' AS canal
    FROM ventas
    WHERE cantidad * precio_unitario < 500
) AS consolidado
GROUP BY canal
ORDER BY total_canal DESC;
-- Hallazgo: solo 3 de las 10 ventas son altas (30%), pero aportan el 69,8% de lo facturado ($4.500 de $6.444).
-- Las 7 ventas bajas suman $1.944: el negocio depende de pocas operaciones grandes.
