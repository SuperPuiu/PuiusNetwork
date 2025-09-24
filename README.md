# PuiusNetwork
PuiusNetwork is a module used to unify and pass all events a game could have through one single RemoteEvent, RemoteFunction, BindableEvent or UnreliableRemoteEvent. It provides everything you'd normally get from vanilla networking while developing games within the ROBLOX engine.

# API
Synopsys:
```luau
void Network:FireServer(Name: string, ...);
void Network:FireClient(Player: Player, Name: string, ...);
void Network:FireServerUnreliable(Name: string, ...);
void Network:FireClientUnreliable(Name: string, ...);
any  Network:InvokeServer(Name: string, ...);
any  Network:InvokeClient(Player: Player, Name: string, ...);

void Network:FireAllClientsExcept(Exception: Player, Name: string, ...);
void Network:FireAllClientsExceptUnreliable(Exception: Player, Name: string, ...);
void Network:FireAllClients(Name: string, ...);
void Network:FireAllClientsUnreliable(Name: string, ...);

void Network:CallBinding(Name: string, ...);

int  Network.ConnectOnEvent(Name: string, Func: any);
int  Network.ConnectOnEventOnce(Name: string, Func: any);
int  Network.ConnectOnEventSanitized(Name: string, SanitizerTable: table OR nil, Func: any);
int  Network.ConnectBinding(Name: string, Func: any);
ints Network:DefineEvents(SanitizerTable: table, Events: table);
void Network.ConnectOnInvoke(Name: string, Func: any);

void Network.ModifyConnectionSanitizer(Connection: string, ID: number, Sanitizer: table);
bool Network.ModifyConnectionConfiguration(Connection: string, ID: number, Entry: string, State: any);

bool Network:WaitForEvent(ConnectionName: string, Player: Player, ConnectionType: number);

void Network.RemoveBinding(Name: string, ID: number);
void Network.RemoveAllBindings(Name: string);
void Network.DisconnectAll(Name: string);
void Network.Disconnect(Name: string, ID: number);
```

# Testing
To use the basic testing suite, you may use the following script:
```lua
local NetworkTest = require(script.Parent.NetworkTest);
NetworkTest.CheckHealth();
```
Both `NetworkTest` and `Network` modules **MUST** be under the same parent.

# DefineEvents
If you'd like to define multiple events in one Network call, you can use `DefineEvents`. SanitizerTable should look as it follows:
```
{
  Event1_Name = {
    Arguments = {
      {
        Type = string,
        Nullable = bool,
        ...
      },

      {
        Type = string,
        Nullable = bool,
        ...
      },

      ...
    }
  },

  ...
}
```
Where all sanitization table keys (in the example from above, Event1_Name) **must** have a matching event name.

The Events table should look as it follows:
```
{
  Event1_Name = function,
  Event2_Name = function,
  ...
}
```

Full example:
```lua
-- Assuming we're on server
local Network = require(game.ReplicatedStorage.NetworkModule);

local Sanitizer = {
  HelloWorld = {
    Arguments = {
      {
        Type = "string",
        Nullable = false
        MaxLength = 256
      },

      {
        Type = "number",
        Nullable = false
      }
    }
  }
};

local Events = {
  HelloWorld = function(Player, Message)
    print(Message);
  end);
};

Network:DefineEvents(Sanitizer, Events);
```

SanitizerTable can also be nil:
```lua
local Network = require(game.ReplicatedStorage.NetworkModule);
local Events = {
  a = function(_, Message)
    print(Message);
  end),

  b = function(_, Number)
    print(Number);
  end)
},

Network:DefineEvents(nil, Events);
```
# Notes
A connection's configuration can have the following table:
```lua
{
  Variadic = bool,
  Sanitize = {
    Enabled = bool,
    Arguments = {
      {
        Type = string,
        Nullable = bool
      },
      
      ...
    }
  }
}
```

ConnectOnEventSanitized excepts the following table structure:
```lua
{
  Arguments = { 
    {
      Type = string,
      Nullable = bool,
    },
  
    {
      Type = string,
      Nullable = bool,
    },

    ...
  }
}
```

Although not required, it is recommended that you set Variadic bool to true if your function is a variadic function. This helps a bit with sanitizer's false negatives.

`FireAllClientsExcept` works with Exception as `nil` as well, which makes it work like the `:FireAllClients` method roblox normally offers. Alternatively, you may call `FireAllClients` for conveniance.

The "unreliable" variants of the methods denote that they're going through an `UnreliableRemoteEvent`.

Passing `nil` as sanitized arguments to `ConnectOnEventSanitized` is like calling `ConnectOnEvent`.

# License
The module is licensed under the MIT license.
