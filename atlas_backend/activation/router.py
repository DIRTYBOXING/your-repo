from fastapi import APIRouter, HTTPException

try:
    from .creators import creator_pack
    from .fighters import fighter_pack
    from .gyms import gym_pack
    from .promoters import promoter_pack
except ImportError:
    from creators import creator_pack
    from fighters import fighter_pack
    from gyms import gym_pack
    from promoters import promoter_pack


router = APIRouter(tags=['activation'])


@router.get('/activation/fighters/{name}')
async def activation_fighter(name: str):
    return fighter_pack(name)


@router.get('/activation/gyms/{name}')
async def activation_gym(name: str):
    return gym_pack(name)


@router.get('/activation/creators/{name}')
async def activation_creator(name: str):
    return creator_pack(name)


@router.get('/activation/promoters/{name}')
async def activation_promoter(name: str):
    return promoter_pack(name)
