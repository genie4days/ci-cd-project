pipeline {
  agent any
  stages {
    stage('Terraform Login') {
      steps {
        script {
          // Get the Terraform token from Jenkins credential.
          def login = credentials('terraform-cloud-login')
          def token = credentials('terraform-cloud-token')

          // Log in to Terraform Cloud.
          echo "Terraform login is --> ${token}"
          sh 'terraform login -token $token'
          sh 'terraform login ${token} --auto-approve'
        }
      }
    }
    stage('Terraform Init') {
      steps {
        sh 'terraform init'
      }
    }
    stage('Terraform Action') {
      steps {
        echo "Terraform action is --> ${action}"
        sh "terraform ${action} --auto-approve"
      }
    }
  }
}
