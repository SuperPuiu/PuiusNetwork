--!strict
--!native
--[[
	Author(s):		WATDAHECKLOL32,SuperPuiu
	Name:           Network.luau
	Info:           funny module.
	Date: 		    3/1/25
	Run context:	Shared
]]

local Network = {};
local RemoteEvents: (RemoteEvents) = {};
local RemoteFunctions: (RemoteFunctions) = {};
local BindedEvents: (Bindings) = {};

local ReplicatedStorage = game:FindService("ReplicatedStorage");
local Players = game:FindService("Players");

local NetworkEvent = ReplicatedStorage.NetworkEvent
local NetworkFunction = ReplicatedStorage.NetworkFunction;

local RunService = game:FindService("RunService");
local IsServer: (boolean) = RunService:IsServer();

local Flags = {
	"-disable-puius-bridge"
};

export type RemoteEvents = {
	name: string;
	connection: (string) -> RBXScriptConnection;
};

export type Bindings = {
	name: string;
	connection: (string) -> RBXScriptConnection;
};

export type RemoteFunctions = {
	name: string;
	connection: (string) -> RBXScriptConnection;
};

local function NetworkAssert(Condition, ...)
	if not Condition then
		local Pack = {...};
		local l_Str = Pack[1];

		table.remove(Pack, 1);

		error(string.format(l_Str, unpack(Pack)), 2);
	end;
end;

function Network:CallBinding(Name, ...) : ()
	NetworkAssert(BindedEvents[Name], "Binding %s does not exist.", Name);

	for _, Func in pairs(BindedEvents[Name]) do
		Func(...);
	end;
end;

function Network.ConnectBinding(Name, Func) : ()
	NetworkAssert(typeof(Name) == "string", "Attempted to connect binding with invalid Name. (string expected, got %s)", typeof(Name));
	if not BindedEvents[Name] then BindedEvents[Name] = {}; end;

	table.insert(BindedEvents[Name], Func);
end;

function Network:FireServer(...) : ()
	NetworkAssert(not IsServer, "Attempted to fire event from server to server.");
	NetworkEvent:FireServer(...);	
end;

function Network:InvokeServer(...) : ()
	NetworkAssert(not IsServer, "Attempted to invoke server from server.");
	return NetworkFunction:InvokeServer(...);
end;

function Network:FireClientToClient(Player: (Player), ...) : ()
	NetworkAssert(Player, "Player was not specified when firing function %s.", ...);
	NetworkAssert(not IsServer, "FireClientToClient must not be called from server.");

	Network:FireServer("PUIUS_NETWORK_SPECIAL_BRIDGE", Player, ...);
end;

function Network:FireClient(Player: (Player), ...) : ()
	NetworkAssert(Player, "Player was not specified.");

	if not IsServer then
		warn(string.format("Attempted to fire function %s from client to another client. Redirecting to FireClientToClient.", ...));
		Network:FireClientToClient(Player, ...);
		return;
	end;

	NetworkEvent:FireClient(Player, ...);
end;

function Network:FireAllClientsExcept(Exception: (Player), ...) : ()
	NetworkAssert(IsServer, "Unable to call method FireAllClientsExcept from client.");

	for _, Player in pairs(Players:GetPlayers()) do
		if Player ~= Exception then
			Network:FireClient(Player, ...);
		end;
	end;
end;

function Network:InvokeClient(Player: (Player), ...) : ()
	NetworkAssert(Player, "Unable to invoke client function without a specified client.");
	NetworkAssert(IsServer, "Unable to invoke client from client.");

	return NetworkFunction:InvokeClient(Player, ...);
end;

function Network.ConnectOnEvent(Name: (string), Func: (any))
	NetworkAssert(typeof(Name) == "string", "Attempted to create a remote connection with a Name which is not a string.");
	if not RemoteEvents[Name] then RemoteEvents[Name] = {}; end;

	table.insert(RemoteEvents[Name], Func);
	return #RemoteEvents[Name];
end;

function Network.ConnectOnInvoke(Name: (string), Func: (any))
	NetworkAssert(typeof(Name) == "string", "Attempted to create a remote connection with a Name which is not a string.");
	RemoteFunctions[Name] = Func;
end;

function Network.DisconnectAll(Name: (string))
	NetworkAssert(RemoteEvents[Name], "Attempted to remove unknown function name (%s is an invalid table key)", tostring(Name) or "");
	RemoteEvents[Name] = nil;
end;

function Network.Disconnect(Name: (string), ID: (number))
	NetworkAssert(RemoteEvents[Name], "Attempted to remove unknown function name (%s is an invalid table key)", tostring(Name) or "");
	NetworkAssert(RemoteEvents[Name][ID], "Attempted to remove empty index (%i is an invalid table key)", ID or -1);

	RemoteEvents[Name][ID] = nil;
end;

if IsServer then
	if table.find(Flags, "-disable-puius-bridge") then
		RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE"] = {};

		RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE"][1] = function(Player, ToPlayer, ...)
			local Args = {...};
			Network:FireClient(ToPlayer, Args[1], Player, ...);
		end;
	end;

	NetworkFunction.OnServerInvoke = function(Player: (Player), Name: (string), ...)
		NetworkAssert(RemoteFunctions[Name], "NetworkFunction invoked with unknown function name. (%s is an invalid table key)", tostring(Name) or "");
		return RemoteFunctions[Name](Player, ...);
	end;

	NetworkEvent.OnServerEvent:Connect(function(Player: (Player), Name: (string), ...)
		NetworkAssert(RemoteEvents[Name], "NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or "");
		for _, Func in pairs(RemoteEvents[Name]) do
			Func(Player, ...);
		end;
	end);

else
	NetworkEvent.OnClientEvent:Connect(function(Name: (string), ...)
		NetworkAssert(RemoteEvents[Name], "NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or "");
		for _, Func in pairs(RemoteEvents[Name]) do
			Func(...);
		end;
	end);

	NetworkFunction.OnClientInvoke = function(Name: (string), ...)
		NetworkAssert(RemoteFunctions[Name], "NetworkFunction invoked with unknown function name. (%s is an invalid table key)", tostring(Name) or "");
		return RemoteFunctions[Name](...);
	end;
end;

return Network;
