/*
COVID 19 EXPLORATION DATA ANALYSIS
Skills Covered: Aggregate Functions, 
                Convertion of Data Types,
                Joins,
	        Windows Functions, 
                Subqueries,
                CTEs, 
		Temp Tables 			    
*/

-- Overiew of the two data tables
select *
  from PortfolioProject..CovidDeaths

select *
  from PortfolioProject..CovidVaccinations


-- Select the main columns needed
select Location
     , continent
     , date
     , total_cases
     , new_cases
     , total_deaths
     , population
  from PortfolioProject..CovidDeaths
 order by 1, 2


-- Total Cases vs Population
-- Shows the percentage of population infected with Covid in specific locations
select Location
     , date
     , Population
     , total_cases
     , round((total_cases/population)*100, 1) as percent_of_population_infected
  from PortfolioProject..CovidDeaths
 where Location = 'Nigeria' 
   and continent is not null
 order by 1, 2


-- Total Cases vs Total Deaths
-- Shows the death rate of Covid patients in specific locations 
select Location
     , date
     , total_cases
     , total_deaths 
     , round((total_deaths/total_cases) * 100, 1) as death_likelihood
  from PortfolioProject..CovidDeaths
 where location = 'Nigeria' 
   and continent is not null
 order by 1, 2


-- Countries highest Infection count in descending order
select Location
     , population
     , MAX(total_cases) as highest_infection_count
  from PortfolioProject..CovidDeaths
 where continent is not null
 group by Location, population
 order by highest_infection_count desc


-- Countries highest Infection rate compared to their Population in descending order
select Location
     , Population
     , MAX(total_cases) as highest_infection_count
     , round(MAX((total_cases/population))*100, 1) as percent_of_population_infected
  from PortfolioProject..CovidDeaths
 where continent is not null
 group by Location, Population
 order by percent_of_population_infected desc


-- Countries highest Death count in descending order
select location
     , population
     , MAX(cast(Total_deaths as int)) as total_death_count
  from PortfolioProject..CovidDeaths
 where continent is not null
 group by location, population
 order by total_death_count desc


-- Countries highest Death rate compared to their Population in descending order
select location
     , population
     , MAX(cast(Total_deaths as int)) as total_death_count
     , round(MAX((cast(Total_deaths as int)/population))*100, 6) as percent_of_population_death
  from PortfolioProject..CovidDeaths
 where continent is not null
 group by location, population
 order by percent_of_population_death desc


-- Continent level
-- Continents Infection Rate compared to their total Population in descending order
select continent
     , sum(population) as total_population
     , sum(infection_count) as total_infection_count
     , round((sum(infection_count) / sum(population)) * 100, 2) as total_infection_rate
  from
       (select continent, location, population
             , max(total_cases) as infection_count
          from PortfolioProject..CovidDeaths
         where continent is not null
         group by continent, location, population
       ) as a
 group by continent
 order by total_infection_rate desc


-- Contintents Death rate compared to their total Population in descending order
select continent
     , sum(population) as total_population
     , sum(death_count) as total_death_count
     , round((sum(death_count) / sum(population)) * 100, 5) as total_death_rate
  from
       (select continent, location, population
             , max(cast(Total_deaths as int)) as death_count
          from PortfolioProject..CovidDeaths
         where continent is not null
         group by continent, location, population
       ) as a
 group by continent
 order by total_death_rate desc


-- Show worldwide records by date
select date
     , SUM(new_cases) as total_cases
     , SUM(cast(new_deaths as int)) as total_deaths 
     , round(SUM(cast(new_deaths as int)) / SUM(New_Cases) * 100, 1)  as death_rate
  from PortfolioProject..CovidDeaths
 where continent is not null
 group by date
 order by 1, 2


-- Total Population vs Vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  from PortfolioProject..CovidDeaths as dea
  join PortfolioProject..CovidVaccinations as vac
    on dea.location = vac.location
   and dea.date = vac.date
 where dea.continent is not null 
   and dea.location = 'united states'
 order by 2, 3


-- Show number of population that has recieved at least one Covid Vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
     , sum(convert(int, vac.new_vaccinations)) over (partition by dea.Location 
	                                                 order by dea.location, dea.Date) 
					         as total_vaccinated
  from PortfolioProject..CovidDeaths as dea
  join PortfolioProject..CovidVaccinations as vac
    on dea.location = vac.location
   and dea.date = vac.date
 where dea.continent is not null
   and dea.location = 'united states'
 order by 2, 3


-- Method 1
-- Using CTE to find the percentage of people vaccinated per population
with PopVsVac (Continent, Location, Date, Population, New_Vaccinations, total_vaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
     , sum(convert(int, vac.new_vaccinations)) over (partition by dea.Location 
	                                                 order by dea.location, dea.Date) 
					         as total_vaccinated
  from PortfolioProject..CovidDeaths as dea
  join PortfolioProject..CovidVaccinations as vac
    on dea.location = vac.location
   and dea.date = vac.date
 where dea.continent is not null
   --and dea.location = 'united states'
)
select *
     , round((total_vaccinated/Population) * 100, 1) as percentage_vaccinated
  from PopVsVac


-- Method 2
-- Using Temp Table to find the percentage of people vaccinated per population
  drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
total_vaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
     , sum(convert(int, vac.new_vaccinations)) over (partition by dea.Location 
	                                                 order by dea.location, dea.Date) 
                                                 as total_vaccinated
  from PortfolioProject..CovidDeaths as dea
  join PortfolioProject..CovidVaccinations as vac
    on dea.location = vac.location
   and dea.date = vac.date
 where dea.continent is not null
   --and dea.location = 'united states'

select * 
     , round((total_vaccinated/Population) * 100, 1) as percentage_vaccinated
  from #PercentPopulationVaccinated
