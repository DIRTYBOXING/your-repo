from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

try:
    from ..event_bus import publish_event
    from .service import build_poster_hook, rewrite_text, summarize_text
except ImportError:
    from event_bus import publish_event
    from ai_core.service import build_poster_hook, rewrite_text, summarize_text


router = APIRouter(tags=['ai-core'])


def _require_non_empty(value: str, field_name: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise HTTPException(status_code=400, detail=f'{field_name} must not be blank')
    return cleaned


class RewriteRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)
    style: str = Field(default='engagement', min_length=1, max_length=32)


class SummarizeRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)
    max_words: int = Field(default=24, ge=5, le=120)


class PosterHookRequest(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    fighter_name: str | None = None


@router.post('/ai/rewrite')
async def rewrite(req: RewriteRequest):
    text = _require_non_empty(req.text, 'text')
    style = _require_non_empty(req.style, 'style').lower()
    rewritten = rewrite_text(text, style)
    await publish_event(
        'ai.rewrite.completed',
        source='ai_core',
        stream='ai',
        subject=style,
        payload={'style': style, 'text_preview': text[:80]},
    )
    return {'rewritten': rewritten, 'style': style}


@router.post('/ai/summarize')
async def summarize(req: SummarizeRequest):
    text = _require_non_empty(req.text, 'text')
    summary = summarize_text(text, req.max_words)
    await publish_event(
        'ai.summary.completed',
        source='ai_core',
        stream='ai',
        payload={'max_words': req.max_words, 'text_preview': text[:80]},
    )
    return {'summary': summary}


@router.post('/ai/poster-hook')
async def poster_hook(req: PosterHookRequest):
    title = _require_non_empty(req.title, 'title')
    fighter_name = req.fighter_name.strip() if req.fighter_name else None
    hook = build_poster_hook(title, fighter_name or None)
    return {'hook': hook}
