pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir('terraform') {
                    withCredentials([usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )]) {
                        sh '''
                            terraform init
                            terraform validate
                            terraform plan -out=tfplan
                        '''
                    }
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
                    withCredentials([usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )]) {
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                script {
                    def elkIp = sh(
                        script: 'cd terraform && terraform output -raw elk_public_ip',
                        returnStdout: true
                    ).trim()

                    writeFile file: 'ansible/hosts.ini', text: """
[es]
${elkIp} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3
"""
                }
            }
        }

        stage('Ansible Deploy ELK') {
    steps {
        withEnv(['ANSIBLE_HOST_KEY_CHECKING=False']) {
            withCredentials([string(credentialsId: 'es-bootstrap-password',
                                   variable: 'ES_BOOTSTRAP_PASSWORD')]) {
                dir('.') {
                    ansiblePlaybook(
                        playbook: 'ansible/playbook.yml',
                        inventory: 'ansible/hosts.ini',
                        credentialsId: 'ssh-ansible-key',
                        extras: """
                          --extra-vars "es_bootstrap_password=${ES_BOOTSTRAP_PASSWORD} cluster_name=pawan-elk-cluster"
                        """
                        )
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished (success or failure)'
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
