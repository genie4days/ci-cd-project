pipeline {
    agent any
   
    stages{   
        stage('Terraform Login') {
      steps {
        // Get the Terraform token from Jenkins credential.
        def token = credentials('terraform-cloud-token')

        // Log in to Terraform Cloud.
        sh 'terraform login -token $token'
      }
    }
        stage ("terraform init") {
            steps {
                sh ('terraform init') 
            }
        }
        
        stage ("terraform Action") {
            steps {
                echo "Terraform action is --> ${action}"
                sh ('terraform ${action} --auto-approve') 
           }
        }
    }
}

