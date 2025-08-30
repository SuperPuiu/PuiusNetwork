# PuiusNetwork
ROBLOX networking module.

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

void Network:CallBinding(Name: string, ...);

int  Network.ConnectOnEvent(Name: string, Func: any);
int  Network.ConnectOnEventSanitized(Name: string, SanitizerTable: table OR nil, Func: any);
int  Network.ConnectBinding(Name: string, Func: any);
void Network.ConnectOnInvoke(Name: string, Func: any);

void Network.ModifyConnectionSanitizer(Connection: string, ID: number, Sanitizer: table);
bool Network.ModifyConnectionConfiguration(Connection: string, ID: number, Entry: string, State: any);

void Network.RemoveBinding(Name: string, ID: number);
void Network.RemoveAllBindings(Name: string);
void Network.DisconnectAll(Name: string);
void Network.Disconnect(Name: string, ID: number);
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

Although not required, it is recommended that you set Variadic bool to true if your function is a variadic function. This hels a bit with sanitizer's false negatives.

`FireAllClientsExcept` works with Exception as `nil` as well, which makes it work like the `:FireAllClients` method roblox normally offers.

The "unreliable" variants of the methods denote that they're going through an `UnreliableRemoteEvent`.

Passing `nil` as sanitized arguments to `ConnectOnEventSanitized` is like calling `ConnectOnEvent`.

# License
The module is licensed under the MIT license.
