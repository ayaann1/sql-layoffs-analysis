-- ===============================================
-- PERCENTAGE LAYOFFS ANALYSIS - Advanced Queries
-- ===============================================
-- This file focuses on analyzing percentage_laid_off to understand
-- the SEVERITY and IMPACT of layoffs relative to company size

-- First, let's understand our percentage_laid_off data
SELECT 
    COUNT(*) as total_records,
    COUNT(percentage_laid_off) as records_with_percentage,
    COUNT(total_laid_off) as records_with_total,
    COUNT(CASE WHEN percentage_laid_off IS NOT NULL AND total_laid_off IS NOT NULL THEN 1 END) as records_with_both
FROM layoffs_staging2;

-- ===============================================
-- 1. COMPLETE SHUTDOWNS (100% layoffs)
-- ===============================================
-- Companies that laid off their entire workforce
-- This indicates complete business closure or acquisition

SELECT 
    company,
    location,
    industry,
    total_laid_off,
    funds_raised_millions,
    `date`,
    stage
FROM layoffs_staging2
WHERE percentage_laid_off = 1.0  -- 100% layoffs
ORDER BY funds_raised_millions DESC;

-- Explanation: These are complete shutdowns. High funds_raised_millions 
-- with 100% layoffs often indicate failed startups or strategic closures.

-- ===============================================
-- 2. SEVERITY ANALYSIS BY RANGES
-- ===============================================
-- Categorize layoffs by severity levels

SELECT 
    CASE 
        WHEN percentage_laid_off = 1.0 THEN '100% - Complete Shutdown'
        WHEN percentage_laid_off >= 0.75 THEN '75-99% - Massive Cuts'
        WHEN percentage_laid_off >= 0.50 THEN '50-74% - Major Downsizing'
        WHEN percentage_laid_off >= 0.25 THEN '25-49% - Significant Cuts'
        WHEN percentage_laid_off >= 0.10 THEN '10-24% - Moderate Cuts'
        WHEN percentage_laid_off > 0 THEN '1-9% - Minor Adjustments'
        ELSE 'Unknown'
    END as severity_category,
    COUNT(*) as company_count,
    ROUND(AVG(percentage_laid_off * 100), 2) as avg_percentage,
    SUM(total_laid_off) as total_people_affected
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY 
    CASE 
        WHEN percentage_laid_off = 1.0 THEN '100% - Complete Shutdown'
        WHEN percentage_laid_off >= 0.75 THEN '75-99% - Massive Cuts'
        WHEN percentage_laid_off >= 0.50 THEN '50-74% - Major Downsizing'
        WHEN percentage_laid_off >= 0.25 THEN '25-49% - Significant Cuts'
        WHEN percentage_laid_off >= 0.10 THEN '10-24% - Moderate Cuts'
        WHEN percentage_laid_off > 0 THEN '1-9% - Minor Adjustments'
        ELSE 'Unknown'
    END
ORDER BY avg_percentage DESC;

-- Explanation: This shows the distribution of layoff severity. 
-- Complete shutdowns vs. partial workforce reductions tell different stories.

-- ===============================================
-- 3. INDUSTRY IMPACT SEVERITY
-- ===============================================
-- Which industries had the most severe layoffs (by percentage)

SELECT 
    industry,
    COUNT(*) as layoff_events,
    ROUND(AVG(percentage_laid_off * 100), 2) as avg_percentage_laid_off,
    ROUND(MIN(percentage_laid_off * 100), 2) as min_percentage,
    ROUND(MAX(percentage_laid_off * 100), 2) as max_percentage,
    COUNT(CASE WHEN percentage_laid_off = 1.0 THEN 1 END) as complete_shutdowns
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL 
    AND industry IS NOT NULL
GROUP BY industry
HAVING COUNT(*) >= 5  -- Only industries with at least 5 layoff events
ORDER BY avg_percentage_laid_off DESC;

-- Explanation: This reveals which industries face more severe layoffs.
-- High averages suggest industry-wide struggles, not just individual company issues.

-- ===============================================
-- 4. COMPANY SIZE vs LAYOFF SEVERITY
-- ===============================================
-- Relationship between company funding/stage and layoff severity

SELECT 
    stage,
    COUNT(*) as events,
    ROUND(AVG(percentage_laid_off * 100), 2) as avg_percentage_laid_off,
    ROUND(AVG(total_laid_off), 0) as avg_total_laid_off,
    COUNT(CASE WHEN percentage_laid_off = 1.0 THEN 1 END) as shutdowns,
    ROUND(AVG(funds_raised_millions), 2) as avg_funding
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL 
    AND stage IS NOT NULL
GROUP BY stage
ORDER BY avg_percentage_laid_off DESC;

-- Explanation: Early-stage companies might show higher percentages but lower totals.
-- Later-stage companies with high percentages indicate serious problems.

-- ===============================================
-- 5. TEMPORAL SEVERITY TRENDS
-- ===============================================
-- How layoff severity changed over time

SELECT 
    YEAR(`date`) as layoff_year,
    QUARTER(`date`) as quarter,
    COUNT(*) as layoff_events,
    ROUND(AVG(percentage_laid_off * 100), 2) as avg_severity_percentage,
    COUNT(CASE WHEN percentage_laid_off = 1.0 THEN 1 END) as complete_shutdowns,
    ROUND(COUNT(CASE WHEN percentage_laid_off = 1.0 THEN 1 END) * 100.0 / COUNT(*), 2) as shutdown_rate
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL 
    AND `date` IS NOT NULL
GROUP BY YEAR(`date`), QUARTER(`date`)
ORDER BY layoff_year, quarter;

-- Explanation: Shows if layoffs became more severe over time.
-- Rising shutdown rates might indicate economic deterioration.

-- ===============================================
-- 6. EFFICIENCY ANALYSIS: Impact per Dollar Raised
-- ===============================================
-- Companies with high funding but severe layoffs (failed investments)

SELECT 
    company,
    industry,
    funds_raised_millions,
    percentage_laid_off * 100 as percentage_laid_off,
    total_laid_off,
    `date`,
    -- Calculate "failure ratio" - higher values indicate worse ROI
    CASE 
        WHEN funds_raised_millions > 0 THEN 
            ROUND((percentage_laid_off * total_laid_off) / funds_raised_millions, 4)
        ELSE NULL 
    END as severity_per_million_raised
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL 
    AND funds_raised_millions > 0
    AND percentage_laid_off >= 0.5  -- Only severe layoffs
ORDER BY severity_per_million_raised DESC;

-- Explanation: Identifies companies that raised significant funding but still
-- had severe layoffs. High ratios suggest poor capital efficiency.

-- ===============================================
-- 7. COMPARATIVE ANALYSIS: Same Company, Different Severity
-- ===============================================
-- Companies with multiple layoff events - comparing severity levels

WITH company_layoffs AS (
    SELECT 
        company,
        COUNT(*) as layoff_events,
        MIN(percentage_laid_off * 100) as min_severity,
        MAX(percentage_laid_off * 100) as max_severity,
        AVG(percentage_laid_off * 100) as avg_severity,
        SUM(total_laid_off) as total_people_affected
    FROM layoffs_staging2
    WHERE percentage_laid_off IS NOT NULL
    GROUP BY company
    HAVING COUNT(*) > 1  -- Only companies with multiple layoffs
)
SELECT 
    company,
    layoff_events,
    ROUND(min_severity, 2) as min_severity_pct,
    ROUND(max_severity, 2) as max_severity_pct,
    ROUND(avg_severity, 2) as avg_severity_pct,
    ROUND(max_severity - min_severity, 2) as severity_range,
    total_people_affected
FROM company_layoffs
ORDER BY severity_range DESC;

-- Explanation: Shows companies with varying layoff severities.
-- Large ranges might indicate different business unit closures or escalating problems.

-- ===============================================
-- 8. GEOGRAPHICAL SEVERITY PATTERNS
-- ===============================================
-- Which locations experienced the most severe layoffs

SELECT 
    country,
    location,
    COUNT(*) as layoff_events,
    ROUND(AVG(percentage_laid_off * 100), 2) as avg_severity,
    SUM(total_laid_off) as total_people_affected,
    COUNT(CASE WHEN percentage_laid_off = 1.0 THEN 1 END) as shutdowns
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY country, location
HAVING COUNT(*) >= 3  -- Locations with at least 3 events
ORDER BY avg_severity DESC;

-- Explanation: Identifies geographic hotspots of severe layoffs.
-- Could indicate regional economic issues or industry concentrations.

-- ===============================================
-- 9. PREDICTIVE INDICATORS: Early WARNING SIGNS
-- ===============================================
-- Companies with initially small layoffs that later had major cuts

WITH layoff_progression AS (
    SELECT 
        company,
        `date`,
        percentage_laid_off,
        ROW_NUMBER() OVER (PARTITION BY company ORDER BY `date`) as layoff_sequence
    FROM layoffs_staging2
    WHERE percentage_laid_off IS NOT NULL 
        AND company IN (
            SELECT company 
            FROM layoffs_staging2 
            WHERE percentage_laid_off IS NOT NULL
            GROUP BY company 
            HAVING COUNT(*) > 1
        )
)
SELECT 
    l1.company,
    l1.`date` as first_layoff_date,
    l1.percentage_laid_off * 100 as first_layoff_pct,
    l2.`date` as subsequent_layoff_date,
    l2.percentage_laid_off * 100 as subsequent_layoff_pct,
    ROUND((l2.percentage_laid_off - l1.percentage_laid_off) * 100, 2) as severity_escalation
FROM layoff_progression l1
JOIN layoff_progression l2 ON l1.company = l2.company
WHERE l1.layoff_sequence = 1 
    AND l2.layoff_sequence = 2
    AND l2.percentage_laid_off > l1.percentage_laid_off
ORDER BY severity_escalation DESC;

-- Explanation: Shows companies where small initial layoffs preceded major cuts.
-- This pattern might help predict which companies are in deeper trouble.

-- ===============================================
-- 10. SUMMARY INSIGHTS QUERY
-- ===============================================
-- Overall summary combining percentage and absolute numbers

SELECT 
    'Dataset Overview' as metric_type,
    COUNT(*) as total_records,
    ROUND(AVG(percentage_laid_off * 100), 2) as overall_avg_percentage,
    COUNT(CASE WHEN percentage_laid_off = 1.0 THEN 1 END) as total_shutdowns,
    ROUND(COUNT(CASE WHEN percentage_laid_off = 1.0 THEN 1 END) * 100.0 / COUNT(*), 2) as shutdown_rate_pct
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL

UNION ALL

SELECT 
    'High Severity (>50%)' as metric_type,
    COUNT(*) as records,
    ROUND(AVG(percentage_laid_off * 100), 2) as avg_percentage,
    SUM(total_laid_off) as people_affected,
    NULL as shutdown_rate_pct
FROM layoffs_staging2
WHERE percentage_laid_off > 0.5

UNION ALL

SELECT 
    'Moderate Severity (10-50%)' as metric_type,
    COUNT(*) as records,
    ROUND(AVG(percentage_laid_off * 100), 2) as avg_percentage,
    SUM(total_laid_off) as people_affected,
    NULL as shutdown_rate_pct
FROM layoffs_staging2
WHERE percentage_laid_off BETWEEN 0.1 AND 0.5

UNION ALL

SELECT 
    'Low Severity (<10%)' as metric_type,
    COUNT(*) as records,
    ROUND(AVG(percentage_laid_off * 100), 2) as avg_percentage,
    SUM(total_laid_off) as people_affected,
    NULL as shutdown_rate_pct
FROM layoffs_staging2
WHERE percentage_laid_off > 0 AND percentage_laid_off < 0.1;

-- ===============================================
-- KEY INSIGHTS FROM PERCENTAGE ANALYSIS:
-- ===============================================
-- 1. Complete shutdowns (100%) reveal failed businesses vs operational cuts
-- 2. Industry severity averages show sector-wide vs company-specific issues  
-- 3. Funding vs severity ratios identify poor capital efficiency
-- 4. Geographic patterns reveal regional economic stress
-- 5. Multiple layoffs show escalating vs isolated problems
-- 6. Stage analysis reveals which company phases are most vulnerable
-- 7. Time trends show if market conditions worsened
-- ===============================================