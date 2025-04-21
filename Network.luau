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

local ReplicatedStorage = game:FindService("ReplicatedStorage");
local Players = game:FindService("Players");

local NetworkEvent = ReplicatedStorage.NetworkEvent
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

RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE"] = function(Player, ...)
  Network:FireClient(Player, ...);
end;

function Network:FireServer(...) : ()
	if IsServer then
    error("Attempted to fire event from server to server.");
	end;
	
	NetworkEvent:FireServer(...);	
end;

function Network:InvokeServer(...) : ()
	if IsServer then
		error("Attempted to invoke server from server.");
	end;
	
	return NetworkFunction:InvokeServer(...);
end;

function Network:FireClientToClient(Player: (Player), ...) : ()
  if not Player then
    local s = {...};
    error(string.format("Player was not specified when firing function %s.", s[1]));
  end;

  Network:FireServer("PUIUS_NETWORK_SPECIAL_BRIDGE", Player, ...);
end;

function Network:FireClient(Player: (Player), ...) : ()
   if not IsServer and Player then
     local s = {...};
     warn(string.format("Attempted to fire function %s from client to another client. Redirecting to FireClientToClient.", s[1]));
   elseif not Player then
     error("Player was not specified.");
   end;
   
   NetworkEvent:FireClient(Player, ...);
end;

function Network:FireAllClientsExcept(Exception: (Player), ...) : ()
  if not IsServer then
		return;
  end;
  
  for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= Exception then
      Network:FireClient(Player, ...);
    end;
  end;
end;

function Network:InvokeClient(Player: (Player), ...) : ()
	if not Player then
		return;
	end;
	
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
  NetworkEvent.OnServerEvent:Connect(function(Player: (Player), Name: (string), ...)
	  assert(RemoteEvents[Name], string.format("NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or ""));
    for _, Func in pairs(RemoteEvents[Name]) do
	    Func(Player, ...);
    end;
  end);
end;

if IsServer then
  NetworkFunction.OnServerInvoke = function(Player: (Player), Name: (string), ...)
	  assert(RemoteFunctions[Name], string.format("NetworkFunction invoked with unknown function name. (%s is an invalid table key)", tostring(Name) or ""));
	  return RemoteFunctions[Name](Player, ...);
  end;
end;

if not IsServer then
  NetworkFunction.OnClientInvoke = function(Name: (string), ...)
	  assert(RemoteFunctions[Name], string.format("NetworkFunction invoked with unknown function name. (%s is an invalid table key)", tostring(Name) or ""));
	  return RemoteFunctions[Name](...);
  end;
end;

if not IsServer then
  NetworkEvent.OnClientEvent:Connect(function(Name: (string), ...)
    assert(RemoteEvents[Name], string.format("NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or ""));
    for _, Func in pairs(RemoteEvents[Name]) do
	    Func(...);
    end;
  end);
end;

return Network;
