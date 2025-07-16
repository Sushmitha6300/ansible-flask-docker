# Flask App CI/CD with Jenkins, Docker & Ansible

This project showcases a complete CI/CD pipeline for a Flask application. Jenkins automates the build and push of a Dockerized Flask app to Docker Hub, while Ansible handles the deployment of the containerized app onto a target EC2 instance in AWS.

---

## Tools & Technologies Used

- **Python (Flask)** – For building the lightweight web application.
- **Docker** – Used to containerize the Flask application.
- **DockerHub** – Serves as the remote registry for storing Docker images.
- **Jenkins** – Automates the CI pipeline: building and pushing Docker images.
- **Ansible** – Handles the automated deployment of the Docker container on EC2.
- **Git & GitHub** – Used for version control and as the source trigger for Jenkins.
- **AWS EC2** – Hosts both the Jenkins controller and the target deployment instance.
- **Terraform** – Provisions and manages all the required AWS infrastructure.

---

## Project Overview

This DevOps project showcases a fully automated CI/CD pipeline to build, ship, and deploy a containerized Python Flask application on AWS infrastructure.

**The process includes:**

1. Developers push code (Flask app + Dockerfile + Jenkinsfile) to a GitHub repository
2. Jenkins automatically pulls the code, builds a Docker image, and pushes it to DockerHub
3. Ansible connects to the target EC2 instance, pulls the image from DockerHub, and runs the     container
4. The Flask app becomes accessible via the EC2 instance's public IP on port 5000

---

## Features

- Complete CI/CD pipeline using Jenkins, Docker, and Ansible
- Automatic build and deployment on every push to GitHub
- Dockerized Flask application with custom Dockerfile
- Infrastructure provisioning and configuration automation using Ansible
- Deployed on AWS EC2, accessible via browser
- Easily reusable and extendable for any containerized app

## How It Works

GitHub ──► Jenkins ──► DockerHub ──► Ansible ──► EC2 ──► Flask App

1. Jenkins monitors the GitHub repository for code changes

2. On every push:

   - Pulls the latest code from GitHub
   - Builds a Docker image using the provided Dockerfile
   - Pushes the image to DockerHub
   - Triggers an Ansible playbook that connects to EC2
   - The EC2 instance pulls the Docker image and runs the container

3. Flask app becomes publicly accessible on port 5000
---

## Architecture Diagram

---

## Project Structure 
```bash
ansible-flask-docker/
│── ansible/
│   ├── playbook.yml
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
│   └── terraform.tfvars
├── flask-app/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── Jenkinsfile
├── .gitignore
└── README.md
```

---

## Steps to Run This Project

### 🔹 Step 1: Clone the Repository
```bash
git clone https://github.com/Sushmitha6300/ansible-flask-docker.git
cd ansible-flask-docker/terraform 
```

### 🔹 Step 2: Generate an SSH Key Pair

Generate a new SSH key that will be used to connect to the EC2 instances:
```bash
ssh-keygen -t rsa -b 4096 -f ansible-key
```

This generates:

ansible-key (private key)

ansible-key.pub (public key)

### 🔹 Step 3: Provision AWS Infrastructure Using Terraform
```bash
terraform init
terraform apply
```

✅ This will launch:

**Ansible Controller EC2 Instance**
  - This is the instance where Ansible will be installed and run the playbook to configure the target.

**Target EC2 Instance**
- This is the instance where your Flask app will run inside a Docker container. Ansible will connect to this instance and install Docker, Jenkins, etc.

**Install Ansible** on the controller instance

**Copy necessary files to the controller:**
- ansible-key (SSH private key)
- Set correct file permissions for the private key on the controller (chmod 400)
- playbook.yml (Ansible playbook)
- Auto-generates inventory.ini file (with the private IP of the target node)

**❗Note: Terraform does NOT run the playbook automatically. This is because, right after the EC2 instance is created, it may still be starting up, installing packages, or finishing setup in the background. To avoid any errors, we wait and run the playbook manually after everything settles.**

### 🔹 Step 4: SSH into the Controller EC2
```bash
ssh -i ansible-key ubuntu@controller-public-ip
```

### 🔹 Step 5: Edit the Ansible Playbook on the Controller Instance

Open the playbook:
```bash
nano playbook.yml
```

Modify the playbook:

Delete the following section and save the file(Ctrl+o, enter, Ctrl+x). 
```bash
- name: Prepare Ansible inventory and configure Target Node
  hosts: localhost
  become: false

  tasks:
    - name: Create inventory.ini with target IP
      copy:
        dest: /home/ubuntu/inventory.ini
        content: |
          [web]
          {{ target_private_ip }} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/ansible-ke
```

It's no longer needed since the inventory.ini file is already present. When you run the playbook without removing it tries to generate the inventory dynamically using a variable ({{ target_private_ip }}).

But that variable is passed only when Terraform runs the playbook using remote-exec — not when you run the playbook manually via SSH. So if you keep that part and run the playbook manually, it will fail with an error like:
```bash 
The task includes an option with an undefined variable. The error was: 'target_private_ip' is undefined
```

### 🔹 Step 6: Run the playbook
```bash
ansible-playbook -i inventory.ini playbook.yml
```

### 🔹 Step 7: SSH into the Target EC2 and Retrieve Jenkins Admin Password
```bash
ssh -i ansible-key ubuntu@target-private-ip
```

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 🔹 Step 8: Access Jenkins Web UI

Visit: 
```bash
http://target-public-ip:8080
```

- Paste the admin password
- Select "Install suggested plugins"
- Settings ──► Manage jenkins ──► plugins 

**Install the following plugins:**

- Docker Pipeline
- Docker Commons
- GitHub Integration
- Blue Ocean
- Git Parameter 
- Pipeline: GitHub 
- Pipeline: Stage View

**Create a Docker Hub Personal Access Token**

- Docker Hub ──► Account Settings ──► Personal cccess tokens ──► Generate new token ──► Access token description (eg: jenkins-deploy-token), Expiration date, Access permissions(Read, Write, Delete)──► Generate

Copy the generated token and save it securely

Use this token as the password when adding DockerHub credentials in Jenkins

**Add DockerHub credentials (via Manage Jenkins → Credentials → Global)**

- Username: your DockerHub username
- Password: DockerHub Personal Access Token
- ID: dockerhub-credentials

**Add SSH Credentials in Jenkins (via Manage Jenkins → Credentials → Global)**

- Kind: SSH Username with private key
- ID: controller-ssh-key
- Username: ubuntu
- Private Key: Select Enter directly and paste the content of your private key (ansible-key)

✅ This allows Jenkins to SSH into the Ansible controller and trigger the deployment remotely.

### 🔹 Step 9: Update Controller IP in Jenkinsfile

In your Jenkinsfile, replace the controller-ec2-public-ip with the actual public IP of your controller EC2 instance:
```bash
ssh -o StrictHostKeyChecking=no ubuntu@controller-ec2-public-ip
```

✅ This ensures Jenkins can connect to the controller instance during deployment.

### 🔹 Step 10: Push the project to GitHub

- Go to GitHub and create a new public repository named anisble-flask-dcoker

**Push Your Project Folder to GitHub**

In your terminal, navigate to ansible-flask-docker and run:
```bash
git init
git remote add origin https://github.com/your-username/ansible-flask-docker.git
git add .
git commit -m "Added Flask CI/CD project using Ansible, Jenkins, Docker, and Terraform"
git push -u origin main
```

Make sure to replace your-username with your actual GitHub username

**Set up the Jenkins pipeline**

- Go to Jenkins → New Item → Enter a name (flask-ci-cd-pipeline) → Select Pipeline → Click OK
- Under Pipeline script from SCM:
- SCM: Git
- Repository URL: your GitHub repo URL
- In the "Branch Specifier" field under Pipeline script from SCM, change the default value from */master to */main to match your GitHub branch name.
- Script Path: app/Jenkinsfile
- Click Save, then Build Now

✅ Jenkins will:

- Clone the Flask app repo
- Build the Docker image
- Push it to DockerHub
- Run the Ansible playbook to deploy the container on target EC2

### 🔹 Step 11: Access the Flask App in Browser

Open your app in a browser:
```bash
http://<target-ec2-public-ip>:5000
```

You should see your custom Flask app running inside a Docker container deployed via Ansible 

---

## Output 


---

## About Me

I'm Shravani, a self-taught and project-driven DevOps engineer passionate about building scalable infrastructure and automating complex workflows.

I love solving real-world problems with tools like Terraform, Ansible, Docker, Jenkins, and AWS — and I’m always learning something new to sharpen my edge in DevOps.

**Connect with me:**
- LinkedIn: www.linkedin.com/in/shravani3001
- GitHub: https://github.com/Shravani3001













