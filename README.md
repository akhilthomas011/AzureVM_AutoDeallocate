# Auto Deallocate Azure VMs

## Description
 This repository contains scripts that automatically deallocate a VM when it is not in active use. The scripts are completely native and do not rely on any third-party sources.
 
 
 ## Approach
 The approach used by these scripts differs from other methods, such as using DevTestLabs or Azure Automation to schedule the start/stop of the VM. These methods have the disadvantage of not considering whether the user is actively using the machine and requiring the machine to wait until the scheduled time to deallocate.

In contrast, the script in this repository creates a scheduled task that checks for active user sessions on the virtual machine at a specified interval. It also checks if the virtual machine has exceeded the maximum idle standby time. If both conditions are met, the scheduled task deallocates the virtual machine using the permissions granted to the System Assigned Managed Identity, from within the VM.

## Prerequisites

- The Virtual Machine OS should be **`Windows`**
- The Virtual Machine should have a `System Assigned Managed Identity` assigned to it with `Virtual Machine Contributor` privileges.
- Optionally, the Virtual Machine can have the below tags with the values you prefer. If the tag is not set, the default value is applied:
  | Tag | Default Value | Purpose | Type | Usage |
  | - | - | - | - | - |
  |autodeallocate_Enabled|`true` | To Enable/Disable the auto deallocation | *Boolean* | **`true`**/**`false`** : Set to **`true`** to enable, **`false`** to disable |
  |autodeallocate_minSessionIdleTime| `10` | The maximum threshold idle time of the session (minutes) after which the session is considered to be inactive | *Int* | Any value from 1 to 1440 |
  |autodeallocate_minStandbyTime| `30` | The minimum standby time for the machine after a start before which it is not considered for deallocation | *Int* | Any value from 1 to 1440 |
  |autodeallocate_statusCheckInterval| `PT5M` | The interval at which the status of session in the Virtual Machine is checked. Value should be lower than *minSessionIdleTime* & *minStandbyTime*. | *TimeInterval* | Any time interval in the format *`P<days>DT<hours>H<minutes>M<seconds>S`* |
  |autodeallocate_ForceShutDown| `false` | Enable or Disable the force shutdown feature, which will deallocate the VM even when a user is connected, if the user surpasses the maximum idle time.| *Boolean* | **`true`**/**`false`** : Set to **`true`** to enable, **`false`** to disable |

## How it works

The solution can be implemented in multiple ways:
- Run the script independently on existing VMs
- Run the script as a custom script extension on existing VMs
- Deploy a new VM using the custom script extension using *Azure CLI*/*ARM*/*Bicep*/*Terraform* (Sample ARM & Bicep is given)

### Run the script individually

To run the script individually on existing virtual machines;
1. Assign a `System Assigned Managed Identity` to the virtual machine with `Virtual Machine Contributor` privileges.
2. Add the tags (optional) to the virtual machine described in the prerequisites sction.
3. Copy the **Scripts** folder to any permanent drive folders (e.g. *'C:/AutoDeallocation'*)
4. Open Powershell as an Administrator
5. Run the **setup.ps1** powershell script under **Scripts** folder.
### Deploy as custom script extension

To deploy a new virtual machine with Auto Deallocation capabilities, you can use the **setup.ps1** powershell script as custom script extension. A sample Bicep file **main.bicep** and an ARM template **main.json** has been provided in the root folder.

> Note: The Bicep and ARM template is intended only for demonstration purposes and shouldn't be used as such, since it does not meet the *`Secure by Default`* Microsoft standards.

The main components of the Bicep/ARM are:
1. Creating a Virtual Machine
2. Assigning a `System Assigned Managed Identity` to the virtual machine.
3. Assigning `Virtual Machine Contributor` role to the Managed Identity in the scope of the deployed virtual machine
4. Adding the tags to the virtual machine
5. Adding a custom script extension to run the **setup.ps1** powershell script under **Scripts** folder.
