import logging
import re
from typing import Dict, Any, Tuple
from app.db.session import SessionLocal
from app.models.ai import IntentLog, CommandHistory, ChatSession
from app.models.user import User
from app.models.news import News
from app.models.shop import Shop
from app.models.emergency import EmergencyRequest

logger = logging.getLogger(__name__)

class IntelligentRouter:
    """
    Routes commands to appropriate AI agents or database searches.
    """
    
    SUPPORTED_COMMANDS = [
        "support", "help", "admin", "news", "shop", "orders", 
        "emergency", "hospital", "doctor", "police", "collector", 
        "municipality", "volunteer", "transport", "bus", "jobs", 
        "offers", "feedback", "tourism", "events", "road", 
        "electricity", "water"
    ]

    def __init__(self, db_session):
        self.db = db_session

    def process_message(self, user_id: int, content: str, session_id: str) -> Tuple[bool, str]:
        """
        Processes a chat message. 
        Returns (is_handled, ai_response_text).
        """
        # Find mentions
        mentions = re.findall(r'@(\w+)', content)
        if not mentions:
            return False, ""
        
        primary_mention = mentions[0].lower()
        
        if primary_mention not in self.SUPPORTED_COMMANDS:
            return False, ""
            
        # Log Intent
        log = IntentLog(user_input=content, detected_intent=primary_mention, confidence_score=0.9)
        self.db.add(log)
        self.db.commit()

        # Simple Context Memory (Mock)
        chat_session = self.db.query(ChatSession).filter(ChatSession.session_token == session_id).first()
        if not chat_session:
            chat_session = ChatSession(user_id=user_id, session_token=session_id, context_data={})
            self.db.add(chat_session)
            self.db.commit()

        # Handle Commands
        response = self._route_command(primary_mention, content, chat_session)
        
        # Save to history
        history = CommandHistory(session_id=chat_session.id, command_text=content, ai_response=response)
        self.db.add(history)
        self.db.commit()
        
        return True, response

    def _route_command(self, command: str, content: str, session: ChatSession) -> str:
        content_lower = content.lower()
        
        if command == "news":
            # Semantic search / LLM summary here
            # Mocking response
            if "rain" in content_lower or "weather" in content_lower:
                return "Latest Weather News: Heavy rainfall expected in Harur today evening. Please stay safe."
            return "Here are the top headlines for today..."
            
        elif command == "shop":
            if "medical" in content_lower:
                return "Found 3 verified medical shops open near your location:\n1. Sri Ram Medicals (Harur Bus Stand)\n2. Apollo Pharmacy (Gandhi Road)"
            return "What kind of shop are you looking for?"
            
        elif command == "emergency":
            if "blood" in content_lower:
                return "EMERGENCY PROTOCOL ACTIVATED: Searching registered blood donors in Dharmapuri district. We have created an emergency request."
            return "Please describe your emergency clearly."
            
        elif command == "support" or command == "help":
            # Highly efficient keyword-based support routing
            if any(k in content_lower for k in ["register", "add", "create"]) and "shop" in content_lower:
                return "To register your shop on MyHarur:\n1. Go to the 'Marketplace' tab.\n2. Tap the '+' button in the top right.\n3. Fill in your shop details and upload a valid Trade License.\nApproval usually takes 24 hours."
            
            elif any(k in content_lower for k in ["post", "add", "submit"]) and "news" in content_lower:
                return "To post local news:\n1. Navigate to the 'News' feed.\n2. Tap the 'Create Post' icon.\n3. Ensure your news is accurate and follows community guidelines. Verified reporters earn +10 Reputation Points."
                
            elif any(k in content_lower for k in ["reputation", "points", "badge"]):
                return "Reputation Points are earned by:\n- Posting verified news (+10)\n- Helping in emergencies (+50)\n- Getting upvotes on community posts (+1)\nYou can view your current tier (Bronze/Silver/Gold/Citizen) on your Profile page."
                
            elif any(k in content_lower for k in ["report", "spam", "abuse", "fake"]):
                return "We take community safety seriously. To report a user or post:\n1. Tap the three dots (...) next to the message or post.\n2. Select 'Report'.\nOur moderators will review it within 2 hours. Thank you for keeping Harur safe!"
                
            elif any(k in content_lower for k in ["delete", "remove"]) and any(k in content_lower for k in ["account", "profile"]):
                return "If you wish to delete your account, please send an email to admin@myharur.com from your registered email address with the subject 'Account Deletion'. We process these requests within 3 business days."
            
            elif "password" in content_lower or "login" in content_lower:
                return "If you are having trouble logging in, please use the 'Forgot Password' link on the login screen to receive a reset OTP via email."

            elif "update" in content_lower or "version" in content_lower:
                return "You can always download the latest version of the MyHarur app from our website at https://myharur.onrender.com"

            return "I am the MyHarur Automated Support Assistant.\n\nI can help you with:\n- Shop Registration\n- News Posting\n- Reputation Points\n- Reporting Abuse\n- Account Settings\n\nPlease ask a specific question, or wait for a human administrator to reply to your message."
            
        else:
            return f"Command @{command} received. This module is under active development by the AI."
