local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Fungsi bypass anti-cheat sederhana
local function hookFunction(original)
    local hooked
    hooked = hookfunction(original, function(...)
        local args = {...}
        -- Bypass deteksi
        return hooked(...)
    end)
end

-- //////// FEATURE 1: AUTO FARM ////////
-- Otomatis kumpulkan resource / kill mobs / click objective
local AutoFarm = false
local FarmSpeed = 0.1 -- detik per aksi

function startAutoFarm()
    AutoFarm = true
    spawn(function()
        while AutoFarm do
            -- Loop semua objek farmable (NPC, resource node, coin, dsb)
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    -- Deteksi berdasarkan nama generik objek farm di game Brainrot
                    local names = {"Coin", "Brain", "Rot", "Currency", "Gem", "Essence", "Farm", "NPC", "Enemy", "Mob", "Dummy", "Loot"}
                    for _, n in pairs(names) do
                        if string.find(string.lower(obj.Name), string.lower(n)) then
                            -- Fire touch / click / proximity
                            if obj:IsA("BasePart") then
                                firetouchinterest(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or nil, obj, 0)
                                wait(0.05)
                                firetouchinterest(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or nil, obj, 1)
                            elseif obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                                -- Attack logic jika NPC
                                local args = {[1] = obj}
                                ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("Attack"):FireServer(unpack(args))
                            end
                            wait(FarmSpeed)
                        end
                    end
                end
            end
            wait(0.5)
        end
    end)
end

function stopAutoFarm()
    AutoFarm = false
end

-- //////// FEATURE 2: DUPE ////////
-- Duplicate item/pet/unit yang dipilih
function dupeItem(itemName, amount)
    amount = amount or 1
    -- Cari remote untuk trading/drop/pickup
    local remotes = {}
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(remotes, v.Name)
        end
    end
    
    -- Attempt dupe via rapid fire request ke server
    local dupeRemote = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("TradeAction") or 
                       ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("ItemAction") or
                       ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("InventoryMove")
    
    if dupeRemote then
        for i = 1, amount do
            spawn(function()
                dupeRemote:FireServer("dupe", itemName, 1)
                dupeRemote:FireServer("claim", itemName, 1)
                dupeRemote:FireServer("add", itemName, 1)
            end)
            wait(0.05)
        end
    else
        -- Fallback: manipulasi local inventory lalu force save
        local inventory = LocalPlayer:FindFirstChild("Inventory") or LocalPlayer:FindFirstChild("Backpack")
        if inventory then
            for i = 1, amount do
                local clone = inventory:FindFirstChild(itemName):Clone()
                clone.Parent = inventory
            end
        end
    end
end

-- //////// FEATURE 3: INFINITE MONEY ////////
-- Set currency value ke jumlah besar / unlimited
function infiniteMoney(moneyType)
    moneyType = moneyType or "Cash" -- Bisa juga "Coins", "Brains", "Points", dll
    
    -- Method 1: langsung overwrite leaderstats jika ada
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local moneyStat = leaderstats:FindFirstChild(moneyType) or leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Coins")
        if moneyStat and moneyStat:IsA("IntValue") then
            moneyStat.Value = 999999999
        end
    end
    
    -- Method 2: hook RemoteFunction yang handle currency
    local econRemote = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("AddMoney") or
                       ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("CurrencyAward") or
                       ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Reward")
    
    if econRemote then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            if self == econRemote and method == "FireServer" then
                args = {999999999}
                return oldNamecall(self, unpack(args))
            end
            return oldNamecall(self, ...)
        end)
    end
    
    -- Method 3: spam purchase exploit jika ada free item yg bisa dijual
    spawn(function()
        while true do
            -- Coba fire event jual/beli terus-menerus
            local shopRemote = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("ShopPurchase") or
                              ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("BuyItem")
            if shopRemote then
                shopRemote:FireServer("AutoSeller", 999)
            end
            wait(0.01)
        end
    end)
end

-- //////// COMMAND INTERFACE ////////
-- Ketik di chat Delta: /autofarm, /dupe [nama], /moneys [jenis]
LocalPlayer.Chatted:Connect(function(msg)
    local cmd = string.lower(msg)
    if cmd == "/autofarm" then
        startAutoFarm()
    elseif cmd == "/stopfarm" then
        stopAutoFarm()
    elseif string.sub(cmd, 1, 5) == "/dupe" then
        local args = string.split(cmd, " ")
        local item = args[2] or "DefaultItem"
        local qty = tonumber(args[3]) or 1
        dupeItem(item, qty)
    elseif string.sub(cmd, 1, 7) == "/moneys" then
        local args = string.split(cmd, " ")
        local type = args[2]
        infiniteMoney(type)
    end
end)

print("TERZ_ARCHIP-00 LOADED. GAS KAN.")
