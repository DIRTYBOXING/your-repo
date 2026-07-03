RISK_TERMS = {
    'pirate': 'piracy',
    'stream leak': 'piracy',
    'doxx': 'privacy',
    'weapon': 'safety',
    'threat': 'abuse',
}


def score_content(text: str) -> float:
    lowered = text.lower()
    score = 0.05
    for term in RISK_TERMS:
        if term in lowered:
            score += 0.2
    return round(min(score, 1.0), 4)


def build_flags(text: str) -> list[str]:
    lowered = text.lower()
    return sorted({flag for term, flag in RISK_TERMS.items() if term in lowered})


def recommend_action(score: float) -> str:
    if score >= 0.75:
        return 'quarantine'
    if score >= 0.35:
        return 'review'
    return 'allow'


def score_sensor_alert(priority: str, status: str) -> float:
    base = 0.3 if status.lower() == 'escalated' else 0.15
    if priority.lower() == 'high':
        base += 0.4
    return round(min(base, 1.0), 4)
