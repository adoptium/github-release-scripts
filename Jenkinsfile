#!groovy

pipeline {
    agent { label 'master' }
    parameters {
        password(name: 'GITHUB_TOKEN', defaultValue: 'SECRET', description: 'Leave this')
        string(name: 'TAG', defaultValue: '', description: 'The GitHub tag of the release, e.g. jdk-12+33')
        choice(name: 'VERSION', choices: ['JDK21', 'JDK20', 'JDK19', 'JDK17', 'JDK11', 'JDK8'], description: 'Which JDK Version?')
        string(name: 'UPSTREAM_JOB_NAME', defaultValue: '', description: 'The full path to the pipeline / job, e.g. build-scripts/openjdk12-pipeline')
        string(name: 'UPSTREAM_JOB_NUMBER', defaultValue: '', description: 'The build number of the pipeline / job you want to release, e.g. 92')
        booleanParam(name: 'RELEASE', defaultValue: false, description: 'Tick this box to actually release the binary to GitHub')
        string(name: 'ARTIFACTS_TO_COPY', defaultValue: '**/*.tar.gz,**/*.zip,**/*.sha256.txt,**/*.msi,**/*.pkg,**/*.json,**/*.sig', description: 'For example to only ship linux x64:<br/>
target/linux/x64/**/*.tar.gz,target/linux/x64/**/*.sha256.txt,target/linux/x64/**/*.json,target/linux/x64/**/*.sig<br/>
Or **/*x64_linux*.tar.gz,**/*x64_linux*.sha256.txt,**/*x64_linux*.json,**/*x64_linux*.sig')
        string(name: 'ARTIFACTS_TO_SKIP', defaultValue: '', description: 'For example in most release builds we skip the testimage: *testimage*.')
        string(name: 'TIMESTAMP', defaultValue: '', description: 'Optional timestamp to add for nightly builds.')
        booleanParam(name: 'DRY_RUN', defaultValue: false, description: 'Tick this box to actually release the binary to GitHub')
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
                        step([$class: 'CopyArtifact',
							fingerprintArtifacts: true,
							flatten: true,
							filter: "${ARTIFACTS_TO_COPY}",
                            excludes: "${ARTIFACTS_TO_SKIP}",
							projectName: "${params.UPSTREAM_JOB_NAME}",
							selector: [$class: 'SpecificBuildSelector', buildNumber: "${params.UPSTREAM_JOB_NUMBER}"]])
                        sh 'JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ./sbin/Release.sh'
                        //withCredentials([usernamePassword(credentialsId: 'eclipse_temurin_bot_email_and_token', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {}
                        }
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