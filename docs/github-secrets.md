# GitHub Secrets Configuration

For the CI/CD pipeline to work properly, configure the following secrets in your GitHub repository:

## Required Secrets

### Nexus Repository Access
- `NEXUS_URL`: Your Nexus repository URL (e.g., `http://your-nexus.com:8081`)
- `NEXUS_USERNAME`: Nexus username for authentication
- `NEXUS_PASSWORD`: Nexus password for authentication
- `NEXUS_DOCKER_REGISTRY`: Nexus Docker registry URL (e.g., `your-nexus.com:8082`)

### Optional Notification Secrets
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications
- `EMAIL_SMTP_SERVER`: SMTP server for email notifications
- `EMAIL_FROM`: From email address
- `EMAIL_TO`: To email address

## How to Add Secrets

1. Go to your GitHub repository
2. Click on **Settings** tab
3. Click on **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret with the appropriate name and value

## Environment Variables

The following environment variables are configured in the workflow:

```yaml
env:
  NEXUS_URL: ${{ secrets.NEXUS_URL }}
  NEXUS_DOCKER_REGISTRY: ${{ secrets.NEXUS_DOCKER_REGISTRY }}
  NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
  NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
```

## Security Best Practices

- Never commit secrets to your repository
- Use least-privilege access for service accounts
- Rotate secrets regularly
- Monitor secret usage in audit logs
- Use environment-specific secrets for different deployment stages

## Local Development

For local development and testing, use the `.env` file:

```bash
# Copy from template
cp .env.example .env

# Edit with your local values
nano .env
```

The local CI simulator (`scripts/simulate-ci.sh`) will use your local environment configuration.
