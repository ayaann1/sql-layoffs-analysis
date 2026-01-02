select *
from layoffs;

#step 1 - Duplicate
#step 2 - standardize the data
#step 3 - null values or blank values
#step 4 - remove column that are not usefull

create table layoffs_staging
like layoffs;

insert into layoffs_staging
select *
from layoffs;

select * 
from layoffs_staging;

select *,
ROW_NUMBER() OVER(partition by company,industry,total_laid_off,'date')as row_num
from layoffs_staging;

with duplicate_cte as
(
select *,
ROW_NUMBER() OVER(partition by company,location,industry,total_laid_off,percentage_laid_off,'date',
stage,country,funds_raised_millions)as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;

select *
from layoffs_staging
where company ='casper';


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into layoffs_staging2
select *,
ROW_NUMBER() OVER(partition by company,location,industry,total_laid_off,percentage_laid_off,'date',
stage,country,funds_raised_millions)as row_num
from layoffs_staging;

DELETE
from layoffs_staging2
where row_num >1;



select * 
from layoffs_staging2;


#Standardizing

select company, trim(company)
from layoffs_staging2;

select *
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
Where industry like 'Crypto%';


select distinct industry
from layoffs_staging2;

select distinct location
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = 'United States'
Where country like 'United States%';

select distinct country
from layoffs_staging2
order by 1;

select `date`
from layoffs_staging2;

update layoffs_staging2
set date = str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

select *
from layoffs_staging2;

#step 3 null or blank values
select *
from layoffs_staging2
where total_laid_off IS NULL
AND percentage_laid_off IS NULL;

update layoffs_staging2
set industry = null
where industry ='';

select *
from layoffs_staging2
where industry IS NULL
OR industry = '';

select *
from layoffs_staging2
where company = 'Airbnb';

select t1.industry,t2.industry
from layoffs_staging2 t1
JOIN layoffs_staging2 t2
	on t1.company=t2.company
    AND t1.location = t2.location
where (t1.industry IS NULL OR t1.industry='')
AND t2.industry IS NOT NULL;



update layoffs_staging2 t1
JOIN layoffs_staging2 t2
	on t1.company=t2.company
SET t1.industry = t2.industry
where (t1.industry IS NULL OR t1.industry='')
AND t2.industry IS NOT NULL;

select *
from layoffs_staging2;


DELETE
from layoffs_staging2
where total_laid_off IS NULL
AND percentage_laid_off IS NULL;


select *
from layoffs_staging2;

alter table layoffs_staging2
drop column row_num;