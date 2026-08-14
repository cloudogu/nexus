## Use nexus-claim to preconfigure repositories

The preconfigured Nexus repositories can be changed by using [nexus-claim](https://github.com/cloudogu/nexus-claim).
First we have to create a model for our changes, e.g.: [sample](https://raw.githubusercontent.com/cloudogu/nexus-claim/develop/resources/nexus3/nexus3-initial-example.hcl). 
We could test our model by using the plan command against a running instance of Nexus (note: do not forget to set credentials):

```bash
nexus-claim plan -i nexus3-initial-example.hcl
```

If the output looks good, we could store our model in the registry. 
If we want to apply our model only once:

`kubectl edit configmap -n ecosystem nexus-config`
````yaml
    data:
      config.yaml: |
        claim.once: "<Inhalt von myModel.hcl>"
````

Or we could apply our model on every start of nexus:

`kubectl edit configmap -n ecosystem nexus-config`
````yaml
    data:
      config.yaml: |
        claim.always: "<Inhalt von myModel.hcl>"
````