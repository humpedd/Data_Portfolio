SELECT *
FROM CovidDeaths
ORDER BY 3,4;

-- Data to use
SELECT location, date, total_cases, new_cases,total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

-- Total Cases vs Total Deaths
-- Show percentage depending on the location
SELECT 
	location, date, 
	total_cases, total_deaths,
	(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))  * 100 as Death_Percentage
FROM CovidDeaths 
WHERE location like '%Philippines%'
ORDER BY 5 DESC;

-- Countries with Highest infection Rate
SELECT location, population,
	MAX(total_cases) AS Highest_Infection_Count,
	MAX((total_cases/population))* 100 AS Percent_Population_Infected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY Percent_Population_Infected DESC;

-- Highest Death Count Per Country
SELECT location,
	MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Highest Death Count Per Continent
SELECT location,
	MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Global Numbers
SELECT 
	date, 
	SUM(new_cases) AS Total_Cases,
	SUM(CAST(new_deaths as INT)) AS Total_Deaths,
	(SUM(CONVERT(FLOAT, new_cases))/SUM(NULLIF(CONVERT(FLOAT,new_deaths),0)))* 100 as Death_Percentage
FROM CovidDeaths 
GROUP BY date
ORDER BY Death_Percentage DESC;

-- Total Population vs Total Vaccinations
SELECT CD.continent,CD.location, CD.date, CD.population,
	CV.new_vaccinations,
	SUM(CONVERT(BIGINT, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, 
		CD.date) AS Rolling_People_Vaccinated
FROM CovidVaccinations as CV 
JOIN CovidDeaths AS CD 
	ON CV.location = CD.location
	and CV.date = CD.date
WHERE CD.continent IS NOT NULL 
ORDER BY 2,3;

-- Using CTE
With PopvsVac (Continent, Location ,Date, Population,New_Vaccinations, Rolling_People_Vaccinated)
AS(
	SELECT CD.continent,CD.location, CD.date, CD.population,
	CV.new_vaccinations,
	SUM(CONVERT(BIGINT, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, 
		CD.date) AS Rolling_People_Vaccinated
FROM CovidVaccinations as CV 
JOIN CovidDeaths AS CD 
	ON CV.location = CD.location
	and CV.date = CD.date
WHERE CD.continent IS NOT NULL 
);
SELECT *, (Rolling_People_Vaccinated/Population)*100
FROM PopvsVac;

-- Using Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated(
Continent NVARCHAR(255),
Location NVARCHAR(255),
date DATETIME,
Population numeric,
new_vaccinations numeric,
Rolling_People_Vaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent,CD.location, CD.date, CD.population,
	CV.new_vaccinations,
	SUM(CONVERT(BIGINT, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, 
		CD.date) AS Rolling_People_Vaccinated
FROM CovidVaccinations as CV 
JOIN CovidDeaths AS CD 
	ON CV.location = CD.location
	and CV.date = CD.date
WHERE CD.continent IS NOT NULL 
ORDER BY 2,3;

SELECT *, (Rolling_People_Vaccinated/Population)*100
FROM #PercentPopulationVaccinated;

-- Using Views
CREATE VIEW PercentPopulationVaccinated AS
	SELECT CD.continent,CD.location, CD.date, CD.population,
		CV.new_vaccinations,
		SUM(CONVERT(BIGINT, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, 
			CD.date) AS Rolling_People_Vaccinated
	FROM CovidVaccinations as CV 
	JOIN CovidDeaths AS CD 
		ON CV.location = CD.location
		and CV.date = CD.date
	WHERE CD.continent IS NOT NULL;