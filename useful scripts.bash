az group create --name adventure-works-rg --location westeurope

az network vnet create \
  --name aw-vnet \
  --resource-group adventure-works-rg \
  --location westeurope \
  --address-prefix 10.0.0.0/16 \
  --subnet-name aw-gateway-subnet \
  --subnet-prefix 10.0.0.0/24
  
az network vnet subnet create \
  --name aw-vm-subnet \
  --resource-group adventure-works-rg \
  --vnet-name aw-vnet \
  --address-prefix 10.0.1.0/24
  
az network public-ip create \
  --resource-group adventure-works-rg \
  --name aw-admin-ip
  
az network public-ip create \
  --resource-group adventure-works-rg \
  --name aw-gateway-ip

  

New-AzureRmVm `
    -ResourceGroupName adventure-works-rg `
    -Name "aw-vm-sql" `
    -ImageName "MicrosoftSQLServer:SQL2016SP1-WS2016:Enterprise:latest" `
    -Location westeurope `
    -VirtualNetworkName aw-vnet `
    -SubnetName aw-vm-subnet `
    -SecurityGroupName "admin" `
    -PublicIpAddressName aw-admin-ip `
    -OpenPorts 3389,1401 
  
Set-AzureRmVMSqlServerExtension `
   -ResourceGroupName adventure-works-rg  `
   -VMName aw-vm-sql `
   -Name "SQLExtension" `
   -Location westeurope 
   
New-AzureRmVm `
    -ResourceGroupName adventure-works-rg `
    -Name "aw-vm-app1" `
    -Location westeurope `
    -VirtualNetworkName aw-vnet `
    -SubnetName aw-vm-subnet `
    -SecurityGroupName "admin" `
	-PublicIpAddressName aw-gateway-ip
    -OpenPorts 80,3389 
	
Set-AzureRmVMExtension `
  -ResourceGroupName adventure-works-rg `
  -ExtensionName IIS `
  -VMName aw-vm-app1 `
  -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension `
  -TypeHandlerVersion 1.4 `
  -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
  -Location westeurope
  
  
az network application-gateway create \
  --name aw-app-gateway \
  --location westeurope \
  --resource-group adventure-works-rg \
  --vnet-name aw-vnet \
  --subnet aw-gateway-subnet \
  --capacity 2 \
  --sku Standard_Medium \
  --http-settings-cookie-based-affinity Disabled \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --public-ip-address aw-gateway-ip
  
az appservice plan create --name adventure-plan --resource-group adventure-works-rg --sku S1 --is-linux


