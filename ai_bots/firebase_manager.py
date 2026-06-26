"""
Firebase Configuration & Integration
Real-time database, Cloud Storage, Authentication
"""

import os
import json
import firebase_admin
from firebase_admin import credentials, db, storage, auth
from datetime import datetime, timedelta

# Initialize Firebase Admin SDK
def initialize_firebase():
    """Initialize Firebase with service account"""
    if not firebase_admin.get_app():
        cred = credentials.Certificate(os.getenv('GOOGLE_APPLICATION_CREDENTIALS'))
        firebase_admin.initialize_app(cred, {
            'databaseURL': 'https://datafightcentral.firebaseio.com',
            'storageBucket': 'datafightcentral.appspot.com'
        })
    return db.reference()

# ============================================================================
# FIREBASE REALTIME DATABASE STRUCTURE
# ============================================================================

FIREBASE_SCHEMA = {
    'users': {
        '{user_id}': {
            'profile': {
                'name': 'string',
                'email': 'string',
                'phone': 'string',
                'role': 'fighter|fan|admin',
                'avatar_url': 'string',
                'bio': 'string',
                'created_at': 'timestamp'
            },
            'preferences': {
                'interests': ['mma', 'boxing', 'wrestling'],
                'notifications': {'ppv': True, 'live': True},
                'content_filter': 'all|safe|explicit'
            },
            'history': {
                'watched_events': [{event_id: 'timestamp'}],
                'purchased_ppv': [{event_id: 'price', 'timestamp': 'timestamp'}],
                'engagement_scores': {event_id: 0-100}
            },
            'shakura_profile': {
                'is_female_athlete': bool,
                'protection_level': 'standard|enhanced|vip',
                'blocked_users': ['user_id'],
                'harassment_reports': [{reporter_id: 'timestamp', 'reason': 'string'}]
            }
        }
    },
    'events': {
        '{event_id}': {
            'details': {
                'title': 'string',
                'date': 'timestamp',
                'location': 'string',
                'promotion': 'UFC|Bellator',
                'status': 'scheduled|live|completed'
            },
            'fights': [{
                'fighter_a_id': 'user_id',
                'fighter_b_id': 'user_id',
                'weight_class': 'heavyweight',
                'odds': {'fighter_a': 2.5, 'fighter_b': 1.5},
                'prediction': {'winner': 'fighter_a_id', 'confidence': 0.75}
            }],
            'ppv': {
                'enabled': bool,
                'price': 49.99,
                'early_bird': {'price': 39.99, 'until': 'timestamp'},
                'bundle': {'package': 'monthly', 'discount': 20},
                'expected_buys': 100000,
                'buy_rate': 0.15
            },
            'content': {
                'thumbnail': 'gs://...',
                'poster': 'gs://...',
                'trailer_video': 'gs://...',
                'highlights': ['gs://...']
            }
        }
    },
    'content': {
        'posts': {
            '{post_id}': {
                'author_id': 'user_id',
                'event_id': 'event_id',
                'text': 'string',
                'images': ['gs://bucket/image.jpg'],
                'video': 'gs://bucket/video.mp4',
                'type': 'caption|highlight|analysis|teaser',
                'timestamp': 'timestamp',
                'engagement': {
                    'likes': 1000,
                    'comments': 50,
                    'shares': 200,
                    'views': 5000
                },
                'generated_by_bot': 'bot_id'
            }
        },
        'feeds': {
            '{user_id}': {
                '{timestamp}': {
                    'posts': [
                        {'post_id': 'post_id', 'rank_score': 0.95},
                        {'post_id': 'post_id', 'rank_score': 0.87}
                    ],
                    'curator_bot': 'dfc-feed-curator-1',
                    'personalization_level': 'high'
                }
            }
        }
    },
    'ai_decisions': {
        'ppv_strategies': {
            '{event_id}': {
                'recommended_price': 49.99,
                'buy_rate_forecast': 0.18,
                'revenue_projection': 8982000,
                'strategy': 'early_bird_discount',
                'confidence': 0.92,
                'timestamp': 'timestamp'
            }
        },
        'safety_alerts': {
            'critical': {
                '{user_id}': {
                    'threat_level': 'critical',
                    'content_summary': 'string',
                    'actions_taken': ['block_user', 'notify_support'],
                    'timestamp': 'timestamp'
                }
            }
        },
        'content_analysis': {
            '{post_id}': {
                'engagement_prediction': 0.85,
                'viral_potential': 'high',
                'recommended_boost': True,
                'audience_sentiment': 'positive'
            }
        }
    },
    'messaging': {
        'conversations': {
            '{conversation_id}': {
                'participants': ['user_id1', 'user_id2'],
                'messages': {
                    '{msg_id}': {
                        'from': 'user_id|bot_id',
                        'text': 'string',
                        'timestamp': 'timestamp',
                        'read': bool
                    }
                },
                'last_message_time': 'timestamp'
            }
        }
    }
}

# ============================================================================
# FIREBASE CLOUD STORAGE STRUCTURE
# ============================================================================

STORAGE_STRUCTURE = {
    'gs://datafightcentral.appspot.com': {
        'events': {
            '{event_id}': {
                'posters': ['poster_1.jpg', 'poster_2.jpg'],
                'thumbnails': ['thumb_16x9.jpg', 'thumb_square.jpg'],
                'videos': ['trailer.mp4', 'promo.mp4'],
                'highlights': ['highlight_round1.mp4', 'highlight_round2.mp4']
            }
        },
        'user_content': {
            '{user_id}': {
                'profile_images': ['avatar.jpg', 'banner.jpg'],
                'posts': ['post_1_image.jpg']
            }
        },
        'generated': {
            'posters': {
                '{date}': ['poster_ai_generated.jpg']
            },
            'captions': {
                '{date}': ['caption_ai_generated.txt']
            }
        }
    }
}

# ============================================================================
# FIREBASE REAL-TIME DATABASE OPERATIONS
# ============================================================================

class FirebaseManager:
    """Manage Firebase operations"""
    
    def __init__(self):
        self.db = initialize_firebase()
        self.bucket = storage.bucket()
    
    # ========== USER OPERATIONS ==========
    
    def create_user(self, user_id: str, profile: dict) -> bool:
        """Create user in Firebase"""
        try:
            self.db.child('users').child(user_id).set({
                'profile': profile,
                'created_at': datetime.utcnow().isoformat(),
                'preferences': {
                    'interests': [],
                    'notifications': {'ppv': True, 'live': True},
                    'content_filter': 'all'
                },
                'history': {
                    'watched_events': [],
                    'purchased_ppv': [],
                    'engagement_scores': {}
                }
            })
            return True
        except Exception as e:
            print(f"Error creating user: {e}")
            return False
    
    def get_user_profile(self, user_id: str) -> dict:
        """Get user profile"""
        return self.db.child('users').child(user_id).child('profile').get().val() or {}
    
    def update_user_preferences(self, user_id: str, preferences: dict):
        """Update user preferences"""
        self.db.child('users').child(user_id).child('preferences').update(preferences)
    
    def add_to_watch_history(self, user_id: str, event_id: str):
        """Add event to user's watch history"""
        self.db.child('users').child(user_id).child('history').child('watched_events').push(
            {event_id: datetime.utcnow().isoformat()}
        )
    
    # ========== EVENT OPERATIONS ==========
    
    def create_event(self, event_id: str, event_data: dict) -> bool:
        """Create fight event"""
        try:
            self.db.child('events').child(event_id).set({
                'details': event_data.get('details', {}),
                'fights': event_data.get('fights', []),
                'ppv': event_data.get('ppv', {}),
                'content': event_data.get('content', {})
            })
            return True
        except Exception as e:
            print(f"Error creating event: {e}")
            return False
    
    def update_event_status(self, event_id: str, status: str):
        """Update event status (scheduled -> live -> completed)"""
        self.db.child('events').child(event_id).child('details').child('status').set(status)
    
    def get_event(self, event_id: str) -> dict:
        """Get event details"""
        return self.db.child('events').child(event_id).get().val() or {}
    
    # ========== CONTENT OPERATIONS ==========
    
    def create_post(self, post_id: str, post_data: dict) -> bool:
        """Create content post"""
        try:
            self.db.child('content').child('posts').child(post_id).set({
                'author_id': post_data.get('author_id'),
                'event_id': post_data.get('event_id'),
                'text': post_data.get('text'),
                'images': post_data.get('images', []),
                'video': post_data.get('video'),
                'type': post_data.get('type', 'caption'),
                'timestamp': datetime.utcnow().isoformat(),
                'engagement': {'likes': 0, 'comments': 0, 'shares': 0, 'views': 0},
                'generated_by_bot': post_data.get('generated_by_bot')
            })
            return True
        except Exception as e:
            print(f"Error creating post: {e}")
            return False
    
    def update_engagement(self, post_id: str, engagement: dict):
        """Update post engagement metrics"""
        self.db.child('content').child('posts').child(post_id).child('engagement').update(engagement)
    
    def save_personalized_feed(self, user_id: str, feed_items: list):
        """Save curated feed for user"""
        timestamp = datetime.utcnow().isoformat()
        self.db.child('content').child('feeds').child(user_id).child(timestamp).set({
            'posts': feed_items,
            'curator_bot': 'dfc-feed-curator-1',
            'timestamp': timestamp
        })
    
    # ========== PPV OPERATIONS ==========
    
    def save_ppv_strategy(self, event_id: str, strategy: dict):
        """Save AI-generated PPV strategy"""
        self.db.child('ai_decisions').child('ppv_strategies').child(event_id).set({
            'recommended_price': strategy.get('recommended_price'),
            'buy_rate_forecast': strategy.get('buy_rate_forecast'),
            'revenue_projection': strategy.get('revenue_projection'),
            'strategy': strategy.get('strategy'),
            'confidence': strategy.get('confidence'),
            'timestamp': datetime.utcnow().isoformat()
        })
    
    def record_ppv_purchase(self, user_id: str, event_id: str, price: float):
        """Record PPV purchase"""
        self.db.child('users').child(user_id).child('history').child('purchased_ppv').push({
            'event_id': event_id,
            'price': price,
            'timestamp': datetime.utcnow().isoformat()
        })
    
    # ========== SAFETY OPERATIONS ==========
    
    def report_safety_alert(self, alert_data: dict, threat_level: str):
        """Report Shakura safety alert"""
        self.db.child('ai_decisions').child('safety_alerts').child(threat_level).push(alert_data)
    
    def add_blocked_user(self, user_id: str, blocked_user_id: str):
        """Block user (Shakura protection)"""
        self.db.child('users').child(user_id).child('shakura_profile').child('blocked_users').push(
            blocked_user_id
        )
    
    # ========== MESSAGING OPERATIONS ==========
    
    def save_message(self, conversation_id: str, from_id: str, text: str):
        """Save message in conversation"""
        msg_id = self.db.child('messaging').child('conversations').child(conversation_id).child('messages').push({
            'from': from_id,
            'text': text,
            'timestamp': datetime.utcnow().isoformat(),
            'read': False
        }).key
        
        # Update last_message_time
        self.db.child('messaging').child('conversations').child(conversation_id).child('last_message_time').set(
            datetime.utcnow().isoformat()
        )
        
        return msg_id
    
    # ========== CLOUD STORAGE OPERATIONS ==========
    
    def upload_file(self, local_path: str, firebase_path: str) -> str:
        """Upload file to Cloud Storage"""
        blob = self.bucket.blob(firebase_path)
        blob.upload_from_filename(local_path)
        return blob.public_url
    
    def upload_from_memory(self, content: bytes, firebase_path: str) -> str:
        """Upload file from memory"""
        blob = self.bucket.blob(firebase_path)
        blob.upload_from_string(content)
        return blob.public_url
    
    def download_file(self, firebase_path: str, local_path: str):
        """Download file from Cloud Storage"""
        blob = self.bucket.blob(firebase_path)
        blob.download_to_filename(local_path)
    
    def delete_file(self, firebase_path: str):
        """Delete file from Cloud Storage"""
        blob = self.bucket.blob(firebase_path)
        blob.delete()
    
    def list_files(self, folder_path: str) -> list:
        """List files in folder"""
        blobs = self.bucket.list_blobs(prefix=folder_path)
        return [blob.name for blob in blobs]
    
    # ========== BATCH OPERATIONS ==========
    
    def batch_create_events(self, events: list) -> int:
        """Create multiple events"""
        created = 0
        for event in events:
            if self.create_event(event['id'], event):
                created += 1
        return created
    
    def batch_create_posts(self, posts: list) -> int:
        """Create multiple posts"""
        created = 0
        for post in posts:
            if self.create_post(post['id'], post):
                created += 1
        return created

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

def export_user_data(user_id: str) -> dict:
    """Export all user data (GDPR compliance)"""
    fm = FirebaseManager()
    user_data = fm.db.child('users').child(user_id).get().val()
    return user_data or {}

def export_all_events() -> dict:
    """Export all events"""
    fm = FirebaseManager()
    return fm.db.child('events').get().val() or {}

if __name__ == '__main__':
    # Example usage
    fm = FirebaseManager()
    
    # Create user
    fm.create_user('user-001', {
        'name': 'Alex Silva',
        'email': 'alex@dfc.com',
        'role': 'fighter'
    })
    
    # Create event
    fm.create_event('event-001', {
        'details': {
            'title': 'UFC 300',
            'date': (datetime.utcnow() + timedelta(days=30)).isoformat(),
            'status': 'scheduled'
        },
        'ppv': {'enabled': True, 'price': 49.99}
    })
    
    print("Firebase operations complete")
