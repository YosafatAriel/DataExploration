-- THIS DATA EXPLORATION IS BASED ON EXCEL FILE FROM => https://ourworldindata.org/covid-deaths

SELECT Location, date, total_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1, 2

-- LOOK FOR TOTAL CASES VS TOTAL DEATHS
-- BASED ON COUNTRY
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths$
WHERE LOCATION = 'Indonesia'
ORDER BY 1, 2 DESC 

-- looking for percentage of total cases vs population in a country
SELECT Location, date, population, total_cases, total_deaths, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths$
WHERE LOCATION = 'Indonesia'
ORDER BY 1, 2 DESC 

-- looking for country with most highest infected count versus population
SELECT Location, population, MAX(total_cases)AS HighestInfectedCount, 
MAX((total_cases/population)*100) AS PercentPopulationInfected
FROM CovidDeaths$
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC 

-- Looking for country with the highest death count.
SELECT Location, MAX(CAST(total_deaths AS INT))AS HighestDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY HighestDeathCount DESC

-- GLOBAL NUMBER of total cases and total deaths with death percentage
SELECT SUM(new_cases) AS TotalCases, 
SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100
AS DeathPercentage
FROM CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- JOIN CovidDeaths Table with CovidVaccinations
SELECT *
FROM CovidDeaths$ as Dea
JOIN CovidVaccinations$ as Vac
	on Dea.location = Vac.location
	AND Dea.date = Vac.date

-- LOOK FOR TOTAL POPULATION VERSUS VACCINATION 
SELECT Dea.continent, Dea.location, Dea.date, Vac.new_vaccinations
FROM CovidDeaths$ as Dea
JOIN CovidVaccinations$ as Vac
	on Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL
ORDER BY 2, 3

-- Showing continents with highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT))AS TotalDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Showing location with highest death count per population
SELECT location, MAX(CAST(total_deaths AS INT))AS TotalDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-->> BREAKING THINGS DOWN BY CONTINENTS <<--
-- looking for total death count in continents
SELECT continent, MAX(CAST(total_deaths AS INT))AS TotalDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- total death globally by continent with dates
SELECT date, 
SUM(new_cases) AS TotalCases, 
SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100
AS DeathPercentage
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2 DESC

-- GLOBAL NUMBER of total cases and total deaths with death percentage
SELECT --date, 
SUM(new_cases) AS TotalCases, 
SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100
AS DeathPercentage
FROM CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2 DESC

-- looking at Total Population VS Vaccination (USING CTE)
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS (
	SELECT cd.continent, cd.location, cd.date, 
	cd.population, cv.new_vaccinations,
	SUM(CAST (cv.new_vaccinations as int)) OVER (PARTITION BY cd.location ORDER BY cv.location, cv.date) AS RollingPeopleVaccinated
	FROM CovidDeaths$ AS cd
	JOIN CovidVaccinations$ AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL
	--ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS PeopleVaccinatedPercentage
FROM PopVsVac

-- looking at Total Population VS Vaccination (USING TEMPORARY TABLE)
DROP TABLE if exists #PercentPeopleVaccinated 
CREATE TABLE #PercentPeopleVaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPeopleVaccinated
SELECT cd.continent, cd.location, cd.date, 
cd.population, cv.new_vaccinations,
SUM(CAST (cv.new_vaccinations as int)) OVER (PARTITION BY cd.location ORDER BY cv.location, cv.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ AS cd
JOIN CovidVaccinations$ AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
--WHERE cd.continent IS NOT NULL
--ORDER BY 2,3
SELECT *, (RollingPeopleVaccinated/population)*100 AS PeopleVaccinatedPercentage
FROM #PercentPeopleVaccinated

-- Creating views store for later data visualization
CREATE VIEW PercentPeopleVaccinated AS
SELECT cd.continent, cd.location, cd.date, 
cd.population, cv.new_vaccinations,
SUM(CAST (cv.new_vaccinations as int)) OVER (PARTITION BY cd.location ORDER BY cv.location, cv.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ AS cd
JOIN CovidVaccinations$ AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

-- calling view table
SELECT *
FROM PercentPeopleVaccinated
