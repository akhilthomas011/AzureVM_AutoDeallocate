@description('Specifies the role definition ID used in the role assignment.')
param roleDefinitionID string

@description('Specifies the principal ID assigned to the role.')
param principalId string

@description('Name of the VM for which role should be assigned.')
param vmName string

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: vmName
}

var roleAssignmentName = guid(principalId, roleDefinitionID, resourceGroup().id)
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  scope: vm
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
    principalId: principalId
  }
}
