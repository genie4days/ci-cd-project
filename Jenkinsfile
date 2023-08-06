pipeline {
  agent any
  stages {
    stage('Terraform Login') {
      steps {
        // Get the Terraform token from Jenkins credential.
        sh 'terraform login -token $(credentials('terraform-cloud-token'))'

        // Log in to Terraform Cloud.
        sh 'terraform login -token $token'
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
