pipeline {
  agent any

  parameters {
    choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose apply or destroy')
  }

  environment {
    TF_IN_AUTOMATION = "true"
  }

  stages {
    stage('Git Checkout') {
      steps {
        // Pull the repo that contains Terraform + scripts + configs
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        dir('terraform') {
          sh '''
            set -e
            terraform version
            terraform init
          '''
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('terraform') {
          sh '''
            set -e
            terraform fmt -check
            terraform validate
            terraform plan -out=tfplan
          '''
        }
      }
    }

    stage('Manual Approval') {
      steps {
        script {
          if (params.ACTION == 'apply') {
            input message: "Approve Terraform APPLY?", ok: "Apply"
          } else {
            input message: "Approve Terraform DESTROY?", ok: "Destroy"
          }
        }
      }
    }

    stage('Terraform Apply/Destroy') {
      steps {
        dir('terraform') {
          script {
            if (params.ACTION == 'apply') {
              sh '''
                set -e
                terraform apply -auto-approve tfplan
              '''
            } else {
              sh '''
                set -e
                terraform destroy -auto-approve
              '''
            }
          }
        }
      }
    }

    stage('Outputs (apply only)') {
      when { expression { return params.ACTION == 'apply' } }
      steps {
        dir('terraform') {
          sh '''
            echo "---- Outputs ----"
            terraform output
          '''
        }
      }
    }
  }
}
