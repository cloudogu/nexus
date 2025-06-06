## Deployment of assets in preconfigured repositories

Files can be deployed in preconfigured [Nexus repositories](preconfigure_repositories_en.md).
The mechanism is started by the configuration key `repository_component_uploads`.
Files can only be used from the volume [`repository_component_uploads`](../../dogu.json).
You must therefore store these in the volume before starting Dogus.
In a multinode environment, the files must be stored using the [`additionalMounts`](https://github.com/cloudogu/k8s-dogu-operator/blob/develop/docs/operations/additional_dogu_mounts_de.md) mechanism.

In general, the Dogu uses the [Nexus Components REST API](https://help.sonatype.com/en/components-api.html) to copy the files to the repositories.
The configuration `repository_component_uploads` is based on the official API.
An upload must therefore contain exactly the keys of the form fields. Also, the name of the target repository.

### Example

#### Official Nexus API call

```bash
curl -v -u admin:admin123 -X POST 'http://nexus:8081/service/rest/v1/components?repository=raw_repository_name' \
 -F raw.directory=exampleDirectory -F raw.asset1=@/absolute/path/to/the/local/file/pub.key -F raw.assetN.filename=filename
```

#### Dogu configuration `repository_component_uploads`

```json
"[{\"repository\": \"raw_repository_name\" ,\"raw.directory\": \"exampleDirectory\", \"raw.asset1\": \"@/absolute/path/to/the/local/file/pub.key\", \"raw.asset1.filename\": \"filename\"}]"
```

> Please note: To ensure data consistency, the Dogu saves all component IDs created by the technical users used.
> When the dogu is restarted, these components are deleted and recreated.
