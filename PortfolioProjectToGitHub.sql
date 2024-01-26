--SELECT * FROM PortfolioProject..Covid_vaccinations
--ORDER BY 3,4

SELECT * FROM PortfolioProject..Covid_deaths

SELECT Location, date, total_cases, new_cases, total_deaths, population FROM PortfolioProject..Covid_deaths
ORDER BY 1,2

-- Looking at TOTAL CASES v TOTAL DEATHS
-- Shows Likelihood of Dying from COVID in your respective country


SELECT Location, Date, total_cases, total_deaths, CONVERT(FLOAT, total_deaths) / CONVERT(FLOAT, total_cases) *100 AS percent_death FROM PortfolioProject..Covid_deaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL AND Location LIKE '%states%'
ORDER BY 1,2

-- Looking at total cases v the population
-- Shows % of population that has COVID in your country

SELECT Location, Date, total_cases, population, CONVERT(Float, total_cases) / CONVERT(FLOAT, Population)*100 AS PercentInfected FROM PortfolioProject..Covid_deaths
WHERE total_cases IS NOT NULL AND population IS NOT NULL AND Location LIKE '%states%' 
ORDER BY 1,2

--Looking at countries with highest infection rates compared to population

SELECT Location, population, MAX(total_cases) AS TotalCaseCount, MAX(CONVERT(Float, total_cases) / CONVERT(FLOAT, Population)*100) AS PercentInfected FROM PortfolioProject..Covid_deaths
WHERE continent IS NOT NULL
GROUP BY Location, Population 
ORDER BY PercentInfected DESC

--Showing Countries with the highest death count total not compared to population

SELECT Location, MAX(CONVERT(Float, total_deaths)) AS TotalDeathCount FROM PortfolioProject..Covid_deaths
WHERE continent IS NOT NULL
GROUP BY Location, Population 
ORDER BY TotalDeathCount DESC


--Showing highest deaths per Continent. Question, what is the difference between these two and which is correct?

SELECT continent, MAX(CONVERT(Float, total_deaths)) AS TotalDeathCount FROM PortfolioProject..Covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


SELECT location, MAX(CONVERT(Float, total_deaths)) AS TotalDeathCount FROM PortfolioProject..Covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

   
--GLOBAL NUMBERS
--Query by date
SELECT date, SUM(new_cases) AS Total_cases, SUM(CONVERT(Float, new_deaths)) as total_deaths, SUM(CONVERT(Float, new_deaths)) / SUM(new_cases) * 100 AS death_percentage FROM PortfolioProject..Covid_deaths
WHERE continent IS NOT NULL AND new_cases IS NOT NULL AND total_deaths < Total_cases
GROUP BY date
ORDER BY 1,2
--Query Global total
SELECT SUM(new_cases) AS Total_cases, SUM(CONVERT(Float, new_deaths)) as total_deaths, SUM(CONVERT(Float, new_deaths)) / SUM(new_cases) * 100 AS death_percentage FROM PortfolioProject..Covid_deaths
WHERE continent IS NOT NULL 
ORDER BY 1,2


--Joining tables covid_deaths and covid_vaccinations on date and location
--dea and vac are given as nicknames so that the entire name does not need to be typed each time

--Looking at total population vs Vaccinations using the ORDER Partition by subclause via new_vaccination rather than using total_vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(Float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) AS Total_Vaccinations_Per_day
FROM PortfolioProject..Covid_deaths dea
JOIN PortfolioProject..Covid_vaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE vac.new_vaccinations IS NOT NULL AND dea.continent IS NOT NULL


--CTE Method. Making a table 'PopVsVac' to set New data as a variable to query

WITH PopVsVac (Continent, location, date, population, new_vaccinations, Total_Vaccinations_Per_day) AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(Float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) AS Total_Vaccinations_Per_day
FROM PortfolioProject..Covid_deaths dea
JOIN PortfolioProject..Covid_vaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE vac.new_vaccinations IS NOT NULL AND dea.continent IS NOT NULL
)
SELECT *, Total_Vaccinations_Per_day / population * 100 AS Percent_Vaccinated_Per_day FROM PopVsVac

--TEMP TABLE METHOD. Creating a Temporary table and Inserting Values into to Create final column of %vaccPerDay

--DROP TABLE if exists #PercentPopulationVaccinated
-- use above line if any changes are to be made to the Temp Table.
CREATE TABLE #PercentPopulationVaccinated
(Continent varchar(255),
location varchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Total_Vaccinations_Per_day numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(Float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) AS Total_Vaccinations_Per_day
FROM PortfolioProject..Covid_deaths dea
JOIN PortfolioProject..Covid_vaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE vac.new_vaccinations IS NOT NULL AND dea.continent IS NOT NULL

SELECT *, Total_Vaccinations_Per_day / population * 100 AS Percent_Vaccinated_Per_day FROM #PercentPopulationVaccinated

--Creating View to store data later for visualizations. must remove order by in order to create a view. will create a permanent table that can be called on
Create view PopVsVacTable as
WITH PopVsVac (Continent, location, date, population, new_vaccinations, Total_Vaccinations_Per_day) AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(Float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) AS Total_Vaccinations_Per_day
FROM PortfolioProject..Covid_deaths dea
JOIN PortfolioProject..Covid_vaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE vac.new_vaccinations IS NOT NULL AND dea.continent IS NOT NULL
)
SELECT *, Total_Vaccinations_Per_day / population * 100 AS Percent_Vaccinated_Per_day FROM PopVsVac

Create View TotalDeaths as
SELECT Location, MAX(CONVERT(Float, total_deaths)) AS TotalDeathCount FROM PortfolioProject..Covid_deaths
WHERE continent IS NOT NULL
GROUP BY Location, Population 
--ORDER BY TotalDeathCount DESC


