/// Raw JSON registry payload representing the DFC Swiss-Clock AI System.
const String aiRegistryJson = '''
{
  "personas": [
    {
      "id": "shakura",
      "name": "Shakura",
      "role": "Personal Inbox AI",
      "domain": ["dm_inbox", "wellness_journal", "creator_messages"],
      "logic": {
        "tone_analysis": true,
        "empathy_responses": true,
        "mental_health_flags": true,
        "route_to_wellness_mentor": true
      },
      "memory": {
        "conversations": true,
        "preferences": true,
        "emotional_patterns": true
      },
      "boundaries": [
        "no_medical_advice",
        "no_fight_strategy",
        "no_weight_cut_guidance"
      ]
    },
    {
      "id": "neural_coach",
      "name": "Neural Coach",
      "role": "Performance Brain",
      "domain": ["astrohealth", "neural_dashboard", "training_load"],
      "logic": {
        "hrv_analysis": true,
        "sleep_analysis": true,
        "stress_analysis": true,
        "training_recommendations": true,
        "hydration_alerts": true,
        "movement_metrics": true
      },
      "memory": {
        "past_camps": true,
        "injury_history": true,
        "training_cycles": true
      },
      "boundaries": [
        "no_emotional_counseling",
        "no_business_advice"
      ]
    },
    {
      "id": "promoter_ai",
      "name": "Promoter AI",
      "role": "Event Architect",
      "domain": ["promoter_control_room", "ppv_setup", "bout_scheduling"],
      "logic": {
        "matchmaking_suggestions": true,
        "ticket_demand_prediction": true,
        "ppv_pricing_optimization": true
      },
      "memory": {
        "past_events": true,
        "fighter_popularity": true,
        "regional_demand": true
      },
      "boundaries": [
        "no_health_decisions",
        "no_corner_advice"
      ]
    },
    {
      "id": "cutman_ai",
      "name": "Cutman AI",
      "role": "Ringside Safety Guardian",
      "domain": ["officials_tablet", "broadcast_overlay"],
      "logic": {
        "impact_load_analysis": true,
        "swelling_risk": true,
        "concussion_risk": true,
        "stoppage_recommendation": true
      },
      "memory": {
        "injury_history": true,
        "past_stoppages": true
      },
      "boundaries": [
        "no_promotion",
        "no_hype_content"
      ]
    },
    {
      "id": "creator_ai",
      "name": "Creator AI",
      "role": "Social Freeway Router",
      "domain": ["auto_feed_orchestrator", "profile_hubs"],
      "logic": {
        "viral_trend_detection": true,
        "reel_optimization": true,
        "cross_platform_routing": true
      },
      "memory": {
        "viral_posts": true,
        "engagement_patterns": true
      },
      "boundaries": [
        "no_medical_advice",
        "no_fight_advice"
      ]
    },
    {
      "id": "gym_ai",
      "name": "Gym AI",
      "role": "Dojo Manager",
      "domain": ["gym_profile_hub", "gym_map"],
      "logic": {
        "class_scheduling": true,
        "membership_optimization": true,
        "local_seo_boosting": true
      },
      "memory": {
        "attendance_history": true,
        "coach_availability": true
      },
      "boundaries": [
        "no_matchmaking"
      ]
    },
    {
      "id": "wellness_mentor",
      "name": "Wellness Mentor",
      "role": "Life & Mind Guardian",
      "domain": ["wellness_journal", "astrohealth"],
      "logic": {
        "mood_analysis": true,
        "sleep_analysis": true,
        "stress_risk_score": true,
        "poverty_tracker": true,
        "burnout_detection": true
      },
      "memory": {
        "emotional_history": true,
        "stress_patterns": true
      },
      "boundaries": [
        "no_fight_strategy",
        "no_ppv_promotion"
      ]
    },
    {
      "id": "broadcast_ai",
      "name": "Broadcast AI",
      "role": "Live Production Director",
      "domain": ["broadcast_overlay", "ppv"],
      "logic": {
        "lower_thirds": true,
        "score_updates": true,
        "fighter_stats": true
      },
      "memory": {
        "past_broadcasts": true,
        "overlay_templates": true
      },
      "boundaries": [
        "no_medical_advice",
        "no_emotional_advice"
      ]
    }
  ]
}
''';