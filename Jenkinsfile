pipeline {
    agent any

     stage ("Git Checkout") {
            steps {
                git branch: 'main', credentialsId: 'github-access', url: 'https://github.com/adebowale123/ci-cd-project'
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

