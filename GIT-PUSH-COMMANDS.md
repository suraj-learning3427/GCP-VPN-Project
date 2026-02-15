# 🚀 Git Push Commands

## Step-by-Step Guide to Push to GitHub

### 1. Add Remote Repository
```bash
git remote add origin https://github.com/suraj-learning3427/GCP-VPN-Project.git
```

### 2. Add All Files
```bash
git add .
```

### 3. Commit Changes
```bash
git commit -m "Initial commit: VPN-based air-gapped Jenkins infrastructure on GCP"
```

### 4. Push to GitHub
```bash
git branch -M main
git push -u origin main
```

## Alternative: If Repository Already Exists

If the repository already has content, use force push (⚠️ WARNING: This will overwrite remote):
```bash
git push -u origin main --force
```

## Verify Push
```bash
git remote -v
git log --oneline
```

## Future Updates

After initial push, use these commands for updates:
```bash
git add .
git commit -m "Your commit message"
git push
```

## Troubleshooting

### Authentication Error
If you get authentication error, use Personal Access Token:
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with 'repo' scope
3. Use token as password when prompted

### Or use SSH
```bash
git remote set-url origin git@github.com:suraj-learning3427/GCP-VPN-Project.git
```

## Check Status
```bash
git status
git remote -v
```
