# Monitored Web Server on AWS EC2 with Terraform

Terraform project that deploys an Nginx web server on Amazon EC2 inside its own VPC, with CloudWatch alarms that email you when the server is overloaded or fails a health check. Access is through SSM Session Manager, so there is no SSH port open to the internet.

---

## The Problem It Solves

A web server that nobody watches fails quietly. Nobody finds out until a visitor complains, and the usual way to log in and investigate, SSH, means opening a port and managing keys. This project shows a safer and more repeatable setup: the whole server, its network and its alerts are defined as code, you are told when something is wrong, and you can still get a shell on the machine without exposing it.

---

## What It Does

1. Creates a VPC with a public subnet, an internet gateway and a route table.
2. Launches an EC2 instance running Amazon Linux 2023. Nginx is installed at first boot and serves a simple page.
3. Allows web traffic on port 80 only. There is no SSH port.
4. Attaches an IAM role so you can open a shell through SSM Session Manager.
5. Creates two CloudWatch alarms that send email through an SNS topic:
   - **High CPU:** average CPU above 70 percent for two five-minute periods. It also emails you when the CPU returns to normal.
   - **Status check failed:** the instance fails an EC2 health check.

---

## Architecture

```text
 Visitor
    |  HTTP (port 80)
    v
 Internet Gateway
    |
 VPC 10.0.0.0/16
 +-------------------------------------------+
 |  Public subnet 10.0.1.0/24                |
 |    EC2 instance (Amazon Linux 2023)       |
 |    - Nginx installed by user data         |
 |    - Security group: port 80 only         |
 |    - IAM role for SSM Session Manager     |
 +-------------------------------------------+
         |
         |  CPU and status check metrics
         v
 CloudWatch alarms ----> SNS topic ----> Email
```

---

## Key Components

| Resource | Role |
|---|---|
| VPC, public subnet, internet gateway, route table | The network the server lives in |
| Security group | Allows HTTP on port 80 from anywhere, with no SSH rule |
| EC2 instance | `t3.micro` running Nginx. Encrypted 8 GB gp3 disk, and IMDSv2 required |
| IAM role and instance profile | Uses the AWS managed `AmazonSSMManagedInstanceCore` policy so SSM can manage the instance |
| SNS topic and email subscription | Delivers alarm notifications |
| CloudWatch alarms | High CPU and failed status check |

### Security choices

- **No SSH.** Port 22 is closed. You connect through SSM Session Manager, which needs no key pair and leaves no open port.
- **IMDSv2 required.** The instance metadata service only answers authenticated requests, which blocks a common way of stealing instance credentials.
- **Encrypted disk.** The root volume is encrypted.
- **Least privilege.** The instance role can only do what SSM needs.

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `alert_email` | none, required | Address that receives alarm notifications |
| `instance_type` | `t3.micro` | EC2 instance type |
| `cpu_alarm_threshold` | `70` | Average CPU percentage that triggers the high CPU alarm |
| `aws_region` | `us-east-1` | Region to deploy into |
| `availability_zone` | `us-east-1a` | Availability zone for the subnet |
| `project_name` | `monitored-web-server` | Prefix for resource names and the `Project` tag |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `public_subnet_cidr` | `10.0.1.0/24` | Public subnet CIDR block |

### Outputs

| Output | Description |
|---|---|
| `website_url` | Public address of the web server |
| `instance_id` | ID of the EC2 instance |
| `ssm_connect_command` | AWS CLI command that opens a shell on the instance |

---

## Things to Know

- **Confirm the email once.** After the first deploy, AWS sends a confirmation email to your alert address. The alarms cannot email you until you click **Confirm subscription**.
- **The site is HTTP only.** There is no certificate, so the browser shows "Not secure". HTTPS would need a load balancer or CloudFront with an ACM certificate.
- **The public IP is not permanent.** It changes if the instance is stopped and started. A fixed address would need an Elastic IP.
- **It is a single server.** If the instance fails, the site is down until it is replaced. This is a monitoring project, not a high-availability one.
- **The AMI is the latest at plan time.** When Amazon publishes a newer Amazon Linux 2023 image, the next `terraform plan` can show the instance being replaced. Read the plan before applying.
- **User data runs once.** Changing `user_data.sh` replaces the instance, because the script only runs at first boot.
- **Give it a minute.** Nginx is installed while the instance boots, so the page can take a minute or two to appear after the deploy.
- **The instance costs money while it runs.** Billing is per hour. Destroy the stack when you are done.
- **No memory or disk alarms.** EC2 does not report memory or disk usage to CloudWatch unless you install the CloudWatch agent.

---

## Project Structure

```text
terraform-monitored-web-server/
├── main.tf          # Network, security group, IAM, EC2, SNS and alarms
├── variables.tf     # Region, instance type, alert email, thresholds
├── outputs.tf       # Website URL, instance ID, SSM command
├── providers.tf     # Provider versions and S3 remote backend
├── user_data.sh     # Installs Nginx and writes the web page at first boot
└── README.md
```

---

## Deployment

Prerequisites: an AWS account with the AWS CLI configured, Terraform `>= 1.0.0`, and an S3 bucket for remote state (set in `providers.tf`, and it must exist before `terraform init`).

Create a `terraform.tfvars` file (ignored by Git):

```hcl
alert_email = "you@example.com"
```

Then deploy:

```bash
terraform init
terraform plan
terraform apply
```

Click **Confirm subscription** in the email AWS sends you, then open the `website_url` output in a browser.

### Connect to the server

In the AWS console, open EC2, select the instance, click **Connect** and choose the **Session Manager** tab. Or, with the AWS CLI and the Session Manager plugin installed, run the `ssm_connect_command` output.

### Test the CPU alarm

In the Session Manager shell on the instance:

```bash
sudo dnf install -y stress-ng
stress-ng --cpu 2 --timeout 900s
```

After roughly 10 to 15 minutes of high CPU, the high CPU alarm should move to the ALARM state and send an email. When the load ends, it returns to OK and sends a second email.

### Tear down

```bash
terraform destroy
```

---

## Ideas for Extending It

- Put the server behind an Application Load Balancer and an Auto Scaling group for high availability
- Add HTTPS with an ACM certificate
- Install the CloudWatch agent to collect memory and disk metrics, and add alarms for them
- Add a CloudWatch dashboard for CPU, network traffic and status checks
- Add a GitHub Actions workflow that runs `terraform fmt` and `validate` on every pull request