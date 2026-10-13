-- Delta Hub Operational Performance Analysis
-- Data: BTS Reporting Carrier On-Time Performance, Jan–Mar 2026

-- Q1: On-time rate by airline, ranked
WITH carrier_stats AS (
  SELECT CASE OP_UNIQUE_CARRIER
           WHEN 'UA' THEN 'United (UA)'
           WHEN 'DL' THEN 'Delta (DL)'
           WHEN 'MQ' THEN 'Envoy Air (MQ)'
           WHEN 'AS' THEN 'Alaska (AS)'
           WHEN 'WN' THEN 'Southwest (WN)'
           WHEN 'OO' THEN 'SkyWest (OO)'
           WHEN 'YX' THEN 'Republic (YX)'
           WHEN 'AA' THEN 'American (AA)'
           WHEN 'G4' THEN 'Allegiant (G4)'
           WHEN 'OH' THEN 'PSA Airlines (OH)'
           WHEN 'F9' THEN 'Frontier (F9)'
           WHEN 'B6' THEN 'JetBlue (B6)'
           WHEN 'NK' THEN 'Spirit (NK)'
           ELSE OP_UNIQUE_CARRIER
         END AS carrier,
         COUNT(*) AS flights,
         ROUND(100.0 * SUM(CASE WHEN ARR_DEL15 = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS on_time_pct
  FROM flights
  WHERE CANCELLED = 0 AND DIVERTED = 0
  GROUP BY OP_UNIQUE_CARRIER
)
SELECT RANK() OVER (ORDER BY on_time_pct DESC) AS on_time_rank,
       carrier,
       flights,
       on_time_pct,
       RANK() OVER (ORDER BY flights DESC) AS volume_rank
FROM carrier_stats
ORDER BY on_time_rank;

-- Q2: Delta on-time rate by hub
SELECT CASE ORIGIN
         WHEN 'ATL' THEN 'Atlanta (ATL)'
         WHEN 'DTW' THEN 'Detroit (DTW)'
         WHEN 'MSP' THEN 'Minneapolis-St. Paul (MSP)'
         WHEN 'SLC' THEN 'Salt Lake City (SLC)'
         WHEN 'JFK' THEN 'New York-JFK (JFK)'
         WHEN 'LGA' THEN 'New York-LaGuardia (LGA)'
         WHEN 'BOS' THEN 'Boston (BOS)'
         WHEN 'SEA' THEN 'Seattle (SEA)'
         WHEN 'LAX' THEN 'Los Angeles (LAX)'
       END AS hub,
       COUNT(*) AS flights,
       ROUND(100.0 * SUM(CASE WHEN ARR_DEL15 = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS on_time_pct
FROM flights
WHERE OP_UNIQUE_CARRIER = 'DL'
  AND CANCELLED = 0 AND DIVERTED = 0
  AND ORIGIN IN ('ATL','DTW','MSP','SLC','JFK','LGA','BOS','SEA','LAX')
GROUP BY ORIGIN
ORDER BY on_time_pct DESC;

-- Q3: Share of Delta delay minutes by cause
WITH totals AS (
  SELECT SUM(CARRIER_DELAY) AS carrier,
         SUM(WEATHER_DELAY) AS weather,
         SUM(NAS_DELAY) AS nas,
         SUM(SECURITY_DELAY) AS security,
         SUM(LATE_AIRCRAFT_DELAY) AS late_aircraft
  FROM flights
  WHERE OP_UNIQUE_CARRIER = 'DL' AND ARR_DEL15 = 1
)
SELECT ROUND(100.0 * carrier / (carrier + weather + nas + security + late_aircraft), 1) AS carrier_pct,
       ROUND(100.0 * weather / (carrier + weather + nas + security + late_aircraft), 1) AS weather_pct,
       ROUND(100.0 * nas / (carrier + weather + nas + security + late_aircraft), 1) AS nas_pct,
       ROUND(100.0 * security / (carrier + weather + nas + security + late_aircraft), 1) AS security_pct,
       ROUND(100.0 * late_aircraft / (carrier + weather + nas + security + late_aircraft), 1) AS late_aircraft_pct
FROM totals;

-- Q4: Delta ATL on-time rate by scheduled departure hour
SELECT CAST(CRS_DEP_TIME / 100 AS INTEGER) AS dep_hour,
       COUNT(*) AS flights,
       ROUND(100.0 * SUM(CASE WHEN ARR_DEL15 = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS on_time_pct,
       ROUND(100.0 * SUM(CASE WHEN LATE_AIRCRAFT_DELAY > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_aircraft_pct
FROM flights
WHERE OP_UNIQUE_CARRIER = 'DL' AND ORIGIN = 'ATL'
  AND CANCELLED = 0 AND DIVERTED = 0
GROUP BY dep_hour
ORDER BY dep_hour;

-- Q5: Delta cancellation rate by month and reason
-- (A = carrier, B = weather, C = NAS, D = security)
SELECT MONTH AS month,
       COUNT(*) AS flights,
       ROUND(100.0 * SUM(CANCELLED) / COUNT(*), 2) AS cancel_pct,
       SUM(CASE WHEN CANCELLATION_CODE = 'A' THEN 1 ELSE 0 END) AS carrier,
       SUM(CASE WHEN CANCELLATION_CODE = 'B' THEN 1 ELSE 0 END) AS weather,
       SUM(CASE WHEN CANCELLATION_CODE = 'C' THEN 1 ELSE 0 END) AS nas,
       SUM(CASE WHEN CANCELLATION_CODE = 'D' THEN 1 ELSE 0 END) AS security
FROM flights
WHERE OP_UNIQUE_CARRIER = 'DL'
GROUP BY month
ORDER BY month;
