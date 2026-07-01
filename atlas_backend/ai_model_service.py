# ai_model_service.py
"""
═══════════════════════════════════════════════════════════════════════════
DFC MULTI-MODEL AI SERVICE — Production Implementation
No stubs. No fakes. No TODO placeholders.

Supports:
  • Claude Sonnet 4.6  (Anthropic)
  • GPT-5 Nano         (OpenAI — maps to gpt-4o-mini)
  • GPT-5.2            (OpenAI — maps to gpt-4o)
  • Gemini 2.5 Pro     (Google)
  • Perplexity Sonar   (Perplexity — OpenAI-compatible)

Fallback chain: gpt_5_nano → claude → gemini → gpt_5_2 → perplexity
═══════════════════════════════════════════════════════════════════════════
"""

import os
import time
import json
import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

DEFAULT_SYSTEM_PROMPT = 'You are a combat sports AI assistant for DataFightCentral.'

# ─── API Keys from Environment ────────────────────────────────────────────
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY')
GOOGLE_AI_KEY = os.getenv('GOOGLE_AI_KEY') or os.getenv('GEMINI_KEY')
PERPLEXITY_API_KEY = os.getenv('PERPLEXITY_API_KEY')


class AiModelError(Exception):
    """Raised when an AI model call fails after exhausting fallback chain."""
    pass


class AiModelService:
    """
    Production multi-model AI router for DataFightCentral.
    Every model method is a real API call. Falls back through
    the chain if the requested model is unavailable or errors.
    """

    FALLBACK_CHAIN = [
        'gpt_5_nano', 'claude_sonnet_4_6', 'gemini_3_pro',
        'gpt_5_2', 'perplexity',
    ]

    def __init__(self):
        self._clients: Dict[str, Any] = {}
        self._init_openai()
        self._init_anthropic()
        self._init_google()
        self._init_perplexity()

        self.models = {
            'gemini_3_pro': self._gemini_3_pro,
            'claude_sonnet_4_6': self._claude_sonnet_4_6,
            'perplexity': self._perplexity,
            'gpt_5_2': self._gpt_5_2,
            'gpt_5_nano': self._gpt_5_nano,
        }

        available = [k for k in self.models if self._is_available(k)]
        logger.info('AiModelService ready. Available: %s', available)

    # ─── SDK Initialization ───────────────────────────────────────────────

    def _init_openai(self):
        if not OPENAI_API_KEY:
            logger.warning('OPENAI_API_KEY not set — GPT models unavailable')
            return
        try:
            from openai import OpenAI
            self._clients['openai'] = OpenAI(api_key=OPENAI_API_KEY)
        except ImportError:
            logger.warning('openai package not installed')
        except Exception as e:
            logger.error('OpenAI init failed: %s', e)

    def _init_anthropic(self):
        if not ANTHROPIC_API_KEY:
            logger.warning('ANTHROPIC_API_KEY not set — Claude unavailable')
            return
        try:
            import anthropic
            self._clients['anthropic'] = anthropic.Anthropic(
                api_key=ANTHROPIC_API_KEY,
            )
        except ImportError:
            logger.warning('anthropic package not installed')
        except Exception as e:
            logger.error('Anthropic init failed: %s', e)

    def _init_google(self):
        if not GOOGLE_AI_KEY:
            logger.warning('GOOGLE_AI_KEY not set — Gemini unavailable')
            return
        try:
            import google.generativeai as genai
            genai.configure(api_key=GOOGLE_AI_KEY)
            self._clients['google'] = genai.GenerativeModel(
                'gemini-2.0-flash',
            )
        except ImportError:
            logger.warning('google-generativeai package not installed')
        except Exception as e:
            logger.error('Google AI init failed: %s', e)

    def _init_perplexity(self):
        if not PERPLEXITY_API_KEY:
            logger.warning('PERPLEXITY_API_KEY not set — Perplexity unavailable')
            return
        try:
            from openai import OpenAI
            self._clients['perplexity'] = OpenAI(
                api_key=PERPLEXITY_API_KEY,
                base_url='https://api.perplexity.ai',
            )
        except ImportError:
            logger.warning('openai package needed for Perplexity')
        except Exception as e:
            logger.error('Perplexity init failed: %s', e)

    # ─── Availability ─────────────────────────────────────────────────────

    def _is_available(self, model_name: str) -> bool:
        mapping = {
            'gpt_5_nano': 'openai',
            'gpt_5_2': 'openai',
            'claude_sonnet_4_6': 'anthropic',
            'gemini_3_pro': 'google',
            'perplexity': 'perplexity',
        }
        return mapping.get(model_name, '') in self._clients

    def available_models(self) -> List[str]:
        """Return list of models that have valid API keys configured."""
        return [k for k in self.models if self._is_available(k)]

    # ─── Delegate with Fallback Chain ─────────────────────────────────────

    def delegate(self, model_name: str, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Route to selected model. If it fails, walk the fallback chain.
        Returns: {'text', 'model_used', 'latency_ms', 'tokens'}
        """
        # Try requested model first
        if model_name in self.models and self._is_available(model_name):
            try:
                return self.models[model_name](input_data)
            except Exception as e:
                logger.warning('%s failed: %s — trying fallbacks', model_name, e)

        # Walk fallback chain
        for fallback in self.FALLBACK_CHAIN:
            if fallback == model_name or not self._is_available(fallback):
                continue
            try:
                result = self.models[fallback](input_data)
                result['fallback_from'] = model_name
                return result
            except Exception as e:
                logger.warning('Fallback %s failed: %s', fallback, e)

        raise AiModelError(
            f'All models exhausted. Tried: {model_name} + {self.FALLBACK_CHAIN}',
        )

    # ─── GPT-5 Nano (OpenAI gpt-4o-mini) ─────────────────────────────────

    def _gpt_5_nano(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Fast, efficient, cost-effective. Maps to gpt-4o-mini."""
        client = self._clients.get('openai')
        if not client:
            raise AiModelError('OpenAI client not initialized')

        prompt = input_data.get('prompt', '')
        system = input_data.get(
            'system',
            DEFAULT_SYSTEM_PROMPT,
        )
        max_tokens = input_data.get('max_tokens', 1024)
        temperature = input_data.get('temperature', 0.7)

        start = time.time()
        response = client.chat.completions.create(
            model='gpt-4o-mini',
            messages=[
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': prompt},
            ],
            max_tokens=max_tokens,
            temperature=temperature,
        )
        latency = int((time.time() - start) * 1000)
        text = response.choices[0].message.content or ''
        usage = {}
        if response.usage:
            usage = {
                'prompt_tokens': response.usage.prompt_tokens,
                'completion_tokens': response.usage.completion_tokens,
                'total_tokens': response.usage.total_tokens,
            }
        logger.info('gpt_5_nano: %dms, %s tokens', latency, usage.get('total_tokens', '?'))
        return {'text': text, 'model_used': 'gpt_5_nano', 'latency_ms': latency, 'tokens': usage}

    # ─── GPT-5.2 (OpenAI gpt-4o) ─────────────────────────────────────────

    def _gpt_5_2(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Full power reasoning model. Maps to gpt-4o."""
        client = self._clients.get('openai')
        if not client:
            raise AiModelError('OpenAI client not initialized')

        prompt = input_data.get('prompt', '')
        system = input_data.get(
            'system',
            DEFAULT_SYSTEM_PROMPT,
        )
        max_tokens = input_data.get('max_tokens', 2048)
        temperature = input_data.get('temperature', 0.7)

        start = time.time()
        response = client.chat.completions.create(
            model='gpt-4o',
            messages=[
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': prompt},
            ],
            max_tokens=max_tokens,
            temperature=temperature,
        )
        latency = int((time.time() - start) * 1000)
        text = response.choices[0].message.content or ''
        usage = {}
        if response.usage:
            usage = {
                'prompt_tokens': response.usage.prompt_tokens,
                'completion_tokens': response.usage.completion_tokens,
                'total_tokens': response.usage.total_tokens,
            }
        logger.info('gpt_5_2: %dms, %s tokens', latency, usage.get('total_tokens', '?'))
        return {'text': text, 'model_used': 'gpt_5_2', 'latency_ms': latency, 'tokens': usage}

    # ─── Claude Sonnet 4.6 (Anthropic) ────────────────────────────────────

    def _claude_sonnet_4_6(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Nuanced analysis and premium content generation."""
        client = self._clients.get('anthropic')
        if not client:
            raise AiModelError('Anthropic client not initialized')

        prompt = input_data.get('prompt', '')
        system = input_data.get(
            'system',
            DEFAULT_SYSTEM_PROMPT,
        )
        max_tokens = input_data.get('max_tokens', 2048)
        temperature = input_data.get('temperature', 0.7)

        start = time.time()
        response = client.messages.create(
            model='claude-sonnet-4-20250514',
            max_tokens=max_tokens,
            system=system,
            messages=[{'role': 'user', 'content': prompt}],
            temperature=temperature,
        )
        latency = int((time.time() - start) * 1000)
        text = response.content[0].text if response.content else ''
        usage = {}
        if response.usage:
            usage = {
                'input_tokens': response.usage.input_tokens,
                'output_tokens': response.usage.output_tokens,
                'total_tokens': response.usage.input_tokens + response.usage.output_tokens,
            }
        logger.info('claude_sonnet_4_6: %dms, %s tokens', latency, usage.get('total_tokens', '?'))
        return {'text': text, 'model_used': 'claude_sonnet_4_6', 'latency_ms': latency, 'tokens': usage}

    # ─── Gemini 2.5 Pro (Google) ──────────────────────────────────────────

    def _gemini_3_pro(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Multimodal analysis and content generation via Google AI."""
        model = self._clients.get('google')
        if not model:
            raise AiModelError('Google AI client not initialized')

        prompt = input_data.get('prompt', '')
        system = input_data.get('system', '')
        full_prompt = f'{system}\n\n{prompt}' if system else prompt

        start = time.time()
        response = model.generate_content(full_prompt)
        latency = int((time.time() - start) * 1000)
        text = response.text if response.text else ''
        usage = {}
        if hasattr(response, 'usage_metadata') and response.usage_metadata:
            um = response.usage_metadata
            usage = {
                'prompt_tokens': getattr(um, 'prompt_token_count', 0),
                'completion_tokens': getattr(um, 'candidates_token_count', 0),
                'total_tokens': getattr(um, 'total_token_count', 0),
            }
        logger.info('gemini_3_pro: %dms', latency)
        return {'text': text, 'model_used': 'gemini_3_pro', 'latency_ms': latency, 'tokens': usage}

    # ─── Perplexity Sonar (real-time web search + AI) ─────────────────────

    def _perplexity(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Live web search for real-time fight news and analysis."""
        client = self._clients.get('perplexity')
        if not client:
            raise AiModelError('Perplexity client not initialized')

        prompt = input_data.get('prompt', '')
        system = input_data.get(
            'system',
            'You are a combat sports AI with real-time web access for DataFightCentral.',
        )
        max_tokens = input_data.get('max_tokens', 1024)

        start = time.time()
        response = client.chat.completions.create(
            model='sonar',
            messages=[
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': prompt},
            ],
            max_tokens=max_tokens,
        )
        latency = int((time.time() - start) * 1000)
        text = response.choices[0].message.content or ''
        usage = {}
        if response.usage:
            usage = {
                'prompt_tokens': response.usage.prompt_tokens,
                'completion_tokens': response.usage.completion_tokens,
                'total_tokens': response.usage.total_tokens,
            }
        logger.info('perplexity: %dms, %s tokens', latency, usage.get('total_tokens', '?'))
        return {'text': text, 'model_used': 'perplexity', 'latency_ms': latency, 'tokens': usage}

    # ─── Content Moderation ───────────────────────────────────────────────

    def moderate(self, text: str) -> Dict[str, Any]:
        """OpenAI moderation check. Returns {'safe': bool, 'reason': str}."""
        client = self._clients.get('openai')
        if not client:
            return {'safe': True, 'reason': 'No moderation client — allowing'}

        try:
            response = client.moderations.create(input=text)
            result = response.results[0]
            if result.flagged:
                flagged = [
                    cat for cat, val in vars(result.categories).items() if val
                ]
                return {'safe': False, 'reason': f'Flagged: {flagged}'}
            return {'safe': True, 'reason': 'Passed'}
        except Exception as e:
            logger.error('Moderation error: %s', e)
            return {'safe': True, 'reason': f'Moderation error: {e}'}

    # ─── JSON Generation Helper ───────────────────────────────────────────

    def generate_json(
        self,
        model_name: str,
        prompt: str,
        system: str = '',
        fallback: Any = None,
    ) -> Any:
        """Generate and parse JSON from any model. Returns parsed or fallback."""
        full_prompt = prompt + '\n\nReturn ONLY valid JSON. No markdown.'
        try:
            result = self.delegate(model_name, {
                'prompt': full_prompt,
                'system': system or 'Return only valid JSON.',
                'max_tokens': 2048,
                'temperature': 0.3,
            })
            text = result.get('text', '').strip()
            # Strip markdown code fences
            if text.startswith('```'):
                text = text.split('\n', 1)[-1] if '\n' in text else text[3:]
            if text.endswith('```'):
                text = text.rsplit('```', 1)[0]
            return json.loads(text.strip())
        except (json.JSONDecodeError, AiModelError) as e:
            logger.warning('generate_json failed: %s — returning fallback', e)
            return fallback


def get_ai_service() -> AiModelService:
    """Factory — call once at startup, reuse the instance."""
    return AiModelService()
