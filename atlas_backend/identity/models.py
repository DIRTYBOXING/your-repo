from dataclasses import asdict, dataclass


VALID_ROLES = {
    'fighter',
    'gym',
    'creator',
    'promoter',
    'fan',
    'operator',
    'edge_device',
    'radar_node',
    'drone_node',
}


@dataclass(slots=True)
class IdentityProfile:
    identity_id: str
    role: str
    display_name: str

    def to_dict(self) -> dict:
        return asdict(self)
