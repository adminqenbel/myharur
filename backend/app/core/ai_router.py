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
            import os
            
            # Context regarding the app for the AI
            system_prompt = """You are the MyHarur AI Support Assistant.
Be concise, helpful, and polite. Handle spelling mistakes gracefully.
Knowledge Base:
- Shop Registration: Go to Marketplace tab -> Click '+' -> Fill details -> Upload Trade License (24hr approval).
- News Posting: Go to News feed -> Click 'Create Post' (+10 Reputation points for verified news).
- Reputation Points: Earned by posting news (+10), emergency help (+50), upvotes (+1). Tiers are Bronze, Silver, Gold, Citizen.
- Reporting Abuse: Tap three dots (...) on a post/message -> Select 'Report'. (2-hour moderator review).
- Account Deletion: Email admin@myharur.com from registered email (3 business days).
- Unknown questions: Apologize and state you are an AI still learning about Harur, and an admin will assist shortly.
User Query: """
            
            # Try Google Gemini AI first
            gemini_key = os.getenv("GEMINI_API_KEY")
            if gemini_key:
                try:
                    import google.generativeai as genai
                    genai.configure(api_key=gemini_key)
                    # Use standard gemini-1.5-flash for fast text responses
                    model = genai.GenerativeModel('gemini-1.5-flash')
                    response = model.generate_content(system_prompt + content)
                    if response.text:
                        return response.text
                except Exception as e:
                    logger.error(f"Gemini AI failed: {e}")
            
            # Fallback to intelligent fuzzy matching if no API key or AI fails
            import difflib
            words = content_lower.split()
            
            kb = {
                "shop": ["register", "add", "create", "shop", "store", "business", "shpo", "reister"],
                "news": ["post", "add", "submit", "news", "article", "new", "nwes"],
                "reputation": ["reputation", "points", "badge", "tier", "score", "ponts", "rep"],
                "report": ["report", "spam", "abuse", "fake", "block"],
                "account": ["delete", "remove", "account", "profile", "password", "login"]
            }
            
            scores = {k: 0 for k in kb.keys()}
            for w in words:
                for cat, keywords in kb.items():
                    # Check for fuzzy match
                    matches = difflib.get_close_matches(w, keywords, n=1, cutoff=0.7)
                    if matches:
                        scores[cat] += 1
                        
            best_cat = max(scores, key=scores.get) if any(scores.values()) else None
            
            if best_cat == "shop":
                return "To register your shop on MyHarur:\n1. Go to the 'Marketplace' tab.\n2. Tap the '+' button in the top right.\n3. Fill in your shop details and upload a valid Trade License."
            elif best_cat == "news":
                return "To post local news:\n1. Navigate to the 'News' feed.\n2. Tap the 'Create Post' icon. Verified reporters earn +10 Reputation Points."
            elif best_cat == "reputation":
                return "Reputation Points are earned by:\n- Posting verified news (+10)\n- Helping in emergencies (+50)\n- Getting upvotes (+1)\nView your tier on your Profile page."
            elif best_cat == "report":
                return "To report a user or post:\n1. Tap the three dots (...) next to the message or post.\n2. Select 'Report'."
            elif best_cat == "account":
                return "For account deletion or password resets, please email admin@myharur.com or use the 'Forgot Password' link."
            
            return "I am the MyHarur AI Assistant. Please ask a specific question about shops, news, reputation, or your account, and I will do my best to help (even if there are typos!)."
            
        else:
            return f"Command @{command} received. This module is under active development by the AI."
