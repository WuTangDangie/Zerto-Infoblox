param(
    [Parameter(HelpMessage="Changes the DNS records back to normal")]
    [switch]$failback = $False,
    [Parameter(Mandatory, HelpMessage="FQDN of the host record to change")]
    [string]$fqdn,
    [string]$operation,
    [string]$ZertoVPGName
)

# Define global variables
$ZertoChangeOpertions = @('Failover','FailoverBeforeCommit')
$sourcezvms = @('source-zvm-p01','source-zvm-p02')
$targetzvm = "target-zvm-p01"
$currentzvm = HOSTNAME.EXE
$protectedsite = '-mdc' # Main Data Center
$failoversite = '-dr' # Disaster Recovery

# Define a log file
$LogFile = "Zerto-DNS-Change-$ZertoVPGName.txt"

# Connect to Infoblox
$infobloxcred = Import-Clixml -Path C:\scripts\infoblox-cred.xml
Set-IBConfig -ProfileName 'mygrid' -WAPIHost 'ddigrid.example.com' -WAPIVersion 'latest' -Credential $infobloxcred -SkipCertificateCheck

# Define the failover function
function fail_over {
  # Get a copy of the protected site record
  $hostrecord = Get-IBObject -type record:host -Filters "name:=$fqdn"

  # Breakout hostname and domain
  $hostname = $hostrecord.name.Substring(0,$hostrecord.name.IndexOf('.'))
  $domainname = $hostrecord.name.Substring($hostrecord.name.IndexOf('.'))

  # Get a copy of the failover site record 
  $drrecord = Get-IBObject -type record:host -Filters "name:=$hostname$failoversite$domainname"
  
  # Check and make sure the host records exist then do stuff
  if (($hostrecord | Where-Object { $_.'_ref' -like 'record:host/*'}) -And ($drrecord | Where-Object { $_.'_ref' -like 'record:host/*' })) {
    # Append the name of the protected site record with -mdc
    $hostname_changed = "$hostname$protectedsite$domainname"
    $hostrecord.name = $hostname_changed

    # remove the read-only 'host' field from the nested 'record:host_ipv4addr' object
    $hostrecord.PSObject.Properties.Remove('ipv4addrs')

    # Save the result
    $hostrecord | Set-IBObject

    # Remove '-dr' from the failoversite record
    $drrecord.name = $fqdn

    # remove the read-only 'host' field from the nested 'record:host_ipv4addr' object
    $drrecord.PSObject.Properties.Remove('ipv4addrs')

    # Save the result
    $drrecord | Set-IBObject

    # Write results to log
    Add-Content $Logfile ((get-date -Format "MM/dd/yyyy HH:mm:ss")+" DNS record successfully failed over for $fqdn. Script triggered for VPG $ZertoVPGName based on Zerto $Operation")
  }

  else {
    # Write results to log
    Add-Content $Logfile ((get-date -Format "MM/dd/yyyy HH:mm:ss")+" Could NOT find DNS entry for either $fqdn or $hostname$failoversite$domainname. Script triggered for VPG $ZertoVPGName based on Zerto $Operation")
  }
}

# Define the failback function
function fail_back {
  # Get a copy of the failover site record
  $hostrecord = Get-IBObject -type record:host -Filters "name:=$fqdn"

  # Breakout hostname and domain
  $hostname = $hostrecord.name.Substring(0,$hostrecord.name.IndexOf('.'))
  $domainname = $hostrecord.name.Substring($hostrecord.name.IndexOf('.'))

  # Get a copy of the protected site record 
  $mdcrecord = Get-IBObject -type record:host -Filters "name:=$hostname$protectedsite$domainname"
  
  # Check and make sure the host records exist then do stuff
  if (($hostrecord | Where-Object { $_.'_ref' -like 'record:host/*'}) -and ($mdcrecord | Where-Object { $_.'_ref' -like 'record:host/*' })) {
    
    # Append the name of the failover site record with -dr
    $hostname_changed = "$hostname$failoversite$domainname"
    $hostrecord.name = $hostname_changed

    # remove the read-only 'host' field from the nested 'record:host_ipv4addr' object
    $hostrecord.PSObject.Properties.Remove('ipv4addrs')

    # Save the result
    $hostrecord | Set-IBObject

    # Remove '-mdc' from the protected site record
    $mdcrecord.name = $fqdn

    # remove the read-only 'host' field from the nested 'record:host_ipv4addr' object
    $mdcrecord.PSObject.Properties.Remove('ipv4addrs')

    # Save the result
    $mdcrecord | Set-IBObject

    # Write results to log
    Add-Content $Logfile ((get-date -Format "MM/dd/yyyy HH:mm:ss")+" DNS record successfully failed back for $fqdn. Script triggered for VPG $ZertoVPGName based on Zerto $Operation")
  }

  else {
    # Write results to log
    Add-Content $Logfile ((get-date -Format "MM/dd/yyyy HH:mm:ss")+" Could NOT find DNS entry for either $fqdn or $hostname$failoversite$domainname. Script triggered for VPG $ZertoVPGName based on Zerto $Operation")
  }
}

# Logic to determine which function to call
if ($failback -eq $true) {
  fail_back
}

elseif ($operation -eq "FailoverRollback") {
  fail_back
}

elseif (($currentzvm -eq $targetzvm) -and ($ZertoChangeOpertions -contains $operation)) {
  fail_over
}

elseif (($sourcezvms -contains $currentzvm) -and ($ZertoChangeOpertions -contains $operation)) 
{
  fail_back
}

else {
  Add-Content $Logfile ((get-date -Format "MM/dd/yyyy HH:mm:ss")+" No changes made to DNS for VPG $ZertoVPGName based on Zerto $Operation")
}

