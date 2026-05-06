# eks-devops-platform
## Project overview
A production-style Kubernetes platform on AWS using Amazon EKS, designed to demonstrate a complete DevOps workflow:
- Infrastructure as Code with Terraform
- Containerized application deployment via ECR
- GitOps-based delivery using Argo CD
- Automated TLS provisioning with cert-manager
- Dynamic DNS management via ExternalDNS
- CI/CD pipelines with GitHub Actions

## Architecture overview
- Terraform provisions and manages AWS infrastructure (VPC, EKS, IAM, ECR, networking)
- GitHub Actions runs separate pipelines for application builds (image to ECR) and infrastructure changes (Terraform)
    - GitHub Actions handles:
    - Application pipeline → build & push Docker images to ECR
    - Infrastructure pipeline → Terraform plan/apply
- Amazon EKS runs the Kubernetes cluster
- ECR (Elastic Container Registry) stores application images
- Argo CD continuously syncs Kubernetes manifests from Git (GitOps)
- Ingress Controller exposes services externally
- cert-manager automatically provisions TLS certificates via Let's Encrypt
- ExternalDNS updates Route 53 records based on Kubernetes resources

## Workflow
### Flow 1 — Application code push (the common case):
- Developer pushes code to the app repo
- GitHub Actions builds the Docker image
- Image is pushed to ECR with a tag
- The Kubernetes manifest in Git is updated to reference the new image tag (or ArgoCD's image updater detects it)
- ArgoCD sees the change, syncs the cluster to match Git
- New pods roll out, old pods terminate

### Flow 2 — Infrastructure change (rare):
- Someone changes Terraform code, opens a PR
- CI runs terraform plan, posts the diff
- PR is reviewed and merged
- CI runs terraform apply against AWS

### Always-on platform components (running continuously, not part of any push):
- Ingress routes incoming traffic to services
- cert-manager watches for Certificate resources and provisions TLS via Let's Encrypt
- ExternalDNS watches Ingress / Service resources and updates Route 53 records to match

## How to Deploy
1. Configure AWS credentials
2. cd terraform/ && terraform init && terraform apply
3. Run bootstrap script: ./bootstrap.sh
4. Configure DNS / domain
5. Trigger app pipeline (manual or via push) to build and push initial image

## Limitations/future work:
- Separate Terraform into persistent state (ECR) and cluster state (VPC, EKS, IAM, etc.) so destroy operations on the cluster cannot affect persistent resources. Add prevent_destroy lifecycle rules as an additional safety layer on persistent resources.
- Security scanning, Checkov for Terraform, Trivy for Docker image
- Add monitoring stack (Prometheus + Grafana)
- Replace bootstrap script with:
    - Terraform-managed Argo CD installation
    - Argo CD managing all platform components (Ingress, cert-manager, ExternalDNS)
- Add ArgoCD Image Updater to automatically update deployment manifests when new images are pushed to ECR. 
- Switch image tags from latest to commit-SHA so updates are detected and rollouts are deterministic