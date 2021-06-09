README
There are two scripts used to change DNS records in a DR event.

infoblox-dns-dr.ps1 is used to manually change the records.
zerto-infoblox-dns-change.ps1 is used by Zerto to automatically change the records when certain types of operations in Zerto are triggered.

Failover - This renames deej-test.example.com to deej-test-mdc.example.com, and renames deej-test-dr.example.com to deej-test.example.com.
Failback - Reverses these operations.


***** Manual *****
To use the script to switch the DNS record to the DR host, run:
infoblox-dns-dr.ps1 -fqdn <FQDN of host>

Example:
infoblox-dns-dr.ps1 -fqdn deej-test.example.com


To use the script to restore the original host, run:
infoblox-dns-dr.ps1 -fqdn <FQDN of host> -failback

Example:
infoblox-dns-dr.ps1 -fqdn deej-test.example.com -failback
******************





*** Automated ***
zerto-infoblox-dns-change.ps1 takes in additional arguments from Zerto.
The value for the arguments is provided by calling an environmental variable that gets created by zerto (see example).

The following list provides possible values for -operation and what the script will do in each case:

Test - No action taken
Move - No action taken
MoveBeforeCommit - No action taken
MoveRollback - No action taken
Failover - Failover
FailoverBeforeCommit - Failover
FailoverRollback - Failback

Example:
zerto-infoblox-dns-change.ps1 -fqdn "deej-test.example.com" -operation %ZertoOperation% -ZertoVPGName %ZertoVPGName%
*****************
