Operations Runbook
Author: Jesus Gracia
Version: 3.0.0
Daily Tasks
bash# Health check
az vm show -g rg-swissre-prod -n vm-swissre-prod

# Check alerts
az monitor alert list -g rg-swissre-prod
Deployment
bash./scripts/deploy.sh dev 3
./scripts/deploy.sh prod 3
Incident Response

L1: Automated (0 min)
L2: Operations (15 min)
L3: Engineering (30 min)


Copyright 2025 Jesus Gracia