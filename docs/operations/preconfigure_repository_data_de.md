## Bereitstellung von Assets in vorkonfigurierten Repositories

Es können Dateien in vorkonfigurierten [Nexus-Repositories](preconfigure_repositories_de.md) ausgebracht werden.
Der Mechanismus wird durch den Konfigurationsschlüssel `repository_component_uploads` gestartet.
Files können dabei nur aus dem Volume [`repository_component_uploads`](../../dogu.json) verwendet werden.
Sie müssen diese also vor dem Start des Dogus in das Volume ablegen.
In Multinode-Umgebung müssen die Files über den Mechanismus [`additionalMounts`](https://github.com/cloudogu/k8s-dogu-operator/blob/develop/docs/operations/additional_dogu_mounts_de.md) abgelegt werden.

Allgemein verwendet das Dogu, um die Dateien in die Repositorys zu kopieren, die [Nexus Components REST API](https://help.sonatype.com/en/components-api.html).
Die Konfiguration `repository_component_uploads` richtet sich nach der offiziellen API.
Ein Upload muss also genau die Keys der Formularfelder enthalten. Außerdem den Namen des Ziel-Repositorys.

### Beispiel

#### Offizieller Nexus API Call

```bash
curl -v -u admin:admin123 -X POST 'http://nexus:8081/service/rest/v1/components?repository=raw_repository_name' \
 -F raw.directory=exampleDirectory -F raw.asset1=@/absolute/path/to/the/local/file/pub.key -F raw.assetN.filename=filename
```

#### Dogu-Konfiguration `repository_component_uploads`

```json
"[{\"repository\": \"raw_repository_name\" ,\"raw.directory\": \"exampleDirectory\", \"raw.asset1\": \"@/absolute/path/to/the/local/file/pub.key\", \"raw.asset1.filename\": \"filename\"}]"
```

> Zu beachten: Um Datenkonsistenz zu gewährleisten, speichert das Dogu alle Component IDs, die von den verwendeten technischen User angelegt wurden.
> Bei einem Neustart des Dogus werden diese Components gelöscht und wieder neu angelegt.