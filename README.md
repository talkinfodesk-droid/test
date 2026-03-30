# Qwen3-TTS Studio

크리에이터를 위한 로컬 AI 음성 생성 도구

## 주요 기능

- **텍스트 → 음성 변환**: 텍스트를 입력하면 자연스러운 음성을 생성 (한국어/영어/중국어/일본어)
- **음성 클로닝**: 짧은 참조 오디오(5~30초)로 목소리를 복제하여 TTS에 활용
- **자막 더빙**: SRT 자막 파일을 업로드하면 타임라인에 맞춰 자동으로 음성 생성

## 요구사항

- Python 3.10+
- GPU 권장 (NVIDIA, VRAM 4GB+) / CPU도 가능 (느림)
- FFmpeg 설치 필요

## 설치 및 실행

```bash
# 의존성 설치
pip install -r requirements.txt

# FFmpeg 설치 (Ubuntu/Debian)
sudo apt install ffmpeg

# 앱 실행
python src/app.py
```

실행 후 브라우저에서 `http://localhost:7860` 접속

## 프로젝트 구조

```
src/
├── app.py              # Gradio UI (메인 엔트리포인트)
├── tts_engine.py       # Qwen3-TTS 모델 로드 및 추론
├── voice_cloner.py     # 음성 프로필 관리
├── subtitle_dubber.py  # SRT 자막 더빙
├── audio_utils.py      # 오디오 변환/병합 유틸
└── config.py           # 설정값
voices/                 # 저장된 음성 프로필
output/                 # 생성된 오디오 출력
```

## 사용법

### 1. 텍스트 → 음성
1. 텍스트 입력
2. 언어, 속도, 출력 형식 설정
3. (선택) 스타일 프롬프트 입력 (예: "밝고 활기찬 목소리")
4. "음성 생성" 클릭

### 2. 음성 클로닝
1. 참조 오디오 업로드 (5~30초)
2. 프로필 이름 입력 후 저장
3. Tab 1에서 저장한 프로필 선택하여 사용

### 3. 자막 더빙
1. SRT 파일 업로드
2. 자막 내용 확인
3. 언어, 속도, 음성 설정
4. "더빙 시작" 클릭 → 타임라인에 맞춘 오디오 자동 생성
