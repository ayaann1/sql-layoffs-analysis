select * 
from layoffs_staging2;

select max(total_laid_off),max(percentage_laid_off)
from layoffs_staging2;

select * 
from layoffs_staging2
where percentage_laid_off=1
order by funds_raised_millions DESC;

select company,sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 DESC;

select min(`date`),max(`date`)
from layoffs_staging2;

select industry,sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 DESC;

select country,sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 DESC;

select year(`date`),
sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 2  DESC;

select stage,sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 DESC;

select substring(`date`,1,7) as `month` ,sum(total_laid_off)
from layoffs_staging2
where substring(`date`,1,7) IS NOT NULL
group by `month`
order by 1;

WITH rolling_total as
(
select substring(`date`,1,7) as `month` ,sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`,1,7) IS NOT NULL
group by `month`
order by 1
)
SELECT `month`,total_off,sum(total_off) over(order by `month`)
from rolling_total;

select company,sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 DESC;

select company,YEAR(`date`),sum(total_laid_off)
from layoffs_staging2
group by company,YEAR(`date`)
order by 3 desc;

with company_year(compnay,years,total_laid_off) as
(
select company,YEAR(`date`),sum(total_laid_off)
from layoffs_staging2
group by company,YEAR(`date`)
),company_year_rank as
(
select *,DENSE_RANK() OVER(PARTITION BY years order by total_laid_off desc)as ranking
from company_year
where years is not null
)
select *
from company_year_rank
where ranking <=5;

SELECT 
    company,
    location,percentage_laid_off,
    industry,
    total_laid_off,
    funds_raised_millions,
    `date`,
    stage
FROM layoffs_staging2
WHERE percentage_laid_off = 1.0  -- 100% layoffs
ORDER BY funds_raised_millions DESC;

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

