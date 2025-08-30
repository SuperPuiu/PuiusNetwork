--!native
--[[
	Author(s):		WATDAHECKLOL32,SuperPuiu
	Name:         Network.luau
	Info:         Networking module.
	Creation: 		3/1/25 (MM/DD/YY)
	Run context:	Shared
]]

local Network = {};
local SanitizedEvents = {};
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
  ["-silence-sanitizer-warnings"] = false,
  ["-sanitizer-strict"] = true
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

local function Sanitize(Data, FunctionName, ...)
  local Arguments = {...};
  local TableLen = #Arguments - 1;
  local Silence = Flags["-silence-sanitizer-warnings"];

  if not Data.Configuration.Variadic and TableLen ~= #Data.Configuration.Sanitize.Arguments then 
    local Message = string.format("Less or more arguments than sanitized arguments detected for %s. (expected %i got %i)", FunctionName, #Data.Configuration.Sanitize.Arguments, TableLen);
    local IsStrict = Flags["-sanitizer-strict"];
    
    if IsStrict then
      if not Silence then warn(Message); end;
      return false;
    elseif not Silence then
      warn(Message);
      warn("Continuing check anyways.");
    end;
  end;

  for Index, ArgProperties in pairs(Data.Configuration.Sanitize.Arguments) do
    if Index > TableLen then break; end;

    local Arg = Arguments[Index + 1];

    if Arg == nil and not ArgProperties.Nullable then
      if not Silence then warn(string.format("Argument %i is nil although it's not Nullable.", Index + 1)); end;
      return false;
    end;

    if typeof(Arg) ~= ArgProperties.Type then
      if not Silence then warn(string.format("Argument %i is of unexpected type (Argument is of type \"%s\" while \"%s\" was expected.)", Index + 1, typeof(Arg), ArgProperties.Type)); end;
      return false;
    end;
  end;

  return true;
end;

local function CallEventsCallbacks(Name, ...) : ()
  NetworkAssert(RemoteEvents[Name], "NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or "");

  for _, Data in pairs(RemoteEvents[Name]) do
    local Safe = true;

    if Data.Configuration.Sanitize.Enabled then
      Safe = Sanitize(Data, Name, ...);
    end;

    if not Safe then continue; end;

    Data.Connection(...);
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

function Network.ConnectOnEventSanitized(Name: (string), SanitizerTable: (table), Func: (any))
  NetworkAssert(typeof(Name) == "string", "Attempted to create a remote connection with a Name that is not a string.");
  NetworkAssert(typeof(SanitizerTable) == "table" or SanitizerTable == nil, "Attempted to create a remote sanitized connection with wrong SanitizerTable table type.");
  local IsEmpty = SanitizerTable ~= nil;
  
  if SanitizerTable == nil then SanitizerTable = {}; end;
  
  if not RemoteEvents[Name] then RemoteEvents[Name] = {}; end;
  if typeof(SanitizerTable.Enabled) ~= "boolean" then SanitizerTable.Enabled = IsEmpty; end;

  table.insert(RemoteEvents[Name], {Connection = Func, Configuration = {Sanitize = SanitizerTable}});
  return #RemoteEvents[Name];
end;

function Network.ModifyConnectionSanitizer(Connection: (string), ID: (number), Sanitizer: (table))
  NetworkAssert(typeof(Sanitizer) == "table", "Attempted to change connection sanitizer with invalid table.");
  NetworkAssert(typeof(Connection) == "string", "Attempted to change invalid connection index.");

  RemoteEvents[Connection][ID].Configuration.Sanitize = Sanitizer;
end;

function Network.ModifyConnectionConfiguration(Connection: (string), ID: (number), Entry: (string), State: (any))
  NetworkAssert(typeof(ID) == "number", "Attempted to change invalid connection index.");
  NetworkAssert(typeof(Connection) == "string", "Attempted to change invalid connection name's index.");
  NetworkAssert(typeof(Entry) == "string", "Attempted to change entry of invalid name (expected string as Entry argument).");
  NetworkAssert(RemoteEvents[Connection], "%s connection name does not exist.", tostring(Connection) or "NON_STRING");
  NetworkAssert(RemoteEvents[Connection][ID], "%s does not exist in the %s connection table.", tostring(ID) or "NON_STRING", Connection);

  if Entry == "Connection" or Entry == "Sanitize" then
    warn("Connection and Sanitize entries may not be manually modified.");
    return false;
  end;

  RemoteEvents[Connection][ID].Configuration[Entry] = State;

  return true;
end;

function Network.ConnectOnEvent(Name: (string), Func: (any)) : ()
  return Network.ConnectOnEventSanitized(Name, nil, Func);
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
