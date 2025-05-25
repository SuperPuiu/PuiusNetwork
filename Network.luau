--!strict
--!native
--[[
	Author(s):		WATDAHECKLOL32,SuperPuiu
	Name:         Network.luau
	Info:         Networking Module.
	Date: 		    3/1/25
	Run context:	Shared
]]


local Network = {};
local RemoteEvents: (RemoteEvents) = {};
local RemoteFunctions: (RemoteFunctions) = {};

local ReplicatedStorage = game:FindService("ReplicatedStorage");
local Players = game:FindService("Players");

local NetworkEvent = ReplicatedStorage.NetworkEvent;
local NetworkFunction = ReplicatedStorage.NetworkFunction;

local RunService = game:FindService("RunService");
local IsServer: (boolean) = RunService:IsServer();

export type RemoteEvents = {
	name: string;
	connection: (string) -> RBXScriptConnection;
};

export type RemoteFunctions = {
	name: string;
	connection: (string) -> RBXScriptConnection;
};

function Network:FireServer(...) : ()
  assert(not IsServer, "Attempted to fire event from server to server.");
	NetworkEvent:FireServer(...);	
end;

function Network:InvokeServer(...) : ()
	assert(not IsServer, "Attempted to invoke server from server.");
	return NetworkFunction:InvokeServer(...);
end;

function Network:FireClientToClient(Player: (Player), ...) : ()
  assert(Player, string.format("Player was not specified when firing function %s.", ...));
  assert(not IsServer, "FireClientToClient must not be called from server.");

  Network:FireServer("PUIUS_NETWORK_SPECIAL_BRIDGE", Player, ...);
end;

function Network:FireClient(Player: (Player), ...) : ()
  assert(Player, "Player was not specified.");
  
  if not IsServer then
    warn(string.format("Attempted to fire function %s from client to another client. Redirecting to FireClientToClient.", ...));
    Network:FireClientToClient(Player, ...);
    return;
  end;
   
  NetworkEvent:FireClient(Player, ...);
end;

function Network:FireAllClientsExcept(Exception: (Player), ...) : ()
  assert(IsServer, "Unable to call method FireAllClientsExcept from client.");
  
  for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= Exception then
      Network:FireClient(Player, ...);
    end;
  end;
end;

function Network:InvokeClient(Player: (Player), ...) : ()
	assert(Player, "Unable to invoke client function without a specified client.");
  assert(IsServer, "Unable to invoke client from client.");

	return NetworkFunction:InvokeClient(Player, ...);
end;

function Network.ConnectOnEvent(Name: (string), Func: (any))
  assert(typeof(Name) == "string", "Attempted to create a remote connection with a Name which is not a string.");
  if not RemoteEvents[Name] then RemoteEvents[Name] = {}; end;

  table.insert(RemoteEvents[Name], Func);
  return #RemoteEvents[Name];
end;

function Network.ConnectOnInvoke(Name: (string), Func: (any))
  assert(typeof(Name) == "string", "Attempted to create a remote connection with a Name which is not a string.");
  RemoteFunctions[Name] = Func;
end;

function Network.DisconnectAll(Name: (string))
  assert(RemoteEvents[Name], string.format("Attempted to remove unknown function name (%s is an invalid table key)", tostring(Name) or ""));
  RemoteEvents[Name] = nil;
end;

function Network.Disconnect(Name: (string), ID: (number))
  assert(RemoteEvents[Name], string.format("Attempted to remove unknown function name (%s is an invalid table key)", tostring(Name) or ""));
  assert(RemoteEvents[Name][ID], string.format("Attempted to remove empty index (%i is an invalid table key)", ID or -1));

  RemoteEvents[Name][ID] = nil;
end;

if IsServer then
  RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE"] = {};

  RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE"][1] = function(Player, ToPlayer, ...)
    local Args = {...};
    Network:FireClient(ToPlayer, Args[1], Player, ...);
  end;

  NetworkFunction.OnServerInvoke = function(Player: (Player), Name: (string), ...)
	  assert(RemoteFunctions[Name], string.format("NetworkFunction invoked with unknown function name. (%s is an invalid table key)", tostring(Name) or ""));
	  return RemoteFunctions[Name](Player, ...);
  end;

  NetworkEvent.OnServerEvent:Connect(function(Player: (Player), Name: (string), ...)
	  assert(RemoteEvents[Name], string.format("NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or ""));
    for _, Func in pairs(RemoteEvents[Name]) do
	    Func(Player, ...);
    end;
  end);

else
  NetworkEvent.OnClientEvent:Connect(function(Name: (string), ...)
    assert(RemoteEvents[Name], string.format("NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or ""));
    for _, Func in pairs(RemoteEvents[Name]) do
	    Func(...);
    end;
  end);

  NetworkFunction.OnClientInvoke = function(Name: (string), ...)
	  assert(RemoteFunctions[Name], string.format("NetworkFunction invoked with unknown function name. (%s is an invalid table key)", tostring(Name) or ""));
	  return RemoteFunctions[Name](...);
  end;
end;

return Network;
