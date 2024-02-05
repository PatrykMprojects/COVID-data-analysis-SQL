Select * 
From PortfolioProject..CovidDeaths$ 
order by 3,4

Select * 
From PortfolioProject..CovidVaccinations$ 
order by 3,4

-- Select data to use 

select Location, date, total_cases, new_cases, total_deaths, population 
From PortfolioProject..CovidDeaths$ 
order by 1,2



-- check type of the data in the table

SELECT 
    COLUMN_NAME, 
    DATA_TYPE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'CovidDeaths$';

-- change data type for integer to be able to perform calculations

Alter table CovidDeaths$ alter column total_deaths float
Alter table CovidDeaths$ alter column total_cases float

-- looking at total cases vs total deaths


select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$ 
order by 1,2

-- looking at total cases vs total deaths filtered by my country Poland
-- shows a likelihood of dying if you contract covid in your country

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$ 
where location like '%Poland%'
order by 1,2

-- looking at total cases vs population

select Location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths$ 
where location like '%Poland%'
order by 1,2

-- countries with highest infection rate compared to population


select Location,  max(total_cases) as HighestInfectionCount, Population, max((total_cases/Population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths$ 
--where location like '%Poland%'
group by Location, Population
order by PercentPopulationInfected desc

-- showing countries with the highest death count per population


select Location,  max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$ 
--where location like '%Poland%'
where continent is not null
group by Location
order by TotalDeathCount desc


-- lets sort it by continent
select continent,  max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$ 
--where location like '%Poland%'
where continent is not null
group by continent
order by TotalDeathCount desc

-- showing continents with the highest death count per population


select continent,  max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$ 
--where location like '%Poland%'
where continent is not null
group by continent
order by TotalDeathCount desc



---------------------------------------------

- joining tables
select * 
from CovidDeaths$ dea
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date

-- looking at population vs vaccination

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidDeaths$ dea
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Rolling count 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingCountPPLvaccinated
from CovidDeaths$ dea 
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Use CTE

with PopvsVac (continent, location, date,population, new_vaccinations, RollingCountPPLvaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingCountPPLvaccinated
from CovidDeaths$ dea 
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

select *, (RollingCountPPLvaccinated/population)* 100
from PopvsVac


-- Temp table

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255), 
date datetime, 
population numeric,
new_vaccinations numeric,
RollingCountPPLvaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingCountPPLvaccinated
from CovidDeaths$ dea 
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


select *, (RollingCountPPLvaccinated/population)* 100
from #PercentPopulationVaccinated


-- creating view to store data for later visualisations

create view PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingCountPPLvaccinated
from CovidDeaths$ dea 
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3