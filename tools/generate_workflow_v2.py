"""Generate the complete DFC Content Brain v2 workflow JSON."""
import json
import os

# Build the workflow as a Python dict, then serialize
# n8n expression values are just strings in JSON - they contain $json, ={{ }}, etc.

CALLBACK_URL = "https://australia-southeast1-datafightcentral.cloudfunctions.net/n8nContentCallback"
OPENAI_CRED = {"openAiApi": {"id": "kQdVNcAb6F7oXVyn", "name": "OpenAI account"}}
GOOGLE_SA_CRED = {"googleServiceAccount": {"id": "wHl6zJAv1Hjm1Kfa", "name": "Google Service Account account"}}

nodes = []

# ── 1. WEBHOOK TRIGGERS ──────────────────────────────────────────────────

nodes.append({
    "parameters": {"httpMethod": "POST", "path": "dfc-content-brain", "responseMode": "responseNode", "options": {}},
    "id": "webhook-intake", "name": "Webhook",
    "type": "n8n-nodes-base.webhook", "typeVersion": 2,
    "position": [200, 340], "webhookId": "dfc-content-brain",
    "notes": "Receives content requests from DFC Cloud Functions / Flutter app."
})

nodes.append({
    "parameters": {"httpMethod": "POST", "path": "ppv-event-created", "responseMode": "responseNode", "options": {}},
    "id": "ppv-event-webhook", "name": "PPV Event Webhook",
    "type": "n8n-nodes-base.webhook", "typeVersion": 2,
    "position": [200, 1000], "webhookId": "ppv-event-created",
    "notes": "Receives PPV event creation from Flutter N8nService.notifyPPVEventCreated().\nPayload: { eventId, title, sport, fighters, priceCents, promotion, eventDate, requestId }"
})

nodes.append({
    "parameters": {"httpMethod": "POST", "path": "post-fight-results", "responseMode": "responseNode", "options": {}},
    "id": "post-fight-webhook", "name": "Post-Fight Results Webhook",
    "type": "n8n-nodes-base.webhook", "typeVersion": 2,
    "position": [200, 1200], "webhookId": "post-fight-results",
    "notes": "Receives post-fight results from Flutter N8nService.notifyPostFightResults().\nPayload: { eventId, winner, loser, method, round, time, requestId }"
})

# ── 2. FORMAT / NORMALIZE NODES ──────────────────────────────────────────

nodes.append({
    "parameters": {
        "mode": "raw",
        "jsonOutput": """={{ {
  "webInput": $json.body.webInput || '',
  "platform": $json.body.platform || 'all',
  "postType": $json.body.postType || 'text',
  "brandTone": $json.body.brandTone || 'hype',
  "audienceType": $json.body.audienceType || 'fans',
  "niche": $json.body.niche || 'general',
  "objective": $json.body.objective || 'engagement',
  "eventData": $json.body.eventData || {},
  "callbackUrl": $json.body.callbackUrl || '',
  "requestId": $json.body.requestId || 'req_' + Date.now(),
  "_triggerType": "webhook"
} }}"""
    },
    "id": "edit-fields", "name": "Edit Fields",
    "type": "n8n-nodes-base.set", "typeVersion": 3.4,
    "position": [420, 340],
    "notes": "Normalize incoming fields with sensible defaults. Tags _triggerType=webhook."
})

nodes.append({
    "parameters": {
        "mode": "raw",
        "jsonOutput": """={{ {
  "webInput": "NEW PPV EVENT: " + ($json.body.title || '') + "! " + (($json.body.fighters || []).join(' vs ')) + " - " + ($json.body.sport || 'MMA') + " action live on DFC. Promotion: " + ($json.body.promotion || 'DFC') + ". Generate launch promo content for all platforms.",
  "platform": "all",
  "postType": "text",
  "brandTone": "hype",
  "audienceType": "fans",
  "niche": ($json.body.sport || 'mma').toLowerCase(),
  "objective": "conversion",
  "eventData": $json.body,
  "callbackUrl": \"""" + CALLBACK_URL + """",
  "requestId": $json.body.requestId || 'ppv_create_' + Date.now(),
  "_triggerType": "webhook"
} }}"""
    },
    "id": "format-ppv-event", "name": "Format PPV Event",
    "type": "n8n-nodes-base.set", "typeVersion": 3.4,
    "position": [420, 1000],
    "notes": "Formats PPV event creation data into the standard pipeline payload."
})

nodes.append({
    "parameters": {
        "mode": "raw",
        "jsonOutput": """={{ {
  "webInput": "POST-FIGHT RESULTS: " + ($json.body.winner || '') + " defeats " + ($json.body.loser || '') + " by " + ($json.body.method || '') + ". Generate post-fight recap and reaction content.",
  "platform": "all",
  "postType": "text",
  "brandTone": "hype",
  "audienceType": "fans",
  "niche": "mma",
  "objective": "engagement",
  "eventData": $json.body,
  "callbackUrl": \"""" + CALLBACK_URL + """",
  "requestId": $json.body.requestId || 'postfight_' + Date.now(),
  "_triggerType": "webhook"
} }}"""
    },
    "id": "format-post-fight-webhook", "name": "Format Post-Fight Webhook",
    "type": "n8n-nodes-base.set", "typeVersion": 3.4,
    "position": [420, 1200],
    "notes": "Formats post-fight results from Flutter webhook into standard pipeline payload."
})

# ── 3. AI PIPELINE NODES ─────────────────────────────────────────────────

INFO_EXTRACTOR_SYSTEM = """You are a content metadata extractor for a combat sports platform called Data Fight Central (DFC). Extract structured fields from the user's content request. Return JSON only.

Extract:
- platform: target social platform (instagram, linkedin, x, tiktok, threads, facebook, youtube, bluesky, pinterest, all)
- niche: combat sport niche (mma, boxing, muay_thai, kickboxing, bare_knuckle, bkfc, general)
- postType: content format (text, image, video, carousel, reel, story, short)
- brandTone: voice (hype, analytical, motivational, news, edgy, underground)
- audienceType: target audience (fighters, fans, promoters, casual, coaches, all)
- objective: goal (engagement, traffic, awareness, conversion, community)
- topicSummary: 1-sentence summary of the content topic
- fighters: array of fighter names mentioned (empty array if none)
- eventName: event name if mentioned (null if none)
- urgency: low | medium | high (based on time-sensitivity)"""

INFO_EXTRACTOR_USER = """={{ $json.webInput }}

Provided context:
Platform: {{ $json.platform }}
Post Type: {{ $json.postType }}
Brand Tone: {{ $json.brandTone }}
Audience: {{ $json.audienceType }}
Niche: {{ $json.niche }}
Objective: {{ $json.objective }}
Event Data: {{ JSON.stringify($json.eventData) }}"""

nodes.append({
    "parameters": {
        "model": "gpt-4.1-mini",
        "messages": {"values": [
            {"role": "system", "content": INFO_EXTRACTOR_SYSTEM},
            {"role": "user", "content": INFO_EXTRACTOR_USER}
        ]},
        "options": {"temperature": 0.4, "response_format": {"type": "json_object"}}
    },
    "id": "info-extractor", "name": "Information Extractor",
    "type": "@n8n/n8n-nodes-langchain.openAi", "typeVersion": 1.8,
    "position": [860, 340], "credentials": OPENAI_CRED,
    "notes": "GPT-4.1-Mini at 0.4 temp - cost-effective extraction."
})

INTENT_SYSTEM = """You are a combat sports content strategist for Data Fight Central (DFC), the world's first AI-powered fight platform.

Your role: Generate INTENT - the strategic purpose behind this content.

Given the extracted metadata, determine:
1. primary_intent: What is this content trying to achieve? (inform, hype, convert, educate, provoke, celebrate, mourn, predict)
2. content_angle: The specific angle to take (e.g., 'underdog story', 'knockout prediction', 'behind-the-scenes')
3. hook_type: What hook pattern works best? (question, statistic, bold_claim, controversy, nostalgia, prediction, challenge, revelation)
4. cta_type: What call to action? (watch_live, buy_ppv, follow, share, comment, sign_up, download_app, visit_link, none)
5. content_pillars: Array of 2-3 thematic pillars to build around
6. controversy_safe: boolean - is this topic safe to be edgy about?
7. viral_potential: 1-10 score of how shareable this content could be

Return JSON only."""

nodes.append({
    "parameters": {
        "model": "gpt-4.1",
        "messages": {"values": [
            {"role": "system", "content": INTENT_SYSTEM},
            {"role": "user", "content": "={{ JSON.stringify($json) }}"}
        ]},
        "options": {"temperature": 0.2}
    },
    "id": "generate-intent", "name": "Generate Intent",
    "type": "@n8n/n8n-nodes-langchain.openAi", "typeVersion": 1.8,
    "position": [1080, 340], "credentials": OPENAI_CRED,
    "notes": "GPT-4.1 at 0.2 temp - high-accuracy intent reasoning."
})

STRATEGY_SYSTEM = """You are a combat sports content strategist for Data Fight Central.

Develop STRATEGY for the content piece. Think like a fight promoter who understands social media.

Output:
1. belief_to_address: What belief or pain point does the audience hold?
2. myth_to_challenge: What common misconception can we bust? (null if N/A)
3. takeaway: What should the reader walk away thinking/feeling/doing?
4. mindset_shift: What perspective change are we creating?
5. tension_point: What creates dramatic tension?
6. stakes: What are the stakes? (career, legacy, money, pride, history)
7. narrative_device: Which storytelling device? (comparison, timeline, what-if, origin-story, countdown, versus, transformation)

Return JSON only."""

nodes.append({
    "parameters": {
        "model": "gpt-4.1",
        "messages": {"values": [
            {"role": "system", "content": STRATEGY_SYSTEM},
            {"role": "user", "content": "={{ JSON.stringify($json) }}"}
        ]},
        "options": {"temperature": 0.6}
    },
    "id": "strategy-node", "name": "Strategy",
    "type": "@n8n/n8n-nodes-langchain.openAi", "typeVersion": 1.8,
    "position": [1300, 340], "credentials": OPENAI_CRED,
    "notes": "GPT-4.1 at 0.6 temp - balanced reasoning for strategy."
})

EMOTIONAL_SYSTEM = """You are an emotional intelligence engine for Data Fight Central content.

Your job: Frame the emotional arc of this content piece.

Combat sports content MUST hit emotionally - neutral content dies on every platform.

Output:
1. core_emotion: The primary emotion to evoke (awe, anger, excitement, respect, fear, pride, nostalgia, curiosity, defiance)
2. emotional_arc: Array of 3-5 emotions in sequence (e.g., ['curiosity', 'tension', 'shock', 'awe'])
3. tone_modifiers: Array of adjective modifiers for the writing (e.g., ['raw', 'visceral', 'unapologetic', 'electric'])
4. charged_phrases: Array of 5-8 emotionally loaded phrases specific to this topic
5. energy_level: 1-10 - how amped should this content feel?
6. vulnerability_moment: One sentence describing a moment of human vulnerability to include

Return JSON only."""

nodes.append({
    "parameters": {
        "model": "gpt-4.1",
        "messages": {"values": [
            {"role": "system", "content": EMOTIONAL_SYSTEM},
            {"role": "user", "content": "={{ JSON.stringify($json) }}"}
        ]},
        "options": {"temperature": 0.3}
    },
    "id": "emotional-framing", "name": "Emotional Framing",
    "type": "@n8n/n8n-nodes-langchain.openAi", "typeVersion": 1.8,
    "position": [1520, 340], "credentials": OPENAI_CRED,
    "notes": "GPT-4.1 at 0.3 temp - consistent emotional framing."
})

nodes.append({
    "parameters": {
        "mode": "raw",
        "jsonOutput": """={{ {
  "extractedMeta": $('Information Extractor').item.json,
  "intent": $('Generate Intent').item.json,
  "strategy": $('Strategy').item.json,
  "emotionalFrame": $('Emotional Framing').item.json,
  "originalRequest": $input.first().json
} }}"""
    },
    "id": "format-emotional-data", "name": "Format Emotional Data",
    "type": "n8n-nodes-base.set", "typeVersion": 3.4,
    "position": [1740, 340],
    "notes": "Merge all upstream AI outputs into a single context object for the outline step."
})

OUTLINE_SYSTEM = """You are a content architect for Data Fight Central.

Create a STRUCTURAL OUTLINE for the content piece. This is NOT the final content - it's the blueprint.

Output (JSON):
1. hook_idea: The attention-grabbing opener (1-2 sentences max)
2. story_or_idea_summary: The main content body guide (3-5 bullet points)
3. pivot_or_punchline: The key insight, stat, or twist
4. cta_idea: The engagement driver
5. hashtag_strategy: Object with { primary: [3-5 core hashtags], trending: [2-3 piggyback hashtags], branded: ['#DFC', '#DataFightCentral', plus 1-2 sport-specific] }
6. platform_notes: Object with specific formatting notes per platform
7. media_suggestion: What visual/media should accompany this?

Return JSON only."""

nodes.append({
    "parameters": {
        "model": "gpt-4.1",
        "messages": {"values": [
            {"role": "system", "content": OUTLINE_SYSTEM},
            {"role": "user", "content": "={{ JSON.stringify($json) }}"}
        ]},
        "options": {"temperature": 0.7}
    },
    "id": "outline-node", "name": "Outline",
    "type": "@n8n/n8n-nodes-langchain.openAi", "typeVersion": 1.8,
    "position": [1960, 340], "credentials": OPENAI_CRED,
    "notes": "GPT-4.1 at 0.7 temp - creative structure."
})

nodes.append({
    "parameters": {
        "mode": "raw",
        "jsonOutput": """={{ {
  "allContext": {
    "originalRequest": $input.first().json.originalRequest,
    "extractedMeta": $('Information Extractor').item.json,
    "intent": $('Generate Intent').item.json,
    "strategy": $('Strategy').item.json,
    "emotionalFrame": $('Emotional Framing').item.json,
    "outline": $('Outline').item.json
  }
} }}"""
    },
    "id": "format-input", "name": "Format Input",
    "type": "n8n-nodes-base.set", "typeVersion": 3.4,
    "position": [2180, 340],
    "notes": "Consolidate ALL upstream context into a single payload for final generation."
})

GENERATE_SYSTEM = """You are the content engine for Data Fight Central (DFC) - the world's first AI-powered combat sports platform.

You have been given:
- Extracted metadata (topic, platform, niche, audience)
- Strategic intent (angle, hook type, CTA)
- Content strategy (belief to address, myth to bust, narrative device)
- Emotional framing (arc, tone modifiers, charged phrases)
- Structural outline (hook, body guide, punchline, CTA)

Now CREATE THE FINAL CONTENT. This is the polished, ready-to-publish output.

Rules:
1. Match the platform's native format and character limits exactly
2. Use the emotional arc - start where it says, end where it says
3. Incorporate at least 3 of the charged phrases naturally
4. The hook MUST stop a scroller in under 2 seconds
5. Never use generic filler ('In the world of MMA...', 'Combat sports fans know...')
6. Write like a fight insider, not a marketing department
7. Include hashtags from the hashtag strategy
8. If multiple platforms, generate SEPARATE versions optimized for each

Output JSON:
{
  "posts": [{"platform": "instagram", "postType": "text", "caption": "...", "slides": [], "alt_text": "...", "best_time_to_post": "..."}],
  "headline": "1-line headline",
  "summary": "2-3 sentence summary",
  "suggestedMedia": "description of ideal visual",
  "viralScore": 8,
  "toneSummary": "how this content feels in 3 words"
}"""

nodes.append({
    "parameters": {
        "model": "gpt-4o",
        "messages": {"values": [
            {"role": "system", "content": GENERATE_SYSTEM},
            {"role": "user", "content": "={{ JSON.stringify($json.allContext) }}"}
        ]},
        "options": {"temperature": 0.9, "frequency_penalty": 0.3, "presence_penalty": 0.6}
    },
    "id": "generate-content", "name": "Generate Content",
    "type": "@n8n/n8n-nodes-langchain.openAi", "typeVersion": 1.8,
    "position": [2400, 340], "credentials": OPENAI_CRED,
    "notes": "GPT-4o at 0.9 temp - premium model for final creative output."
})

# ── 4. POST-PROCESSING ───────────────────────────────────────────────────

STRINGIFY_CODE = r"""const input = $input.all();
const aiOutput = input[0].json;
let originalRequest = {};
try { originalRequest = $('Edit Fields').item.json; } catch(e) {}
if (!originalRequest.webInput) try { originalRequest = $('Format PPV Event').item.json; } catch(e) {}
if (!originalRequest.webInput) try { originalRequest = $('Format Post-Fight Webhook').item.json; } catch(e) {}
if (!originalRequest.webInput) try { originalRequest = $('Generate Countdown Content').item.json; } catch(e) {}
if (!originalRequest.webInput) try { originalRequest = $('Format Post-Fight Scheduled').item.json; } catch(e) {}

let content;
try {
  content = typeof aiOutput === 'string' ? JSON.parse(aiOutput) : aiOutput;
  if (content.message && content.message.content) {
    content = JSON.parse(content.message.content);
  }
} catch (e) {
  content = { posts: [], headline: 'Generation failed', summary: '', viralScore: 0 };
}

const output = {
  requestId: originalRequest.requestId || 'gen_' + Date.now(),
  callbackUrl: originalRequest.callbackUrl || '',
  source: 'n8n_content_brain',
  generatedAt: new Date().toISOString(),
  platform: originalRequest.platform || 'all',
  postType: originalRequest.postType || 'text',
  brandTone: originalRequest.brandTone || 'hype',
  niche: originalRequest.niche || 'mma',
  objective: originalRequest.objective || 'engagement',
  _triggerType: originalRequest._triggerType || 'scheduled',
  posts: content.posts || [],
  headline: content.headline || '',
  summary: content.summary || '',
  suggestedMedia: content.suggestedMedia || '',
  viralScore: content.viralScore || 0,
  toneSummary: content.toneSummary || '',
  pipeline: {
    extractedMeta: $('Information Extractor').item.json,
    intent: $('Generate Intent').item.json,
    strategy: $('Strategy').item.json,
    emotionalFrame: $('Emotional Framing').item.json,
    outline: $('Outline').item.json
  }
};

return [{ json: output }];"""

nodes.append({
    "parameters": {"jsCode": STRINGIFY_CODE},
    "id": "stringify-json", "name": "stringifyJSON",
    "type": "n8n-nodes-base.code", "typeVersion": 2,
    "position": [2620, 340],
    "notes": "Parse AI output and structure the final DFC pipeline payload."
})

nodes.append({
    "parameters": {
        "conditions": {
            "options": {"caseSensitive": False},
            "conditions": [{
                "id": "trigger-check",
                "leftValue": "={{ $json._triggerType }}",
                "rightValue": "webhook",
                "operator": {"type": "string", "operation": "equals"}
            }]
        }
    },
    "id": "is-webhook-trigger", "name": "Is Webhook Trigger?",
    "type": "n8n-nodes-base.if", "typeVersion": 2,
    "position": [2840, 340],
    "notes": "Routes: TRUE (webhook) -> Respond to Webhook -> Callback. FALSE (scheduled) -> Callback directly."
})

nodes.append({
    "parameters": {"respondWith": "json", "responseBody": "={{ $json }}"},
    "id": "respond-webhook", "name": "Respond to Webhook",
    "type": "n8n-nodes-base.respondToWebhook", "typeVersion": 1.1,
    "position": [3060, 240],
    "notes": "Return generated content back to the webhook caller."
})

CALLBACK_NODE = {
    "parameters": {
        "method": "POST",
        "url": CALLBACK_URL,
        "authentication": "none",
        "sendBody": True,
        "specifyBody": "json",
        "jsonBody": "={{ JSON.stringify($json) }}",
        "options": {"timeout": 10000}
    },
    "type": "n8n-nodes-base.httpRequest", "typeVersion": 4.2
}

cb1 = dict(CALLBACK_NODE)
cb1["id"] = "send-to-callback"
cb1["name"] = "Send to Callback"
cb1["position"] = [3280, 240]
cb1["notes"] = "Forwards content to DFC n8nContentCallback. Stores in Firestore + optionally auto-publishes."
nodes.append(cb1)

cb2 = dict(CALLBACK_NODE)
cb2["id"] = "send-to-callback-scheduled"
cb2["name"] = "Send to Callback (Scheduled)"
cb2["position"] = [3060, 480]
cb2["notes"] = "Same callback for scheduled runs (no webhook response needed)."
# Deep copy parameters
cb2["parameters"] = dict(CALLBACK_NODE["parameters"])
cb2["parameters"]["options"] = dict(CALLBACK_NODE["parameters"]["options"])
nodes.append(cb2)

# ── 5. COUNTDOWN PIPELINE ────────────────────────────────────────────────

nodes.append({
    "parameters": {"rule": {"interval": [{"field": "hours", "hoursInterval": 24}]}},
    "id": "countdown-t24h", "name": "Countdown T-24h",
    "type": "n8n-nodes-base.scheduleTrigger", "typeVersion": 1.2,
    "position": [200, 600],
    "notes": "Fires every 24 hours to check for upcoming events within the next 48h."
})

nodes.append({
    "parameters": {
        "method": "GET",
        "url": "https://firestore.googleapis.com/v1/projects/datafightcentral/databases/(default)/documents/ppv_events",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "googleServiceAccount",
        "sendQuery": True,
        "queryParameters": {"parameters": [
            {"name": "orderBy", "value": "eventDate"},
            {"name": "pageSize", "value": "20"}
        ]},
        "options": {"response": {"response": {"responseFormat": "json"}}}
    },
    "id": "fetch-upcoming-events", "name": "Fetch Upcoming Events",
    "type": "n8n-nodes-base.httpRequest", "typeVersion": 4.2,
    "position": [420, 600], "credentials": GOOGLE_SA_CRED,
    "notes": "Fetches upcoming PPV events from Firestore via REST API."
})

CHECK_EVENT_TIME_CODE = r"""const now = new Date();
const in48h = new Date(now.getTime() + 48 * 60 * 60 * 1000);
const docs = $input.first().json.documents || [];
const upcoming = [];
for (const doc of docs) {
  const fields = doc.fields || {};
  const eventDateStr = fields.eventDate?.timestampValue || fields.eventDate?.stringValue;
  if (!eventDateStr) continue;
  const eventDate = new Date(eventDateStr);
  if (eventDate >= now && eventDate <= in48h) {
    const eventId = doc.name.split('/').pop();
    upcoming.push({
      eventId,
      title: fields.title?.stringValue || fields.eventName?.stringValue || 'Upcoming Event',
      eventDate: eventDateStr,
      mainEvent: fields.mainEvent?.stringValue || '',
      venue: fields.venue?.stringValue || '',
      niche: fields.niche?.stringValue || 'mma',
      promotion: fields.promotion?.stringValue || 'DFC'
    });
  }
}
if (upcoming.length === 0) return [];
return upcoming.map(e => ({ json: e }));"""

nodes.append({
    "parameters": {"jsCode": CHECK_EVENT_TIME_CODE},
    "id": "check-event-time", "name": "Check Event Time",
    "type": "n8n-nodes-base.code", "typeVersion": 2,
    "position": [640, 600],
    "notes": "Filters to events within next 48 hours. Stops flow if none qualify."
})

nodes.append({
    "parameters": {
        "mode": "raw",
        "jsonOutput": '={{ {\n  "webInput": "COUNTDOWN CONTENT: " + $json.title + " is happening in less than 48 hours! Main event: " + $json.mainEvent + ". Venue: " + $json.venue + ". Generate hype countdown content for all platforms.",\n  "platform": "all",\n  "postType": "text",\n  "brandTone": "hype",\n  "audienceType": "fans",\n  "niche": $json.niche || "mma",\n  "objective": "engagement",\n  "eventData": $json,\n  "callbackUrl": "' + CALLBACK_URL + '",\n  "requestId": "countdown_" + $json.eventId + "_" + Date.now(),\n  "_triggerType": "scheduled"\n} }}'
    },
    "id": "generate-countdown-content", "name": "Generate Countdown Content",
    "type": "n8n-nodes-base.set", "typeVersion": 3.4,
    "position": [860, 600],
    "notes": "Formats countdown data into standard pipeline payload. _triggerType=scheduled."
})

# ── 6. POST-FIGHT SCHEDULED PIPELINE ─────────────────────────────────────

nodes.append({
    "parameters": {"rule": {"interval": [{"field": "hours", "hoursInterval": 1}]}},
    "id": "post-fight-trigger", "name": "Post-Fight Trigger",
    "type": "n8n-nodes-base.scheduleTrigger", "typeVersion": 1.2,
    "position": [200, 800],
    "notes": "Fires every hour to check for recently completed events (within last 3 hours)."
})

nodes.append({
    "parameters": {
        "method": "GET",
        "url": "https://firestore.googleapis.com/v1/projects/datafightcentral/databases/(default)/documents/ppv_events",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "googleServiceAccount",
        "sendQuery": True,
        "queryParameters": {"parameters": [
            {"name": "orderBy", "value": "eventDate desc"},
            {"name": "pageSize", "value": "20"}
        ]},
        "options": {"response": {"response": {"responseFormat": "json"}}}
    },
    "id": "fetch-recent-events", "name": "Fetch Recent Events",
    "type": "n8n-nodes-base.httpRequest", "typeVersion": 4.2,
    "position": [420, 800], "credentials": GOOGLE_SA_CRED,
    "notes": "Fetches recent PPV events from Firestore to find completed fights."
})

CHECK_COMPLETED_CODE = r"""const now = new Date();
const threeHoursAgo = new Date(now.getTime() - 3 * 60 * 60 * 1000);
const docs = $input.first().json.documents || [];
const completed = [];
for (const doc of docs) {
  const fields = doc.fields || {};
  const eventDateStr = fields.eventDate?.timestampValue || fields.eventDate?.stringValue;
  if (!eventDateStr) continue;
  const eventDate = new Date(eventDateStr);
  if (eventDate <= now && eventDate >= threeHoursAgo) {
    const eventId = doc.name.split('/').pop();
    completed.push({
      eventId,
      title: fields.title?.stringValue || fields.eventName?.stringValue || 'Recent Event',
      eventDate: eventDateStr,
      mainEvent: fields.mainEvent?.stringValue || '',
      venue: fields.venue?.stringValue || '',
      niche: fields.niche?.stringValue || 'mma',
      promotion: fields.promotion?.stringValue || 'DFC',
      headliner: fields.headliner?.stringValue || ''
    });
  }
}
if (completed.length === 0) return [];
return completed.map(e => ({ json: e }));"""

nodes.append({
    "parameters": {"jsCode": CHECK_COMPLETED_CODE},
    "id": "check-completed-events", "name": "Check Completed Events",
    "type": "n8n-nodes-base.code", "typeVersion": 2,
    "position": [640, 800],
    "notes": "Filters to events completed within last 3 hours. Stops flow if none."
})

nodes.append({
    "parameters": {
        "mode": "raw",
        "jsonOutput": '={{ {\n  "webInput": "POST-FIGHT RECAP: " + $json.title + " just wrapped up! " + ($json.mainEvent ? "Main event: " + $json.mainEvent + ". " : "") + "Venue: " + ($json.venue || "N/A") + ". Generate post-fight reaction content with highlights and fan reactions.",\n  "platform": "all",\n  "postType": "text",\n  "brandTone": "hype",\n  "audienceType": "fans",\n  "niche": $json.niche || "mma",\n  "objective": "engagement",\n  "eventData": $json,\n  "callbackUrl": "' + CALLBACK_URL + '",\n  "requestId": "postfight_" + $json.eventId + "_" + Date.now(),\n  "_triggerType": "scheduled"\n} }}'
    },
    "id": "format-post-fight-scheduled", "name": "Format Post-Fight Scheduled",
    "type": "n8n-nodes-base.set", "typeVersion": 3.4,
    "position": [860, 800],
    "notes": "Formats post-fight recap with REAL event data from Firestore. _triggerType=scheduled."
})

# ── 7. ERROR HANDLER ─────────────────────────────────────────────────────

ERROR_CODE = r"""const error = $input.first().json;
const errorOutput = {
  status: 'pipeline_error',
  error: error.message || error.errorMessage || 'Unknown pipeline error',
  failedNode: error.node || 'unknown',
  timestamp: new Date().toISOString(),
  requestId: 'error_' + Date.now()
};
console.log('DFC Content Brain pipeline error:', JSON.stringify(errorOutput));
return [{ json: errorOutput }];"""

nodes.append({
    "parameters": {"jsCode": ERROR_CODE},
    "id": "error-handler", "name": "Error Handler",
    "type": "n8n-nodes-base.code", "typeVersion": 2,
    "position": [2620, 600],
    "notes": "Catches pipeline errors and logs them."
})

# ── CONNECTIONS ───────────────────────────────────────────────────────────

def conn(target, index=0):
    return [{"node": target, "type": "main", "index": index}]

connections = {
    "Webhook":                    {"main": [conn("Edit Fields")]},
    "PPV Event Webhook":          {"main": [conn("Format PPV Event")]},
    "Post-Fight Results Webhook": {"main": [conn("Format Post-Fight Webhook")]},
    "Edit Fields":                {"main": [conn("Information Extractor")]},
    "Format PPV Event":           {"main": [conn("Information Extractor")]},
    "Format Post-Fight Webhook":  {"main": [conn("Information Extractor")]},
    "Information Extractor":      {"main": [conn("Generate Intent")]},
    "Generate Intent":            {"main": [conn("Strategy")]},
    "Strategy":                   {"main": [conn("Emotional Framing")]},
    "Emotional Framing":          {"main": [conn("Format Emotional Data")]},
    "Format Emotional Data":      {"main": [conn("Outline")]},
    "Outline":                    {"main": [conn("Format Input")]},
    "Format Input":               {"main": [conn("Generate Content")]},
    "Generate Content":           {"main": [conn("stringifyJSON")]},
    "stringifyJSON":              {"main": [conn("Is Webhook Trigger?")]},
    "Is Webhook Trigger?":        {"main": [conn("Respond to Webhook"), conn("Send to Callback (Scheduled)")]},
    "Respond to Webhook":         {"main": [conn("Send to Callback")]},
    "Countdown T-24h":            {"main": [conn("Fetch Upcoming Events")]},
    "Fetch Upcoming Events":      {"main": [conn("Check Event Time")]},
    "Check Event Time":           {"main": [conn("Generate Countdown Content")]},
    "Generate Countdown Content":  {"main": [conn("Information Extractor")]},
    "Post-Fight Trigger":         {"main": [conn("Fetch Recent Events")]},
    "Fetch Recent Events":        {"main": [conn("Check Completed Events")]},
    "Check Completed Events":     {"main": [conn("Format Post-Fight Scheduled")]},
    "Format Post-Fight Scheduled": {"main": [conn("Information Extractor")]},
}

# ── ASSEMBLE ──────────────────────────────────────────────────────────────

workflow = {
    "id": "dfc-content-brain-v2",
    "name": "DFC Content Brain: AI Fight Content Generator",
    "nodes": nodes,
    "connections": connections,
    "settings": {
        "executionOrder": "v1",
        "saveManualExecutions": True,
        "saveExecutionProgress": True
    },
    "staticData": None,
    "tags": [
        {"id": "1", "name": "DFC"},
        {"id": "2", "name": "content-generation"},
        {"id": "3", "name": "ai-pipeline"},
        {"id": "4", "name": "v2-complete"}
    ],
    "meta": {
        "templateCredsSetupCompleted": True
    },
    "pinData": {}
}

# Write
output_path = os.path.join(os.path.dirname(__file__), "n8n-dfc-content-brain-workflow.json")
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(workflow, f, indent=2, ensure_ascii=False)

print(f"Written {len(nodes)} nodes to {output_path}")
print(f"Entry paths: 5 (Webhook, PPV Event, Post-Fight Results, Countdown Schedule, Post-Fight Schedule)")
print(f"Connections: {len(connections)}")
