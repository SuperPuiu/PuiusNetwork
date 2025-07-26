--!native
--[[
	Author(s):		WATDAHECKLOL32,SuperPuiu
	Name:         Network.luau
	Info:         Networking module.
	Creation: 		3/1/25 (MM/DD/YY)
	Run context:	Shared
]]

local Network = {};
local RemoteEvents: (RemoteEvents) = {};
local RemoteFunctions: (RemoteFunctions) = {};
local BindedEvents: (Bindings) = {};

local ReplicatedStorage = game:FindService("ReplicatedStorage");
local Players = game:FindService("Players");

local NetworkEvent = ReplicatedStorage:FindFirstChild("NetworkEvent");
local NetworkFunction = ReplicatedStorage:FindFirstChild("NetworkFunction");
local NetworkUnreliable = ReplicatedStorage:FindFirstChild("NetworkUnreliable");

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

local function CallEventsCallbacks(Name, ...) : ()
  NetworkAssert(RemoteEvents[Name], "NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or "");
  for _, Func in pairs(RemoteEvents[Name]) do
    Func(...);
  end;
end;

function Network:CallBinding(Name, ...) : ()
  NetworkAssert(BindedEvents[Name], "Binding \"%s\" does not exist.", Name);

  for _, Func in pairs(BindedEvents[Name]) do
    Func(...);
  end;
end;

function Network.ConnectBinding(Name, Func) : ()
  NetworkAssert(typeof(Name) == "string", "Attempted to connect binding with invalid Name. (string expected, got %s)", typeof(Name));
  if not BindedEvents[Name] then BindedEvents[Name] = {}; end;

  table.insert(BindedEvents[Name], Func);
end;

function Network.RemoveBinding(Name, ID)
  NetworkAssert(BindedEvents[Name], "Attempted to remove unknown function name (%s is an invalid table key)", tostring(Name) or "");
  NetworkAssert(BindedEvents[Name][ID], "Attempted to remove invalid index (%s is an invalid table key)", tostring(ID) or "");

  BindedEvents[Name][ID] = nil;
end;

function Network.RemoveAllBindings(Name)
  NetworkAssert(BindedEvents[Name], "Attempted to remove unknown bindings (%s is an invalid table key)", tostring(Name) or "");
  BindedEvents[Name] = nil;
end;

function Network.ConnectOnEvent(Name: (string), Func: (any)) : ()
  NetworkAssert(typeof(Name) == "string", "Attempted to create a remote connection with a Name that is not a string.");
  if not RemoteEvents[Name] then RemoteEvents[Name] = {}; end;

  table.insert(RemoteEvents[Name], Func);
  return #RemoteEvents[Name];
end;

function Network.ConnectOnInvoke(Name: (string), Func: (any)) : ()
  NetworkAssert(typeof(Name) == "string", "Attempted to create a remote connection with a Name which is not a string.");
  RemoteFunctions[Name] = Func;
end;

function Network.DisconnectAll(Name: (string)) : ()
  NetworkAssert(RemoteEvents[Name], "Attempted to remove unknown function name (%s is an invalid table key)", tostring(Name) or "");
  RemoteEvents[Name] = nil;
end;

function Network.Disconnect(Name: (string), ID: (number)) : ()
  NetworkAssert(RemoteEvents[Name], "Attempted to remove unknown function name (%s is an invalid table key)", tostring(Name) or "");
  NetworkAssert(RemoteEvents[Name][ID], "Attempted to remove invalid index (%s is an invalid table key)", tostring(ID) or "");

  RemoteEvents[Name][ID] = nil;
end;

if IsServer then
  if not NetworkFunction then
    NetworkFunction = Instance.new("RemoteFunction");
    NetworkFunction.Name = "NetworkFunction";
    NetworkFunction.Parent = game.ReplicatedStorage;
  end;
  
  if not NetworkEvent then
    NetworkEvent = Instance.new("RemoteEvent");
    NetworkEvent.Name = "NetworkEvent";
    NetworkEvent.Parent = game.ReplicatedStorage;
  end;
  
  if not NetworkUnreliable then
    NetworkUnreliable = Instance.new("UnreliableRemoteEvent");
    NetworkUnreliable.Name = "NetworkUnreliable";
    NetworkUnreliable.Parent = game.ReplicatedStorage;
  end;
  
  function Network:FireClient(Player: (Player), ...) : ()
    NetworkAssert(Player, "Player was not specified.");
    NetworkAssert(IsServer, "Attempted to fire a function from client to another client. Maybe you could use FireClientToClient?");

    NetworkEvent:FireClient(Player, ...);
  end;

  function Network:FireClientUnreliable(Player: (Player), ...) : ()
    NetworkAssert(Player, "Player was not specified.");
    NetworkAssert(IsServer, "Attempted to call FireClientUnreliable from client.");

    NetworkUnreliable:FireClient(Player, ...);
  end;

  function Network:FireAllClientsExcept(Exception: (Player), ...) : ()
    NetworkAssert(IsServer, "Unable to call method FireAllClientsExcept from client.");

    for _, Player in pairs(Players:GetPlayers()) do
      if Player ~= Exception then
        Network:FireClient(Player, ...);
      end;
    end;
  end;
  
  function Network:FireAllClientsExceptUnreliable(Exception: (Player), ...) : ()
    NetworkAssert(IsServer, "Unable to call method FireAllClientsExcept from client.");

    for _, Player in pairs(Players:GetPlayers()) do
      if Player ~= Exception then
        Network:FireClientUnreliable(Player, ...);
      end;
    end;
  end;

  function Network:InvokeClient(Player: (Player), ...) : ()
    NetworkAssert(Player, "Unable to invoke client function without a specified client.");
    NetworkAssert(IsServer, "Unable to invoke client from client.");

    return NetworkFunction:InvokeClient(Player, ...);
  end;
  
  if not table.find(Flags, "-disable-puius-bridge") then
    RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE_CTC"] = {};
    RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE_CTCsE"] = {};
    
    RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE_CTC"][1] = function(Player, ToPlayer, ...)
      local Args = {...};
      local Name = table.remove(Args, 1);
      Network:FireClient(ToPlayer, Name, Player, table.unpack(Args));
    end;
    
    RemoteEvents["PUIUS_NETWORK_SPECIAL_BRIDGE_CTCsE"][1] = function(Player, Exception, ...)
      local Args = {...};
      local Name = table.remove(Args, 1);
      Network:FireAllClientsExcept(Exception, Name, Player, table.unpack(Args));
    end;
  end;
  
  NetworkFunction.OnServerInvoke = function(Player: (Player), Name: (string), ...)
    NetworkAssert(RemoteFunctions[Name], "NetworkFunction invoked with unknown function name. (%s is an invalid table key)", tostring(Name) or "");
    return RemoteFunctions[Name](Player, ...);
  end;

  NetworkEvent.OnServerEvent:Connect(function(Player: (Player), Name: (string), ...)
    CallEventsCallbacks(Name, Player, ...);
  end);
  
  NetworkUnreliable.OnServerEvent:Connect(function(Player: (Player), Name: (string), ...)
    CallEventsCallbacks(Name, Player, ...);
  end);
else
  if not NetworkFunction then
    NetworkFunction = game.ReplicatedStorage:WaitForChild("NetworkFunction");
  end;
  
  if not NetworkEvent then
    NetworkEvent = game.ReplicatedStorage:WaitForChild("NetworkEvent");
  end;
  
  if not NetworkUnreliable then
    NetworkUnreliable = game.ReplicatedStorage:WaitForChild("NetworkUnreliable");
  end;
  
  function Network:FireServer(...) : ()
    NetworkAssert(not IsServer, "Attempted to fire event from server to server.");
    NetworkEvent:FireServer(...);	
  end;

  function Network:FireServerUnreliable(...) : ()
    NetworkAssert(not IsServer, "Attempted to fire event from server to server.");
    NetworkUnreliable:FireServer(...);	
  end;

  function Network:InvokeServer(...) : ()
    NetworkAssert(not IsServer, "Attempted to invoke server from server.");
    return NetworkFunction:InvokeServer(...);
  end;
  
  function Network:FireClientToClient(Player: (Player), ...) : ()
    NetworkAssert(Player, "Player was not specified when firing function %s.", ...);
    NetworkAssert(not IsServer, "FireClientToClient must not be called from server.");
    NetworkAssert(not table.find(Flags, "-disable-puius-bridge"), "FireClientToClient cannot be used when the special bridge is disabled.");

    Network:FireServer("PUIUS_NETWORK_SPECIAL_BRIDGE_CTC", Player, ...);
  end;
  
  function Network:FireAllClientsExcept(Exception: (Player), ...) : ()
    Network:FireServer("PUIUS_NETWORK_SPECIAL_BRIDGE_CTCsE", Exception, ...);
  end;
  
  NetworkEvent.OnClientEvent:Connect(function(Name: (string), ...)
    CallEventsCallbacks(Name, ...);
  end);
  
  NetworkUnreliable.OnClientEvent:Connect(function(Name: (string), ...)
    CallEventsCallbacks(Name, ...);
  end);

  NetworkFunction.OnClientInvoke = function(Name: (string), ...)
    NetworkAssert(RemoteFunctions[Name], "NetworkFunction invoked with unknown function name. (%s is an invalid table key)", tostring(Name) or "");
    return RemoteFunctions[Name](...);
  end;
end;

return Network;
