local QBCore = exports['qb-core']:GetCoreObject()
local function OpenGudangWithPin(kode, pin, lokasi)
  local _sendData = {}
  _sendData.kode = kode
  _sendData.pin = pin
  _sendData.lokasi = lokasi
  local ownedData = lib.callback.await('gudang:checkOwnedPin', false, _sendData)
  if not ownedData then QBCore.Functions.Notify('Kode Gudang Atau Pin Salah', 'error', 7500) return end
  exports.ox_inventory:openInventory('stash', {id=ownedData.lokasi..'_'..ownedData.kode})
end

local function OpenGudangMenu(data)
    local menulist= {}
    local ownedData = lib.callback.await('gudang:checkOwned', false, data.location)
    menulist[#menulist+1] = {
        title = 'Akses Gudang Dengan Pin',
        description = 'Akses Gudang Dengan Kode Gudang dan Pin',
        icon = 'fas fa-unlock-alt',
        onSelect = function()
          local input = lib.inputDialog('Buka Gudang', {
            { type = 'input', label = 'Kode Gudang', placeholder = 'Kode Gudang' },
            { type = 'input', label = 'Pin', placeholder = 'Pin', password = true },
          })
          if not input then return end
          OpenGudangWithPin(input[1], input[2], data.location)
          print(json.encode(input, {indent=true}))
        end,
    }
    if ownedData then
        menulist[#menulist+1] = {
            title = 'Buka Gudang Kamu',
            description = "Kode Gudang Kamu: "..ownedData.kode:upper(),
            icon = 'fas fa-inbox',
            onSelect = function()
              print("open gudang: "..ownedData.lokasi..'_'..ownedData.kode)
              exports.ox_inventory:openInventory('stash', {id=ownedData.lokasi..'_'..ownedData.kode})
            end,
        }
        menulist[#menulist+1] = {
            title = 'Ubah Pin',
            description = 'Ubah Pin Kode Gudang '..ownedData.kode:upper(),
            icon = 'fas fa-unlock-alt',
            onSelect = function()
              local input = lib.inputDialog('Rubah Pin Gudang', {
                { type = 'input', label = 'pin', placeholder = 'pin', password = true },
              })
              if not input then return end
              local datasend = {}
              datasend.kode = ownedData.kode
              datasend.pin = input[1]
              local response = lib.callback.await('gudang:updatePin', false, datasend)
              if response then QBCore.Functions.Notify('Berhasil Merubah Pin', 'success', 7500) return end
            end,
        }
    else
        menulist[#menulist+1] = {
            title = 'Beli Gudang',
            description = 'Beli Gudang Dengan Harga '..tostring(Config.Gudang.price),
            icon = 'fas fa-dollar',
            onSelect = function()
              local hasMoney = lib.callback.await('gudang:checkMoney', false)
              if not hasMoney then QBCore.Functions.Notify('Tidak Memiliki Cukup Uang', 'error', 7500) return end
              local input = lib.inputDialog('Buat Pin Gudang', {
                { type = 'input', label = 'pin', placeholder = 'pin', password = true },
              })
              if not input then return end
              local datasend = {}
              datasend.location = data.location
              datasend.pin = input[1]
              print(json.encode(datasend, {indent=true}))
              TriggerServerEvent('gudang:buyGudang', datasend)
            end,
        }
    end
    lib.registerContext({
        id = 'gudang_menu',
        title = "Gudang Menu",
        options = menulist
    })
    lib.showContext('gudang_menu')
end

Citizen.CreateThread(function()
  for _, data in pairs(Config.Gudang.location) do
      local blip = AddBlipForCoord(data.location.x, data.location.y, data.location.z)
      SetBlipSprite(blip, 50)
      SetBlipAsShortRange(blip, true)
      SetBlipScale(blip, 0.7)
      SetBlipColour(blip, 25)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString(data.label)
      EndTextCommandSetBlipName(blip)
      exports["qb-target"]:AddCircleZone(data.hash, data.location, 1.0,{
          name = data.hash,
          debugPoly = false,
          useZ = true,
          }, {
          options = {
              {
                  action = function()
                      local datapass = {}
                      datapass.location = data.hash
                      OpenGudangMenu(datapass)
                  end,
                  icon = "fas fa-inbox",
                  label = data.label,
              },
          },
          distance = 1.5
      })
  end
end)