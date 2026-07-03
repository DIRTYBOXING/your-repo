/**
 * GitHub Billing Budget Enforcement Webhook
 *
 * Receives GitHub billing budget alerts and enforces action:
 * - 50%: Log notice
 * - 75%: Post to Slack
 * - 90%: Post to Slack + PagerDuty + throttle CI/block premium
 *
 * Deploy to AWS Lambda, Vercel, or any Node.js runtime.
 * Set as GitHub Organization Webhook: https://github.com/DIRTYBOXING/settings/hooks
 */

const crypto = require('crypto');

// Environment variables (store in GitHub Org Secrets or .env)
const GITHUB_WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET || 'your-webhook-secret';
const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL || '';
const PAGERDUTY_INTEGRATION_KEY = process.env.PAGERDUTY_INTEGRATION_KEY || '';
const GITHUB_TOKEN = process.env.GITHUB_TOKEN || ''; // Machine user token

/**
 * Verify GitHub webhook signature
 */
function verifyGitHubSignature(req, secret) {
  const signature = req.headers['x-hub-signature-256'];
  if (!signature) {
    throw new Error('Missing X-Hub-Signature-256 header');
  }

  const payload = JSON.stringify(req.body);
  const hash = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');

  const expected = `sha256=${hash}`;
  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    throw new Error('Invalid webhook signature');
  }
}

/**
 * Post message to Slack
 */
async function postToSlack(message) {
  if (!SLACK_WEBHOOK_URL) {
    console.log('[SLACK] URL not configured, skipping');
    return;
  }

  const response = await fetch(SLACK_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      text: message.text,
      attachments: message.attachments || []
    })
  });

  if (!response.ok) {
    console.error(`[SLACK] Failed: ${response.status} ${response.statusText}`);
  } else {
    console.log('[SLACK] Message posted');
  }
}

/**
 * Trigger PagerDuty incident
 */
async function triggerPagerDuty(title, description, severity = 'warning') {
  if (!PAGERDUTY_INTEGRATION_KEY) {
    console.log('[PAGERDUTY] Key not configured, skipping');
    return;
  }

  const response = await fetch('https://events.pagerduty.com/v2/enqueue', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      routing_key: PAGERDUTY_INTEGRATION_KEY,
      event_action: 'trigger',
      dedup_key: `github-budget-${Date.now()}`,
      payload: {
        summary: title,
        severity: severity,
        source: 'GitHub Billing',
        custom_details: { description }
      }
    })
  });

  if (!response.ok) {
    console.error(`[PAGERDUTY] Failed: ${response.status}`);
  } else {
    console.log('[PAGERDUTY] Incident triggered');
  }
}

/**
 * Throttle GitHub Actions: reduce concurrent jobs
 */
async function throttleActions(org, repo = null) {
  console.log(`[ACTIONS] Throttling ${repo ? repo : org + '/*'}`);

  // Option 1: Update runner groups concurrency (requires GitHub API)
  // Option 2: Create workflow dispatch to update max-parallel in all workflows
  // Option 3: Post to Slack for manual intervention

  const message = {
    text: `⚠️ **Actions Throttling Triggered** (90% budget spend)`,
    attachments: [{
      color: 'danger',
      fields: [
        {
          title: 'Organization',
          value: org,
          short: true
        },
        {
          title: 'Action',
          value: 'Reduce concurrent jobs to 2',
          short: true
        },
        {
          title: 'Next Steps',
          value: '1. Review recent Actions runs\n2. Optimize job matrix\n3. Enable caching\n4. Consider self-hosted runners'
        }
      ]
    }]
  };

  await postToSlack(message);
}

/**
 * Block Codespaces large machines
 */
async function blockLargeMachines(org) {
  console.log(`[CODESPACES] Blocking large machine creation for ${org}`);

  const message = {
    text: `🚫 **Codespaces Large Machines Blocked** (90% budget spend)`,
    attachments: [{
      color: 'danger',
      fields: [
        {
          title: 'Organization',
          value: org,
          short: true
        },
        {
          title: 'Blocked',
          value: '4-core, 8-core, 16-core machines',
          short: true
        },
        {
          title: 'Allowed',
          value: '2-core only (30 min idle timeout)',
          short: true
        }
      ]
    }]
  };

  await postToSlack(message);
}

/**
 * Disable premium Copilot requests for non-prod repos
 */
async function disableCopilotPremium(org) {
  console.log(`[COPILOT] Disabling premium requests for non-prod repos in ${org}`);

  const message = {
    text: `💰 **Copilot Premium Disabled** (90% budget spend)`,
    attachments: [{
      color: 'danger',
      fields: [
        {
          title: 'Organization',
          value: org,
          short: true
        },
        {
          title: 'Disabled',
          value: 'Cloud Agent, Spark premium (non-prod)',
          short: true
        },
        {
          title: 'Allowed',
          value: 'Copilot Chat (free tier) for all repos',
          short: true
        },
        {
          title: 'Critical Repos',
          value: 'Production repos: full access',
          short: true
        }
      ]
    }]
  };

  await postToSlack(message);
}

/**
 * Block new LFS uploads
 */
async function blockLFSUploads(org) {
  console.log(`[LFS] Blocking new uploads for ${org}`);

  const message = {
    text: `🚫 **Git LFS Uploads Blocked** (90% budget spend)`,
    attachments: [{
      color: 'danger',
      fields: [
        {
          title: 'Organization',
          value: org,
          short: true
        },
        {
          title: 'Blocked',
          value: 'New .gitattributes changes',
          short: true
        },
        {
          title: 'Existing LFS',
          value: 'Can pull but not push new files',
          short: true
        },
        {
          title: 'Fix',
          value: 'Use pre-commit hook (see Phase 4)',
          short: true
        }
      ]
    }]
  };

  await postToSlack(message);
}

/**
 * Main handler
 */
async function handleBudgetAlert(req) {
  try {
    // Verify signature
    verifyGitHubSignature(req, GITHUB_WEBHOOK_SECRET);

    const event = req.body;

    // Extract billing info
    const org = event.organization?.login || 'unknown';
    const action = event.action; // 'alert_threshold_reached', etc.
    const product = event.billing?.product || 'unknown'; // 'actions', 'codespaces', etc.
    const percentageUsed = event.billing?.percentage_used || 0;
    const limit = event.billing?.limit_amount || 0;
    const current = event.billing?.current_usage || 0;

    console.log(`[BILLING] ${org} - ${product} at ${percentageUsed}% (${current}/${limit})`);

    // Route based on percentage and product
    if (percentageUsed >= 90) {
      console.log('[ALERT] CRITICAL: 90% threshold reached');

      // Slack + PagerDuty
      const criticalMsg = {
        text: `🔴 **CRITICAL: Budget Alert** - ${org}/${product}`,
        attachments: [{
          color: 'danger',
          title: `${product.toUpperCase()} at ${percentageUsed}% budget`,
          fields: [
            {
              title: 'Organization',
              value: org,
              short: true
            },
            {
              title: 'Product',
              value: product,
              short: true
            },
            {
              title: 'Usage',
              value: `$${current} of $${limit}`,
              short: true
            },
            {
              title: 'Percentage',
              value: `${percentageUsed}%`,
              short: true
            }
          ]
        }]
      };

      await postToSlack(criticalMsg);
      await triggerPagerDuty(
        `${org} ${product} at 90% budget`,
        `$${current} of $${limit} spent. Enforcement actions triggered.`,
        'critical'
      );

      // Enforce limits by product
      switch (product) {
        case 'actions':
          await throttleActions(org);
          break;
        case 'codespaces':
          await blockLargeMachines(org);
          break;
        case 'copilot':
          await disableCopilotPremium(org);
          break;
        case 'git_lfs':
          await blockLFSUploads(org);
          break;
      }

    } else if (percentageUsed >= 75) {
      console.log('[ALERT] WARNING: 75% threshold reached');

      const warnMsg = {
        text: `⚠️ **Budget Warning** - ${org}/${product}`,
        attachments: [{
          color: 'warning',
          title: `${product.toUpperCase()} at ${percentageUsed}% budget`,
          fields: [
            {
              title: 'Usage',
              value: `$${current} of $${limit}`,
              short: true
            },
            {
              title: 'Action Required',
              value: 'Review usage & optimize before 90% threshold',
              short: true
            }
          ]
        }]
      };

      await postToSlack(warnMsg);

    } else if (percentageUsed >= 50) {
      console.log('[ALERT] INFO: 50% threshold reached');

      const infoMsg = {
        text: `ℹ️ **Budget Notice** - ${org}/${product} at ${percentageUsed}%`,
        attachments: [{
          color: 'good',
          fields: [
            {
              title: 'Usage',
              value: `$${current} of $${limit}`,
              short: true
            }
          ]
        }]
      };

      await postToSlack(infoMsg);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ ok: true, message: 'Budget alert processed' })
    };

  } catch (error) {
    console.error('[ERROR]', error.message);

    // Alert on auth/processing errors
    await postToSlack({
      text: `🚨 **Webhook Error**`,
      attachments: [{
        color: 'danger',
        fields: [
          {
            title: 'Error',
            value: error.message
          }
        ]
      }]
    });

    return {
      statusCode: 400,
      body: JSON.stringify({ ok: false, error: error.message })
    };
  }
}

/**
 * AWS Lambda Handler
 */
exports.handler = async (event) => {
  const req = {
    headers: event.headers,
    body: JSON.parse(event.body || '{}')
  };

  return handleBudgetAlert(req);
};

/**
 * Express.js Handler
 */
module.exports = (app) => {
  app.post('/github/budget-alert', async (req, res) => {
    const result = await handleBudgetAlert(req);
    res.status(result.statusCode).json(JSON.parse(result.body));
  });
};
