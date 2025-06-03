function GetIndividual(bee)
    return bee.individual
end

function IsBee(bee)
    return GetIndividual(bee) ~= nil
end

function GetActiveTrait(bee)
    return GetIndividual(bee).active
end

function GetInactiveTrait(bee)
    return GetIndividual(bee).inactive
end

function GetTrait(bee, active)
    if active then
        return GetActiveTrait(bee)
    else
        return GetInactiveTrait(bee)
    end
end

function GetSpecies(bee, active)
    return GetTrait(bee, active).species
end

function GetName(bee, active)
    return GetSpecies(bee, active).binomialName
end

function GetSpeed(bee, active)
    return GetTrait(bee, active).speed
end

function GetLifespan(bee, active)
    return GetTrait(bee, active).lifespan
end

function IsPure(bee, sel)
    return sel(bee, true) == sel(bee, false)
end
