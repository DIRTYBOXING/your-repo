import logging
from ..dataconnect_client import dc

class DiscoveryService:
    async def search(self, city: str = None, style: str = None):
        """
        Search gyms and fighting styles.
        """
        logging.info(f"🔍 Discovery search initiated: city={city}, style={style}")
        
        if not city:
            result = await dc.list_gyms.execute()
            gyms = result.data.gyms
        else:
            result = await dc.search_gyms.execute(city=city)
            gyms = result.data.gyms

        # Real-world filter: Only return gyms with valid coordinates for the map
        gyms = [
            gym for gym in gyms 
            if gym.latitude is not None and gym.longitude is not None
        ]
        
        return gyms
