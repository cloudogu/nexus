#!groovy
@Library([
  'pipe-build-lib',
  'ces-build-lib',
  'dogu-build-lib@bug/fix_verify_error'
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
    doBatsTests         : true,
    checkMarkdown       : true,
    runIntegrationTests : true,
    cypressImage        : 'cypress/included:13.2.0'

])
com.cloudogu.ces.dogubuildlib.EcoSystem ecoSystem = pipe.ecoSystem

pipe.setBuildProperties()
pipe.addDefaultStages()
pipe.overrideStage('Setup') {
    ecoSystem.loginBackend('cesmarvin-setup')
    ecoSystem.setup([ additionalDependencies: [ 'official/postgresql' ] ])
}
pipe.run()