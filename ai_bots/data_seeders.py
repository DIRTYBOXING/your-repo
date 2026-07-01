"""
DFC Data Seeders & Feeders
Intelligent data generation and population for realistic test environments
"""

import os
import json
import random
from datetime import datetime, timedelta
from typing import List, Dict
import asyncio

import anthropic
from vertexai.generative_models import GenerativeModel

from firebase_manager import FirebaseManager

class RealisticDataGenerator:
    """Generate realistic combat sports data using AI"""
    
    def __init__(self):
        self.claude = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))
        self.gemini = GenerativeModel("gemini-2.0-flash-exp")
        self.fm = FirebaseManager()
    
    # ========== FIGHTER DATA ==========
    
    async def generate_fighters(self, count: int = 50) -> List[Dict]:
        """Generate realistic fighter profiles"""
        prompt = f"""
        Generate {count} realistic MMA fighter profiles with:
        - Name (mix of nationalities)
        - Weight class (lightweight to heavyweight)
        - Record (wins-losses-draws)
        - Stats (strike accuracy, takedown defense, submission defense)
        - Style (wrestler, striker, balanced)
        - Ranking (1-500)
        - Win streak
        
        Return JSON array of fighters. Make data realistic and diverse.
        """
        
        response = await self.gemini.generate_content_async(prompt)
        fighters = json.loads(response.text)
        
        # Save to Firebase
        for fighter in fighters:
            self.fm.create_user(f"fighter-{fighter.get('id')}", {
                'name': fighter.get('name'),
                'role': 'fighter',
                'stats': fighter.get('stats'),
                'weight_class': fighter.get('weight_class'),
                'record': fighter.get('record')
            })
        
        return fighters
    
    # ========== EVENT DATA ==========
    
    async def generate_events(self, count: int = 20) -> List[Dict]:
        """Generate realistic fight events"""
        prompt = f"""
        Generate {count} realistic UFC/MMA events with:
        - Event name and date
        - 8-13 fights per event
        - Main event, co-main, prelims
        - Fighter matchups (balanced)
        - Venues (realistic locations)
        - PPV pricing
        
        Make dates varied (past, present, future).
        Return JSON array of events.
        """
        
        response = await self.gemini.generate_content_async(prompt)
        events = json.loads(response.text)
        
        # Save to Firebase
        for event in events:
            self.fm.create_event(f"event-{event.get('id')}", {
                'details': {
                    'title': event.get('title'),
                    'date': event.get('date'),
                    'location': event.get('location'),
                    'status': 'scheduled' if event.get('date') > datetime.utcnow().isoformat() else 'completed'
                },
                'fights': event.get('fights', []),
                'ppv': {
                    'enabled': True,
                    'price': event.get('ppv_price', 49.99)
                }
            })
        
        return events
    
    # ========== CONTENT POSTS ==========
    
    async def generate_content_posts(self, event_id: str, count: int = 10) -> List[Dict]:
        """Generate engaging fight content posts"""
        prompt = f"""
        Generate {count} engaging MMA content posts for event {event_id}:
        - Fight teasers
        - Fighter profiles
        - Prediction/analysis
        - Hype content
        - Highlight captions
        
        Include:
        - Engaging text (100-200 chars)
        - Type (teaser, analysis, hype, highlight)
        - Hashtags
        - Predicted engagement level
        
        Make content viral-worthy, authentic, sport-appropriate.
        Return JSON array of posts.
        """
        
        response = await self.gemini.generate_content_async(prompt)
        posts = json.loads(response.text)
        
        # Save to Firebase
        for post in posts:
            self.fm.create_post(f"post-{event_id}-{random.randint(1000, 9999)}", {
                'event_id': event_id,
                'text': post.get('text'),
                'type': post.get('type'),
                'author_id': 'bot-content-gen',
                'generated_by_bot': 'dfc-content-gen-1'
            })
        
        return posts
    
    # ========== USER ENGAGEMENT DATA ==========
    
    async def generate_user_engagement(self, user_count: int = 1000) -> int:
        """Simulate realistic user engagement patterns"""
        
        # Get real events and posts
        events = self.fm.db.child('events').get().val() or {}
        posts = self.fm.db.child('content').child('posts').get().val() or {}
        
        if not events or not posts:
            print("No events or posts found. Create them first.")
            return 0
        
        event_ids = list(events.keys())[:10]
        post_ids = list(posts.keys())[:100]
        
        # Generate engagement patterns
        prompt = f"""
        Generate engagement data for {user_count} users across {len(post_ids)} posts.
        
        For each user:
        - Views (Pareto distribution: few posts get most views)
        - Likes (10-30% of viewers)
        - Comments (2-5% of viewers)
        - Shares (1-2% of viewers)
        
        Make patterns realistic:
        - Some posts viral (100K+ views)
        - Most posts normal (1K-10K views)
        - Few posts fail (< 500 views)
        
        Return JSON with engagement counts per post_id.
        """
        
        response = await self.gemini.generate_content_async(prompt)
        engagement_data = json.loads(response.text)
        
        # Update Firebase
        for post_id, engagement in engagement_data.items():
            if post_id in posts:
                self.fm.update_engagement(post_id, engagement)
        
        return len(engagement_data)
    
    # ========== PPV DATA ==========
    
    async def generate_ppv_history(self, event_count: int = 50) -> List[Dict]:
        """Generate historical PPV data for pattern analysis"""
        prompt = f"""
        Generate {event_count} historical PPV events with realistic data:
        - Buy rate (5%-25%)
        - Peak concurrent viewers
        - Revenue
        - Fighter star power impact
        - Time slot impact
        - Marketing spend ROI
        
        Include patterns:
        - Major events (star fighters) higher buy rates
        - Weekend events higher buys
        - Holiday events variable
        - Seasonal trends
        
        Return JSON array with ppv_metrics.
        """
        
        response = await self.gemini.generate_content_async(prompt)
        ppv_data = json.loads(response.text)
        
        return ppv_data
    
    # ========== SHAKURA FEMALE ATHLETE DATA ==========
    
    async def setup_shakura_protection(self) -> int:
        """Setup Shakura protection profiles for female athletes"""
        
        # Get all female fighters (filter by profile)
        all_users = self.fm.db.child('users').get().val() or {}
        
        female_fighter_count = 0
        
        for user_id, user_data in all_users.items():
            if user_data.get('profile', {}).get('role') == 'fighter':
                # Assume ~20% are female (realistic MMA ratio)
                if random.random() < 0.2:
                    self.fm.db.child('users').child(user_id).child('shakura_profile').set({
                        'is_female_athlete': True,
                        'protection_level': 'enhanced',  # Female athletes get enhanced protection
                        'blocked_users': [],
                        'harassment_reports': [],
                        'created_at': datetime.utcnow().isoformat()
                    })
                    female_fighter_count += 1
        
        print(f"✅ Setup Shakura protection for {female_fighter_count} female athletes")
        return female_fighter_count

class DataFeeder:
    """Continuously feed data - simulates real platform activity"""
    
    def __init__(self):
        self.generator = RealisticDataGenerator()
        self.fm = FirebaseManager()
    
    async def feed_engagement_stream(self, interval_seconds: int = 60):
        """Continuously simulate user engagement"""
        while True:
            try:
                # Simulate some users engaging with content
                posts = self.fm.db.child('content').child('posts').get().val() or {}
                
                for post_id, post_data in list(posts.items())[:20]:  # Update 20 posts
                    current_engagement = post_data.get('engagement', {})
                    
                    # Simulate engagement growth
                    new_engagement = {
                        'views': current_engagement.get('views', 0) + random.randint(10, 500),
                        'likes': current_engagement.get('likes', 0) + random.randint(1, 50),
                        'comments': current_engagement.get('comments', 0) + random.randint(0, 20),
                        'shares': current_engagement.get('shares', 0) + random.randint(0, 10)
                    }
                    
                    self.fm.update_engagement(post_id, new_engagement)
                
                await asyncio.sleep(interval_seconds)
                
            except Exception as e:
                print(f"Error in engagement feeder: {e}")
                await asyncio.sleep(interval_seconds)
    
    async def feed_ppv_purchases(self, interval_seconds: int = 30):
        """Simulate PPV purchases"""
        while True:
            try:
                events = self.fm.db.child('events').get().val() or {}
                
                # Find upcoming PPV events
                for event_id, event_data in events.items():
                    if event_data.get('ppv', {}).get('enabled'):
                        # Simulate random purchases
                        if random.random() < 0.3:  # 30% chance per check
                            user_id = f"user-{random.randint(1, 10000)}"
                            price = event_data.get('ppv', {}).get('price', 49.99)
                            
                            self.fm.record_ppv_purchase(user_id, event_id, price)
                
                await asyncio.sleep(interval_seconds)
                
            except Exception as e:
                print(f"Error in PPV purchase feeder: {e}")
                await asyncio.sleep(interval_seconds)

class DataOrchestrator:
    """Orchestrate all data generation and feeding"""
    
    def __init__(self):
        self.generator = RealisticDataGenerator()
        self.feeder = DataFeeder()
    
    async def bootstrap(self):
        """Initial data bootstrap"""
        print("🌱 Bootstrapping DFC data...")
        
        # Generate core data
        await self.generator.generate_fighters(count=100)
        print("✅ Generated 100 fighters")
        
        await self.generator.generate_events(count=30)
        print("✅ Generated 30 events")
        
        await self.generator.generate_content_posts('event-001', count=50)
        print("✅ Generated content posts")
        
        await self.generator.generate_user_engagement(user_count=5000)
        print("✅ Generated user engagement")
        
        ppv_history = await self.generator.generate_ppv_history(count=50)
        print("✅ Generated PPV history")
        
        shakura_count = await self.generator.setup_shakura_protection()
        print(f"✅ Setup Shakura protection for {shakura_count} female athletes")
        
        print("\n🎉 Bootstrap complete!")
    
    async def run_continuous(self):
        """Run continuous feeders"""
        print("🤖 Starting continuous data feeders...")
        
        tasks = [
            self.feeder.feed_engagement_stream(interval_seconds=30),
            self.feeder.feed_ppv_purchases(interval_seconds=20)
        ]
        
        await asyncio.gather(*tasks)

if __name__ == '__main__':
    orchestrator = DataOrchestrator()
    
    # Bootstrap data
    print("Starting data orchestrator...")
    asyncio.run(orchestrator.bootstrap())
    
    # Optional: Run continuous feeders
    # asyncio.run(orchestrator.run_continuous())
