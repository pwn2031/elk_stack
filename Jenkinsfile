pipeline {
    agent any
    parameters {
        choice(name: 'ENV', choices: ['dev', 'prod'], description: 'Environment')
    }
    environment {
        TF_VAR_env = "${params.ENV}"
        ANSIBLE_VAULT_PASS = credentials('ansible-vault-pass')  // Optional
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
                    // Parse outputs (adjust resource names from your main.tf)
                    def ips = sh(script: 'terraform output -raw instance_ips || echo "13.126.124.229"', returnStdout: true).trim()
                    writeFile file: 'ansible/hosts.ini', text: """
[elk_servers]
${ips} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_python_interpreter=/usr/bin/python3
"""
                }
            }
        }
        stage('Ansible Deploy ELK') {
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/main.yml',
                    inventory: 'ansible/hosts.ini',
                    credentialsId: 'ssh-ansible-key',  // Your SSH key ID in Jenkins
                    extras: '''
                        --extra-vars "es_bootstrap_password=3K+Hmcvo56SwKxfPi82U 
                                     cluster_name=pawan-elk-cluster 
                                     env=${TF_VAR_env}"
                        --vault-id @prompt  # If vaulted
                    '''
                )
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'terraform/tfplan, ansible/inventory/dynamic.ini, **/*.log'
            publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'ansible/', reportFiles: 'main.html', reportName: 'Ansible Report'])
        }
        success {
            echo 'ELK infra deployed! Check Kibana at https://${terraform output kibana_url}'
        }
        failure {
            echo 'Pipeline failed. Check logs.'
        }
    }
}
