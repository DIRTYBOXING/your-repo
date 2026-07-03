def _normalize(text: str) -> str:
    return ' '.join(text.split())


def rewrite_text(text: str, style: str = 'engagement') -> str:
    cleaned = _normalize(text)
    if style == 'poster':
        return cleaned.upper()[:160]
    if style == 'summary':
        return summarize_text(cleaned, max_words=18)
    if style == 'hype':
        return f'{cleaned} Tap in now.'
    return cleaned


def summarize_text(text: str, max_words: int = 24) -> str:
    words = _normalize(text).split()
    if len(words) <= max_words:
        return ' '.join(words)
    return ' '.join(words[:max_words]) + '...'


def build_poster_hook(title: str, fighter_name: str | None = None) -> str:
    subject = fighter_name or 'DFC'
    return f'{subject}: {rewrite_text(title, style="poster")}'
