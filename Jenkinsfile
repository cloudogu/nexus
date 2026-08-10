#!groovy
@Library([
  'pipe-build-lib',
  'ces-build-lib',
  'dogu-build-lib'
]) _

def pipe = new com.cloudogu.sos.pipebuildlib.DoguPipe(this, [
    doguName           : 'nexus',
    shellScripts       : ['''
                            resources/pre-upgrade.sh
                            resources/startup.sh
                            resources/upgrade-notification.sh
                            resources/util.sh
                            resources/pre-startup.sh
                            resources/claim.sh
                            resources/create-sa.sh
                            resources/remove-sa.sh
                            resources/nexus_api.sh
                          '''],
    dependedDogus       : ['cas', 'usermgt', 'postgresql'],
    additionalDogus     : ['official/postgresql'],
    doBatsTests         : true,
    checkMarkdown       : true,
    runIntegrationTests : true,
    cypressImage        : 'cypress/included:13.2.0',
    defaultBranch       : 'master'
])
com.cloudogu.ces.dogubuildlib.EcoSystem ecoSystem = pipe.ecoSystem

pipe.setBuildProperties()
pipe.addDefaultStages()

pipe.overrideStage('Setup') {
    ecoSystem.loginBackend('cesmarvin-setup')
    ecoSystem.setup([ additionalDependencies: [ 'official/postgresql' ] ])
}

String doguV3ReleaseName = "nexus"
String doguV3ChartRegistry = "registry.cloudogu.com"
def doguV3RegistryNamespaceBase = "${doguV3ChartRegistry}/official/nexus/official/nexus"
def doguV3RegistryRepositoryChart = "${doguV3RegistryNamespaceBase}/v3/charts"
def doguV3RegistryRepositoryImages = "${doguV3RegistryNamespaceBase}/images"
String doguV3ChartTargetDir = "target/k8s/helm"
String doguV3BuildImageRepository = "registry.cloudogu.com/official/usermgt"

def doguV3Stages = { group ->
    group.stage('Dogu v3 Checkout') {
        checkout scm
    }

    group.stage('Dogu v3 Build') {
        runMakeInGoContainer("install-yq")
        docker.withRegistry('https://registry.cloudogu.com/', 'cesmarvin-setup') {
            sh "make docker-build"
        }
    }

    group.stage('Dogu v3 Test') {
        runMakeInGoContainer("helm-lint")
    }

    group.stage('Dogu v3 Smoke Test (k3d)') {
        K3d k3d = new K3d(this, "${WORKSPACE}", "${WORKSPACE}/k3d", env.PATH)
        Makefile makefile = new Makefile(this)
        String releaseVersion = makefile.getVersion().trim()

        try {
            echo "[Dogu v3 k3d] Start cluster"
            k3d.startK3d()

            echo "[Dogu v3 k3d] Prepare prerequisites"
            k3d.kubectl("delete configmap global-config || true")
            k3d.kubectl("create configmap global-config --from-literal=config.yaml='domain: \"ces.test\"'")

            echo "[Dogu v3 k3d] Generate helm chart"
            runMakeInGoContainer("helm-generate")

            echo "[Dogu v3 k3d] Retag image for local smoke test"
            sh "docker tag ${doguV3BuildImageRepository}:${releaseVersion} local-smoke/ldap:${releaseVersion}"

            echo "[Dogu v3 k3d] Import previously built image"
            sh "sudo ${WORKSPACE}/k3d/.k3d/bin/k3d image import local-smoke/ldap:${releaseVersion} -c ${k3d.registryName}"

            echo "[Dogu v3 k3d] Deploy Dogu v3 via helm"
            k3d.helm("upgrade --install ${doguV3ReleaseName} ${doguV3ChartTargetDir} --namespace default --set fullnameOverride=${doguV3ReleaseName} --set image.registry=local-smoke --set image.repository=ldap --set image.tag=${releaseVersion} --set imagePullPolicy=Never --set migration.enabled=false --wait --timeout 5m")

            echo "[Dogu v3 k3d] Verify Dogu v3 startup"
            k3d.kubectl("rollout status deployment/${doguV3ReleaseName} --timeout=300s")
            k3d.kubectl("wait --for=condition=ready pod -l app.kubernetes.io/instance=${doguV3ReleaseName} --timeout=300s")
        } catch (Exception e) {
            echo "An error occurred. Start collecting logs..."
            k3d.collectAndArchiveLogs()
            throw e
        } finally {
            k3d.deleteK3d()
        }
    }

    if (pipe.gitflow.isReleaseBranch()) {
        group.stage('Push Dogu v3 Chart to Harbor') {
            sh "make helm-package"

            def doguV3ChartFile = sh(returnStdout: true, script: "ls -1t ${doguV3ChartTargetDir}/*.tgz 2>/dev/null | head -n 1").trim()
            if (!doguV3ChartFile) {
                error("No packaged Dogu v3 chart found in ${doguV3ChartTargetDir}")
            }

            withCredentials([usernamePassword(credentialsId: 'harborhelmchartpush', usernameVariable: 'HARBOR_USERNAME', passwordVariable: 'HARBOR_PASSWORD')]) {
                try {
                    sh ".bin/helm registry login ${doguV3ChartRegistry} --username '${HARBOR_USERNAME}' --password '${HARBOR_PASSWORD}'"
                    sh ".bin/helm push ${doguV3ChartFile} oci://${doguV3RegistryRepositoryChart}/"
                } finally {
                    sh ".bin/helm registry logout ${doguV3ChartRegistry}"
                }
            }
        }
    }
}

pipe.addStageGroup('doguV3Stages', pipe.agentMultinode, componentStages)


pipe.run()