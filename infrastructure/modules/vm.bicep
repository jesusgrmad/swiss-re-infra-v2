// ============================================================================
// Virtual Machine Module - Swiss Re Infrastructure
// Ubuntu 22.04 LTS with progressive configuration per version
// ============================================================================

@description('Azure region for resources')
param location string

@description('VM name')
param vmName string

@description('Subnet ID for VM')
param subnetId string

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('NSG ID')
param nsgId string

@description('Deployment version')
param deploymentVersion int

@description('Key Vault name for Version 3')
param keyVaultName string = ''

@description('Storage Account name for Version 3')
param storageAccountName string = ''

@description('Log Analytics Workspace ID for Version 3')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags')
param tags object

// ============================================================================
// VARIABLES
// ============================================================================

var vmSize = {
  dev: 'Standard_B2s'
  test: 'Standard_B2s'
  prod: 'Standard_D2s_v3'
}

var environment = tags.Environment
var selectedVmSize = vmSize[environment]
var computerName = 'swissre-${environment}'

// Cloud-init configuration per version
var cloudInitScript = loadFileAsBase64('../../scripts/cloud-init-v${deploymentVersion}.yaml')

// ============================================================================
// NETWORK INTERFACE
// ============================================================================

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'nic-${vmName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAddress: '10.0.3.4'
          privateIPAllocationMethod: 'Static'
          primary: true
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
    enableAcceleratedNetworking: environment == 'prod'
    enableIPForwarding: false
  }
}

// ============================================================================
// VIRTUAL MACHINE
// ============================================================================

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  tags: tags
  identity: deploymentVersion >= 3 ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    hardwareProfile: {
      vmSize: selectedVmSize
    }
    storageProfile: {
      osDisk: {
        name: 'osdisk-${vmName}'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: environment == 'prod' ? 'Premium_LRS' : 'Standard_LRS'
        }
        diskSizeGB: 30
        caching: 'ReadWrite'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      dataDisks: deploymentVersion >= 3 ? [
        {
          lun: 0
          name: 'datadisk-${vmName}'
          createOption: 'Empty'
          diskSizeGB: 128
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          caching: 'ReadOnly'
        }
      ] : []
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: cloudInitScript
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          assessmentMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    availabilitySet: null
    licenseType: null
  }
}

// ============================================================================
// VM EXTENSIONS
// ============================================================================

// Azure Monitor Agent (Version 3)
resource azureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = if (deploymentVersion >= 3) {
  parent: vm
  name: 'AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output vmName string = vm.name
output vmId string = vm.id
output privateIpAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output principalId string = deploymentVersion >= 3 ? vm.identity.principalId : ''
