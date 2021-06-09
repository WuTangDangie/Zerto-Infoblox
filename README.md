# Zerto-Infoblox

I wrote these scripts to help automate DNS changes for disaster recovery. They assume you have two DNS records:

A main dataceter record (the one that is in use before the disaster), and a DR record (used to reserve an IP at the disaster recovery site).

Example:

Main datacenter record = deej-test.example.com (points to the everyday IP that it uses at the main site)

DR record = deej-test-dr.example.com (points to the DR site IP)

In the event of a disaster the scripts change the main datacenter record to deej-test-mdc.example.com, and remove the "-dr" from the dr record (so that clients continue to hit the active server). The failback option reverses this.

Please see the readme text file for examples and more details.

These scripts require the Posh-IBWAPI PowerShell module to interact with Infoblox (https://github.com/rmbolger/Posh-IBWAPI). Big thanks to rmbolger for creating the module and for helping me use it!

I stole the logging peices from https://github.com/sammcgeown/Change-HostPasswords/blob/master/Change-HostPasswords.ps1.

Some of the Zerto logic was taken from here: http://s3.amazonaws.com/zertodownload_docs/Latest/Zerto%20Virtual%20Replication%20Zerto%20Virtual%20Manager%20(ZVM)%20-%20vSphere%20Online%20Help/Content/AdminVC/Creating_a_Script.htm

