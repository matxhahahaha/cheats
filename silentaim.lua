-- Activación automática e invisible (Sin UI)
local Players = game:Service("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuración de las partes válidas del cuerpo (Se excluye Head, LeftArm y RightArm)
local PartesValidas = {"Torso", "HumanoidRootPart", "LeftLeg", "RightLeg", "Left Lower Leg", "Right Lower Leg", "UpperTorso", "LowerTorso"}

-- Función interna para buscar al enemigo vivo más cercano a la mira
local function ObtenerEnemigoMasCercano()
    local ObjetivoMasCercano = nil
    local DistanciaMasCorta = math.huge

    for _, Jugador in ipairs(Players:GetPlayers()) do
        if Jugador ~= LocalPlayer and Jugador.Team ~= LocalPlayer.Team then -- Filtro de equipo opcional
            local Personaje = Jugador.Character
            local Humanoid = Personaje and Personaje:FindFirstChildOfClass("Humanoid")
            
            -- Verificar que el enemigo esté vivo
            if Humanoid and Humanoid.Health > 0 then
                -- Seleccionar aleatoriamente una de las partes permitidas del cuerpo del enemigo
                local PartesDisponibles = {}
                for _, NombreParte in ipairs(PartesValidas) do
                    local Parte = Personaje:FindFirstChild(NombreParte)
                    if Parte then
                        table.insert(PartesDisponibles, Parte)
                    end
                end

                if #PartesDisponibles > 0 then
                    local ParteObjetivo = PartesDisponibles[math.random(1, #PartesDisponibles)]
                    local PosicionPantalla, EnPantalla = Camera:WorldToViewportPoint(ParteObjetivo.Position)
                    
                    if EnPantalla then
                        -- Calcular distancia del cursor al objetivo
                        local MousePos = LocalPlayer:GetMouse()
                        local DistanciaCursor = (Vector2.new(MousePos.X, MousePos.Y) - Vector2.new(PosicionPantalla.X, PosicionPantalla.Y)).Magnitude
                        
                        if DistanciaCursor < DistanciaMasCorta then
                            DistanciaMasCorta = DistanciaCursor
                            ObjetivoMasCercano = ParteObjetivo
                        end
                    end
                end
            end
        end
    end
    return ObjetivoMasCercano
end

-- Intercepción de la Metatabla (Metatable Hooking)
-- Esto altera los argumentos que las armas envían al servidor sin mover tu cámara real
local RawMetatable = getrawmetatable(game)
local OldNamecall = RawMetatable.__namecall
setreadonly(RawMetatable, false)

RawMetatable.__namecall = newcclosure(function(Self, ...)
    local Method = getnamecallmethod()
    local Args = {...}

    -- Detecta si el arma está intentando enviar un disparo o calcular la posición del mouse
    if (Method == "FireServer" or Method == "InvokeServer") and (Self.Name == "Shoot" or Self.Name == "Hit" or Self.Name == "Remote") then
        local Objetivo = ObtenerEnemigoMasCercano()
        if Objetivo then
            -- Reemplaza el argumento de la posición (usualmente el primero o segundo) por la posición del Torso/Pierna
            for i, Arg in ipairs(Args) do
                if typeof(Arg) == "Vector3" then
                    Args[i] = Objetivo.Position
                    break
                elseif typeof(Arg) == "CFrame" then
                    Args[i] = Objetivo.CFrame
                    break
                end
            end
        end
    end

    return OldNamecall(Self, unpack(Args))
end)

setreadonly(RawMetatable, true)
