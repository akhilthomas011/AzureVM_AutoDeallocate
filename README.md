# Auto Deallocate Azure VMs

## Description
 This repository contains scripts that automatically deallocate a VM when it is not in active use. The scripts are completely native and do not rely on any third-party sources.
 
 
 ## How it works
 The approach used by these scripts differs from other methods, such as using DevTestLabs or Azure Automation to schedule the start/stop of the VM. These methods have the disadvantage of not considering whether the user is actively using the machine and requiring the machine to wait until the scheduled time to deallocate.

In contrast, the script in this repository creates a scheduled task that checks for active user sessions on the virtual machine at a specified interval. It also checks if the virtual machine has exceeded the maximum idle standby time. If both conditions are met, the scheduled task deallocates the virtual machine using the permissions granted to the System Assigned Managed Identity, from within the VM.

## Prerequisites

- The Virtual Machine OS should be **`Windows`**
- The Virtual Machine should have a `System Assigned Managed Identity` assigned to it with `Virtual Machine Contributor` privileges.
- Optionally, the Virtual Machine should have the below tags with the values you prefer:
  | Tag | Default Value | Purpose | Type | Usage |
  | - | - | - | - | - |
  |autodeallocate_Enabled|`true` | To Enable/Disable the auto deallocation | *Boolean* | **`true`**/**`false`** : Set to **`true`** to enable, **`false`** to disable
  |autodeallocate_minSessionIdleTime| `10` | The maximum threshold idle time of the session (minutes) after which the session is considered to be inactive | *Int* | Any value from 1 to 1440 |
  |autodeallocate_minStandbyTime| `30` | The minimum standby time for the machine after a start before which it is not considered for deallocation | *Int* | Any value from 1 to 1440 |
  |autodeallocate_statusCheckInterval| `PT5M` | The interval at which the status of session in the Virtual Machine is checked.
  |autodeallocate_ForceShutDown| `false` |




