"""Qwen3-TTS 데스크톱 앱 설정"""

import os
from pathlib import Path

# 프로젝트 루트 디렉토리
PROJECT_ROOT = Path(__file__).parent.parent

# 디렉토리 경로
VOICES_DIR = PROJECT_ROOT / "voices"
OUTPUT_DIR = PROJECT_ROOT / "output"

# 디렉토리 자동 생성
VOICES_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

# Qwen3-TTS 모델 설정
MODEL_NAME = "Qwen/Qwen3-TTS-12Hz-1.7B-Base"
MODEL_NAME_SMALL = "Qwen/Qwen3-TTS-12Hz-0.6B-Base"
DEVICE = "cuda" if os.environ.get("FORCE_CPU") != "1" else "cpu"

# 오디오 설정
DEFAULT_SAMPLE_RATE = 24000
DEFAULT_SPEED = 1.0
MIN_SPEED = 0.5
MAX_SPEED = 2.0

# 지원 언어
LANGUAGES = {
    "한국어": "ko",
    "English": "en",
    "中文": "zh",
    "日本語": "ja",
    "Deutsch": "de",
    "Français": "fr",
    "Español": "es",
    "Português": "pt",
    "Русский": "ru",
    "Italiano": "it",
}

# 출력 형식
AUDIO_FORMATS = ["wav", "mp3"]
DEFAULT_FORMAT = "wav"

# Gradio UI 설정
APP_TITLE = "Qwen3-TTS Studio"
APP_DESCRIPTION = "크리에이터를 위한 로컬 AI 음성 생성 도구"
SERVER_PORT = 7860
