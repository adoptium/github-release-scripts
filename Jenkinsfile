#!groovy

pipeline {
    agent { label 'master' }
    options {
        copyArtifactPermission('*');
    }
    parameters {
        password(name: 'GITHUB_TOKEN', defaultValue: 'SECRET', description: 'Leave this')
        string(name: 'TAG', defaultValue: '', description: 'The GitHub tag of the release, e.g. jdk-12+33')
        choice(name: 'VERSION', choices: ['jdk21', 'jdk20', 'jdk19', 'jdk17', 'jdk11', 'jdk8'], description: 'Which JDK Version?')
        string(name: 'UPSTREAM_JOB_NAME', defaultValue: '', description: 'The full path to the pipeline / job, e.g. build-scripts/openjdk12-pipeline')
        string(name: 'UPSTREAM_JOB_NUMBER', defaultValue: '', description: 'The build number of the pipeline / job you want to release, e.g. 92')
        string(name: 'UPSTREAM_JOB_LINK', defaultValue: '', description: 'The build link of the pipeline / job you want to release, e.g. 92')
        booleanParam(name: 'RELEASE', defaultValue: false, description: 'Tick this box to actually release the binary to GitHub')
        string(name: 'ARTIFACTS_TO_COPY', defaultValue: '**/*.tar.gz,**/*.zip,**/*.sha256.txt,**/*.msi,**/*.pkg,**/*.json,**/*.sig', description: '''For example to only ship linux x64:<br/> 
target/linux/x64/**/*.tar.gz,target/linux/x64/**/*.sha256.txt,target/linux/x64/**/*.json,target/linux/x64/**/*.sig<br/> 
Or **/*x64_linux*.tar.gz,**/*x64_linux*.sha256.txt,**/*x64_linux*.json,**/*x64_linux*.sig''')
        string(name: 'ARTIFACTS_TO_SKIP', defaultValue: '', description: 'For example in most release builds we skip the testimage: *testimage*.')
        string(name: 'TIMESTAMP', defaultValue: '', description: 'Optional timestamp to add for nightly builds.')
        booleanParam(name: 'DRY_RUN', defaultValue: false, description: 'Tick this box will not release the binary to GitHub')
        booleanParam(name: 'UPLOAD_TESTRESULTS_ONLY', defaultValue: false, description: 'Tick this box to actually release the binary to GitHub')
    }
    stages {
        stage('Upload Releases') {
            steps {
                script {
                    try {
                        cleanWs()
                        // use Jenkins crendential to download JDK if source is from openjdkX-pipline
                        checkout scm

                        def upstreamJobName = params.UPSTREAM_JOB_NAME
                        def upstreamJobNumber = params.UPSTREAM_JOB_NUMBER
                        if (params.RELEASE && !params.UPSTREAM_JOB_NAME && !params.UPSTREAM_JOB_NUMBER) {
                            //JOB_LINK could be specific artifact one or the general one
                            def upstreamJobLink = params.UPSTREAM_JOB_LINK
                            if (params.UPSTREAM_JOB_LINK) {
                                if (params.UPSTREAM_JOB_LINK.contains('/artifact/')) {
                                    upstreamJobLink = upstreamJobLink.substring(0, upstreamJobLink.indexOf('/artifact/'))
                                }
                                if (upstreamJobLink.endsWith("/")) {
                                    upstreamJobLink= upstreamJobLink.substring(0, upstreamJobLink.length() - 1)
                                }
                                upstreamJobNumber = upstreamJobLink.tokenize('/').last()
                                upstreamJobName = upstreamJobLink.substring(0, upstreamJobLink.indexOf("${upstreamJobNumber}"))
                            } else {
                                echo "Set up UPSTREAM_JOB_LINK or UPSTREAM_JOB_NAME with UPSTREAM_JOB_NUMBER "
                                currentBuild.result = 'FAILURE'
                                return
                            }

                        }
                        step([$class: 'CopyArtifact',
                            fingerprintArtifacts: true,
                            flatten: true,
                            filter: "${params.ARTIFACTS_TO_COPY}",
                            excludes: "${params.ARTIFACTS_TO_SKIP}",
                            projectName: "${upstreamJobName}",
                            selector: [$class: 'SpecificBuildSelector', buildNumber: "${upstreamJobNumber}"]])
                        sh '''
                        export VERSION=`echo $VERSION | awk '{print toupper($0)}'`
                        JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ./sbin/Release.sh
                        '''
                    } catch (Exception err) {
                        echo err.getMessage()
                        currentBuild.result = 'FAILURE'
                    } finally {
                        cleanWs()
                    }
                }
            }
        }
    }
}