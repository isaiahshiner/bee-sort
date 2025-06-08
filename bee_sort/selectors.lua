function GetRank(item)
    return item.rank
end

function GetBee(item)
    return item.bee
end

function GetIndividual(item)
    return GetBee(item).individual
end

function IsBee(item)
    return GetIndividual(item) ~= nil
end

function GetActiveTrait(item)
    return GetIndividual(item).active
end

function GetInactiveTrait(item)
    return GetIndividual(item).inactive
end

function GetTrait(item, active)
    if active then
        return GetActiveTrait(item)
    else
        return GetInactiveTrait(item)
    end
end

function GetSpecies(item, active)
    return GetTrait(item, active).species
end

function GetName(item, active)
    return GetSpecies(item, active).binomialName
end

function GetSpeed(item, active)
    return GetTrait(item, active).speed
end

function GetLifespan(item, active)
    return GetTrait(item, active).lifespan
end

function IsPure(item, sel)
    return sel(item, true) == sel(item, false)
end

function IsFullyPure(item)
    return table.isEqual(GetTrait(item, true), GetTrait(item, false))
end
