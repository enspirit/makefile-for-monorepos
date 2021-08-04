pipeline {

  agent {
    label 'buildkit'
  }

  triggers {
    issueCommentTrigger('.*build this please.*')
  }

  environment {
    SLACK_CHANNEL = '#opensource-cicd'
  }

  stages {

    stage ('Start') {
      steps {
        cancelPreviousBuilds()
        sendNotifications('STARTED', SLACK_CHANNEL)
      }
    }

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
            sh 'make tests.run'
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
    success {
      sendNotifications('SUCCESS', SLACK_CHANNEL)
    }
    failure {
      sendNotifications('FAILED', SLACK_CHANNEL)
    }
  }
}
