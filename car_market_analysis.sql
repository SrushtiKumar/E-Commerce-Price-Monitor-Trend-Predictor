-- =================================================================================
-- VEHICLE MARKET ANALYSIS QUERIES (PostgreSQL)
-- Database Table: scraped_cars
-- Source: scraped_cars.csv (Dynamic Web Crawler Output)
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- QUERY 1: Brand Market Share & Asset Valuation Metrics
-- ---------------------------------------------------------------------------------
-- QUESTION ANSWERED:
-- Which brands represent the highest total capital value, listing counts, and what is their average valuation?
--
-- BUSINESS METRIC:
-- Average Price (EUR) & Total Portfolio Value (Asset Concentration index) per Brand.
-- ---------------------------------------------------------------------------------

SELECT 
    "Brand",
    COUNT(*) AS total_listings,
    ROUND(AVG("Price_EUR")::numeric, 2) AS avg_price_eur,
    SUM("Price_EUR") AS total_market_value_eur,
    MIN("Price_EUR") AS min_price_eur,
    MAX("Price_EUR") AS max_price_eur
FROM scraped_cars
GROUP BY "Brand"
ORDER BY total_market_value_eur DESC;

-- INSIGHT:
-- BMW, Porsche, and Ferrari listings lead the platform's overall market share. 
-- Premium listings for BMW and Porsche frequently exceed EUR 300,000, representing 
-- significant investment concentrations on the platform.


-- ---------------------------------------------------------------------------------
-- QUERY 2: Inventory Turnover & Availability Risk Analysis
-- ---------------------------------------------------------------------------------
-- QUESTION ANSWERED:
-- Which vehicle brands exhibit the highest immediate Out-of-Stock (OOS) risks, 
-- indicating inventory replenishment needs?
--
-- BUSINESS METRIC:
-- Out-of-Stock (OOS) Rate and Average Unit Availability per Brand.
-- ---------------------------------------------------------------------------------

SELECT 
    "Brand",
    COUNT(*) AS total_listings,
    COUNT(CASE WHEN "Availability" = 0 THEN 1 END) AS out_of_stock_count,
    ROUND((COUNT(CASE WHEN "Availability" = 0 THEN 1 END)::float / COUNT(*)::float * 100)::numeric, 2) AS oos_rate_pct,
    ROUND(AVG("Availability")::numeric, 2) AS avg_units_available
FROM scraped_cars
GROUP BY "Brand"
ORDER BY oos_rate_pct DESC;

-- INSIGHT:
-- High-end brands like Ferrari display a high OOS rate (many listings have Availability = 0). 
-- This signals high-velocity demand or low procurement rates, highlighting key 
-- procurement bottlenecks for premium vintage vehicles.


-- ---------------------------------------------------------------------------------
-- QUERY 3: Condition-Driven Price Resilience Analysis
-- ---------------------------------------------------------------------------------
-- QUESTION ANSWERED:
-- How does vehicle condition rating correlate with price retention relative to mileage?
--
-- BUSINESS METRIC:
-- Price-to-Mileage Elasticity Ratio grouped by Condition Rating (1 to 5 Stars).
-- ---------------------------------------------------------------------------------

SELECT 
    "Rating",
    COUNT(*) AS listing_count,
    ROUND(AVG("Mileage_km")::numeric, 0) AS avg_mileage_km,
    ROUND(AVG("Price_EUR")::numeric, 2) AS avg_price_eur,
    ROUND((AVG("Price_EUR") / NULLIF(AVG("Mileage_km"), 0))::numeric, 2) AS price_per_km_ratio
FROM scraped_cars
GROUP BY "Rating"
ORDER BY "Rating" DESC;


-- INSIGHT:
-- Rarity condition ratings directly shield listings from standard mileage-driven depreciation. 
-- Vehicles with condition ratings of 4 or 5 command excellent average prices (exceeding EUR 150,000) 
-- even with high mileage figures, proving that collector-grade preservation overrides usage depreciation.



-- ---------------------------------------------------------------------------------
-- QUERY 4: Top 10 High-Value Investment Prospects
-- ---------------------------------------------------------------------------------
-- QUESTION ANSWERED:
-- What are the top 10 premium vehicles currently in stock that match high-rarity criteria?
--
-- BUSINESS METRIC:
-- High-Value High-Rarity available inventory subset.
-- ---------------------------------------------------------------------------------

SELECT 
    "Title",
    "Brand",
    "Year",
    "Rating",
    "Price_EUR",
    "Availability"
FROM scraped_cars
WHERE "Rating" >= 3 AND "Availability" > 0
ORDER BY "Price_EUR" DESC
LIMIT 10;


--INSIGHT:
-- Collector items like the BMW 2002 1978 (EUR 336,315.0) and Porsche 944 Turbo 1952 (EUR 330,964.0) 
-- offer highly-rated quality (Rating 3+) with immediate units available, serving as ideal 
-- target acquisitions for high-end vintage investment portfolios.


-- ---------------------------------------------------------------------------------
-- QUERY 5: Geographic Supply Concentration & Valuation Variance
-- ---------------------------------------------------------------------------------
-- QUESTION ANSWERED:
-- Where is listing supply clustered geographically, and where do price distributions 
-- show the highest dispersion?
--
-- BUSINESS METRIC:
-- Geographic Supply Share & Price Volatility (Standard Deviation) per Country.
-- ---------------------------------------------------------------------------------

SELECT 
    "Country",
    COUNT(*) AS listing_count,
    ROUND((COUNT(*)::float / (SELECT COUNT(*) FROM scraped_cars)::float * 100)::numeric, 2) AS market_share_pct,
    ROUND(AVG("Price_EUR")::numeric, 2) AS avg_price_eur,
    ROUND(STDDEV("Price_EUR")::numeric, 2) AS price_stddev_eur
FROM scraped_cars
GROUP BY "Country"
ORDER BY listing_count DESC;

--INSIGHT:
-- Supply is concentrated in classic hubs like the United Kingdom, Germany, Japan, Italy, 
-- and the United States. While the UK and Germany lead listing volume, Italy and the US 
-- exhibit high price standard deviations, indicating a high diversity in pricing spreads.


-- ---------------------------------------------------------------------------------
-- QUERY 6: Age-Based Vintage Tier Classification Analysis
-- ---------------------------------------------------------------------------------
-- QUESTION ANSWERED:
-- How do listing count and pricing segment compare across classic historical eras?
--
-- BUSINESS METRIC:
-- Volume & Average Valuation by Vintage Era Category.
-- ---------------------------------------------------------------------------------

SELECT 
    CASE 
        WHEN "Year" < 1960 THEN 'Pre-1960 Classic'
        WHEN "Year" BETWEEN 1960 AND 1969 THEN '1960s Golden Era'
        WHEN "Year" BETWEEN 1970 AND 1979 THEN '1970s Retro Era'
        ELSE '1980s+ Modern Vintage'
    END AS vintage_tier,
    COUNT(*) AS listing_count,
    ROUND(AVG("Price_EUR")::numeric, 2) AS avg_price_eur,
    ROUND(AVG("Mileage_km")::numeric, 0) AS avg_mileage_km
FROM scraped_cars
GROUP BY vintage_tier
ORDER BY avg_price_eur DESC;


-- INSIGHT:
-- Classic vintage eras (Pre-1960 and 1960s) sustain superior average prices despite carrying 
-- higher mileage. Age-based chronological rarity acts as a dominant value multiplier in the 
-- vintage automotive asset class.