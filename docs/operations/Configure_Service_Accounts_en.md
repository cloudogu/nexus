# Configuration of service accounts

Nexus offers the possibility to create service accounts.

## Configuration

To do this, an entry must be made in the `ServiceAccount` section of `dogu.json` in the target dogu:

```json
{
  "Type": "nexus",
  "Params": [
    "fullAccessRepository=myRepositoryData",
    "permissions=nx-repository-admin-maven2-maven-public-*,nx-repository-view-nuget-nuget-hosted-*"
  ]
}
```

Both parameters (`params`) are optional and have the following function:

**fullAccessRepository** - The account being created will have full access to a newly created repository in Nexus.
The name of the repository is written to the `params` along with the parameter.
From the above example configuration with `fullAccessRepository=myRepositoryData` a repository with the
name `myRepositoryData` is created.

**permissions** - defines a set of Nexus permissions which will be given to the creating service account.
From the above example `permissions=nx-repository-admin-maven2-maven-public-*,nx-repository-view-nuget-nuget-hosted-*`
the service account will be given the Nexus permission: `nx-repository-admin-maven2-maven-public-*` and `nx-repository-view-nuget-nuget-hosted-*`.

## Usage

The service account user data is stored in the `<dogu>-config` secret.
The following keys are created:

**sa-nexus/username** - the username of the service account. This key is always created.

**sa-nexus/password** - the password of the service account. This key is always created.

**sa-nexus/repository** - the name of the repository configured by the `fullAccessRepository=repoName` parameter. 
This key is created only if the SA was configured with the `fullAccessRepository` parameter.