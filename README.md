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

void Network:FireClientToClient(Player: Player, Name: string, ...);
void Network:FireAllClientsExcept(Exception: Player, Name: string, ...);
void Network:FireAllClientsExceptUnreliable(Exception: Player, Name: string, ...);

void Network:CallBinding(Name: string, ...);

int  Network.ConnectOnEvent(Name: string, Func: any);
int  Network.ConnectBinding(Name: string, Func: any);
void Network.ConnectOnInvoke(Name: string, Func: any);

void Network.RemoveBinding(Name: string, ID: number);
void Network.RemoveAllBindings(Name: string);
void Network.DisconnectAll(Name: string);
void Network.Disconnect(Name: string, ID: number);
```

# Notes
`FileClientToClient` works only after the module was required on server. Aformentioned method should also NOT be used to replicate something accross ALL clients. If you want to fire to all clients from a client, use the specialized `FireAllClientsExcept` variant from the client. Or even better, don't use either of those functions due to their security problems.

To use `FireClientToClient` and its family of functions make sure to delete the `"-disable-puius-bridge"` string from the `Flags` table.

`FireAllClientsExcept` works with Exception as `nil` as well, which makes it work like the `:FireAllClients` method roblox normally offers.

The "unreliable" variants of the methods denote that they're going through an `UnreliableRemoteEvent`.

# License
The module is licensed under the MIT license.
