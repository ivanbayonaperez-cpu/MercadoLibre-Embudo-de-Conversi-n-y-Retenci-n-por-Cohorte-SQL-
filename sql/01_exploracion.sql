-- =====================================================
-- Paso 1: Exploración del esquema
-- Objetivo: entender la estructura de las tablas de eventos
-- (funnel) y de retención antes de construir el análisis.
-- =====================================================

SELECT * FROM mercadolibre_funnel LIMIT 5;

SELECT * FROM mercadolibre_retention LIMIT 5;

-- Catálogo de eventos disponibles en el funnel
SELECT DISTINCT event_name
FROM mercadolibre_funnel
WHERE user_id IS NOT NULL
ORDER BY event_name;
