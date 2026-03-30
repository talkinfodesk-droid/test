"""Qwen3-TTS 모델 로드 및 추론 엔진"""

import re
import torch
import numpy as np
import soundfile as sf
from pathlib import Path
from transformers import AutoTokenizer, AutoModelForCausalLM

from config import MODEL_NAME, DEVICE, DEFAULT_SAMPLE_RATE, VOICES_DIR, OUTPUT_DIR


class TTSEngine:
    """Qwen3-TTS 모델 싱글턴 엔진"""

    _instance = None

    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.sample_rate = DEFAULT_SAMPLE_RATE
        self._loaded = False

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def load_model(self, progress_callback=None):
        """모델을 로드합니다. 첫 호출 시 HuggingFace에서 다운로드됩니다."""
        if self._loaded:
            return

        if progress_callback:
            progress_callback(0.1, "토크나이저 로딩 중...")

        self.tokenizer = AutoTokenizer.from_pretrained(
            MODEL_NAME, trust_remote_code=True
        )

        if progress_callback:
            progress_callback(0.3, "모델 로딩 중... (첫 실행 시 다운로드가 필요합니다)")

        device_map = "auto" if DEVICE == "cuda" else "cpu"
        dtype = torch.float16 if DEVICE == "cuda" else torch.float32

        self.model = AutoModelForCausalLM.from_pretrained(
            MODEL_NAME,
            torch_dtype=dtype,
            device_map=device_map,
            trust_remote_code=True,
        )

        if progress_callback:
            progress_callback(1.0, "모델 로딩 완료!")

        self._loaded = True

    def is_loaded(self):
        return self._loaded

    def _split_text(self, text, max_length=200):
        """긴 텍스트를 문장 단위로 분할합니다."""
        sentences = re.split(r"(?<=[.!?。！？\n])\s*", text.strip())
        chunks = []
        current_chunk = ""

        for sentence in sentences:
            if not sentence.strip():
                continue
            if len(current_chunk) + len(sentence) > max_length and current_chunk:
                chunks.append(current_chunk.strip())
                current_chunk = sentence
            else:
                current_chunk += " " + sentence if current_chunk else sentence

        if current_chunk.strip():
            chunks.append(current_chunk.strip())

        return chunks if chunks else [text.strip()]

    def generate_speech(
        self,
        text,
        language="ko",
        speed=1.0,
        style_prompt=None,
        reference_audio_path=None,
        output_path=None,
    ):
        """텍스트에서 음성을 생성합니다.

        Args:
            text: 변환할 텍스트
            language: 언어 코드 (ko, en, zh, ja)
            speed: 재생 속도 (0.5 ~ 2.0)
            style_prompt: 감정/스타일 프롬프트 (선택)
            reference_audio_path: 음성 클로닝용 참조 오디오 경로 (선택)
            output_path: 출력 파일 경로 (None이면 자동 생성)

        Returns:
            tuple: (output_path, sample_rate)
        """
        if not self._loaded:
            raise RuntimeError("모델이 로드되지 않았습니다. load_model()을 먼저 호출하세요.")

        # 출력 경로 설정
        if output_path is None:
            output_path = OUTPUT_DIR / f"tts_output_{id(text) & 0xFFFF:04x}.wav"
        output_path = Path(output_path)

        # 텍스트 분할
        chunks = self._split_text(text)

        # 프롬프트 구성
        audio_segments = []
        for chunk in chunks:
            prompt = self._build_prompt(chunk, language, speed, style_prompt)

            # 참조 오디오가 있으면 음성 클로닝 모드
            if reference_audio_path:
                audio_array = self._generate_with_reference(
                    prompt, reference_audio_path
                )
            else:
                audio_array = self._generate_default(prompt)

            audio_segments.append(audio_array)

        # 오디오 세그먼트 병합
        if len(audio_segments) > 1:
            # 문장 사이에 짧은 무음 삽입 (0.3초)
            silence = np.zeros(int(self.sample_rate * 0.3))
            combined = []
            for i, seg in enumerate(audio_segments):
                combined.append(seg)
                if i < len(audio_segments) - 1:
                    combined.append(silence)
            final_audio = np.concatenate(combined)
        else:
            final_audio = audio_segments[0]

        # 속도 조절
        if speed != 1.0:
            final_audio = self._adjust_speed(final_audio, speed)

        # WAV 파일로 저장
        sf.write(str(output_path), final_audio, self.sample_rate)

        return str(output_path), self.sample_rate

    def _build_prompt(self, text, language, speed, style_prompt):
        """모델 입력 프롬프트를 구성합니다."""
        prompt_parts = []

        # 언어 태그
        lang_tags = {
            "ko": "[Korean]",
            "en": "[English]",
            "zh": "[Chinese]",
            "ja": "[Japanese]",
        }
        prompt_parts.append(lang_tags.get(language, "[Korean]"))

        # 스타일 프롬프트
        if style_prompt:
            prompt_parts.append(f"[Style: {style_prompt}]")

        # 텍스트
        prompt_parts.append(text)

        return " ".join(prompt_parts)

    def _generate_default(self, prompt):
        """기본 음성으로 텍스트를 음성 변환합니다."""
        inputs = self.tokenizer(prompt, return_tensors="pt")
        inputs = {k: v.to(self.model.device) for k, v in inputs.items()}

        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=4096,
                do_sample=True,
                temperature=0.7,
                top_p=0.9,
            )

        # 모델 출력에서 오디오 추출 (Qwen3-TTS의 출력 형식에 따라 조정 필요)
        audio_tokens = outputs[0][inputs["input_ids"].shape[1] :]
        audio_array = self._decode_audio_tokens(audio_tokens)

        return audio_array

    def _generate_with_reference(self, prompt, reference_audio_path):
        """참조 오디오를 사용한 zero-shot 음성 클로닝으로 변환합니다."""
        # 참조 오디오 로드
        ref_audio, ref_sr = sf.read(str(reference_audio_path))

        # 참조 오디오를 모델 입력에 포함
        # Qwen3-TTS의 음성 클로닝 API에 맞춰 조정 필요
        inputs = self.tokenizer(prompt, return_tensors="pt")
        inputs = {k: v.to(self.model.device) for k, v in inputs.items()}

        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=4096,
                do_sample=True,
                temperature=0.7,
                top_p=0.9,
            )

        audio_tokens = outputs[0][inputs["input_ids"].shape[1] :]
        audio_array = self._decode_audio_tokens(audio_tokens)

        return audio_array

    def _decode_audio_tokens(self, tokens):
        """모델 출력 토큰을 오디오 numpy 배열로 디코딩합니다.

        NOTE: Qwen3-TTS의 실제 디코딩 방식에 맞춰 구현 필요.
        현재는 플레이스홀더로 무음을 반환합니다.
        """
        # TODO: Qwen3-TTS 모델의 실제 오디오 디코딩 로직으로 교체
        # 모델의 generate() 출력이 직접 오디오 토큰을 반환하는지,
        # 별도의 vocoder가 필요한지 확인 후 구현
        duration_seconds = max(1.0, len(tokens) * 0.01)
        return np.zeros(int(self.sample_rate * duration_seconds))

    def _adjust_speed(self, audio, speed):
        """오디오 재생 속도를 조절합니다 (리샘플링 방식)."""
        if speed == 1.0:
            return audio

        # 간단한 리샘플링으로 속도 조절
        indices = np.arange(0, len(audio), speed)
        indices = indices[indices < len(audio)].astype(int)
        return audio[indices]
