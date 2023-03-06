$EnvironmentsName = (Get-Content "$PSScriptRoot\environments.json" -Raw | ConvertFrom-Json).Environments

$PUMLContent = "@startuml environment" + "`n"
$PUMLContent += "!define AzurePuml https://raw.githubusercontent.com/plantuml-stdlib/Azure-PlantUML/release/2-2/dist" + "`n"
$PUMLContent += "!includeurl AzurePuml/AzureCommon.puml" + "`n"
$PUMLContent += "!includeurl AzurePuml/Networking/AzureVirtualNetwork.puml" + "`n"
$PUMLContent += "!includeurl AzurePuml/Compute/AzureVirtualMachine.puml" + "`n"
$PUMLContent += "!includeurl AzurePuml/Databases/AzureSqlServer.puml" + "`n"
$PUMLContent += "`n`n`n"

foreach($EnvName in $EnvironmentsName){
    $Environment = Get-Content "$PSScriptRoot\$EnvName.json" -Raw | ConvertFrom-Json
    $Resources = @()
    foreach($Module in $Environment.Modules){
        $ModuleKey = $Module | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name -First 1
        $ModuleValue = $Module.$ModuleKey
        switch ($ModuleValue.PSObject.Properties.Name) {
            {$_ -contains "AppServerSKU"} { 
                $Type = "AzureVirtualMachine"
                $Spec = $ModuleValue.AppServerSKU
                break;
            }
            {$_ -contains "HANADatabaseSKU"} { 
                $Type = "AzureSqlServer"
                $Spec = $ModuleValue.HANADatabaseSKU
                break;
            }
        }
        for ($i = 0; $i -lt $ModuleValue.InstanceCount; $i++) {
            $Resources += [PSCustomObject]@{
                Name = $ModuleValue.ModuleTemplate + "_" + $i
                Type = $Type
                Spec = $Spec

            }
        }
    }

    $PUMLContent += "AzureVirtualNetwork($EnvName, $EnvName, $($Environment.Network.NetworkIndex)){" + "`n"
    foreach($Resource in $Resources){
        $PUMLContent += "`t" + "$($Resource.Type)($($EnvName)_$($Resource.Name), $($Resource.Name), $($Resource.Spec))" + "`n"
    }
    $PUMLContent += "}" + "`n"
}

$PUMLContent += "@enduml"
Set-Content -Value $PUMLContent -Path "$PSScriptRoot\environments.puml"