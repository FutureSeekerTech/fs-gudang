local QBCore = exports['qb-core']:GetCoreObject()
local ListGudang = {}
local ListGudangStatus = false

local function GetAllDataGudang()
    for k,v in pairs(Config.Gudang.location) do
        ListGudang[k] = {}
    end
    local data = MySQL.query.await('SELECT * from gudang')
    for i=1, #data, 1 do
        kode = data[i].kode
        lokasi = data[i].lokasi
        if ListGudang[lokasi] ~= nil then
            ListGudang[lokasi][kode] = {
                kode                = data[i].kode,
                lokasi              = data[i].lokasi,
                owner               = data[i].owner,
                pin                 = data[i].pin,
            }
        else
            ListGudang[lokasi] = {}
            ListGudang[lokasi][kode] = {
                kode                = data[i].kode,
                lokasi              = data[i].lokasi,
                owner               = data[i].owner,
                pin                 = data[i].pin,
            }
        end
    end
    ListGudangStatus = true
end

-- Fungsi Update Pin dan Simpan dalam database dan local tabel server
local function GudangUpdatePin(data)
    local kode = data.kode
    local pin = data.pin
    MySQL.query.await('UPDATE gudang SET pin = @pin WHERE kode = @kode', {
        ['@kode'] = kode,
        ['@pin'] = pin
    })
    -- Update Table
    for i=1, #ListGudang, 1 do
        if ListGudang[i].kode == kode then
            ListGudang[i].pin = pin
        end
    end
end

-- Fungsi Generator Kode
local function GudangCreateHash(length)
	local res = ""
	for i = 1, length do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end

local function SetupGudang()
    for i=1, #ListGudang, 1 do
        local tempat
        if ListGudang[i].lokasi == 'gudang_paleto' then
            tempat = 'Gudang Paleto '..ListGudang[i].kode
        elseif ListGudang[i].lokasi == 'gudang_ss' then
            tempat = 'Gudang Sandy Shores '..ListGudang[i].kode
        elseif ListGudang[i].lokasi == 'gudang_kota' then
            tempat = 'Gudang Kota '..ListGudang[i].kode
        end

        stash = {
            id = ListGudang[i].lokasi..'_'..ListGudang[i].kode,
            label = tempat,
            slots = 100,
            weight = 1000000,
            owner = false
        }
        print("registered gudang: "..stash.id)
        exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots, stash.weight, stash.owner)
    end
end

RegisterNetEvent('gudang:buyGudang', function(data)
    local src = source
    local pin = data.pin
    local lokasi = data.location
    local Player = QBCore.Functions.GetPlayer(src)
    local identifier = Player.PlayerData.citizenid
    local kode = GudangCreateHash(6)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM gudang WHERE lokasi = @lokasi and kode = @kode', {
        ['@lokasi'] = lokasi,
        ['@kode'] = kode
    }, function(count)
        if count == 0 then
            MySQL.Async.execute('INSERT INTO gudang (kode, lokasi, owner, pin) VALUES (@kode, @lokasi, @owner, @pin)', {
                ['@kode'] = kode,
                ['@lokasi'] = lokasi,
                ['@owner'] = identifier,
                ['@pin'] = pin
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    if ListGudang[lokasi] ~= nil then
                        ListGudang[lokasi][kode] = {
                            kode = kode,
                            lokasi = lokasi,
                            owner = identifier,
                            pin = pin
                        }
                    else
                        ListGudang[lokasi] = {}
                        ListGudang[lokasi][kode] = {
                            kode = kode,
                            lokasi = lokasi,
                            owner = identifier,
                            pin = pin
                        }
                    end
                    local tempat
                    if lokasi == 'gudang_paleto' then
                        tempat = 'Gudang Paleto '..kode
                    elseif lokasi == 'gudang_ss' then
                        tempat = 'Gudang Sandy Shores '..kode
                    elseif lokasi == 'gudang_kota' then
                        tempat = 'Gudang Kota '..kode
                    end
                    stash = {
                        id = lokasi..'_'..kode,
                        label = tempat,
                        slots = 100,
                        weight = 1000000,
                        owner = false
                    }
                    print("registered gudang: "..stash.id)
                    exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots, stash.weight, stash.owner)
                    TriggerClientEvent('QBCore:Notify', src, 'Kamu telah membeli gudang dengan kode: '..kode)
                    Player.Functions.RemoveMoney('cash', Config.Gudang.price, 'beli-gudang')
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Gagal membeli gudang')
                end
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Gudang sudah ada yang memiliki')
        end
    end)
end)


lib.callback.register('gudang:checkOwned', function(source, location)
    local PlayerData = QBCore.Functions.GetPlayer(source).PlayerData
    local identifier = PlayerData.citizenid
    local owned = nil
    if ListGudang[location] == nil then return nil end
    for k,v in pairs(ListGudang[location]) do
        if v.owner == identifier then
            owned = v
            break
        end
    end
    return owned
end)

lib.callback.register('gudang:checkOwnedPin', function(source, data)
    local lokasi = data.lokasi
    local kode = data.kode
    local pin = data.pin
    if ListGudang[lokasi] and ListGudang[lokasi][kode] then
        if ListGudang[lokasi][kode].pin == pin then
            owned = ListGudang[lokasi][kode]
        end
    end
    return owned
end)

lib.callback.register('gudang:checkMoney', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    return Player.PlayerData.money["cash"] >= Config.Gudang.price
end)

lib.callback.register('gudang:updatePin', function(source, data)
    GudangUpdatePin(data)
    return true
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() or resource == "ox_inventory" then
        if not ListGudangStatus then
            GetAllDataGudang()
        end
        Wait(5000)
        SetupGudang()
    end
end)