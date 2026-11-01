-- Motor utilizado: PostgreSQL 16
-- Base: Ventas_Tech_DB (creada en M3)
-- Nota de sintaxis: en PostgreSQL MONTH(fecha) se escribe EXTRACT(MONTH FROM fecha)
-- y TOP 5 se escribe con LIMIT 5 al final de la consulta.

-- =========================================================
-- CONSULTA 1 - Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes
-- =========================================================
SELECT
    EXTRACT(MONTH FROM fecha_venta)               AS mes,
    SUM(cantidad * precio_unitario)               AS total_facturado,
    COUNT(*)                                      AS cantidad_pedidos,
    ROUND(AVG(cantidad * precio_unitario), 2)     AS ticket_promedio
FROM ventas
GROUP BY EXTRACT(MONTH FROM fecha_venta)
ORDER BY mes;

-- =========================================================
-- CONSULTA 2 - Ranking de productos (top 5 por facturación)
-- =========================================================
SELECT
    id_producto,
    SUM(cantidad)                      AS unidades_vendidas,
    SUM(cantidad * precio_unitario)    AS total_generado
FROM ventas
GROUP BY id_producto
ORDER BY total_generado DESC
LIMIT 5;

-- =========================================================
-- CONSULTA 3 - Clientes recurrentes (más de un pedido)
-- =========================================================
SELECT
    id_cliente,
    COUNT(*)                           AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)    AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;

-- =========================================================
-- CONSULTA 4 - Productos por encima o por debajo del promedio
-- El promedio se calcula sobre los totales por producto,
-- no sobre las filas de ventas.
-- =========================================================
WITH totales_por_producto AS (
    SELECT
        id_producto,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY id_producto
)
SELECT
    id_producto,
    total_facturado,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM totales_por_producto)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END AS posicion_vs_promedio
FROM totales_por_producto
ORDER BY total_facturado DESC;

-- =========================================================
-- HALLAZGOS
-- =========================================================
-- 1. El producto 1 concentra el 55,9% de la facturación del mes ($3.600 de $6.444),
--    y junto con el producto 3 son los únicos dos que quedan por encima del
--    promedio por producto ($1.074).
-- 2. El producto 2 es el que más unidades vende (13 de 29, un 44,8% del volumen),
--    pero apenas aporta el 5,6% de lo facturado: mucho movimiento, poca plata.
-- 3. Los clientes 1 y 5 suman el 73,6% del total gastado ($4.740 de $6.444).
--    Los 5 clientes compraron dos veces, así que todos son recurrentes, pero el
--    gasto está muy concentrado en esos dos.
