local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataHandler = {}
DataHandler.__index = DataHandler

function DataHandler.new(ID: string, Template: any, LoadEvent: RBXScriptSignal?, SaveEvent: RBXScriptSignal?)
	local LoadEvent = LoadEvent or Players.PlayerAdded -- Defaults to PlayerAdded if not defined
	local SaveEvent = SaveEvent or Players.PlayerRemoving -- Defaults to PlayerRemoving if not defined
	
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
		local Success, Data = pcall(function() -- pcall() incase DataStore call fails
			return Handler.DataStore:GetAsync(Player.UserId) -- Fetch data
		end)
		
		if Success then
			if not Data then
				Data = Handler.Template -- Set nonexisting data to user defined default
			end
			Handler.Data[Player.UserId] = Data
			Loaded:Fire(Player, Data) -- Send newly loaded data
		else
			warn(Data)
		end
	end)
	
	SaveEvent:Connect(function(Player)
		local Success, Error = pcall(function() -- pcall() incase DataStore call fails
			Handler.DataStore:SetAsync(Player.UserId, Handler.Data[Player.UserId]) -- Save data
		end)
		
		if Success then
			Saved:Fire(Player, Handler.Data[Player.UserId]) -- Tell scripts that data has been saved
			Handler.Data[Player.UserId] = nil -- Remove data from temporary storage
		else
			warn(Error)
		end
	end)
	
	return setmetatable(Handler, DataHandler) -- Use setmetatable() to utilize OOP and add the helper function :Cleanup()
end

function DataHandler:Cleanup() -- Disconnects and destroys loose ends
	self._Events.Load:Disconnect()
	self._Events.Save:Disconnect()
	self._Events.Loaded:Destroy()
	self._Events.Saved:Destroy()
end

return DataHandler
