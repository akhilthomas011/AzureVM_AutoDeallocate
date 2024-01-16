# Auto Deallocate Azure VMs

## Description
 This repository contains scripts that automatically deallocate a VM when it is not in active use. The scripts are completely native and do not rely on any third-party sources.
 
 
 ## How it works
 The approach used by these scripts differs from other methods, such as using DevTestLabs or Azure Automation to schedule the start/stop of the VM. These methods have the disadvantage of not considering whether the user is actively using the machine and requiring the machine to wait until the scheduled time to deallocate.

In contrast, the script in this repository creates a scheduled task that checks for active user sessions on the virtual machine at a specified interval. It also checks if the virtual machine has exceeded the maximum idle standby time. If both conditions are met, the scheduled task deallocates the virtual machine using the permissions granted to the System Assigned Managed Identity, from within the VM.




