--!native
--[[
	Author(s):		WATDAHECKLOL32,SuperPuiu
	Name:         Network.luau
	Info:         Networking module.
	Creation: 		3/1/25 (MM/DD/YY)
	Run context:	Shared
	
	Changelog:
	* Implemented WaitForEvent. - @SuperPuiu
	* Implemented DefineEvents. - @watdahecklol32
	* Implemented ConnectOnEventOnce. - @SuperPuiu
	* Implemented new sanitization options for numbers and strings:
	  - strings: MaxLength, specifying what's the maximum length accepted. Option is optional;
	  - numbers: Smallest and Largest, specifying what's the limit between which the number is accepted. Both are optional;
	* Fixed InvokeClient unhandled exception when calling with a non-player argument. - @SuperPuiu
	* Fixed Sanitizer skipping first argument even if it's called on client side. - @SuperPuiu
	* Code cleanups. -@watdahecklol32
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
  ["-silence-sanitizer-warnings"] = false,
  ["-sanitizer-strict"] = true,
  ["-silence-all"] = false
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
  local TableLen = RunService:IsServer() and #Arguments - 1 or #Arguments;
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
    local ArgIndex = IsServer and Index + 1 or Index;
    
    local Arg = Arguments[ArgIndex];

    if Arg == nil and not ArgProperties.Nullable then
      if not Silence then 
        warn(string.format("Argument %i is nil although it's not Nullable.", ArgIndex)); 
      end;
      
      return false;
    end;

    if typeof(Arg) ~= ArgProperties.Type then
      if not Silence then 
        warn(string.format("Argument %i is of unexpected type (argument is of type \"%s\" while \"%s\" was expected.)", ArgIndex, typeof(Arg), ArgProperties.Type)); 
      end;
      
      return false;
    end;
    
    if ArgProperties.Type == "string" then
      local Len, MaxLength = string.len(Arg), ArgProperties.Maximum or math.huge;
      
      if not Silence and Len > MaxLength then 
        warn(string.format("Argument %i is too long. (expected length %i, got %i)", ArgIndex, MaxLength, Len)); 
      end;
      
      if Len > MaxLength then 
        return false; 
      end;
    elseif ArgProperties.Type == "number" then
      local Smallest, Largest = ArgProperties.Smallest or math.huge * -1, ArgProperties.Largest or math.huge;
      
      if not Silence and not (Arg >= Smallest and Arg <= Largest) then
        warn(string.format("Argument %i is not between %i and %i (number is %i)", ArgIndex, ArgProperties.Smallest, Largest, Arg));
      end;
      
      if not (Arg >= Smallest and Arg <= Largest) then
        return false;
      end;
    end;
  end;

  return true;
end;

local function CallEventsCallbacks(Name, ...) : ()
  NetworkAssert(RemoteEvents[Name], "NetEvent fired with unknown function name. (%s is an invalid table key)", tostring(Name) or "");

  for Index, Data in pairs(RemoteEvents[Name]) do
    local Safe = true;

    if Data.Configuration.Sanitize.Enabled then
      Safe = Sanitize(Data, Name, ...);
    end;

    if not Safe then continue; end;

    Data.Connection(...);
    
    if Data.Configuration.Once then Network.Disconnect(Name, Index); end;
  end;
end;

local function WaitForEventInternal(ConnectionName, ConnectionType)
  local InternalTable;
  
  if ConnectionType == 1 then
    InternalTable = RemoteEvents;
  elseif ConnectionType == 2 then
    InternalTable = RemoteFunctions;
  elseif ConnectionType == 3 then
    InternalTable = BindedEvents;
  end;
  
  repeat task.wait(); until InternalTable[ConnectionName];
end;

function Network:WaitForEvent(ConnectionName: (string), Player: (Player), ConnectionType: number)
  NetworkAssert(typeof(ConnectionName) == "string", "Attempted to call WaitForEvent with invalid ConnectionName type (expected string, got %s)", typeof(ConnectionName));
  NetworkAssert(typeof(Player) == "Instance" or Player == nil, "Attempted to call WaitForEvent with invalid Player (expected Instance or nil, got %s)", typeof(Player));
  NetworkAssert(IsServer and Player ~= nil, "Attempted to call WaitForEvent with Player non null from client.");
  
  local InfiniteMessage = "Infinite yield possible for connection "..ConnectionName;
  
  if not Player then
    if ConnectionType >= 1 and ConnectionType <= 3 then
      local WarnTask = task.delay(3, warn, InfiniteMessage);
      
      WaitForEventInternal(ConnectionName, ConnectionType);
      
      task.cancel(WarnTask);
      return true;
    else
      warn("WaitForEvent called with unknown ConnectionType.");
      return false;
    end;
  else
    local WarnTask = task.delay(3, warn, InfiniteMessage);
   
    Network:InvokeClient(Player, "Puius_WaitForEvent", ConnectionName, ConnectionType);
    
    task.cancel(WarnTask);
    return true;
  end;
end;

function Network:CallBinding(Name, ...) : ()
  NetworkAssert(BindedEvents[Name], "Binding \"%s\" does not exist.", Name);

  for _, Func in pairs(BindedEvents[Name]) do
    Func(...);
  end;
end;

function Network:DefineEvents(Sanziter: {[string]: any}, Events: {[string]: any}): ({[number]: number})
  NetworkAssert(Events and typeof(Events) == "table", `Invalid Events table (expected table, got %s)`, typeof(Events));
  NetworkAssert(Sanziter and typeof(Sanziter) == "table", `Invalid Sanitizer table (expected table, got %s)`, typeof(Events));
	
	local ok: {[number]: number} = {};
	for i: string, v: (...any) -> (...any) in Events do
		if type(i) ~= "string" then continue; end;
		if Sanziter[i] then
			local Id = Network.ConnectOnEventSanitized(i, Sanziter[i], v);
			table.insert(ok, Id);
		else
			local Id = Network.ConnectOnEvent(i, v);
			table.insert(ok, Id);
		end;
	end;

	return ok;
end;

function Network.ConnectBinding(Name, Func) : ()
  NetworkAssert(typeof(Name) == "string", "Attempted to connect binding with invalid Name. (string expected, got %s)", typeof(Name));
  NetworkAssert(typeof(Func) == "function", "Attempted to connect binding with invalid Func. (function expected, got %s)", typeof(Func));

  if not BindedEvents[Name] then BindedEvents[Name] = {}; end;

  table.insert(BindedEvents[Name], Func);
  return #BindedEvents[Name];
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

function Network.ConnectOnEventSanitized(Name: (string), SanitizerTable: {[number]: {[string]: any}}, Func: (any))
  NetworkAssert(typeof(Name) == "string", "Attempted to create a remote connection with a Name that is not a string.");
  NetworkAssert(typeof(SanitizerTable) == "table" or SanitizerTable == nil, "Attempted to create a remote connection with wrong SanitizerTable table type.");
  NetworkAssert(typeof(Func) == "function", "Attempted to create a remote connection with a non function argument (expected function, got %s)", typeof(Func));
  local IsEmpty = SanitizerTable ~= nil;

  if SanitizerTable == nil then SanitizerTable = {}; end;

  if not RemoteEvents[Name] then RemoteEvents[Name] = {}; end;
  if typeof(SanitizerTable.Enabled) ~= "boolean" then SanitizerTable.Enabled = IsEmpty; end;

  table.insert(RemoteEvents[Name], {Connection = Func, Configuration = {Sanitize = SanitizerTable}});
  return #RemoteEvents[Name];
end;

function Network.ModifyConnectionSanitizer(Connection: (string), ID: (number), Sanitizer: {[number]: {[string]: any}})
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

function Network.ConnectOnEventOnce(Name: (string), Func: (any)) : ()
  local ID = Network.ConnectOnEventSanitized(Name, nil, Func);
  Network.ModifyConnectionConfiguration(Name, ID, "Once", true);
  return ID;
end;

function Network.ConnectOnInvoke(Name: (string), Func: (any)) : ()
  NetworkAssert(typeof(Name) == "string", "Attempted to create a remote connection with a Name which is not a string.");
  NetworkAssert(typeof(Func) == "function", "Attempted to create a remote connection with incorrect Func argument (expected function, got %s)", typeof(Func));

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

Network.ConnectOnInvoke("Puius_WaitForEvent", function(...)
  local Args = {...};
  local ConnectionName, ConnectionType;
  
  if IsServer then
    ConnectionName, ConnectionType = Args[2], Args[3];
  else
    ConnectionName, ConnectionType = unpack(Args);    
  end;
  
  NetworkAssert(typeof(ConnectionName) == "string", "Attempted to invoke Puius_WaitForEvent with invalid ConnectionName. (expected string, got %s)", typeof(ConnectionName));
  NetworkAssert(typeof(ConnectionType) == "number", "Attempted to invoke Puius_WaitForEvent with invalid ConnectionType. (expected number, got %s)", typeof(ConnectionType));
  
  WaitForEventInternal(ConnectionName, ConnectionType);
  
  return true;  
end);

if IsServer then
  if not NetworkFunction then
    NetworkFunction = Instance.new("RemoteFunction");
    NetworkFunction.Name = "NetworkFunction";
    NetworkFunction.Parent = ReplicatedStorage;
  end;

  if not NetworkEvent then
    NetworkEvent = Instance.new("RemoteEvent");
    NetworkEvent.Name = "NetworkEvent";
    NetworkEvent.Parent = ReplicatedStorage;
  end;

  if not NetworkUnreliable then
    NetworkUnreliable = Instance.new("UnreliableRemoteEvent");
    NetworkUnreliable.Name = "NetworkUnreliable";
    NetworkUnreliable.Parent = ReplicatedStorage;
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

  function Network:FireAllClients(...: any): ()
    NetworkAssert(IsServer, "Unable to call method FireAllClients from client.");
    Network:FireAllClientsExcept(nil, ...);
  end;

  function Network:FireAllClientsUnreliable(...: any): ()
    NetworkAssert(IsServer, "Unable to call method FireAllClientsUnreliable from client.");
    Network:FireAllClientsExceptUnreliable(nil, ...);
  end;

  function Network:InvokeClient(Player: (Player), ...) : ()
    NetworkAssert(Player, "Unable to invoke client function without a specified client.");
    NetworkAssert(typeof(Player) == "Instance", "Unable to invoke client with a non-instance Player.");
    NetworkAssert(Player:IsA("Player"), "Unable to invoke client (provided Player isn't a player instance.)");
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
