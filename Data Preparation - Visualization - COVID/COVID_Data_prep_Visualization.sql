/*

Cleaning Data using PostgreSQL RDBMS and pgAdmin 4
and getting the tables ready for visualization in Tableau

In this project I will be creating a proper table in a database in pgAdmin 4
that can receive the data from the COVID Dataset found on 
https://github.com/danielryvero/Portfolio-Projects-Data-Analytics/tree/main/Data%20Preparation%20-%20Visualization/Raw%20Datasets

I will be commenting my code throughout the way
*/


/*in order to achieve a successful importation of the data into pgAdmin 4, 
columns with number values had to be set to NUMERIC data type because of the 
data format at the source*/

--creation of "table death_info"
DROP TABLE IF EXISTS death_info
CREATE TABLE death_info (
    continent VARCHAR (50),
    location VARCHAR (50),
    date_col date,
    total_cases NUMERIC,
    new_cases NUMERIC,
    total_deaths NUMERIC,
    new_deaths NUMERIC,
    total_tests NUMERIC,
    new_tests NUMERIC,
    tests_per_case NUMERIC,
    population NUMERIC
);
SELECT * FROM death_info;



--create "table vaccination_info"

CREATE TABLE vaccination_info (
    continent VARCHAR (50),
    location VARCHAR (50),
    date_col date,
    total_cases NUMERIC,
    new_cases NUMERIC,
    total_tests NUMERIC,
    new_tests NUMERIC,
    tests_per_case NUMERIC,
	total_vaccinations NUMERIC,
	people_vaccinated NUMERIC,
	people_fully_vaccinated NUMERIC,
	total_boosters NUMERIC,
	new_vaccinations NUMERIC,
	median_age NUMERIC,
    population NUMERIC
);



--working with death_info, getting some insights of location, date, deaths, population

SELECT 
	location,
	date_col,
	new_cases,
	total_deaths,
	population 
FROM death_info
ORDER BY location, date_col;



--global numbers of pandemia: total cases, total deaths, death percentage

SELECT 
	MAX(date_col) AS Date,
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths,
	(SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
FROM death_info
WHERE continent IS NOT NULL; --continent NULL comprehends 'World', 'European Union', etc



--likelihood of dying in Spain ordered by rate and date

SELECT 
	location,
	date_col,
	total_cases,
	total_deaths,
	ROUND((total_deaths/total_cases)*100,3) AS percentage_deaths
FROM death_info
WHERE total_deaths IS NOT NULL
	AND total_cases IS NOT NULL
	AND location LIKE '%Spain'
ORDER BY percentage_deaths DESC, date_col;



--rate of infection of the population in Spain order infection and date

SELECT 
	location,
	date_col,
	population,
	total_cases,
	(total_cases/population)*100 AS percentage_infected
FROM death_info
WHERE total_cases IS NOT NULL
	AND location LIKE '%Spain'
ORDER BY percentage_infected DESC, date_col;



--countries with highest infection rate by population in the world, 
--ordered by percentage_infected

SELECT 
	location,
	population,
	continent,
	MAX(total_cases),
	MAX((total_cases/population))*100 AS percentage_infected
FROM death_info
WHERE total_cases IS NOT NULL
	AND continent IS NOT NULL
GROUP BY location, population, continent
ORDER BY percentage_infected DESC;



-- countries with highest death rate ordered by total_deaths, 
-- filtering by continent, location

SELECT 
	location,
	continent,
	MAX(total_deaths) AS total_death_count
FROM death_info
WHERE total_deaths IS NOT NULL
	AND total_cases IS NOT NULL
	AND continent IS NOT NULL
GROUP BY location, continent
ORDER BY total_death_count DESC;




--maximum number of infected people in Spain and percentage infected 
--till today ordered by death_percentage

SELECT 
	location,
	date_col,
	population,
	MAX(total_cases) as highest_infection_count,
	MAX((total_cases/population))*100 AS percentage_infected
FROM death_info
WHERE location LIKE '%Spain'
	AND total_cases IS NOT NULL
GROUP BY location, population, date_col
ORDER BY percentage_infected DESC;




/*working with vaccination_info, getting some insights of location, date, vaccination, 
boosters, median age, population
looking at total population vs vaccinations*/

SELECT 
	dea.location,
	dea.continent,
	dea.date_col,
	vac.population,
	vac.new_vaccinations 
FROM death_info dea
JOIN vaccination_info vac
	ON dea.date_col=vac.date_col
	AND dea.location=vac.location
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
ORDER BY dea.location ,vac.new_vaccinations;



--parsing through increment of vaccinations over date over location

SELECT 
	dea.location,
	dea.continent,
	dea.date_col,
	vac.population, 
	vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY 
		dea.location ORDER BY dea.location, dea.date_col) AS rolling_vaccinations
FROM death_info dea
JOIN vaccination_info vac
	ON dea.date_col = vac.date_col
	AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
	AND vac.new_vaccinations IS NOT NULL;




--CTE of people vaccinated versus population

WITH Population_vs_Vaccination (
	Location, 
	Continent, 
	Date, 
	Population, 
	New_Vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT 
	dea.location, 
	dea.continent, 
	dea.date_col, 
	vac.population, 
	vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY 
		dea.location ORDER BY dea.location, dea.date_col) AS rolling_vaccinations
FROM death_info dea
JOIN vaccination_info vac
	ON dea.date_col=vac.date_col
	AND dea.location=vac.location
WHERE dea.continent IS NOT NULL
	AND vac.new_vaccinations IS NOT NULL
)

SELECT *,
	(Rolling_People_Vaccinated/Population)*100 AS percentage_vaccination
FROM Population_vs_Vaccination
ORDER BY location, date;



--creating a temp table to filter previous information, instead of a CTE

DROP TABLE IF EXISTS PopulationVaccination;
CREATE TEMP TABLE PopulationVaccination 
	(Location VARCHAR (255), 
	 Continent VARCHAR (255),
	 Date_col DATE, 
	 Population NUMERIC, 
	 New_Vaccinations NUMERIC, 
	 Rolling_People_Vaccinated NUMERIC);

INSERT INTO PopulationVaccination 
SELECT 
	dea.location, 
	dea.continent, 
	dea.date_col, 
	vac.population, 
	vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY 
		dea.location ORDER BY dea.location, dea.date_col) AS rolling_vaccinations
FROM death_info dea
JOIN vaccination_info vac
	ON dea.date_col=vac.date_col
	AND dea.location=vac.location
WHERE dea.continent IS NOT NULL
	AND vac.new_vaccinations IS NOT NULL;


SELECT *,
	(Rolling_People_Vaccinated/Population)*100 AS percentage_vaccination
FROM PopulationVaccination 
ORDER BY location, date;



/*creating some views for future visualization
view of PercentPopulationVaccinated*/


DROP VIEW IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.location,
	dea.continent,
	dea.date_col,
	vac.population, 
	vac.new_vaccinations, 
	(vac.new_vaccinations/vac.population)*100 AS Percent_Population_Vaccinated
FROM death_info dea
JOIN vaccination_info vac
	ON dea.date_col=vac.date_col
	AND dea.location=vac.location
WHERE dea.continent IS NOT NULL
	AND vac.new_vaccinations IS NOT NULL
ORDER BY dea.location ,vac.new_vaccinations;



--view of Maximum_Infection


DROP VIEW IF EXISTS Maximum_Infection;
CREATE VIEW Maximum_Infection AS
SELECT 
	location,
	date_col,
	population,
	MAX(total_cases) as highest_infection_count, 
	MAX((total_cases/population))*100 AS percentage_infected
FROM death_info
WHERE location LIKE '%Spain'
	AND total_cases IS NOT NULL
GROUP BY location, population, date_col
ORDER BY percentage_infected DESC;



--deaths by continents sorted by amount of deaths

SELECT 
	location AS Continent,
	SUM (new_deaths) AS TotalDeathCount
FROM death_info
WHERE continent IS NULL
	AND location NOT LIKE '%income'
	AND location NOT LIKE '%Asia'
	AND location NOT LIKE '%Europe'
	AND location NOT LIKE '%World'
GROUP BY location
ORDER BY TotalDeathCount DESC;

