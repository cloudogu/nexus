<img src="https://cloudogu.com/images/dogus/nexus.png" alt="nexus logo" height="100px">


[![GitHub license](https://img.shields.io/github/license/cloudogu/nexus.svg)](https://github.com/cloudogu/nexus/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/cloudogu/nexus.svg)](https://github.com/cloudogu/nexus/releases)

# Nexus Repository OSS Dogu

## About this Dogu

**Name:** official/nexus

**Description:** [Nexus Repository OSS](https://www.sonatype.com/nexus-repository-oss) is an open source artifact repository with universal support for popular formats.

**Website:** https://www.sonatype.com/nexus-repository-oss

**Dependencies:** cas, nginx, postfix

## Installation Ecosystem
```
cesapp install official/nexus

cesapp start nexus
```

## Claim

The preconfigured nexus repositories can be changed by using [nexus-claim](https://github.com/cloudogu/nexus-claim).
First we have to create a model for our changes, e.g.: [sample](https://raw.githubusercontent.com/cloudogu/nexus-claim/develop/resources/nexus3/nexus3-initial-example.hcl). 
We could test our model by using the plan command against a running instance of nexus (note: do not forget to set credentials):

```bash
nexus-claim plan -i nexus3-initial-example.hcl
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

---
### What is the Cloudogu EcoSystem?
The Cloudogu EcoSystem is an open platform, which lets you choose how and where your team creates great software. Each service or tool is delivered as a Dogu, a Docker container. Each Dogu can easily be integrated in your environment just by pulling it from our registry. We have a growing number of ready-to-use Dogus, e.g. SCM-Manager, Jenkins, Nexus, SonarQube, Redmine and many more. Every Dogu can be tailored to your specific needs. Take advantage of a central authentication service, a dynamic navigation, that lets you easily switch between the web UIs and a smart configuration magic, which automatically detects and responds to dependencies between Dogus. The Cloudogu EcoSystem is open source and it runs either on-premises or in the cloud. The Cloudogu EcoSystem is developed by Cloudogu GmbH under [MIT License](https://cloudogu.com/license.html).

### How to get in touch?
Want to talk to the Cloudogu team? Need help or support? There are several ways to get in touch with us:

* [Website](https://cloudogu.com)
* [myCloudogu-Forum](https://forum.cloudogu.com/topic/34?ctx=1)
* [Email hello@cloudogu.com](mailto:hello@cloudogu.com)

---
&copy; 2020 Cloudogu GmbH - MADE WITH :heart:&nbsp;FOR DEV ADDICTS. [Legal notice / Impressum](https://cloudogu.com/imprint.html)
