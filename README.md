# Usage

Saying you are in the root folder of all your repo

### Scan local repo

```
bash trivy-scan.sh --repo-path /path/to/project
```

### With Docker image scan

```
bash trivy-scan.sh --repo-path /path/to/project --image myapp:latest
```

### Customize severity and output location

```
bash trivy-scan.sh --repo-path /path/to/project --severity CRITICAL,HIGH --output-dir ./reports
```

### Scan remote repo

```
bash trivy-remote-scan.sh --url https://github.com/user/repo.git
```

### Scan all repos in a folder

Place `trivy-scan-all.sh` at the root of a folder containing multiple project subdirectories:

```
bash trivy-scan-all.sh
```

#### With options

```
bash trivy-scan-all.sh --root /path/to/projects --severity HIGH --skip node_modules
```

| Option | Description |
|--------|-------------|
| `--root DIR` | Root directory containing repos (default: current directory) |
| `--severity LIST` | Comma-separated severity levels (default: `CRITICAL,HIGH,MEDIUM`) |
| `--output-dir DIR` | Output directory (default: `./trivy-reports`) |
| `--skip NAME` | Subdirectory name(s) to skip (repeatable) |

## Scripts

| Script | Purpose |
|--------|---------|
| `trivy-scan.sh` | Scan a single local repository |
| `trivy-remote-scan.sh` | Clone a remote repo and scan it |
| `trivy-scan-all.sh` | Scan all subdirectories in a folder at once |
