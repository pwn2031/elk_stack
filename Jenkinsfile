pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'prod'], description: 'Environment')
    }

    environment {
        TF_VAR_env = "${params.ENV}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init
                        terraform validate
                        terraform plan -var="env=${TF_VAR_env}" -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply?') {
            when { branch 'main' }
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                script {
                    // Read single ELK public IP from Terraform output
                    def elkIp = sh(
                        script: 'cd terraform && terraform output -raw elk_public_ip',
                        returnStdout: true
                    ).trim()

                    writeFile file: 'ansible/hosts.ini', text: """
[elk_servers]
${elkIp} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/pawan-elk-key.pem ansible_python_interpreter=/usr/bin/python3
"""
                }
            }
        }

        stage('Ansible Deploy ELK') {
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/main.yml',
                    inventory: 'ansible/hosts.ini',
                    credentialsId: 'ssh-ansible-key',
                    extras: """
                        --extra-vars "es_bootstrap_password=3K+Hmcvo56SwKxfPi82U cluster_name=pawan-elk-cluster env=${TF_VAR_env}"
                    """
                )
            }
        }
    }

    post {
        always {
            // archiveArtifacts artifacts: 'terraform/tfplan, ansible/hosts.ini, **/*.log', allowEmptyArchive: true
        }
        success {
            script {
                def kibanaUrl = sh(
                    script: 'cd terraform && terraform output -raw kibana_url',
                    returnStdout: true
                ).trim()
                echo "ELK infra deployed successfully. Kibana: ${kibanaUrl}"
            }
        }
        failure {
            echo 'Pipeline failed. Check logs.'
        }
    }
}
