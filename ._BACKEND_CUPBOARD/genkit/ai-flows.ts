/**
 * ═══════════════════════════════════════════════════════════════════════════
 * DATAFIGHTCENTRAL GENKIT AI FLOWS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Server-side AI orchestration for DataFightCentral
 *
 * ARCHITECTURE RULES:
 * ✓ AI NEVER writes directly to Firestore
 * ✓ AI NEVER makes decisions - only explains and suggests
 * ✓ AI NEVER diagnoses medical conditions
 * ✓ All AI outputs are logged for audit
 * ✓ Human escalation paths always available
 *
 * DEPLOYMENT:
 * This file is deployed as Firebase Cloud Functions via Genkit
 *
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { genkit, z } from "genkit";
import { googleAI, gemini15Flash, gemini15Pro } from "@genkit-ai/googleai";
import * as admin from "firebase-admin";

// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

const ai = genkit({
  plugins: [
    googleAI({
      apiKey:
        process.env.GOOGLE_GENAI_API_KEY ?? process.env.GOOGLE_AI_API_KEY ?? "",
    }),
  ],
});

admin.initializeApp();
const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════════════════
// SCHEMAS
// ═══════════════════════════════════════════════════════════════════════════

const HealthSignalSchema = z.object({
  userId: z.string(),
  signalDate: z.string(),
  recoveryScore: z.number(),
  trainingReadiness: z.number(),
  fightReadiness: z.number(),
  stressLoad: z.number(),
  fatigueIndex: z.number(),
  overallRisk: z.enum(["green", "amber", "orange", "red"]),
  hydrationRisk: z.enum(["green", "amber", "orange", "red"]),
  overtrainingRisk: z.enum(["green", "amber", "orange", "red"]),
  sleepDebtRisk: z.enum(["green", "amber", "orange", "red"]),
  weightCutRisk: z.enum(["green", "amber", "orange", "red"]),
  mentalHealthRisk: z.enum(["green", "amber", "orange", "red"]),
  activeFlags: z.array(z.string()),
  primaryRecommendation: z.string().optional(),
});

const AIInsightRequestSchema = z.object({
  userId: z.string(),
  signal: HealthSignalSchema,
  context: z
    .object({
      daysUntilFight: z.number().optional(),
      currentPhase: z.string().optional(),
      userPreferences: z
        .object({
          tone: z.enum(["friendly", "intense", "clinical"]).optional(),
          language: z.string().optional(),
        })
        .optional(),
    })
    .optional(),
});

const AIInsightResponseSchema = z.object({
  summary: z.string(),
  interpretation: z.string(),
  encouragement: z.string(),
  actionItems: z.array(z.string()),
  safetyNote: z.string().optional(),
  escalationTriggered: z.boolean(),
});

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM PROMPTS
// ═══════════════════════════════════════════════════════════════════════════

const SYSTEM_PROMPT_BASE = `
You are the AI Coach for DataFightCentral, a combat sports intelligence platform.

IDENTITY:
- You are supportive, knowledgeable, and safety-focused
- You speak like a respected coach who has been in the game for decades
- You never use medical terminology or make diagnoses
- You are calm even when data shows concerning patterns

CRITICAL RULES:
1. NEVER diagnose any medical condition
2. NEVER prescribe treatments, supplements, or medications
3. NEVER encourage pushing through pain or ignoring warning signs
4. ALWAYS suggest professional consultation for concerning patterns
5. ALWAYS maintain a supportive, non-judgmental tone
6. NEVER use fear tactics or catastrophizing language
7. ALWAYS acknowledge the fighter's effort and commitment

VOICE GUIDELINES:
- Use "we" language: "Let's look at this together"
- Be specific but not alarmist
- Acknowledge both challenges and strengths
- End with actionable, positive direction
`;

const SYSTEM_PROMPT_FRIENDLY = `${SYSTEM_PROMPT_BASE}

TONE: Friendly and encouraging
- Use conversational language
- Include appropriate encouragement
- Make the fighter feel supported
- Use phrases like "You've got this" and "Nice work"
`;

const SYSTEM_PROMPT_INTENSE = `${SYSTEM_PROMPT_BASE}

TONE: Intense and focused
- Be direct and no-nonsense
- Focus on what matters for performance
- Use phrases like "Here's what we're dealing with" and "Time to lock in"
- Still maintain safety-first approach
`;

const SYSTEM_PROMPT_CLINICAL = `${SYSTEM_PROMPT_BASE}

TONE: Clinical and analytical
- Use precise, measured language
- Present data clearly without emotional language
- Focus on objective observations
- Professional and detached but still supportive
`;

// ═══════════════════════════════════════════════════════════════════════════
// MAIN AI INSIGHT FLOW
// ═══════════════════════════════════════════════════════════════════════════

export const generateDailyInsight = ai.defineFlow(
  {
    name: "generateDailyInsight",
    inputSchema: AIInsightRequestSchema,
    outputSchema: AIInsightResponseSchema,
  },
  async (input) => {
    // Select appropriate system prompt based on tone preference
    let systemPrompt = SYSTEM_PROMPT_FRIENDLY;
    if (input.context?.userPreferences?.tone === "intense") {
      systemPrompt = SYSTEM_PROMPT_INTENSE;
    } else if (input.context?.userPreferences?.tone === "clinical") {
      systemPrompt = SYSTEM_PROMPT_CLINICAL;
    }

    // Build context for the AI
    const contextParts = [];

    if (input.context?.daysUntilFight) {
      contextParts.push(`Days until fight: ${input.context.daysUntilFight}`);
    }
    if (input.context?.currentPhase) {
      contextParts.push(`Current phase: ${input.context.currentPhase}`);
    }

    const prompt = `
${systemPrompt}

CURRENT HEALTH SIGNAL DATA:
- Recovery Score: ${(input.signal.recoveryScore * 100).toFixed(0)}%
- Training Readiness: ${(input.signal.trainingReadiness * 100).toFixed(0)}%
- Fight Readiness: ${(input.signal.fightReadiness * 100).toFixed(0)}%
- Stress Load: ${(input.signal.stressLoad * 100).toFixed(0)}%
- Fatigue Index: ${(input.signal.fatigueIndex * 100).toFixed(0)}%

RISK LEVELS:
- Overall: ${input.signal.overallRisk.toUpperCase()}
- Hydration: ${input.signal.hydrationRisk}
- Overtraining: ${input.signal.overtrainingRisk}
- Sleep Debt: ${input.signal.sleepDebtRisk}
- Weight Cut: ${input.signal.weightCutRisk}
- Mental Health: ${input.signal.mentalHealthRisk}

ACTIVE FLAGS:
${input.signal.activeFlags.length > 0 ? input.signal.activeFlags.map((f) => `- ${f}`).join("\n") : "- None"}

${contextParts.length > 0 ? `CONTEXT:\n${contextParts.join("\n")}` : ""}

TASK:
Generate a daily insight for this fighter. Provide:
1. A one-sentence summary of their current state
2. A 2-3 sentence interpretation of what the data means
3. An encouraging message
4. 2-4 specific action items for today
5. A safety note ONLY if there are concerning flags (otherwise omit)

Remember: You are their coach, not their doctor. Support, don't prescribe.
`;

    // Call Gemini via Genkit 1.0 API
    const { text } = await ai.generate({
      model: gemini15Flash,
      prompt,
      config: {
        temperature: 0.7,
        maxOutputTokens: 1024,
      },
    });

    // Parse the response (simplified - in production, use structured output)
    const insight = parseAIResponse(text, input.signal);

    // Log for audit
    await logAIInteraction(
      input.userId,
      "generateDailyInsight",
      input,
      insight,
    );

    return insight;
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// WEIGHT CUT GUIDANCE FLOW
// ═══════════════════════════════════════════════════════════════════════════

const WeightCutRequestSchema = z.object({
  userId: z.string(),
  currentWeight: z.number(),
  targetWeight: z.number(),
  daysUntilWeighIn: z.number(),
  hydrationPercentage: z.number().optional(),
  weightCutPhase: z.string(),
  recentWeightHistory: z
    .array(
      z.object({
        date: z.string(),
        weight: z.number(),
      }),
    )
    .optional(),
});

const WeightCutResponseSchema = z.object({
  assessment: z.string(),
  riskLevel: z.enum(["safe", "moderate", "elevated", "dangerous"]),
  dailyGuidance: z.string(),
  hydrationAdvice: z.string(),
  warningFlags: z.array(z.string()),
  professionalConsultAdvised: z.boolean(),
});

export const analyzeWeightCut = ai.defineFlow(
  {
    name: "analyzeWeightCut",
    inputSchema: WeightCutRequestSchema,
    outputSchema: WeightCutResponseSchema,
  },
  async (input) => {
    const weightToLose = input.currentWeight - input.targetWeight;
    const percentToLose = (weightToLose / input.currentWeight) * 100;
    const dailyLossRequired =
      weightToLose / Math.max(1, input.daysUntilWeighIn);
    const dailyPercentRequired =
      (dailyLossRequired / input.currentWeight) * 100;

    // Deterministic risk calculation
    let riskLevel: "safe" | "moderate" | "elevated" | "dangerous" = "safe";
    const warningFlags: string[] = [];

    if (percentToLose > 10) {
      riskLevel = "dangerous";
      warningFlags.push("extreme_weight_loss_target");
    } else if (percentToLose > 7) {
      riskLevel = "elevated";
      warningFlags.push("high_weight_loss_target");
    } else if (percentToLose > 5) {
      riskLevel = "moderate";
    }

    if (dailyPercentRequired > 1.5) {
      riskLevel = "dangerous";
      warningFlags.push("dangerous_daily_rate");
    } else if (dailyPercentRequired > 1) {
      if (riskLevel !== "dangerous") riskLevel = "elevated";
      warningFlags.push("aggressive_daily_rate");
    }

    if (input.hydrationPercentage && input.hydrationPercentage < 50) {
      warningFlags.push("low_hydration");
      if (riskLevel === "safe") riskLevel = "moderate";
    }

    if (input.daysUntilWeighIn <= 2 && percentToLose > 3) {
      riskLevel = "dangerous";
      warningFlags.push("insufficient_time");
    }

    const prompt = `
${SYSTEM_PROMPT_BASE}

WEIGHT CUT ANALYSIS REQUEST:

Current Weight: ${input.currentWeight} kg
Target Weight: ${input.targetWeight} kg
Weight to Lose: ${weightToLose.toFixed(1)} kg (${percentToLose.toFixed(1)}%)
Days Until Weigh-In: ${input.daysUntilWeighIn}
Daily Loss Required: ${dailyLossRequired.toFixed(2)} kg/day (${dailyPercentRequired.toFixed(2)}%/day)
Current Phase: ${input.weightCutPhase}
${input.hydrationPercentage ? `Hydration: ${input.hydrationPercentage}%` : ""}

CALCULATED RISK LEVEL: ${riskLevel.toUpperCase()}
ACTIVE FLAGS: ${warningFlags.join(", ") || "None"}

TASK:
Provide weight cut guidance in the following format:
1. Brief assessment of the current situation
2. Daily guidance for today
3. Hydration advice specific to their phase
4. Any safety concerns to be aware of

CRITICAL RULES FOR WEIGHT CUT ADVICE:
- NEVER suggest extreme measures like saunas, diuretics, or laxatives
- NEVER encourage skipping water in early phases
- ALWAYS emphasize gradual, sustainable approaches
- If the cut looks dangerous, say so clearly but calmly
- Suggest consulting professionals for any elevated or dangerous cuts
`;

    const { text } = await ai.generate({
      model: gemini15Flash,
      prompt,
      config: {
        temperature: 0.5,
        maxOutputTokens: 800,
      },
    });

    // Parse and structure the response
    const result: z.infer<typeof WeightCutResponseSchema> = {
      assessment:
        extractSection(text, "assessment") || "Weight cut analysis complete.",
      riskLevel,
      dailyGuidance:
        extractSection(text, "guidance") || "Focus on gradual progress today.",
      hydrationAdvice:
        extractSection(text, "hydration") ||
        "Maintain consistent water intake.",
      warningFlags,
      professionalConsultAdvised:
        riskLevel === "elevated" || riskLevel === "dangerous",
    };

    await logAIInteraction(input.userId, "analyzeWeightCut", input, result);

    return result;
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// MENTAL WELLNESS CHECK FLOW
// ═══════════════════════════════════════════════════════════════════════════

const WellnessCheckRequestSchema = z.object({
  userId: z.string(),
  moodScore: z.number().min(1).max(10),
  stressLevel: z.number().min(1).max(10),
  energyLevel: z.number().min(1).max(10),
  recentMoodHistory: z.array(z.number()).optional(),
  notes: z.string().optional(),
  context: z.string().optional(),
});

const WellnessCheckResponseSchema = z.object({
  acknowledgment: z.string(),
  reflection: z.string(),
  supportMessage: z.string(),
  suggestedActivities: z.array(z.string()),
  resourcesOffered: z.boolean(),
  escalationTriggered: z.boolean(),
});

export const wellnessCheck = ai.defineFlow(
  {
    name: "wellnessCheck",
    inputSchema: WellnessCheckRequestSchema,
    outputSchema: WellnessCheckResponseSchema,
  },
  async (input) => {
    // Check for crisis indicators
    const isCritical =
      input.moodScore <= 2 || (input.stressLevel >= 9 && input.moodScore <= 4);

    // Check for declining pattern
    let decliningPattern = false;
    if (input.recentMoodHistory && input.recentMoodHistory.length >= 3) {
      const recent = input.recentMoodHistory.slice(0, 3);
      decliningPattern = recent.every((v, i) => i === 0 || v <= recent[i - 1]);
    }

    const prompt = `
${SYSTEM_PROMPT_FRIENDLY}

MENTAL WELLNESS CHECK:

Current Mood: ${input.moodScore}/10
Stress Level: ${input.stressLevel}/10
Energy Level: ${input.energyLevel}/10
${input.notes ? `Notes: "${input.notes}"` : ""}
${input.context ? `Context: ${input.context}` : ""}
${decliningPattern ? "PATTERN: Mood has been declining over recent days" : ""}
${isCritical ? "STATUS: Elevated concern - low mood detected" : ""}

TASK:
Provide a supportive wellness response:
1. Acknowledge how they're feeling (without judgment)
2. A brief reflection on what might be contributing
3. A supportive, encouraging message
4. 2-3 gentle activity suggestions (not prescriptions)

CRITICAL RULES FOR MENTAL WELLNESS:
- NEVER diagnose depression, anxiety, or any condition
- NEVER prescribe or suggest medications
- NEVER use phrases like "you should see a therapist" (instead: "talking to someone can help")
- ALWAYS validate their feelings
- If mood is very low (1-2), gently mention that support is available
- Keep the tone warm, human, and non-clinical
- Focus on what they CAN do, not what's wrong
`;

    const { text } = await ai.generate({
      model: gemini15Pro,
      prompt,
      config: {
        temperature: 0.8,
        maxOutputTokens: 600,
      },
    });

    const result: z.infer<typeof WellnessCheckResponseSchema> = {
      acknowledgment:
        extractSection(text, "acknowledge") ||
        "Thank you for checking in and sharing how you're feeling.",
      reflection:
        extractSection(text, "reflection") ||
        "Training and life can create pressure. Your awareness is a strength.",
      supportMessage:
        extractSection(text, "support") ||
        "You're doing the best you can, and that matters.",
      suggestedActivities: extractActivities(text),
      resourcesOffered: isCritical || input.moodScore <= 3,
      escalationTriggered: isCritical,
    };

    await logAIInteraction(input.userId, "wellnessCheck", input, result);

    // If critical, also log to escalation collection
    if (isCritical) {
      await logEscalation(
        input.userId,
        "wellness_check_critical",
        input,
        result,
      );
    }

    return result;
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

function parseAIResponse(
  text: string,
  signal: z.infer<typeof HealthSignalSchema>,
): z.infer<typeof AIInsightResponseSchema> {
  // Default fallback response
  const defaultResponse: z.infer<typeof AIInsightResponseSchema> = {
    summary: "Your data has been analyzed.",
    interpretation: "Based on your metrics, here's what we see.",
    encouragement: "Keep showing up. That's what matters.",
    actionItems: ["Focus on recovery today", "Stay hydrated"],
    escalationTriggered: signal.overallRisk === "red",
  };

  // Simple extraction (in production, use structured JSON output)
  try {
    const lines = text.split("\n").filter((l) => l.trim());

    return {
      summary:
        lines
          .find((l) => l.toLowerCase().includes("summary"))
          ?.replace(/^.*?:/i, "")
          .trim() ||
        lines[0] ||
        defaultResponse.summary,
      interpretation:
        lines
          .find((l) => l.toLowerCase().includes("interpret"))
          ?.replace(/^.*?:/i, "")
          .trim() ||
        lines[1] ||
        defaultResponse.interpretation,
      encouragement:
        lines
          .find((l) => l.toLowerCase().includes("encourag"))
          ?.replace(/^.*?:/i, "")
          .trim() || defaultResponse.encouragement,
      actionItems:
        lines
          .filter(
            (l) => l.startsWith("-") || l.startsWith("•") || l.match(/^\d\./),
          )
          .map((l) => l.replace(/^[-•\d.]\s*/, "").trim())
          .slice(0, 4) || defaultResponse.actionItems,
      safetyNote:
        signal.overallRisk === "red" || signal.overallRisk === "orange"
          ? "If you're feeling unwell, please reach out to a healthcare professional."
          : undefined,
      escalationTriggered:
        signal.overallRisk === "red" ||
        signal.activeFlags.includes("crisis_support_needed"),
    };
  } catch {
    return defaultResponse;
  }
}

function extractSection(text: string, keyword: string): string | null {
  const lines = text.split("\n");
  const idx = lines.findIndex((l) => l.toLowerCase().includes(keyword));
  if (idx === -1) return null;

  // Return this line and potentially the next
  let result = lines[idx].replace(/^.*?:/i, "").trim();
  if (idx + 1 < lines.length && !lines[idx + 1].includes(":")) {
    result += " " + lines[idx + 1].trim();
  }
  return result || null;
}

function extractActivities(text: string): string[] {
  const activities: string[] = [];
  const lines = text.split("\n");

  for (const line of lines) {
    if (line.startsWith("-") || line.startsWith("•") || line.match(/^\d\./)) {
      activities.push(line.replace(/^[-•\d.]\s*/, "").trim());
    }
  }

  return activities.length > 0
    ? activities.slice(0, 3)
    : [
        "Take a short walk outside",
        "Do some light stretching or mobility",
        "Reach out to someone you trust",
      ];
}

async function logAIInteraction(
  userId: string,
  flowName: string,
  input: unknown,
  output: unknown,
): Promise<void> {
  try {
    await db.collection("ai_logs").add({
      userId,
      flowName,
      input: JSON.stringify(input),
      output: JSON.stringify(output),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      version: "1.0.0",
    });
  } catch (error) {
    console.error("Failed to log AI interaction:", error);
  }
}

async function logEscalation(
  userId: string,
  type: string,
  input: unknown,
  output: unknown,
): Promise<void> {
  try {
    await db.collection("escalations").add({
      userId,
      type,
      input: JSON.stringify(input),
      output: JSON.stringify(output),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      resolved: false,
      acknowledgedByUser: false,
      reviewedByStaff: false,
    });
  } catch (error) {
    console.error("Failed to log escalation:", error);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CORNER VOICE LIVE AI FLOW
// ═══════════════════════════════════════════════════════════════════════════

const CornerVoiceRequestSchema = z.object({
  userId: z.string(),
  context: z.enum([
    "training_start",
    "between_rounds",
    "training_end",
    "morning_check",
    "pre_fight",
    "weight_cut",
    "recovery_day",
    "mental_support",
  ]),
  metrics: z
    .object({
      readinessScore: z.number().optional(),
      campDay: z.number().optional(),
      totalCampDays: z.number().optional(),
      daysUntilFight: z.number().optional(),
      currentWeight: z.number().optional(),
      targetWeight: z.number().optional(),
      moodScore: z.number().optional(),
      energyLevel: z.number().optional(),
      lastSessionType: z.string().optional(),
    })
    .optional(),
  fighterName: z.string().optional(),
  preferredTone: z
    .enum(["intense", "calm", "motivational", "tactical"])
    .optional(),
});

const CornerVoiceResponseSchema = z.object({
  primaryMessage: z.string(),
  secondaryMessage: z.string().optional(),
  voiceTone: z.enum(["intense", "calm", "motivational", "tactical"]),
  urgency: z.enum(["low", "medium", "high"]),
});

export const cornerVoiceLive = ai.defineFlow(
  {
    name: "cornerVoiceLive",
    inputSchema: CornerVoiceRequestSchema,
    outputSchema: CornerVoiceResponseSchema,
  },
  async (input) => {
    const name = input.fighterName || "fighter";
    const metrics = input.metrics || {};
    const tone = input.preferredTone || "motivational";

    // Determine urgency based on context and metrics
    let urgency: "low" | "medium" | "high" = "medium";
    if (input.context === "pre_fight" || input.context === "between_rounds") {
      urgency = "high";
    } else if (
      input.context === "recovery_day" ||
      input.context === "morning_check"
    ) {
      urgency = "low";
    }
    if (metrics.daysUntilFight && metrics.daysUntilFight <= 3) {
      urgency = "high";
    }

    const toneGuide = {
      intense:
        "Short, direct, no-nonsense. Like a seasoned corner man mid-fight.",
      calm: "Measured, reassuring. Like a wise mentor between sessions.",
      motivational: "Uplifting, energizing. Make them feel invincible.",
      tactical: "Strategic, focused. About the game plan, not emotions.",
    };

    const contextGuide = {
      training_start: "Beginning a training session. Fire them up.",
      between_rounds: "Mid-training rest. Quick, sharp instructions.",
      training_end: "Session complete. Acknowledge effort, set up tomorrow.",
      morning_check: "Daily check-in. Set the day's intention.",
      pre_fight: "Fight is imminent. Focus and belief.",
      weight_cut: "In weight cut phase. Support without pressure.",
      recovery_day: "Rest day. Remind them rest is strategy.",
      mental_support: "They need encouragement. Be human first.",
    };

    const prompt = `
You are the CORNER VOICE for DataFightCentral - the legendary coach in the fighter's ear.

STYLE GUIDE:
${toneGuide[tone]}

CONTEXT: ${contextGuide[input.context]}
FIGHTER: ${name}

CURRENT STATE:
${metrics.readinessScore ? `- Readiness: ${metrics.readinessScore}%` : ""}
${metrics.campDay ? `- Camp Day: ${metrics.campDay}/${metrics.totalCampDays || "?"}` : ""}
${metrics.daysUntilFight ? `- Days Until Fight: ${metrics.daysUntilFight}` : ""}
${metrics.currentWeight && metrics.targetWeight ? `- Weight: ${metrics.currentWeight}kg → ${metrics.targetWeight}kg` : ""}
${metrics.moodScore ? `- Mood: ${metrics.moodScore}/10` : ""}
${metrics.energyLevel ? `- Energy: ${metrics.energyLevel}/10` : ""}
${metrics.lastSessionType ? `- Last Session: ${metrics.lastSessionType}` : ""}

TASK:
Generate a corner voice message. Maximum 2 sentences.
- Primary message: The main instruction or motivation (max 15 words)
- Secondary message: A follow-up or tactical note (max 12 words, optional)

RULES:
- Sound like a veteran combat sports master - 50 years of hard-won wisdom
- NO clichés like "you got this" or "believe in yourself"  
- NO medical advice - NEVER mention injuries or pain
- Reference their actual metrics when meaningful
- Be specific, not generic
- If mood is low, acknowledge before motivating
- NEVER condescend or dismiss their efforts

Respond in this format only:
PRIMARY: [message]
SECONDARY: [message or NONE]
`;

    const { text } = await ai.generate({
      model: gemini15Flash,
      prompt,
      config: {
        temperature: 0.9,
        maxOutputTokens: 150,
      },
    });

    // Parse response
    const lines = text.split("\n").filter((l) => l.trim());
    const primaryLine = lines.find((l) => l.startsWith("PRIMARY:"));
    const secondaryLine = lines.find((l) => l.startsWith("SECONDARY:"));

    const primaryMessage =
      primaryLine?.replace("PRIMARY:", "").trim() ||
      "Let's work. Every rep counts.";
    const secondaryRaw = secondaryLine?.replace("SECONDARY:", "").trim();
    const secondaryMessage =
      secondaryRaw && secondaryRaw !== "NONE" ? secondaryRaw : undefined;

    const result: z.infer<typeof CornerVoiceResponseSchema> = {
      primaryMessage,
      secondaryMessage,
      voiceTone: tone,
      urgency,
    };

    await logAIInteraction(input.userId, "cornerVoiceLive", input, result);

    return result;
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// NEURAL MESH BOT FLOWS — PSYCHE, SCALES (uses analyzeWeightCut), SHIELD, FUEL
// ═══════════════════════════════════════════════════════════════════════════

const InjuryRiskRequestSchema = z.object({
  userId: z.string(),
  acuteLoad: z.number(),
  chronicLoad: z.number(),
  bodyPartRisk: z.record(z.string(), z.number()).optional(),
  consecutiveHighDays: z.number(),
  trainingSessions: z
    .array(
      z.object({
        type: z.string(),
        durationMinutes: z.number(),
        intensity: z.number(),
        timestamp: z.string().optional(),
      }),
    )
    .optional(),
});

const InjuryRiskResponseSchema = z.object({
  assessment: z.string(),
  injuryRiskScore: z.number(),
  riskLevel: z.enum([
    "LOW",
    "OPTIMAL",
    "CAUTION",
    "HIGH_RISK",
    "UNDERTRAINING",
  ]),
  deloadRecommended: z.boolean(),
  suggestedDeloadDays: z.number(),
  recommendations: z.array(z.string()),
  bodyPartAlerts: z.array(z.string()),
});

export const analyzeInjuryRisk = ai.defineFlow(
  {
    name: "analyzeInjuryRisk",
    inputSchema: InjuryRiskRequestSchema,
    outputSchema: InjuryRiskResponseSchema,
  },
  async (input) => {
    const ratio =
      input.chronicLoad > 0 ? input.acuteLoad / input.chronicLoad : 1.0;

    let riskLevel:
      | "LOW"
      | "OPTIMAL"
      | "CAUTION"
      | "HIGH_RISK"
      | "UNDERTRAINING" = "OPTIMAL";
    if (ratio > 1.5) riskLevel = "HIGH_RISK";
    else if (ratio > 1.3) riskLevel = "CAUTION";
    else if (ratio < 0.8) riskLevel = "UNDERTRAINING";

    const bodyPartAlerts: string[] = [];
    if (input.bodyPartRisk) {
      for (const [part, risk] of Object.entries(input.bodyPartRisk)) {
        if (risk > 70)
          bodyPartAlerts.push(
            `${part}: ${risk.toFixed(0)}% risk — reduce load`,
          );
      }
    }

    const prompt = `
${SYSTEM_PROMPT_BASE}

INJURY RISK ANALYSIS:

Acute Load (7-day): ${input.acuteLoad.toFixed(0)}
Chronic Load (28-day avg): ${input.chronicLoad.toFixed(0)}
Acute:Chronic Ratio: ${ratio.toFixed(2)}
Risk Level: ${riskLevel}
Consecutive High-Intensity Days: ${input.consecutiveHighDays}
${bodyPartAlerts.length > 0 ? `Body Part Alerts:\n${bodyPartAlerts.map((a) => `- ${a}`).join("\n")}` : "No specific body part concerns"}

TASK:
1. Brief assessment of injury risk
2. Whether a deload is recommended and for how many days
3. 2-3 specific recommendations
4. Any body part alerts

RULES:
- NEVER diagnose injuries
- NEVER suggest pain medications
- ALWAYS recommend professional assessment for high-risk situations
- Focus on prevention, not treatment
`;

    const { text } = await ai.generate({
      model: gemini15Flash,
      prompt,
      config: { temperature: 0.4, maxOutputTokens: 600 },
    });

    const deloadRecommended = ratio > 1.4 || input.consecutiveHighDays >= 4;
    const injuryRiskScore = Math.min(
      100,
      ratio * 25 + input.consecutiveHighDays * 8 + bodyPartAlerts.length * 5,
    );

    const result: z.infer<typeof InjuryRiskResponseSchema> = {
      assessment:
        extractSection(text, "assessment") || "Injury risk analysis complete.",
      injuryRiskScore: Math.round(injuryRiskScore),
      riskLevel,
      deloadRecommended,
      suggestedDeloadDays: deloadRecommended ? (ratio > 1.5 ? 3 : 2) : 0,
      recommendations: extractActivities(text).slice(0, 3),
      bodyPartAlerts,
    };

    await logAIInteraction(input.userId, "analyzeInjuryRisk", input, result);
    return result;
  },
);

const MealPlanRequestSchema = z.object({
  userId: z.string(),
  phase: z.string(),
  currentMacros: z
    .object({
      protein: z.number().optional(),
      hydration: z.number().optional(),
      calories: z.number().optional(),
    })
    .optional(),
  nutritionHistory: z
    .array(
      z.object({
        calories: z.number(),
        proteinG: z.number(),
        carbsG: z.number(),
        fatG: z.number(),
        mealType: z.string(),
      }),
    )
    .optional(),
});

const MealPlanResponseSchema = z.object({
  nutritionAssessment: z.string(),
  mealPlan: z.array(z.string()),
  supplementRecommendations: z.array(z.string()),
  hydrationAdvice: z.string(),
  macroTargets: z.object({
    proteinG: z.number(),
    carbsG: z.number(),
    fatG: z.number(),
    calorieTarget: z.number(),
  }),
});

export const generateMealPlan = ai.defineFlow(
  {
    name: "generateMealPlan",
    inputSchema: MealPlanRequestSchema,
    outputSchema: MealPlanResponseSchema,
  },
  async (input) => {
    const macros = input.currentMacros || {};

    const prompt = `
${SYSTEM_PROMPT_BASE}

NUTRITION PLANNING:

Training Phase: ${input.phase}
${macros.protein !== undefined ? `Protein Adequacy: ${macros.protein}%` : ""}
${macros.hydration !== undefined ? `Hydration Score: ${macros.hydration}%` : ""}
${macros.calories !== undefined ? `Caloric Balance: ${macros.calories} kcal` : ""}

TASK:
1. Brief nutrition assessment
2. Next 2-3 meal recommendations specific to their phase
3. 2-3 supplement recommendations
4. Hydration advice
5. Daily macro targets (protein/carbs/fat grams + calorie target)

RULES:
- NEVER prescribe medications or specific medical supplements
- NEVER suggest extreme caloric restriction
- Tailor advice to the training phase
- Focus on whole foods first, supplements second
`;

    const { text } = await ai.generate({
      model: gemini15Flash,
      prompt,
      config: { temperature: 0.5, maxOutputTokens: 600 },
    });

    const result: z.infer<typeof MealPlanResponseSchema> = {
      nutritionAssessment:
        extractSection(text, "assessment") || "Nutrition analysis complete.",
      mealPlan: extractActivities(text).slice(0, 3),
      supplementRecommendations: [
        "Creatine monohydrate 5g daily",
        "Electrolyte mix with training",
        "Omega-3 fish oil 2g daily",
      ],
      hydrationAdvice:
        extractSection(text, "hydration") ||
        "Maintain 4L daily, increase on training days.",
      macroTargets: {
        proteinG: 176,
        carbsG: 280,
        fatG: 75,
        calorieTarget: input.phase === "weight_cut" ? 2200 : 2800,
      },
    };

    await logAIInteraction(input.userId, "generateMealPlan", input, result);
    return result;
  },
);

const MentalStateRequestSchema = z.object({
  userId: z.string(),
  journalText: z.string().optional(),
  moodHistory: z
    .array(
      z.object({
        moodScore: z.number(),
        anxietyLevel: z.number().optional(),
        confidenceScore: z.number().optional(),
        focusRating: z.number().optional(),
      }),
    )
    .optional(),
});

const MentalStateResponseSchema = z.object({
  acknowledgment: z.string(),
  mentalStateLabel: z.string(),
  overallScore: z.number(),
  copingStrategies: z.array(z.string()),
  preFightPatterns: z.array(z.string()),
  escalationTriggered: z.boolean(),
});

export const analyzeMentalState = ai.defineFlow(
  {
    name: "analyzeMentalState",
    inputSchema: MentalStateRequestSchema,
    outputSchema: MentalStateResponseSchema,
  },
  async (input) => {
    const moodAvg =
      input.moodHistory && input.moodHistory.length > 0
        ? input.moodHistory.reduce((s, e) => s + e.moodScore, 0) /
          input.moodHistory.length
        : 6;

    const isCritical = moodAvg <= 3;

    const prompt = `
${SYSTEM_PROMPT_FRIENDLY}

MENTAL STATE ANALYSIS:

Average Mood: ${moodAvg.toFixed(1)}/10
Data Points: ${input.moodHistory?.length || 0}
${input.journalText ? `Journal Entry: "${input.journalText.substring(0, 500)}"` : "No journal entry"}
${isCritical ? "STATUS: Low mood detected — provide gentle support" : ""}

TASK:
1. Acknowledge the fighter's current state
2. Label the mental state (peak/stable/stressed/declining)
3. Overall mental score (0-100)
4. 2-3 coping strategies
5. Any pre-fight patterns detected

RULES:
- NEVER diagnose depression, anxiety, or any condition
- NEVER prescribe medications
- ALWAYS validate their feelings
- If mood is very low, gently mention that support is available
`;

    const { text } = await ai.generate({
      model: gemini15Pro,
      prompt,
      config: { temperature: 0.6, maxOutputTokens: 500 },
    });

    const result: z.infer<typeof MentalStateResponseSchema> = {
      acknowledgment:
        extractSection(text, "acknowledge") || "Thank you for checking in.",
      mentalStateLabel:
        moodAvg >= 7.5
          ? "peak"
          : moodAvg >= 6
            ? "stable"
            : moodAvg >= 4
              ? "stressed"
              : "declining",
      overallScore: Math.round(moodAvg * 10),
      copingStrategies: extractActivities(text).slice(0, 3),
      preFightPatterns: [],
      escalationTriggered: isCritical,
    };

    await logAIInteraction(input.userId, "analyzeMentalState", input, result);

    if (isCritical) {
      await logEscalation(input.userId, "mental_state_critical", input, result);
    }

    return result;
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS FOR CLOUD FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

export const flows = {
  generateDailyInsight,
  analyzeWeightCut,
  wellnessCheck,
  cornerVoiceLive,
  analyzeInjuryRisk,
  generateMealPlan,
  analyzeMentalState,
};
