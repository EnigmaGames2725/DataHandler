local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataHandler = {}
DataHandler.__index = DataHandler

function DataHandler.new(ID: string, Template: any, LoadEvent: RBXScriptSignal?, SaveEvent: RBXScriptSignal?)
	local LoadEvent = LoadEvent or Players.PlayerAdded
	local SaveEvent = SaveEvent or Players.PlayerRemoving
	
	local Loaded = Instance.new("BindableEvent")
	local Saved = Instance.new("BindableEvent")
	
	local Handler = {
		DataStore = DataStoreService:GetDataStore(ID),
		_Events = {
			Load = LoadEvent,
			Save = SaveEvent,
			Loaded = Loaded,
			Saved = Saved
		},
		DataLoaded = Loaded.Event,
		DataSaved = Saved.Event,
		Template = Template,
		Data = {}
	}
	
	LoadEvent:Connect(function(Player)
		local Success, Data = pcall(function()
			return Handler.DataStore:GetAsync(Player.UserId)
		end)
		
		if Success then
			if not Data then
				Data = Handler.Template
			end
			Handler.Data[Player.UserId] = Data
			Loaded:Fire(Player, Data)
		else
			warn(Data)
		end
	end)
	
	SaveEvent:Connect(function(Player)
		local Success, Error = pcall(function()
			Handler.DataStore:SetAsync(Player.UserId, Handler.Data[Player.UserId])
		end)
		
		if Success then
			Saved:Fire(Player, Handler.Data[Player.UserId])
			Handler.Data[Player.UserId] = nil
		else
			warn(Error)
		end
	end)
	
	return setmetatable(Handler, DataHandler)
end

function DataHandler:Cleanup()
	self._Events.Load:Disconnect()
	self._Events.Save:Disconnect()
	self._Events.Loaded:Destroy()
	self._Events.Saved:Destroy()
end

return DataHandler
