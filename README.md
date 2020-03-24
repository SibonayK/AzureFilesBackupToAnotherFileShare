# AzCopy based Azure Files Backup To Another FileShare

Many Azure Files customers who service, choose to implement a backup solution to another file share to be able to recover from unintended changes or deletions to their file systems. Azure Bakup solution today, is snapshot based. Which means that it will store data in same file share. This solution will enable you to create your own easy backup solution that automatically creates incremental backups of an Azure Files system on a customer-defined schedule. This webpage provides an overview of the Azure Files AzCopy based backup solution's design and functionality.


## Solution overview

This solution utilizes AzCopy - an purpose-built tool optimized for Azure Storage data movement needs. AzCopy is a command-line utility that you can use to copy blobs or files to or from a storage account. This solution copies snapshots from one file share to the other to ensure fast backups with minimal space overhead. Only changes will be at copied every backup. The copy happens on server side ensuring that it is fast and has minimal egress. This solution utilizes familiar technologies like Windows task Scheduler and Powershell making it easy to maintain without spending time on ramp-up.

![solution overview](./diyazfilesbackup.jpg)

## Advantages
### Space/Cost/Time efficiency

Share snapshots are incremental in nature. Only the data that has changed after your most recent share snapshot is saved. This minimizes the time required to create the share snapshot and saves on storage costs. Any write operation to the object or property or metadata update operation is counted toward "changed content" and is stored in the share snapshot.

### Familiar tooling

Powershell, task scheduler and AzCopy are no strangers to most. This solution just uses these to orchestrate your DIY backup.

## Limitations
* There is no exhausive perf testing done and this solution only works on low churn datasets.
* There is no CSS support on this solution.

## Step by step instruction

* Step 1 - Create a Windows Server VM and download the contents of this repo to a permanent location
* Step 2 - Create Azure AD application and service principal with serviceprincipl.ps1
* Step 3 - Create a new task scheduler task with backup.ps1
* Step 4 - Monitor history in Task scheduler

## Contributions
* This is an open-source community maintained project and we welcome direct contributions to this project.
