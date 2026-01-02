# SQL Project – Global Layoffs Analysis

## Overview
This project analyzes global layoffs data using SQL. The objective is to clean the dataset,
perform exploratory data analysis (EDA), and calculate layoff percentages to identify trends
across companies, industries, and time periods.

## Dataset
- **File:** layoffs.csv
- **Source:** Public layoffs dataset
- **Description:** Contains information on company layoffs including industry, country,
  total laid off, percentage laid off, and date.

## SQL Files Description

### 1. data_cleaning.sql
- Removes duplicates
- Handles null and missing values
- Standardizes column formats
- Prepares data for analysis

### 2. eda.sql
- Exploratory analysis of layoffs data
- Layoffs by company, industry, and country
- Time-based trends and patterns

### 3. percentage_layoff_analysis.sql
- Calculates percentage of workforce laid off
- Identifies companies with highest layoff impact
- Compares relative layoffs across industries

## Tools Used
- SQL (MySQL / PostgreSQL compatible)
- CSV dataset

## How to Use
1. Import `layoffs.csv` into your SQL database
2. Run `data_cleaning.sql` first
3. Execute `eda.sql` for exploration
4. Run `percentage_layoff_analysis.sql` for insights

## Key Insights
- Layoff trends vary significantly by industry
- Certain periods show spikes in layoffs
- Percentage-based analysis provides better comparison than raw counts
