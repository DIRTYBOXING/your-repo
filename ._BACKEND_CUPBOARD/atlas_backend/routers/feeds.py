from typing import Annotated, Any

from fastapi import APIRouter, Depends

try:
    from ..auth.firebase_auth import ensure_user_profile, get_current_user
    from ..promotions.service import list_home_feed
except ImportError:
    from auth.firebase_auth import ensure_user_profile, get_current_user
    from promotions.service import list_home_feed


router = APIRouter()


def _targeting_regions(item: dict[str, Any]) -> list[str]:
    targeting = item.get('targeting') if isinstance(item.get('targeting'), dict) else {}
    regions = targeting.get('regions') if isinstance(targeting, dict) else None
    if isinstance(regions, list):
        return [str(region).strip().upper() for region in regions if str(region).strip()]

    region = item.get('region')
    if isinstance(region, str) and region.strip():
        return [region.strip().upper()]
    return []


def _targeting_tags(item: dict[str, Any]) -> list[str]:
    targeting = item.get('targeting') if isinstance(item.get('targeting'), dict) else {}
    tags = targeting.get('tags') if isinstance(targeting, dict) else None
    if not isinstance(tags, list):
        return []
    return [str(tag).strip().lower() for tag in tags if str(tag).strip()]


def _matches_item_targeting(item: dict[str, Any], region: str | None, tags: set[str]) -> bool:
    item_regions = _targeting_regions(item)
    if item_regions and region and region not in item_regions and 'GLOBAL' not in item_regions:
        return False

    item_tags = _targeting_tags(item)
    if item_tags and tags and set(item_tags).isdisjoint(tags):
        return False
    return True


@router.get('/home')
async def get_personalized_home_feed(
    current_user: Annotated[dict[str, Any], Depends(get_current_user)],
    limit: int = 20,
    cursor: str | None = None,
    region: str | None = None,
    include_promotions: bool = True,
):
    del cursor
    safe_limit = max(1, min(limit, 100))
    profile = await ensure_user_profile(current_user)
    preferences = profile.get('preferences') if isinstance(profile.get('preferences'), dict) else {}
    resolved_region = (region or preferences.get('region') or 'GLOBAL').strip().upper()
    user_tags = {
        str(tag).strip().lower()
        for tag in (preferences.get('tags') if isinstance(preferences.get('tags'), list) else [])
        if str(tag).strip()
    }

    items = await list_home_feed(limit=max(safe_limit, 50), include_promotions=include_promotions)
    filtered = [item for item in items if _matches_item_targeting(item, resolved_region, user_tags)]

    return {
        'items': filtered[:safe_limit],
        'cursor': None,
        'region': resolved_region,
        'include_promotions': include_promotions,
    }
