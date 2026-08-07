# Usage

Saying you are in the root folder of all your repo

### Scan any repo

```
bash scripts/trivy-scan.sh --repo-path /path/to/project
```

### With Docker image scan

```
bash scripts/trivy-scan.sh --repo-path /path/to/project --image myapp:latest
```

### Customize severity and output location

```
bash scripts/trivy-scan.sh --repo-path /path/to/project --severity CRITICAL,HIGH --output-dir ./reports
```
