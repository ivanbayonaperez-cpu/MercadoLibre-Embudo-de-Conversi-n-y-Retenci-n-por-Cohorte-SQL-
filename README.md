# 🛒 MercadoLibre: Embudo de Conversión y Retención por Cohorte (SQL)

Análisis de producto sobre el journey completo de compra en MercadoLibre — desde la primera visita hasta la compra — para identificar en qué etapa se pierden más usuarios y qué tan bien retiene la plataforma a los que se registran. Periodo analizado: enero–agosto 2025.

## 🎯 Contexto de negocio

El equipo de Crecimiento y Retención necesitaba responder dos preguntas: ¿en qué etapa del embudo se pierden más usuarios, y cómo varía eso por país?, y ¿qué tan bien retenemos a los usuarios a lo largo del tiempo, por cohorte y por país?

## 🧱 Esquema de datos

Dos tablas: `mercadolibre_funnel` (eventos de usuario: `first_visit`, `select_item`, `add_to_cart`, `begin_checkout`, `add_shipping_info`, `add_payment_info`, `purchase`) y `mercadolibre_retention` (actividad recurrente por usuario y período, con indicador binario `active` y `day_after_signup`).

## 🧮 Metodología SQL

Consultas disponibles en [`/sql`](./sql):

**1. Exploración del esquema** ([`01_exploracion.sql`](./sql/01_exploracion.sql)) — catálogo de eventos disponibles en el funnel.

**2. Embudo general** ([`02_embudo_general.sql`](./sql/02_embudo_general.sql)) — construcción del macro journey con 7 CTEs (uno por etapa) y cálculo de tasa de conversión de cada paso respecto a `first_visit`.

**3. Embudo por país** ([`03_embudo_por_pais.sql`](./sql/03_embudo_por_pais.sql)) — mismo embudo segmentado por `country`, para detectar variaciones regionales.

**4. Retención por cohorte** ([`04_retencion_cohorte.sql`](./sql/04_retencion_cohorte.sql)) — asignación de cohorte mensual (`YYYY-MM`) vía `DATE_TRUNC` + `TO_CHAR`, y cálculo de retención acumulada D7/D14/D21/D28 con `COUNT(DISTINCT CASE WHEN...)`.

```sql
-- Extracto: retención acumulada por cohorte mensual
ROUND(
    COUNT(DISTINCT CASE WHEN day_after_signup >= 7 AND active = 1 THEN user_id END) * 100.0
    / NULLIF(COUNT(DISTINCT user_id), 0), 1) AS retention_d7_pct
```

## 📊 Resultados — Embudo general

| Etapa | Conversión desde first_visit |
|---|---|
| Select Item | 76.9% |
| Add to Cart | 11.0% |
| Begin Checkout | 4.0% |
| Add Shipping Info | 2.4% |
| Add Payment Info | 2.1% |
| **Purchase** | **1.3%** |

## 🔎 Hallazgo principal — Punto de fuga (C→F→I)

**Finding:** La mayor caída del embudo ocurre entre `select_item` y `add_to_cart`: se pierde el **85.7% del tráfico** en un solo paso. Es, con diferencia, el cuello de botella más crítico de todo el proceso de compra.

**Implication:** Sugiere fricción de usabilidad, falta de incentivo, precios no competitivos o un problema técnico puntual en el flujo de "añadir al carrito" — no un problema de interés del usuario, ya que el 77% sí llega a considerar un producto.

## 🌎 Hallazgo por país — El "embudo roto"

**Finding:** Ecuador, Colombia y Paraguay cierran en **0% de conversión a compra**. Paraguay es el caso más crítico: su caída a cero ocurre desde `begin_checkout`, no al final del proceso. En contraste, Uruguay lidera con 4.55% de conversión final, y junto con Chile muestra la mejor atracción inicial a carrito (22.7% y 17.5%).

**Implication:** Es prioritario auditar el proceso de pago en Ecuador, Colombia y Paraguay — probablemente pasarelas de pago rotas, ausencia de métodos de pago locales o barreras logísticas país-específicas, no falta de intención de compra. En paralelo, estudiar qué hace bien Uruguay/Chile en la parte alta del embudo y evaluar si es replicable en mercados grandes de bajo desempeño como Brasil.

## 🔁 Hallazgo de retención — Anomalía de cohorte

**Finding:** Las cohortes de enero a julio 2025 son sumamente estables (D7 ≈ 86%, D14 ≈ 55%, D21 ≈ 25%, D28 ≈ 2.5%). La cohorte de agosto rompe el patrón: cae a 70.8% en D7 y a apenas 0.2% en D28.

**Implication:** Una caída de esa magnitud en un solo mes apunta a un evento puntual — cambio de producto, una fuente de adquisición de baja calidad, o un problema técnico crítico iniciado ese mes — más que a una tendencia orgánica de deterioro.

**A nivel país**, la retención inicial (D7) es consistente en toda la región (>79%), pero diverge en D28: Perú (3.2%) y México (3.1%) retienen mejor a largo plazo, mientras Colombia (1.6%) y Chile (1.7%) son los más volátiles — señal de que el *product-market fit* varía por mercado incluso cuando la atracción inicial no lo hace.

## 📁 Estructura del repositorio

```
mercadolibre-embudo-retencion/
├── README.md
├── sql/
│   ├── 01_exploracion.sql
│   ├── 02_embudo_general.sql
│   ├── 03_embudo_por_pais.sql
│   └── 04_retencion_cohorte.sql
├── visualizaciones/
│   ├── embudo_general.png
│   └── retencion_por_cohorte.png
└── MercadoLibre_Resumen_Ejecutivo.xlsx
```

## 🛠️ Herramientas

SQL (CTEs multietapa, `COUNT DISTINCT CASE WHEN`, `DATE_TRUNC`, `TO_CHAR`, `NULLIF` para división segura) — Excel/Google Sheets para consolidación y comunicación ejecutiva C→F→I.
