# GitHub Billing & Budget Setup for DIRTYBOXING

## Phase 1: Unblock and Configure Billing

### Step 1: Verify Payment Method
1. Go to **GitHub.com** → **Settings** (top-right profile) → **Billing and plans**
2. Click **Billing** in left sidebar
3. Under **Payment method**, click **Add payment method**
   - Card type: Credit/Debit
   - Fill in card details
   - Set as default
4. Click **Update payment method** → **Save**

### Step 2: Set Organization Spending Limit
1. From **Settings**, go to **Organizations** (left sidebar) → select **DIRTYBOXING**
2. In org settings, go to **Billing and plans**
3. Under **Billing**, find **Spending limit**
4. Set spending limit to **$500/month** (adjust based on budget)
   - Or remove limit if unconstrained budget
5. Click **Update spending limit**

---

## Phase 2: Create Product Budgets

### Budget 1: GitHub Actions
1. Stay in **DIRTYBOXING org** → **Billing**
2. Under **Budgets**, click **Create a budget**
   - **Product**: GitHub Actions
   - **Amount**: $250/month (adjust as needed)
   - **Period**: Monthly
   - **Notification threshold**: 50%, 75%, 90%
   - **Notification channels**: Email (to eng-lead@company.com)
3. Click **Create budget**

### Budget 2: Codespaces
1. Click **Create a budget**
   - **Product**: Codespaces
   - **Amount**: $150/month
   - **Period**: Monthly
   - **Notification threshold**: 50%, 75%, 90%
   - **Notification channels**: Email
2. Click **Create budget**

### Budget 3: GitHub Copilot (Cloud Agent + Premium)
1. Click **Create a budget**
   - **Product**: GitHub Copilot
   - **Amount**: $100/month
   - **Period**: Monthly
   - **Notification threshold**: 50%, 75%, 90%
   - **Notification channels**: Email
2. Click **Create budget**

### Budget 4: Git LFS
1. Click **Create a budget**
   - **Product**: Git LFS
   - **Amount**: $50/month
   - **Period**: Monthly
   - **Notification threshold**: 50%, 75%
2. Click **Create budget**

---

## Phase 3: Enable Advanced Alerting

### Webhook for Budget Alerts
If your organization has Slack/PagerDuty integration:

1. Go to **DIRTYBOXING org** → **Settings** → **Webhooks**
2. Click **Add webhook**
   - **Payload URL**: `https://your-webhook-receiver.com/github/budget-alert`
   - **Content type**: `application/json`
   - **Secret**: Generate strong token, store in org secrets
   - **Events**: `billing` (if available) or custom events
3. Click **Add webhook**

---

## Phase 4: Enforce Spending Limits at Critical Threshold

### At 90% Budget Spend:
- **Actions**: Reduce concurrent job limit from 10 to 2 (via workflow matrix)
- **Codespaces**: Disable large machine creation (enforce 2-core default)
- **Copilot**: Rate-limit premium requests or disable Cloud Agent for non-prod repos
- **LFS**: Block new LFS uploads with pre-commit hook

*See webhook enforcement script (Phase 2) for automation details.*

---

## Phase 5: Organization Secrets for CI/CD

### Store PROD Credentials
1. Go to **DIRTYBOXING org** → **Settings** → **Secrets and variables** → **Actions**
2. Click **New organization secret**
   - **Name**: `PROD_API_KEY`
   - **Value**: (paste key, never commit to repo)
   - **Repository access**: Select only `Data-Fight-Central` and critical repos
3. Repeat for:
   - `PROD_DATABASE_URL`
   - `STRIPE_SECRET_KEY`
   - `FIREBASE_SERVICE_ACCOUNT_JSON`
   - `SLACK_WEBHOOK_URL`
   - `GITHUB_TOKEN_MACHINE_USER`

---

## Phase 6: Budget Owners and Approval Workflow

### Assign Budget Owners
- **Finance Lead**: Tracks monthly spend, approves overages
- **Engineering Lead**: Monitors Actions usage, optimizes CI jobs
- **DevOps Owner**: Manages Codespaces, LFS, and enforcement

### Override Process
1. **50% threshold**: Auto-email to owners (no action)
2. **75% threshold**: Email + Slack alert (prepare to optimize)
3. **90% threshold**: Email + Slack + PagerDuty page (immediate action required)
4. **Override**: Only Finance Lead + Eng Lead can approve spending over limit

---

## Quick Checklist

- [ ] Add payment method
- [ ] Set org spending limit ($500/month)
- [ ] Create Actions budget ($250/month)
- [ ] Create Codespaces budget ($150/month)
- [ ] Create Copilot budget ($100/month)
- [ ] Create LFS budget ($50/month)
- [ ] Configure notification thresholds (50%, 75%, 90%)
- [ ] Set up webhook to alert Slack/PagerDuty
- [ ] Store PROD secrets in org secrets
- [ ] Document budget owners in CODEOWNERS
- [ ] Schedule weekly budget review (Monday 9 AM)

---

## Next Steps
→ **Phase 2**: Webhook Enforcement Script (Node.js)
→ **Phase 3**: Branch Protection Policy
→ **Phase 4**: Pre-Commit Hooks
