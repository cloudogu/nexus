#!groovy
@Library(['github.com/cloudogu/ces-build-lib@4.0.1', 'github.com/cloudogu/dogu-build-lib@v3.0.0'])
import com.cloudogu.ces.cesbuildlib.*
import com.cloudogu.ces.dogubuildlib.*

node('vagrant') {
    String doguName = "nexus"
    Git git = new Git(this, "cesmarvin")
    git.committerName = 'cesmarvin'
    git.committerEmail = 'cesmarvin@cloudogu.com'
    GitFlow gitflow = new GitFlow(this, git)
    GitHub github = new GitHub(this, git)
    Changelog changelog = new Changelog(this)
    timestamps{
        properties([
                // Keep only the last x builds to preserve space
                buildDiscarder(logRotator(numToKeepStr: '10')),
                // Don't run concurrent builds for a branch, because they use the same workspace directory
                disableConcurrentBuilds(),
                // Parameter to activate dogu upgrade test on demand
                parameters([
                    booleanParam(defaultValue: false, description: 'Test dogu upgrade from latest release or optionally from defined version below', name: 'TestDoguUpgrade'),
                    string(defaultValue: '', description: 'Old Dogu version for the upgrade test (optional; e.g. 3.23.0-1)', name: 'OldDoguVersionForUpgradeTest'),
                    booleanParam(defaultValue: true, description: 'Enables cypress to record video of the integration tests.', name: 'EnableVideoRecording'),
                    booleanParam(defaultValue: true, description: 'Enables cypress to take screenshots of failing integration tests.', name: 'EnableScreenshotRecording'),
                    choice(name: 'TrivySeverityLevels', choices: [TrivySeverityLevel.CRITICAL, TrivySeverityLevel.HIGH_AND_ABOVE, TrivySeverityLevel.MEDIUM_AND_ABOVE, TrivySeverityLevel.ALL], description: 'The levels to scan with trivy', defaultValue: TrivySeverityLevel.CRITICAL),
                    choice(name: 'TrivyStrategy', choices: [TrivyScanStrategy.UNSTABLE, TrivyScanStrategy.FAIL, TrivyScanStrategy.IGNORE], description: 'Define whether the build should be unstable, fail or whether the error should be ignored if any vulnerability was found.', defaultValue: TrivyScanStrategy.UNSTABLE),
                ])
        ])

        EcoSystem ecoSystem = new EcoSystem(this, "gcloud-ces-operations-internal-packer", "jenkins-gcloud-ces-operations-internal")

        stage('Checkout') {
            checkout scm
        }

        stage('Lint') {
            lintDockerfile()
        }

        stage('Check Markdown Links') {
            Markdown markdown = new Markdown(this, "3.12.2")
            markdown.check()
        }

        stage('Shellcheck'){
            // TODO: Change this to shellCheck("./resources") as soon as https://github.com/cloudogu/dogu-build-lib/issues/8 is solved
            shellCheck("./resources/pre-upgrade.sh ./resources/pre-startup.sh ./resources/startup.sh ./resources/upgrade-notification.sh ./resources/claim.sh ./resources/util.sh ./resources/create-sa.sh ./resources/remove-sa.sh ./resources/nexus_api.sh")
        }

        try {
            stage('Bats Tests') {
                Bats bats = new Bats(this, docker)
                bats.checkAndExecuteTests()
            }

            stage('Provision') {
                // change namespace to prerelease_namespace if in develop-branch
                if (gitflow.isPreReleaseBranch()) {
                    sh "make prerelease_namespace"
                }
                ecoSystem.provision("/dogu")
            }

            stage('Setup') {
                ecoSystem.loginBackend('cesmarvin-setup')
                ecoSystem.setup([additionalDependencies: ['official/postgresql']])
            }

            stage('Wait for dependencies') {
                timeout(15) {
                    ecoSystem.waitForDogu("cas")
                    ecoSystem.waitForDogu("usermgt")
                    ecoSystem.waitForDogu("postgresql")
                }
            }

            stage('Build') {
                ecoSystem.build("/dogu")
            }

            stage('Trivy scan') {
                ecoSystem.copyDoguImageToJenkinsWorker("/dogu")
                Trivy trivy = new Trivy(this)
                trivy.scanDogu(".", params.TrivySeverityLevels, params.TrivyStrategy)
                trivy.saveFormattedTrivyReport(TrivyScanFormat.TABLE)
                trivy.saveFormattedTrivyReport(TrivyScanFormat.JSON)
                trivy.saveFormattedTrivyReport(TrivyScanFormat.HTML)
            }

            stage('Verify') {
                ecoSystem.verify("/dogu")
            }

            stage('Integration Tests') {
                ecoSystem.runCypressIntegrationTests([cypressImage     : "cypress/included:12.9.0",
                                                      enableVideo      : params.EnableVideoRecording,
                                                      enableScreenshots: params.EnableScreenshotRecording])
            }

            if (params.TestDoguUpgrade != null && params.TestDoguUpgrade){
                stage('Upgrade dogu') {
                    // Remove new dogu that has been built and tested above
                    ecoSystem.purgeDogu(doguName)

                    if (params.OldDoguVersionForUpgradeTest != '' && !params.OldDoguVersionForUpgradeTest.contains('v')){
                        println "Installing user defined version of dogu: " + params.OldDoguVersionForUpgradeTest
                        ecoSystem.installDogu("official/" + doguName + " " + params.OldDoguVersionForUpgradeTest)
                    } else {
                        println "Installing latest released version of dogu..."
                        ecoSystem.installDogu("official/" + doguName)
                    }
                    ecoSystem.startDogu(doguName)
                    ecoSystem.waitForDogu(doguName)
                    ecoSystem.upgradeDogu(ecoSystem)

                    // Wait for upgraded dogu to get healthy
                    ecoSystem.waitForDogu(doguName)
                    ecoSystem.waitUntilAvailable(doguName)
                }

                stage('Integration Tests - After Upgrade') {
                    ecoSystem.runCypressIntegrationTests([
                        cypressImage     : "cypress/included:13.2.0",
                        enableVideo      : params.EnableVideoRecording,
                        enableScreenshots: params.EnableScreenshotRecording
                    ])
                }
            }

            if (gitflow.isReleaseBranch()) {
                String releaseVersion = git.getSimpleBranchName()

                stage('Finish Release') {
                    gitflow.finishRelease(releaseVersion)
                }

                stage('Push Dogu to registry') {
                    ecoSystem.push("/dogu")
                }

                stage ('Add Github-Release'){
                    github.createReleaseWithChangelog(releaseVersion, changelog)
                }
            } else if (gitflow.isPreReleaseBranch()) {
                // push to registry in prerelease_namespace
                stage('Push Prerelease Dogu to registry') {
                    ecoSystem.pushPreRelease("/dogu")
                }
            }
        } finally {
            stage('Clean') {
                ecoSystem.destroy()
            }
        }
    }
}
