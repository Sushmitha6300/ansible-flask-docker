# Flask App CI/CD with Jenkins, Docker & Ansible

This project demonstrates a complete CI/CD pipeline that uses Jenkins to build and push a Dockerized Flask app to DockerHub, and Ansible to deploy and run the containerized app on an AWS EC2 instance.

---

## Tools & Technologies Used

- **Python (Flask)** – Lightweight web framework used to build the app
- **Docker** – To containerize the Flask application
- **DockerHub** – Remote registry to store and retrieve Docker images
- **Jenkins** – Automates the build and push stages in the CI pipeline
- **Ansible** – Automates deployment of the Docker container on EC2
- **Git & GitHub** – Version control and trigger source for the pipeline
- **AWS EC2** – Cloud instances used for Jenkins and app deployment
- **Terraform** – To provision AWS infrastructure

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

1. Jenkins watches GitHub repo for changes
2. On push:
   - Pulls code
   - Builds Docker image from Dockerfile
   - Pushes image to DockerHub
   - Runs Ansible playbook to deploy container on EC2

---

## Architecture Diagram

---

## Project Structure 
```bash
ansible-flask-docker/
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
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
cd ansible-flask-docker
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
cd terraform
terraform init
terraform apply
```

✅ This will launch:

- Controller EC2 instance – Hosts Jenkins and Ansible, responsible for CI/CD orchestration and deployment automation

- Target EC2 instance – Acts as the deployment environment where the Flask app container is pulled and run

### 🔹 Step 4: SSH into the Controller EC2
```bash
ssh -i ansible-key ubuntu@controller-public-ip
```

### 🔹 Step 5: Copy the Private Key to the Controller EC2

Enter exit on the instance and run this from your project folder(ansible-flask-docker):
```bash
scp -i ansible-key ansible-key ubuntu@controller-public-ip:/home/ubuntu/
```

### 🔹 Step 6: SSH into the Controller EC2:

Run this command in ansible-flask-docker/terraform folder:
```bash
ssh -i ansible-key ubuntu@controller-public-ip
```

Run this command on the Controller EC2:
```bash
chmod 400 ansible-key
```

### 🔹 Step 7: Install Ansible on the Controller

On the controller instance:
```bash
sudo apt update
sudo apt install -y ansible
```

### 🔹 Step 8: Create and Run Ansible Playbook
```bash 
mkdir ansible-setup && cd ansible-setup
nano inventory.ini
```
paste this: 
```bash
[web]
<target-private-ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/ansible-key
```

**Save and Exit:**

Ctrl + o

Click Enter

Ctrl + x

```bash 
nano playbook.yml
```
paste this:
```bash
---
- name: Configure Target Node with Docker and Jenkins
  hosts: web
  become: yes

  tasks:

    - name: Update and upgrade packages
      apt:
        update_cache: yes
        upgrade: dist

    - name: Install Docker
      apt:
        name: docker.io
        state: present

    - name: Enable and start Docker
      systemd:
        name: docker
        enabled: yes
        state: started

    - name: Add ubuntu user to docker group
      user:
        name: ubuntu
        groups: docker
        append: yes

    - name: Install required packages for Jenkins
      apt:
        name:
          - curl
          - gnupg2
          - fontconfig
          - openjdk-17-jdk
        state: present

    - name: Add Jenkins GPG key
      shell: |
        curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
      args:
        executable: /bin/bash

    - name: Add Jenkins repo
      shell: |
        echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
      args:
        executable: /bin/bash

    - name: Update APT cache with Jenkins repo
      apt:
        update_cache: yes

    - name: Install Jenkins
      apt:
        name: jenkins
        state: present

    - name: Enable and start Jenkins
      systemd:
        name: jenkins
        enabled: yes
        state: started

    - name: Add jenkins user to docker group
      user:
        name: jenkins
        groups: docker
        append: yes

    - name: Restart Jenkins
      systemd:
        name: jenkins
        state: restarted

```

**Save and Exit:**

Ctrl + o

Click Enter

Ctrl + x

Run the playbook:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

### 🔹 Step 9: SSH into the Target EC2 and Retrieve Jenkins Admin Password

After running the Ansible playbook from the ansible/ folder on the controller instance, navigate back using "cd .." and SSH into the target node to retrieve the Jenkins initial admin password and verify the setup.

```bash
ssh -i ansible-key ubuntu@target-private-ip
```
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 🔹 Step 10: Access Jenkins Web UI

Visit: 
```bash
http://target-public-ip:8080
```

Paste the admin password

Select "Install suggested plugins"

Settings ──► Manage jenkins ──► plugins 

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

### 🔹 Step 11: Trigger the Jenkins Pipeline

**Push the project to GitHub**

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

- Go to Jenkins → New Item → Enter a name → Select Pipeline
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

### 🔹 Step 12: Access the Flask App in Browser

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













