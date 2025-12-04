
-- Select data we need 
SELECT location, date, total_cases, new_cases, total_deaths,population
FROM Coviddeathsnew$
ORDER BY 1,2


-- DATA EXPLORATION

-- Total cases Vs Total deaths 
-- Shows Likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases,0))*100 AS DeathsPercentage
FROM Coviddeathsnew$
-- WHERE LOCATION LIKE '%STATE%'
ORDER BY 1,2

-- Total cases vs Populations
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percentpopulationinfected
FROM Coviddeathsnew$
-- WHERE LOCATION LIKE '%STATE%'
ORDER BY 1,2


-- Countries with highest infection rate compared to population 

SELECT location, population, MAX(total_cases) as HighestinfectionCount, MAX((total_cases/population))*100 AS percentpopulationinfected
FROM Coviddeathsnew$
-- WHERE LOCATION LIKE '%STATE%'
GROUP BY location, population
ORDER BY percentpopulationinfected desc

 
-- Countries with Highest Death Count per population
SELECT location, MAX(cast(total_deaths as int)) as TotaldeathCount
FROM Coviddeathsnew$
-- WHERE LOCATION LIKE '%STATE%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotaldeathCount desc


-- Continent with Highest Death Count 
SELECT continent, MAX(cast(total_deaths as int)) as TotaldeathCount
FROM Coviddeathsnew$
-- WHERE LOCATION LIKE '%STATE%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotaldeathCount desc



-- GLOBAL NUMBERS

SELECT SUM(new_cases) as Total_cases,  SUM(new_deaths) as total_deaths,
(SUM(CAST(new_deaths as int))/nullif(SUM(new_cases),0))*100 as deathspercentage
FROM Coviddeathsnew$
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2 



-- TOTAL POPULATION VS VACCINATION

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location  order by dea.location, dea.date ) as RollingPeoplevaccinated,
FROM Coviddeathsnew$ dea
JOIN Covidvaccination$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


/*
We need to calculaate those vaccinated base on the rollingtotal
*/

-- USE CTE 

WITH popvsvac
-- (continent, location, date, population, new_vaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location  order by dea.location, dea.date ) as RollingPeoplevaccinated
FROM Coviddeathsnew$ dea
JOIN Covidvaccination$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (RollingPeoplevaccinated/population)*100
FROM popvsvac


-- USE TEMP TABLE 
DROP TABLE IF EXISTS  #percentPopulationVaccinated
CREATE TABLE #percentPopulationVaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #percentPopulationVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location  order by dea.location, dea.date ) as RollingPeoplevaccinated
FROM Coviddeathsnew$ dea
JOIN Covidvaccination$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL
 ORDER BY 2,3

SELECT *, (RollingPeoplevaccinated/population)*100
FROM #percentPopulationVaccinated




-- Creating view to store data for later visualization 


CREATE VIEW percentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location  order by dea.location, dea.date ) as RollingPeoplevaccinated
FROM Coviddeathsnew$ dea
JOIN Covidvaccination$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--  ORDER BY 2,3


SELECT *
FROM percentPopulationVaccinated

