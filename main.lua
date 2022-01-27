local debugEnabled = false
local comboZone = nil
local insideZone = false
local createdZones = {}
local zoneCache = {}

local function addToComboZone(zone)
    if comboZone ~= nil then
        comboZone:AddZone(zone)
    else
        comboZone = ComboZone:Create({ zone }, { name = 'polyzones' })
        comboZone:onPlayerInOutExhaustive(function(isPointInside, point, insideZones, enteredZones, leftZones)
            if leftZones ~= nil then
                for i = 1, #leftZones do
                    TriggerEvent('polyzones:exit', leftZones[i].name, leftZones[i].data)
                end
            end
            if enteredZones ~= nil then
                for i = 1, #enteredZones do
                    TriggerEvent('polyzones:enter', enteredZones[i].name, enteredZones[i].data, enteredZones[i].center)
                end
            end
        end, 500)
    end
end

local function doCreateZone(options)
    if options.data and options.data.id then
        local k = options.name .. '_' .. tostring(options.data.id)
        if not createdZones[k] then
            createdZones[k] = true
            return true
        else
            print('PolyZone matching the name or id is already in the list, moving forward: ', k)
            return false
        end
    end
    return true
end

local function addZoneEvent(eventName, zoneName)
    if comboZone.events and comboZone.events[eventName] ~= nil then
        return
    end
    comboZone:addEvent(eventName, zoneName)
end

local function addZoneEvents(zone, zoneEvents)
    if zoneEvents == nil then return end
    for _, v in pairs(zoneEvents) do
        addZoneEvent(v, zone.name)
    end
end

exports('AddBoxZone', function(name, vectors, length, width, options)
    if not options then
        options = {}
    end
    
    options.name = name
    options.debugPoly = debugEnabled or options.debugPoly

    if not doCreateZone(options) then 
        return 
    end
    
    local boxCenter = type(vectors) ~= 'vector3' and vector3(vectors.x, vectors.y, vectors.z) or vectors
    local zone = BoxZone:Create(boxCenter, length, width, options)
    addToComboZone(zone)
    addZoneEvents(zone, options.zoneEvents)
    if options.data and options.data.ref then
        zoneCache[options.data.ref] = zone
    end
end)

exports('PointInside', function(ref, coords)
    return zoneCache[ref]:isPointInside(coords)
end)

local function addCircleZone(name, center, radius, options)
    if not options then 
        options = {} 
    end
    
    options.name = name
    options.debugPoly = debugEnabled or options.debugPoly

    if not doCreateZone(options) then 
        return 
    end
    
    local circleCenter = type(center) ~= 'vector3' and vector3(center.x, center.y, center.z) or center
    local zone = CircleZone:Create(circleCenter, radius, options)
    addToComboZone(zone)
    addZoneEvents(zone, options.zoneEvents)
end
exports('AddCircleZone', addCircleZone)

exports('AddPolyZone', function(name, vectors, options)
    if not options then
        options = {} 
    end
    
    options.name = name
    options.debugPoly = debugEnabled or options.debugPoly
    if not doCreateZone(options) then
        return
    end
    local zone = PolyZone:Create(vectors, options)
    addToComboZone(zone)
    addZoneEvents(zone, options.zoneEvents)
end)

exports("AddZoneEvent", function(eventName, zoneName)
    addZoneEvent(eventName, zoneName)
end)

RegisterNetEvent('polyzones:createCircleZone')
AddEventHandler('polyzones:createCircleZone', function(name, ...)
    addCircleZone(name, ...)
end)

local function toggleDebug(state)
    if state == debugEnabled then return end
    debugEnabled = state
    if debugEnabled then
        while debugEnabled do
            comboZone:draw()
            Wait(0)
        end
    end
end