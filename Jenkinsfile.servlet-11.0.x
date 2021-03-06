pipeline {
  agent { node { label 'linux' } }
  triggers {
    cron '@daily'
  }
  options {
    buildDiscarder logRotator( numToKeepStr: '50' )
  }
  parameters {
    string( defaultValue: "http://download.eclipse.org/ee4j/jakartaee-tck/master/nightly/servlet-tck-5.0.0.zip",
            description: 'Url to download TCK () do not change anything if you are not sure :)',
            name: 'TCK_SVLT_JAKARTA_URL' )
    string( defaultValue: "jetty-11.0.x",
            description: 'Jetty 11.0.x branch to build',
            name: 'JETTY_BRANCH' )
  }
  stages {
    stage( 'Tck Run' ) {
      steps {
        script{
            def built = build( job: 'servlettck-run', propagate: false,
                           parameters: [string( name: 'JETTY_BRANCH', value: "${JETTY_BRANCH}" ),
                                        string( name: 'JDK', value: 'jdk11' ),
                                        string( name: 'JDKTCK', value: 'jdk9' ),
                                        string( name: 'TCKURL', value: "${TCK_SVLT_JAKARTA_URL}" ),
                                        string( name: 'SVLT_NS', value: 'jakarta' )] )
            copyArtifacts(projectName: 'servlettck-run', selector: specific("${built.number}"));
        }
        //unarchive mapping: ['**/**' : '.']
      }
      post {
        always {
          tckreporttojunit tckReportTxtPath: "${env.WORKSPACE}/JTReport/text/summary.txt", junitFolderPath: 'surefire-reports'
          junit testResults: '**/surefire-reports/*.xml'
          script{
            currentBuild.description = "Run TCK branch ${JETTY_BRANCH}"
          }
          archiveArtifacts artifacts: "**/surefire-reports/*.xml",allowEmptyArchive: true
          archiveArtifacts artifacts: "JTReport/**",allowEmptyArchive: true
          archiveArtifacts artifacts: "jetty-home/target/jetty-base/logs/*.*",allowEmptyArchive: true
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: "${env.WORKSPACE}/JTReport/html", reportFiles: 'report.html', reportName: 'TCK Report', reportTitles: ''])
        }
      }
    }
  }
}
