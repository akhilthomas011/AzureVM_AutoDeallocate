param location string
param adminUsername string
@secure()
param adminPassword string
param imageReference object
param osDisk object
param vmSize string
param newOrExistingVirtualNetwork string

module virtualMachine './modules/virtual-machine/main.json' = {
  name: '${uniqueString(deployment().name, location)}-test-cvmwinmin'
  params: {
    // Required parameters
    adminUsername: adminUsername
    imageReference: imageReference
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: '<subnetResourceId>'
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: osDisk
    osType: 'Windows'
    vmSize: vmSize
    // Non-required parameters
    adminPassword: adminPassword
    extensionCustomScriptConfig: {
      enabled: true
      fileData: [
        {
          storageAccountId: '<storageAccountId>'
          uri: '<uri>'
        }
      ]
      tags: {
        Environment: 'Non-Prod'
        'hidden-title': 'This is visible in the resource name'
        Role: 'DeploymentValidation'
      }
    }
    managedIdentities: {
      systemAssigned: true
    }
    tags: {
      autodeallocate_minSessionIdleTime: '10'
      autodeallocate_minStandbyTime: '10'
      autodeallocate_statusCheckInterval: 'PT5M'
    }
  }
}
