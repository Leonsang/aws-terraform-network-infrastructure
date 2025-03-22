# Diccionario de Datos

## Tabla: transactions

Tabla principal que contiene las transacciones financieras.

| Campo | Tipo | Descripción | Ejemplo |
|-------|------|-------------|---------|
| transaction_id | VARCHAR | Identificador único de la transacción | "T123456" |
| timestamp | TIMESTAMP | Fecha y hora de la transacción | "2024-03-22 10:30:00" |
| amount | DECIMAL | Monto de la transacción | 150.50 |
| merchant_id | VARCHAR | Identificador del comerciante | "M789" |
| customer_id | VARCHAR | Identificador del cliente | "C456" |
| is_fraud | BOOLEAN | Indica si la transacción es fraudulenta | true |
| category | VARCHAR | Categoría de la transacción | "online_shopping" |
| description | VARCHAR | Descripción de la transacción | "Purchase at Amazon" |

## Tabla: merchants

Tabla que contiene información de los comerciantes.

| Campo | Tipo | Descripción | Ejemplo |
|-------|------|-------------|---------|
| merchant_id | VARCHAR | Identificador único del comerciante | "M789" |
| name | VARCHAR | Nombre del comerciante | "Amazon" |
| category | VARCHAR | Categoría principal del comerciante | "ecommerce" |
| risk_level | VARCHAR | Nivel de riesgo del comerciante | "high" |
| registration_date | DATE | Fecha de registro del comerciante | "2024-01-01" |

## Vista: fraud_metrics

Vista que proporciona métricas agregadas de fraude.

| Campo | Tipo | Descripción | Ejemplo |
|-------|------|-------------|---------|
| date | DATE | Fecha de las métricas | "2024-03-22" |
| total_transactions | BIGINT | Total de transacciones | 1000 |
| fraud_count | BIGINT | Número de fraudes | 5 |
| fraud_rate | DECIMAL | Tasa de fraude | 0.005 |
| avg_amount | DECIMAL | Monto promedio | 150.50 |
| fraud_amount | DECIMAL | Monto total de fraudes | 750.25 |

## Relaciones

- `transactions.merchant_id` → `merchants.merchant_id`
- `fraud_metrics` se calcula a partir de `transactions`

## Particionamiento

- Las tablas están particionadas por fecha (timestamp)
- Formato de archivo: Parquet
- Compresión: Snappy

## Actualización

- Las transacciones se actualizan en tiempo real
- Las métricas se calculan cada hora
- Los datos históricos se mantienen por 90 días
