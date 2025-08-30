--!native
local module = {};
local Network = require(script.Parent.Network);

local function TestAssert(Condition, Message)
  if Condition then
    print(Message.."OK");
  else
    warn(Message.."FAIL");
  end;
end;

local function DummyFunction() end;
local DummySanitization = {Arguments = {{Type = "string", Nullable = false}}};

function module.CheckHealth()
  local Fail_BindName           = pcall(Network.ConnectBinding, 123, DummyFunction);
  local Fail_BindFunction       = pcall(Network.ConnectBinding, "Fail_BindFunction", "NotAFunction");

  local Fail_BindRemoveID       = pcall(function()
    Network.ConnectBinding("Fail_BindRemoveID", DummyFunction);
    Network.RemoveBinding("Fail_BindRemoveID", "NotANumber");
  end);
  
  local Fail_BindRemoveOOB      = pcall(function()
    Network.ConnectBinding("Fail_BindRemoveOOB", DummyFunction);
    Network.RemoveBinding("Fail_BindRemoveOOB", 3);
  end);

  local Fail_BindRemove                 = pcall(Network.RemoveAllBindings, "NotExisting");
  local Fail_BindRemoveAll              = pcall(Network.RemoveBinding, "NotExisting", 1);
  local Fail_CallBinding                = pcall(Network.CallBinding, nil, "NotExisting");

  local Success_BindName                = pcall(Network.ConnectBinding, "Success_BindName", DummyFunction);
  
  local Success_BindRemoveID            = pcall(function()
    local ID = Network.ConnectBinding("Success_BindRemoveID", DummyFunction);
    Network.RemoveBinding("Success_BindRemoveID", ID);
  end);
  
  local Success_BindRemoveAll           = pcall(function()
    Network.ConnectBinding("Success_BindRemove", DummyFunction);
    Network.RemoveAllBindings("Success_BindRemove");
  end);
  
  local Success_CallBinding             = pcall(function()
    Network.ConnectBinding("Success_BindCallBinding", DummyFunction);
    Network:CallBinding("Success_BindCallBinding");
  end);
  
  local Fail_EventName                  = pcall(Network.ConnectOnEvent, 123, DummyFunction);
  local Fail_EventFunction              = pcall(Network.ConnectOnEvent, "Fail_EventFunction", "NotAFunction");
  
  local Fail_EventDisconnectAll         = pcall(Network.DisconnectAll, "NotExisting");
  local Fail_EventDisconnectID          = pcall(function()
    Network.ConnectOnEvent("Fail_EventDisconnectID", DummyFunction);
    Network.Disconnect("Fail_EventDisconnectID", "NotANumber");
  end);
  
  local Fail_EventConnectSanitizedName  = pcall(Network.ConnectOnEventSanitized, 123, DummySanitization, DummyFunction);
  local Fail_EventConnectSanitizedTable = pcall(Network.ConnectOnEventSanitized, "Fail_EventConnectSanitizedTable", "NotATable", DummyFunction);
  local Fail_EventConnectSanitizedFunc  = pcall(Network.ConnectOnEventSanitized, "Fail_EventConnectSanitizedFunc", DummySanitization, "NotAFunction");
  
  local Fail_InvokeConnectName          = pcall(Network.ConnectOnInvoke, 123, DummyFunction);
  local Fail_InvokeConnectFunc          = pcall(Network.ConnectOnInvoke, "Fail_InvokeConnectFunc", "NotAFunction");
  
  local Fail_EventDisconnectOOB         = pcall(function()
    Network.ConnectOnEvent("Fail_EventDisconnectOOB", DummyFunction);
    Network.Disconnect("Fail_EventDisconnectOOB", 2);
  end);
  
  local Success_InvokeConnectName       = pcall(Network.ConnectOnInvoke, "Success_InvokeConnectName", DummyFunction);
  
  local Success_EventDisconnectAll      = pcall(function()
    Network.ConnectOnEvent("Success_EventDisconnectAll", DummyFunction);
    Network.DisconnectAll("Success_EventDisconnectAll");
  end);
  
  local Success_EventDisconnectID       = pcall(function()
    local ID = Network.ConnectOnEvent("Fail_EventDisconnectID", DummyFunction);
    Network.Disconnect("Fail_EventDisconnectID", ID);
  end);
  
  local Success_EventConnectSanitized   = pcall(Network.ConnectOnEventSanitized, "Success_EventConnectSanitized", DummySanitization, DummyFunction);
  local Success_EventName               = pcall(Network.ConnectOnEvent, "Success_EventName", DummyFunction);
  
  print("======== BINDINGS ========");
  print("Errors:");
  TestAssert(not Fail_BindName, " BindName error: ");
  TestAssert(not Fail_BindFunction, " BindFunction error: ");
  TestAssert(not Fail_BindRemove, " BindRemove error: ");
  TestAssert(not Fail_BindRemoveID, " BindRemoveID error: ");
  TestAssert(not Fail_BindRemoveAll, " BindRemoveAll error: ");
  TestAssert(not Fail_CallBinding, " CallBinding error: ");
  TestAssert(not Fail_BindRemoveOOB, " BindRemoveOOB error: ");
  
  print("Normal:");
  TestAssert(Success_BindName, " BindName success: ");
  TestAssert(Success_BindRemoveID, " BindRemoveID succes: ");
  TestAssert(Success_BindRemoveAll, " BindRemoveAll success: ");
  TestAssert(Success_CallBinding, " CallBinding success: ");
  
  print("======== EVENTS ========");
  print("Errors:");
  TestAssert(not Fail_EventName, " EventName error: ");
  TestAssert(not Fail_EventFunction, " EventFunction error: ");
  TestAssert(not Fail_EventDisconnectAll, " EventDisconnectAll error: ");
  TestAssert(not Fail_EventDisconnectID, " EventDisconnectID error: ");
  TestAssert(not Fail_EventDisconnectOOB, " EventDisconnectOOB error: ");
  TestAssert(not Fail_EventConnectSanitizedFunc, " EventConnectSanitizedFunc error: ");
  TestAssert(not Fail_EventConnectSanitizedName, " EventConnectSanitizedName error: ");
  TestAssert(not Fail_EventConnectSanitizedTable, " EventConnectSanitizedTable error: ");
  TestAssert(not Fail_InvokeConnectName, " InvokeConnectName error: ");
  TestAssert(not Fail_InvokeConnectFunc, " InvokeConnectFunc error: ");
  
  print("Normal:");
  TestAssert(Success_EventDisconnectAll, " EventDisconnectAll success: ");
  TestAssert(Success_EventDisconnectID, " EventDisconnectID success: ");
  TestAssert(Success_EventName, " EventName success: ");
  TestAssert(Success_EventConnectSanitized, " EventConnectSanitized success: ");
  TestAssert(Success_InvokeConnectName, "InvokeConnectName success: ");
end;

return module;
