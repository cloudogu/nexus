## Verwenden Sie nexus-claim, um die Repositories vorzukonfigurieren

Die vorkonfigurierten Nexus-Repositories können mit [nexus-claim](https://github.com/cloudogu/nexus-claim) geändert werden.
Zuerst müssen wir ein Model für unsere Änderungen erstellen, z.B.: [sample](https://raw.githubusercontent.com/cloudogu/nexus-claim/develop/resources/nexus3/nexus3-initial-example.hcl). 
Wir können unser Model testen, indem wir den Befehl plan gegen eine laufende Instanz von Nexus verwenden (Hinweis: Vergessen Sie nicht, die Anmeldedaten zu setzen):

```bash
nexus-claim plan -i nexus3-initial-example.hcl
```

Wenn die Ausgabe gut aussieht, können wir unser Model in der Registry speichern. 
Wenn wir unser Model nur einmal anwenden wollen:

```bash
cat mymodel.hcl | etcdctl set /config/nexus/claim/once
```

Oder wir könnten unser Model bei jedem Start von Nexus anwenden:

```bash
cat mymodel.hcl | etcdctl set /config/nexus/claim/always
```
