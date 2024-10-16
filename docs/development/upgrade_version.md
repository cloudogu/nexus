### Upgrade der Nexus-Version

Wenn die Nexus-Version geupgraded wird muss zusätzlich die passende Version vom Nexus Repository Database Migrator angepasst werden. 
Die passende Version findet sich [hier](https://help.sonatype.com/en/download.html#download-sonatype-nexus-repository-database-migrator). 
Wenn die Version vom Database Migrator nicht passt, dann kann kein Upgrade von einer pre 3.70.2-Version auf eine höhere Version durchgeführt werden.

#### Dockerfile
```NEXUS_DB_MIGRATOR_VERSION=3.73.0-3```