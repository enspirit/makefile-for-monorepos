pipeline {

  agent {
    label 'buildkit'
  }

  triggers {
    issueCommentTrigger('.*build this please.*')
  }

  stages {

    stage ('Building Docker Images') {
      steps {
        container('builder') {
          script {
            sh 'make images'
          }
        }
      }
    }

    stage ('Make up') {
      steps {
        container('builder') {
          script {
            sh 'make up'
          }
        }
      }
    }

    stage ('Run tests') {
      steps {
        container('builder') {
          script {
            sh 'make tests'
          }
        }
      }
    }
  }

  post {
    always {
      container('builder') {
        sh 'make down'
      }
    }
  }
}
