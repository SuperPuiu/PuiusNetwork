# PuiusNetwork
ROBLOX networking module.

# API
Synopsys:
```luau
void Network:FireServer(Name: string, ...);
void Network:FireClient(Player: Player, Name: string, ...);
any Network:InvokeServer(Name: string, ...);
any Network:InvokeClient(Player: Player, Name: string, ...);

void Network:FireClientToClient(Player: Player, Name: string, ...);
void Network:FireAllClientsExcept(Exception: Player, Name: string, ...);

int Network.ConnectOnEvent(Name: string, Func: any);
void Network.ConnectOnInvoke(Name: string, Func: any);

void Network.DisconnectAll(Name: string);
void Network.Disconnect(Name: string, ID: number);
```

# Notes
`FileClientToClient` works only after the module was required on server. Aformentioned method should also NOT be used to replicate something accross ALL clients.

To use `FireClientToClient` make sure to delete the `"-disable-puius-bridge"` string from the `Flags` table.

`FireAllClientsExcept` works with Exception as `nil` as well, which makes it work like the `:FireAllClients` method roblox normally offers.

# License
The module is licensed under the MIT license.
