#!groovy
@Library([
  // renovate: datasource=github-tags depName=cloudogu/ces-build-lib
  'github.com/cloudogu/ces-build-lib@6.2.0',
  // renovate: datasource=github-tags depName=cloudogu/dogu-build-lib
  'github.com/cloudogu/dogu-build-lib@v5.0.0',
])
import com.cloudogu.ces.cesbuildlib.*
import com.cloudogu.ces.dogubuildlib.*
import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

// renovate: datasource=docker depName=hadolint/hadolint
final String hadolintVersion = 'v2.15.1-debian'
// renovate: datasource=docker depName=ghcr.io/tcort/markdown-link-check
final String markdownLinkCheckVersion = '3.15.0'
// renovate: datasource=docker depName=cypress/included
final String cypressVersion = '13.14.2'

node(params.WorkerLabel ?: 'cpu4mem8') {
  Git git = new Git(this, "cesmarvin")
  git.committerName = 'cesmarvin'
  git.committerEmail = 'cesmarvin@cloudogu.com'
  GitFlow gitflow = new GitFlow(this, git)
  GitHub github = new GitHub(this, git)
  Changelog changelog = new Changelog(this)
  Trivy trivy = new Trivy(this)
  timestamps {
    //noinspection GroovyAssignabilityCheck
    properties([
      buildDiscarder(logRotator(numToKeepStr: '10')),
      disableConcurrentBuilds(),
      parameters([
        choice(
          name: 'PipelineMode',
          description: 'Which CES variation to run tests in',
          choices: ['Full', 'Classic', 'MultiNode', 'MultiNodeV3'],
        ),
        string(
          name: 'WorkerLabel',
          description: 'Optional: node label expression to run on, overriding the default worker.',
          defaultValue: '',
        ),
        booleanParam(
          name: 'TestDoguUpgrade',
          description: 'Test dogu upgrade from latest release or optionally from defined version below',
          defaultValue: false,
        ),
        string(
          name: 'OldDoguVersionForUpgradeTest',
          description: 'Old Dogu version for the upgrade test (optional; e.g. 3.23.0-1)',
          defaultValue: '',
        ),
        booleanParam(
          name: 'EnableVideoRecording',
          description: 'Enables cypress to record video of the integration tests.',
          defaultValue: true,
        ),
        booleanParam(
          name: 'EnableScreenshotRecording',
          description: 'Enables cypress to take screenshots of failing integration tests.',
          defaultValue: true,
        ),
        string(
          name: 'CypressVersion',
          description: 'Version of the Cypress testing framework (cypress/included image) to run integration tests with',
          defaultValue: cypressVersion,
        ),
        choice(
          name: 'TrivySeverityLevels',
          description: 'The levels to scan with trivy',
          choices: [
            TrivySeverityLevel.HIGH_AND_ABOVE,
            TrivySeverityLevel.CRITICAL,
            TrivySeverityLevel.MEDIUM_AND_ABOVE,
            TrivySeverityLevel.ALL
          ],
        ),
        choice(
          name: 'TrivyStrategy',
          description: 'Define whether the build should be unstable, fail or whether the error should be ignored if any vulnerability was found.',
          choices: [
            TrivyScanStrategy.UNSTABLE,
            TrivyScanStrategy.FAIL,
            TrivyScanStrategy.IGNORE
          ],
        ),
        choice(
          name: 'MarkdownLinkStrategy',
          description: 'Define whether the build should be unstable or fail if any unreachable link was found.',
          choices: [
            MarkdownCheckStrategy.UNSTABLE,
            MarkdownCheckStrategy.FAIL,
          ],
        ),
        string(
          name: 'ClusterName',
          description: 'Optional: Name of the multinode integration test cluster. A new instance gets created if this parameter is not supplied',
          defaultValue: '',
        ),
        booleanParam(
          name: 'KeepCluster',
          description: 'Optional: If True, the cluster will not be deleted after the build execution',
          defaultValue: false,
        ),
      ])
    ])
    params.keySet().sort().each { key -> echo "${key}: \"${params[key]}\"" }
    // A changed parameter default only applies from the next build on, and the field may be cleared
    String cypressImageVersion = params.CypressVersion ?: cypressVersion
    // Jobs created by the old pipe-build-lib pipeline pass its default "FULL" in their first build after the switch
    String pipelineMode = params.PipelineMode?.toLowerCase() == 'full' ? 'Full' : params.PipelineMode

    stage('Checkout') {
      git.checkoutWithSubmodules()
    }

    // GitFlow.isPreReleaseBranch() compares the simple branch name (after the last "/") with "develop",
    // so it's also true on dogu_v3/develop, which must not push the v3 POC as a prerelease.
    boolean prereleaseBranch = gitflow.isPreReleaseBranch() && env.BRANCH_NAME != 'dogu_v3/develop'

    def doguJson = readJSON file: 'dogu.json'
    String doguNameSpace = doguJson.Name.split('/')[0]
    String doguName = doguJson.Name.split('/')[1]

    List<String> additionalDogus = [
      'official/postgresql',
    ]

    stage('Lint') {
      new Dockerfile(this).lint('Dockerfile', hadolintVersion)
    }

    stage('Check Markdown Links') {
      Markdown markdown = new Markdown(this, markdownLinkCheckVersion)
      markdown.check(params.MarkdownLinkStrategy)
    }

    stage('Check Changelog') {
      // This check will skip on non-pull-request.
      checkChangelog()
      checkReleaseNotes()
    }

    stage('Shellcheck') {
      def fileList = sh(script: 'find ./resources/ -type f -regex .*\\.sh -print', returnStdout: true).trim()
      if (fileList) {
        fileList = '"' + fileList.trim().replaceAll('\n', '" "') + '"'
        shellCheck(fileList)
      } else {
        unstable(message: "ShellCheck called but no scripts found!")
      }
    }

    stage('Bats Tests') {
      new Bats(this, docker).checkAndExecuteTests()
    }

    def branches = [failFast: false]

    if (pipelineMode in ['Full', 'Classic']) {

      EcoSystem ecoSystem = new EcoSystem(this, "gcloud-ces-operations-internal-packer", "jenkins-gcloud-ces-operations-internal")
      branches['Classic'] = {
        ws("${env.WORKSPACE}@classic") {
          git.checkoutWithSubmodules()

          stage('Classic: Infos') {
            echo "This pipeline-branch will build and test the ${doguNameSpace}/${doguName} Dogu on a Classic-CES Vagrant GCP machine."
            echo "Libraries:\n${getLibInfos().join("\n")}"
          }

          try {
            stage('Classic: Provision') {
              if (prereleaseBranch) {
                sh "make prerelease_namespace"
              }
              ecoSystem.provision("/dogu", "n2-highmem-4", 30)
            }

            stage('Classic: Setup') {
              ecoSystem.loginBackend('cesmarvin-setup')
              ecoSystem.setup([additionalDependencies: additionalDogus])
            }

            stage('Classic: Wait for dependencies') {
              timeout(30) {
                ecoSystem.waitForDogu("cas")
                ecoSystem.waitForDogu("usermgt")
                additionalDogus.each { dep -> ecoSystem.waitForDogu(dep.split('/')[1]) }
              }
            }

            stage('Classic: Build Dogu Image') {
              ecoSystem.build("/dogu")
            }

            // Trivy and the post-join release push both use this image and dogu.json.
            stage('Classic: Export Image') {
              ecoSystem.copyDoguImageToJenkinsWorker("/dogu")
              stash name: 'dogu-json', includes: 'dogu.json'
            }

            stage('Classic: Verify') {
              ecoSystem.verify("/dogu")
            }

            stage('Classic: Integration Tests') {
              ecoSystem.runCypressIntegrationTests(cypressConfig('classic', cypressImageVersion))
            }

            conditionalStage('Classic: Upgrade dogu', params.TestDoguUpgrade) {
              ecoSystem.upgradeFromPreviousRelease(params.OldDoguVersionForUpgradeTest, doguName, doguNameSpace)
            }

            conditionalStage('Classic: Integration Tests (Post-Upgrade)', params.TestDoguUpgrade) {
              ecoSystem.runCypressIntegrationTests(cypressConfig('classic', cypressImageVersion))
            }

          } finally {
            stage('Classic: Clean') {
              ecoSystem.destroy()
            }
          }
        }
      }
    }

    if (pipelineMode in ['Full', 'MultiNode']) {

      MultiNodeEcoSystem mn = new MultiNodeEcoSystem(this, 'jenkins_workspace_gcloud_key', 'automatic_migration_coder_token', doguName)
      branches['MultiNode'] = {
        ws("${env.WORKSPACE}@multinode") {
          git.checkoutWithSubmodules()

          stage('MultiNode: Infos') {
            echo "This pipeline-branch will build and test the ${doguNameSpace}/${doguName} Dogu on a MultiNode-LOP Coder cluster."
            echo "Libraries:\n${getLibInfos().join("\n")}"
          }

          try {
            stage('MultiNode: Setup') {
              timeout(time: 70, unit: 'MINUTES') {
                mn.setup([
                  clustername    : params.ClusterName,
                  additionalDogus: additionalDogus,
                  machineType    : "n2-highmem-4",
                  nodeCount      : 2
                ])
              }
            }

            stage('MultiNode: Wait for dependencies') {
              timeout(30) {
                mn.waitForDogu("cas")
                mn.waitForDogu("usermgt")
                additionalDogus.each { dogu -> mn.waitForDogu(dogu.split('/')[1]) }
              }
            }

            stage('MultiNode: Build Dogu Image') {
              mn.build(doguName)
            }

            stage('MultiNode: Wait for Dogu') {
              mn.waitForDogu(doguName)
            }

            stage('MultiNode: Verify') {
              mn.verify(doguName)
            }

            stage('MultiNode: Integration Tests') {
              mn.runCypressIntegrationTests(cypressConfig('multinode', cypressImageVersion))
            }

            conditionalStage('MultiNode: Upgrade dogu', params.TestDoguUpgrade) {
              mn.upgradeFromPreviousRelease(params.OldDoguVersionForUpgradeTest, doguName, doguNameSpace)
            }

            conditionalStage('MultiNode: Integration Tests (Post-Upgrade)', params.TestDoguUpgrade) {
              mn.runCypressIntegrationTests(cypressConfig('multinode', cypressImageVersion))
            }
          } finally {
            conditionalStage('MultiNode: Clean', !params.KeepCluster) {
              mn.destroy()
            }
          }
        }
      }
    }

    // v3 dogus (Helm chart, installed with cldk) are marked by a cldk.yaml, like in the makefiles' release scripts.
    // Without it, e.g. on develop before the dogu_v3 branches are merged, this pipeline-branch is left out.
    if (fileExists('cldk.yaml') && pipelineMode in ['Full', 'MultiNodeV3']) {
      branches['MultiNode v3'] = {
        ws("${env.WORKSPACE}@multinode-v3") {
          git.checkoutWithSubmodules()

          stage('MultiNode v3: Infos') {
            echo "This pipeline-branch will build and test the ${doguNameSpace}/${doguName} Dogu as v3 Dogu (Helm chart) on a MultiNode cluster."
            echo "Libraries:\n${getLibInfos().join("\n")}"
          }

          // TODO: Skeleton, the stages below only mark where the v3 steps go.
          try {
            stage('MultiNode v3: Setup') {
              echo "TODO: provision a cluster for v3 dogus"
            }

            stage('MultiNode v3: Build and Install Dogu') {
              echo "TODO: make dogu-apply (cldk dogu dev-push, from the makefiles' dogu-v3.mk)"
            }

            stage('MultiNode v3: Wait for Dogu') {
              echo "TODO: wait until the dogu is healthy"
            }

            stage('MultiNode v3: Verify') {
              echo "TODO: run the goss checks"
            }

            stage('MultiNode v3: Integration Tests') {
              echo "TODO: run the Cypress integration tests"
            }
          } finally {
            stage('MultiNode v3: Clean') {
              echo "TODO: delete the cluster"
            }
          }
        }
      }
    }

    // parallel() throws if any branch failed, so nothing below releases
    // unless all of them passed.
    parallel(branches)

    // Scan and release the Dogu image exported from the Classic worker.
    boolean classicRan = pipelineMode in ['Full', 'Classic']
    boolean releasing = classicRan && gitflow.isReleaseBranch()
    boolean prereleasing = classicRan && prereleaseBranch
    String releaseVersion = git.getSimpleBranchName()

    conditionalStage('Trivy scan', classicRan) {
      // Classic's dogu.json names the exported image - on prerelease branches it carries the prerelease namespace.
      dir('classic-dogu-export') {
        unstash 'dogu-json'
      }
      trivy.scanDogu('classic-dogu-export', params.TrivySeverityLevels, params.TrivyStrategy)
      trivy.saveFormattedTrivyReport(TrivyScanFormat.TABLE)
      trivy.saveFormattedTrivyReport(TrivyScanFormat.JSON)
      trivy.saveFormattedTrivyReport(TrivyScanFormat.HTML)
    }

    // Before Finish Gitflow Release: archiveDoguReport() reads the commit from HEAD, which that stage moves.
    conditionalStage('Archive Trivy', releasing) {
      trivy.archiveDoguReport('classic-dogu-export')
    }

    conditionalStage('Finish Gitflow Release', releasing) {
      gitflow.finishRelease(releaseVersion)
    }

    conditionalStage('Push Dogu to registry', releasing) {
      pushDogu('cesmarvin-setup')
    }

    conditionalStage('Add Github Release', releasing) {
      github.createReleaseWithChangelog(releaseVersion, changelog)
    }

    conditionalStage('Notify Webhook', releasing) {
      new Webhook(this).notifyRelease()
    }


    conditionalStage('Push Prerelease Dogu to registry', prereleasing) {
      pushDogu('harborrobotprerelease')
    }
  }
}

private List<String> getLibInfos() {
  (currentBuild.rawBuild
    .getAction(org.jenkinsci.plugins.workflow.libs.LibrariesAction)
    ?.libraries
    ?.collect { "${it.name}@${it.version} trusted=${it.trusted}" } ?: []) as List<String>
}

// Pushes the image and dogu.json exported from classic CES to the Jenkins worker.
private void pushDogu(String credentialsId) {
  // classic-dogu-export holds Classic's dogu.json, unstashed by the Trivy scan stage.
  dir('classic-dogu-export') {
    def dogu = readJSON file: 'dogu.json'
    withCredentials([usernamePassword(credentialsId: credentialsId, usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_PASSWORD')]) {
      // Own config dir, so the login doesn't touch the worker's baked registry auth.
      withEnv(["DOCKER_CONFIG=${pwd(tmp: true)}/docker-push-config"]) {
        sh 'echo "$REGISTRY_PASSWORD" | docker login registry.cloudogu.com -u "$REGISTRY_USER" --password-stdin'
        sh "docker push ${dogu.Image}:${dogu.Version}"
      }
    }
    new DoguRegistry(this, 'https://dogu.cloudogu.com', credentialsId).pushDogu()
  }
}

private Map cypressConfig(String artifactPathPrefix, String cypressImageVersion) {
  [
    cypressImage        : "cypress/included:${cypressImageVersion}",
    enableVideo         : params.EnableVideoRecording,
    enableScreenshots   : params.EnableScreenshotRecording,
    additionalCypressEnv: [TAGS: "not @ignore"],
    artifactPathPrefix  : artifactPathPrefix,
  ]
}

// Always shows the stage; marks it skipped instead of running body when condition is false.
private void conditionalStage(String name, boolean condition, Closure body) {
  stage(name) {
    if (!condition) {
      Utils.markStageSkippedForConditional(name)
      return
    }
    body()
  }
}
