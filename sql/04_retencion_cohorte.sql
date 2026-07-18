-- =====================================================
-- Paso 4: Retención por cohorte mensual (D7, D14, D21, D28)
-- Objetivo: para cada cohorte de registro (YYYY-MM), calcular
-- el % de usuarios activos acumulados a cada hito de días.
-- Periodo de actividad: 2025-01-01 a 2025-08-31
-- =====================================================

WITH cohort AS (
    SELECT
        user_id,
        TO_CHAR(DATE_TRUNC('month', MIN(signup_date)), 'YYYY-MM') AS cohort_name
    FROM mercadolibre_retention
    GROUP BY user_id
),
activity AS (
    SELECT
        m.user_id,
        c.cohort_name,
        m.day_after_signup,
        m.active
    FROM mercadolibre_retention m
    LEFT JOIN cohort c ON m.user_id = c.user_id
    WHERE m.activity_date BETWEEN '2025-01-01' AND '2025-08-31'
)
SELECT
    cohort_name AS cohort,
    ROUND(
        COUNT(DISTINCT CASE WHEN day_after_signup >= 7 AND active = 1 THEN user_id END) * 100.0
        / NULLIF(COUNT(DISTINCT user_id), 0), 1) AS retention_d7_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN day_after_signup >= 14 AND active = 1 THEN user_id END) * 100.0
        / NULLIF(COUNT(DISTINCT user_id), 0), 1) AS retention_d14_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN day_after_signup >= 21 AND active = 1 THEN user_id END) * 100.0
        / NULLIF(COUNT(DISTINCT user_id), 0), 1) AS retention_d21_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN day_after_signup >= 28 AND active = 1 THEN user_id END) * 100.0
        / NULLIF(COUNT(DISTINCT user_id), 0), 1) AS retention_d28_pct
FROM activity
GROUP BY cohort_name
ORDER BY cohort_name;

-- =====================================================
-- ⚠️ PENDIENTE: retención por país (D7/D14/D21/D28)
-- El resultado existe en el Excel ("Retencion x Pais") pero
-- el query correspondiente (Task 1 y Task 2 del enunciado)
-- no quedó documentado. Reconstruir siguiendo la misma
-- lógica de CASE WHEN + agrupando por country en vez de cohort.
-- =====================================================
