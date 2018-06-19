<img src="https://cloudogu.com/images/dogus/nexus.png" alt="nexus logo" height="100px">


[![GitHub license](https://img.shields.io/github/license/cloudogu/nexus.svg)](https://github.com/cloudogu/nexus/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/cloudogu/nexus.svg)](https://github.com/cloudogu/nexus/releases)

# Nexus Repository OSS Dogu

## About this Dogu

**Name:** official/nexus

**Description:** [Nexus Repository OSS](https://www.sonatype.com/nexus-repository-oss) is a open source artifact repository with universal support for popular formats.

**Website:** https://www.sonatype.com/nexus-repository-oss

**Dependencies:** cas, nginx, postfix

## Installation Ecosystem
```
cesapp install official/nexus

cesapp start nexus
```

## Claim

The preconfigured nexus repositories can be changed by using [nexus-claim](https://github.com/cloudogu/nexus-claim).
First we have to create a model for our changes e.g.: [sample](https://github.com/cloudogu/nexus-claim/blob/develop/resources/nexus-initial-example.hcl). 
We could test our model by using the plan command against a running instance of nexus (note: do not forget to set credentials):

```bash
nexus-claim plan -i nexus-initial-example.hcl
```

If the output looks good, we could store our model in the registry. 
If we want to apply our model only once:

```bash
cat mymodel.hcl | etcdctl set /config/nexus/claim/once
```

Or we could apply our model on every start of nexus:

```bash
cat mymodel.hcl | etcdctl set /config/nexus/claim/always
```