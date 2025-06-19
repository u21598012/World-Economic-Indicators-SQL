--Country-Level Development Analysis
-- 1. How does GDP per capita vary by income group and region?
SELECT [region], AVG([gdp_per_capita_usd]) AS 'Average GDP per Capita (USD)'
FROM [master].[dbo].[WorldBank]
GROUP BY [region]

SELECT [incomegroup], AVG([gdp_per_capita_usd]) AS 'Average GDP per Capita (USD)'
FROM [master].[dbo].[WorldBank]
GROUP BY [incomegroup]

-- 2. Which countries had the highest and lowest life expectancy in 2018?
SELECT TOP (5)
    [country_name], AVG([life_expectancy_at_birth_years]) AS 'Average Life Expectancy'
FROM [master].[dbo].[WorldBank]
WHERE [year] = 2018
GROUP BY [country_name]
ORDER BY [Average Life Expectancy] DESC;

SELECT TOP (3)
    [country_name], AVG([life_expectancy_at_birth_years]) AS 'Average Life Expectancy'
FROM [master].[dbo].[WorldBank]
WHERE [year] = 2018
GROUP BY [country_name]
ORDER BY [Average Life Expectancy] ASC;

-- 3. Which countries had the highest HDI in the most recent year?
SELECT TOP (5)
    [country], AVG([hdi_2021]) AS 'Average HDI for 2021'
FROM [master].[dbo].[HDI]
GROUP BY [country]
ORDER BY 'Average HDI for 2021' DESC;

-- 4. What is the correlation between electricity consumption and GDP per capita by country?
SELECT TOP (5) [country_name],
    (COUNT(*) * SUM(electric_power_consumption_kwh_per_capita * gdp_per_capita_usd) - SUM(electric_power_consumption_kwh_per_capita) * SUM(gdp_per_capita_usd)) / 
    (SQRT(COUNT(*) * SUM(POWER(electric_power_consumption_kwh_per_capita, 2)) - POWER(SUM(electric_power_consumption_kwh_per_capita), 2)) * 
     SQRT(COUNT(*) * SUM(POWER(gdp_per_capita_usd, 2)) - POWER(SUM(gdp_per_capita_usd), 2))) AS correlation_coefficient
FROM [master].[dbo].[WorldBank]
WHERE electric_power_consumption_kwh_per_capita IS NOT NULL AND gdp_per_capita_usd IS NOT NULL
GROUP BY [country_name]
ORDER BY 'correlation_coefficient' DESC;

SELECT TOP (5) [country_name],
    (COUNT(*) * SUM(electric_power_consumption_kwh_per_capita * gdp_per_capita_usd) - SUM(electric_power_consumption_kwh_per_capita) * SUM(gdp_per_capita_usd)) / 
    (SQRT(COUNT(*) * SUM(POWER(electric_power_consumption_kwh_per_capita, 2)) - POWER(SUM(electric_power_consumption_kwh_per_capita), 2)) * 
     SQRT(COUNT(*) * SUM(POWER(gdp_per_capita_usd, 2)) - POWER(SUM(gdp_per_capita_usd), 2))) AS correlation_coefficient
FROM [master].[dbo].[WorldBank]
WHERE electric_power_consumption_kwh_per_capita IS NOT NULL AND gdp_per_capita_usd IS NOT NULL
GROUP BY [country_name]
ORDER BY 'correlation_coefficient' ASC;

-- Trend Over Time
-- 1. Which regions have shown the greatest improvement in life expectancy over the last 3 years?
WITH CountryChange AS (
    SELECT 
        region,
        country,
        le_2019,
        le_2021,
        ((le_2021 - le_2019) / le_2019) * 100 AS pct_change
    FROM [master].[dbo].[HDI]
    WHERE le_2019 IS NOT NULL AND le_2021 IS NOT NULL
)
SELECT 
    region,
    AVG(pct_change) AS avg_life_expectancy_pct_change
FROM CountryChange
GROUP BY region
ORDER BY avg_life_expectancy_pct_change DESC;


-- 2. How has the internet usage changed globally and by income group from year to year?
-- SELECT [year], AVG([individuals_using_the_internet_of_population]) 
-- FROM [master].[dbo].[WorldBank]
-- WHERE [year] > 2015 AND [individuals_using_the_internet_of_population] IS NOT NULL
-- GROUP BY [year]
-- ORDER BY [year];

SELECT [incomegroup], [year], AVG([individuals_using_the_internet_of_population]) AS 'Average Internet Usage (%)', LAG(AVG([individuals_using_the_internet_of_population]), 1)  
OVER (PARTITION BY [incomegroup] ORDER BY [year]) AS 'Previous Year Usage (%)',
    AVG([individuals_using_the_internet_of_population]) - 
        LAG(AVG([individuals_using_the_internet_of_population]), 1) 
        OVER (PARTITION BY [incomegroup] ORDER BY [year]) AS 'Year-over-Year Change (%)'
FROM
    [master].[dbo].[WorldBank]
WHERE 
    [year] > 2015 AND
    [individuals_using_the_internet_of_population] IS NOT NULL
GROUP BY 
    [incomegroup], [year]
ORDER BY 
    [incomegroup], [year];

-- 3. Which countries have seen the largest changes in HDI rank between 2020 and 2021?
SELECT TOP (5) [country], ((AVG([hdi_2021]) - AVG([hdi_2020]))/AVG([hdi_2020]))*100 AS "Change in HDI from 2020 to 2021"
FROM [master].[dbo].[HDI]
GROUP BY [country]
ORDER BY "Change in HDI from 2020 to 2021" DESC;

-- 4. Which country had the greatest increase in GDP per capita over the last 10 years?
WITH GDP_Trends AS (
    SELECT country_name, year, gdp_per_capita_usd,
           LAG(gdp_per_capita_usd, 10) OVER (PARTITION BY country_name ORDER BY year) AS gdp_10_years_ago
    FROM [master].[dbo].[WorldBank]
    WHERE year >= 2007
)
SELECT TOP(5) country_name,
       ((gdp_per_capita_usd - gdp_10_years_ago) / gdp_10_years_ago) * 100 AS pct_change
FROM GDP_Trends
WHERE gdp_10_years_ago IS NOT NULL
ORDER BY pct_change DESC;


-- Health & Demographics

-- 1. What is the relationship between infant mortality rate and GDP per capita?
SELECT TOP(5)
    [country_name],
    CASE 
        WHEN (COUNT(*) * SUM(POWER(infant_mortality_rate_per_1000_live_births, 2)) - POWER(SUM(infant_mortality_rate_per_1000_live_births), 2)) <= 0 THEN NULL
        WHEN (COUNT(*) * SUM(POWER(gdp_per_capita_usd, 2)) - POWER(SUM(gdp_per_capita_usd), 2)) <= 0 THEN NULL
        ELSE
            (COUNT(*) * SUM(infant_mortality_rate_per_1000_live_births * gdp_per_capita_usd) - SUM(infant_mortality_rate_per_1000_live_births) * SUM(gdp_per_capita_usd)) / 
            (SQRT(COUNT(*) * SUM(POWER(infant_mortality_rate_per_1000_live_births, 2)) - POWER(SUM(infant_mortality_rate_per_1000_live_births), 2)) * 
             SQRT(COUNT(*) * SUM(POWER(gdp_per_capita_usd, 2)) - POWER(SUM(gdp_per_capita_usd), 2)))
    END AS correlation_coefficient
FROM [master].[dbo].[WorldBank]
WHERE infant_mortality_rate_per_1000_live_births IS NOT NULL AND gdp_per_capita_usd IS NOT NULL
GROUP BY [country_name]
HAVING COUNT(*) > 1
ORDER BY [correlation_coefficient] DESC; 

SELECT TOP(26)
    [country_name],
    CASE 
        WHEN (COUNT(*) * SUM(POWER(infant_mortality_rate_per_1000_live_births, 2)) - POWER(SUM(infant_mortality_rate_per_1000_live_births), 2)) <= 0 THEN NULL
        WHEN (COUNT(*) * SUM(POWER(gdp_per_capita_usd, 2)) - POWER(SUM(gdp_per_capita_usd), 2)) <= 0 THEN NULL
        ELSE
            (COUNT(*) * SUM(infant_mortality_rate_per_1000_live_births * gdp_per_capita_usd) - SUM(infant_mortality_rate_per_1000_live_births) * SUM(gdp_per_capita_usd)) / 
            (SQRT(COUNT(*) * SUM(POWER(infant_mortality_rate_per_1000_live_births, 2)) - POWER(SUM(infant_mortality_rate_per_1000_live_births), 2)) * 
             SQRT(COUNT(*) * SUM(POWER(gdp_per_capita_usd, 2)) - POWER(SUM(gdp_per_capita_usd), 2)))
    END AS correlation_coefficient
FROM [master].[dbo].[WorldBank]
WHERE infant_mortality_rate_per_1000_live_births IS NOT NULL AND gdp_per_capita_usd IS NOT NULL
GROUP BY [country_name]
HAVING COUNT(*) > 1
ORDER BY [correlation_coefficient] ASC; 

-- 2. How do birth and death rates differ across regions and income groups?
SELECT TOP(5) [country_name], AVG([birth_rate_crude_per_1000_people]) AS "Average Birth Rate", AVG([death_rate_crude_per_1000_people]) AS "Average Death Rate", AVG([birth_rate_crude_per_1000_people]) -AVG([death_rate_crude_per_1000_people]) AS 'Difference' FROM [master].[dbo].[WorldBank] GROUP BY [country_name] ORDER BY [Difference] DESC;

SELECT TOP(5) [country_name], AVG([birth_rate_crude_per_1000_people]) AS "Average Birth Rate", AVG([death_rate_crude_per_1000_people]) AS "Average Death Rate", AVG([birth_rate_crude_per_1000_people]) -AVG([death_rate_crude_per_1000_people]) AS 'Difference' FROM [master].[dbo].[WorldBank] GROUP BY [country_name] ORDER BY [Difference] ASC;

-- Sustainability and Inequality

-- 3. Which countries have the highest CO₂ emissions per capita for 2021?
WITH prod AS(
SELECT 
    h.[country],
    w.[country_name],
    h.[iso3],
    w.[country_code],
    h.[region] AS hdi_region,
    w.[region] AS wb_region,
    h.[hdi_2019],
    h.[hdi_2020],
    h.[hdi_2021],
    w.[gdp_per_capita_usd],
    h.[co2_prod_2021]
FROM 
    [master].[dbo].[HDI] h
INNER JOIN 
    [master].[dbo].[WorldBank] w
    ON h.[iso3] = w.[country_code]
WHERE 
    h.[iso3] IS NOT NULL 
    AND w.[country_code] IS NOT NULL)

SELECT TOP (5) [country],AVG([co2_prod_2021]) AS "Average CO2 Production for 2021" FROM [prod] GROUP BY [country] ORDER BY [Average CO2 Production for 2021] DESC; 

-- Composite Metrics & Rankings

-- 1. Create a custom "Wellbeing Index" using normalized life expectancy, GDP per capita, and education. How do countries rank?
WITH CountryData AS (
    SELECT DISTINCT
        h.country,
        h.le_2021 AS life_expectancy,
        h.eys_2021 AS expected_years_schooling,  
        h.mys_2021 AS mean_years_schooling,      
        w.gdp_per_capita_usd
    FROM 
        [master].[dbo].[HDI] h
    LEFT JOIN 
        [master].[dbo].[WorldBank] w
        ON h.iso3 = w.country_code
    WHERE 
        h.le_2021 IS NOT NULL AND 
        h.eys_2021 IS NOT NULL AND
        h.mys_2021 IS NOT NULL AND
        w.gdp_per_capita_usd IS NOT NULL
),

MetricRanges AS (
    SELECT
        MIN(life_expectancy) AS min_le,
        MAX(life_expectancy) AS max_le,
        MIN(expected_years_schooling) AS min_eys,
        MAX(expected_years_schooling) AS max_eys,
        MIN(mean_years_schooling) AS min_mys,
        MAX(mean_years_schooling) AS max_mys,
        MIN(gdp_per_capita_usd) AS min_gdp,
        MAX(gdp_per_capita_usd) AS max_gdp
    FROM CountryData
)

SELECT TOP 100
    cd.country,
    (cd.life_expectancy - mr.min_le) / (mr.max_le - mr.min_le) AS norm_life_expectancy,
    (cd.expected_years_schooling - mr.min_eys) / (mr.max_eys - mr.min_eys) AS norm_expected_schooling,
    (cd.mean_years_schooling - mr.min_mys) / (mr.max_mys - mr.min_mys) AS norm_mean_schooling,
    (LOG(cd.gdp_per_capita_usd) - LOG(mr.min_gdp)) / (LOG(mr.max_gdp) - LOG(mr.min_gdp)) AS norm_gdp_log,
    0.25 * (cd.life_expectancy - mr.min_le) / (mr.max_le - mr.min_le) +
    0.25 * (cd.expected_years_schooling - mr.min_eys) / (mr.max_eys - mr.min_eys) +
    0.25 * (cd.mean_years_schooling - mr.min_mys) / (mr.max_mys - mr.min_mys) +
    0.25 * (LOG(cd.gdp_per_capita_usd) - LOG(mr.min_gdp)) / (LOG(mr.max_gdp) - LOG(mr.min_gdp))
    AS wellbeing_index
FROM 
    CountryData cd
CROSS JOIN
    MetricRanges mr
ORDER BY 
    wellbeing_index DESC;

-- 2. Rank countries by average HDI over the last 3 years.
SELECT TOP (10) [country], AVG([hdi_2019]) AS 'Average HDI 2019', AVG([hdi_2020]) AS 'Average HDI 2020', AVG([hdi_2021]) AS 'Average HDI 2021',((AVG([hdi_2019]) + AVG([hdi_2020]) + AVG([hdi_2021]))/3) AS "Average HDI 2019 - 2021" FROM [master].[dbo].[HDI] GROUP BY [country] ORDER BY [Average HDI 2019 - 2021] DESC;

-- 3. Which countries are consistently performing poorly in both economic and human development indicators?
WITH prod AS (
    SELECT 
        h.[country],
        w.[country_name],
        h.[iso3],
        w.[country_code],
        h.[region] AS hdi_region,
        w.[region] AS wb_region,
        h.[hdi_rank_2021],
        h.[hdi_2021],
        w.[gdp_per_capita_usd],
        h.[co2_prod_2021]
    FROM 
        [master].[dbo].[HDI] h
    INNER JOIN 
        [master].[dbo].[WorldBank] w
        ON h.[iso3] = w.[country_code]
    WHERE 
        h.[iso3] IS NOT NULL 
        AND w.[country_code] IS NOT NULL
        AND h.[hdi_2021] IS NOT NULL
        AND w.[gdp_per_capita_usd] IS NOT NULL
),
MetricRanges AS (
    SELECT
        MIN(gdp_per_capita_usd) AS min_gdp,
        MAX(gdp_per_capita_usd) AS max_gdp
    FROM prod
),
ScoredCountries AS (
    SELECT
        p.*,
        (p.[gdp_per_capita_usd] - mr.min_gdp) / (mr.max_gdp - mr.min_gdp) AS gdp_score
    FROM 
        prod p
    CROSS JOIN
        MetricRanges mr
)
SELECT TOP 15
    country_name,
    AVG(hdi_rank_2021) AS avg_hdi_rank,
    AVG(gdp_per_capita_usd) AS avg_gdp,
    AVG(gdp_score) AS avg_gdp_score,
    AVG(hdi_2021) AS avg_hdi
FROM 
    ScoredCountries
GROUP BY 
    country_name
ORDER BY 
    avg_hdi_rank DESC, avg_gdp_score ASC;
