"""Qwen3-TTS 모델 로드 및 추론 엔진

qwen-tts 공식 패키지의 Qwen3TTSModel API를 사용합니다.
- 기본 TTS: generate_voice_clone()에 기본 참조 음성 사용
- 음성 클로닝: generate_voice_clone()에 사용자 참조 음성 전달
"""

import re
import torch
import numpy as np
import soundfile as sf
from pathlib import Path

from config import MODEL_NAME, MODEL_NAME_SMALL, DEVICE, DEFAULT_SAMPLE_RATE, OUTPUT_DIR


def _detect_best_config():
    """GPU/VRAM을 감지하여 최적 모델 설정을 반환합니다."""
    if not torch.cuda.is_available():
        return {
            "model_name": MODEL_NAME_SMALL,
            "device": "cpu",
            "dtype": torch.float32,
            "attn_implementation": "eager",
        }

    vram_gb = torch.cuda.get_device_properties(0).total_mem / (1024**3)
    # Ampere 이상(compute capability >= 8.0)이면 FlashAttention 2 사용
    cc = torch.cuda.get_device_capability(0)
    has_flash = cc[0] >= 8

    if vram_gb >= 8:
        return {
            "model_name": MODEL_NAME,
            "device": "cuda:0",
            "dtype": torch.bfloat16,
            "attn_implementation": "flash_attention_2" if has_flash else "eager",
        }
    elif vram_gb >= 4:
        return {
            "model_name": MODEL_NAME_SMALL,
            "device": "cuda:0",
            "dtype": torch.bfloat16,
            "attn_implementation": "flash_attention_2" if has_flash else "eager",
        }
    else:
        return {
            "model_name": MODEL_NAME_SMALL,
            "device": "cpu",
            "dtype": torch.float32,
            "attn_implementation": "eager",
        }


class TTSEngine:
    """Qwen3-TTS 모델 싱글턴 엔진"""

    _instance = None

    def __init__(self):
        self.model = None
        self.sample_rate = DEFAULT_SAMPLE_RATE
        self._loaded = False
        self._config = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def load_model(self, progress_callback=None):
        """모델을 로드합니다. 첫 호출 시 HuggingFace에서 다운로드됩니다."""
        if self._loaded:
            return

        from qwen_tts import Qwen3TTSModel

        self._config = _detect_best_config()

        if progress_callback:
            model_label = "1.7B" if "1.7B" in self._config["model_name"] else "0.6B"
            progress_callback(
                0.1,
                f"모델 로딩 중 ({model_label}, {self._config['device']})... "
                f"첫 실행 시 다운로드가 필요합니다",
            )

        self.model = Qwen3TTSModel.from_pretrained(
            self._config["model_name"],
            torch_dtype=self._config["dtype"],
            attn_implementation=self._config["attn_implementation"],
            device_map=self._config["device"],
        )

        if progress_callback:
            progress_callback(1.0, "모델 로딩 완료!")

        self._loaded = True

    def is_loaded(self):
        return self._loaded

    def get_model_info(self):
        """현재 로드된 모델 정보를 반환합니��."""
        if not self._config:
            return "모델이 아직 로드되지 않았습니다."
        model_label = "1.7B" if "1.7B" in self._config["model_name"] else "0.6B"
        return f"모델: {model_label} | 디바이스: {self._config['device']} | dtype: {self._config['dtype']}"

    def _split_text(self, text, max_length=200):
        """�� 텍스트를 문장 단위로 분할합니다."""
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
        reference_text=None,
        output_path=None,
    ):
        """텍스트에서 음성을 생성합니다.

        Args:
            text: 변환할 텍스트
            language: 언어 코드 (ko, en, zh, ja 등)
            speed: 재�� 속도 (0.5 ~ 2.0)
            style_prompt: 감정/스타일 프롬프트 (선택)
            reference_audio_path: 음성 클로닝용 참조 오디오 경로 (선택)
            reference_text: 참조 오디오의 텍스트 전사 (선택, 클로닝 품질 향상)
            output_path: 출력 파일 경로 (None이면 자동 생성)

        Returns:
            tuple: (output_path, sample_rate)
        """
        if not self._loaded:
            raise RuntimeError("모델이 로드되지 않았습��다. load_model()을 먼��� 호출하세요.")

        # 출력 경로 설정
        if output_path is None:
            import time
            output_path = OUTPUT_DIR / f"tts_{int(time.time() * 1000) % 100000}.wav"
        output_path = Path(output_path)

        # 텍스트 분할
        chunks = self._split_text(text)

        audio_segments = []
        for chunk in chunks:
            # 스타일 프롬프트가 있으면 텍스트에 앞에 추가
            gen_text = chunk
            if style_prompt:
                gen_text = f"({style_prompt}) {chunk}"

            audio_array = self._generate_chunk(
                text=gen_text,
                reference_audio_path=reference_audio_path,
                reference_text=reference_text,
            )
            audio_segments.append(audio_array)

        # 오디오 세그먼트 병합
        if len(audio_segments) > 1:
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

    def _generate_chunk(self, text, reference_audio_path=None, reference_text=None):
        """단일 텍스트 청크에서 오디오를 생성합니다.

        Qwen3-TTS의 generate_voice_clone() API를 사용합니다.
        참조 오디오가 없으면 x_vector_only_mode로 기본 음성을 사용합니다.
        """
        kwargs = {"text": text}

        if reference_audio_path:
            kwargs["ref_audio"] = str(reference_audio_path)
            if reference_text:
                kwargs["ref_text"] = reference_text
            else:
                # 참조 텍스트 없이 음성 특성만 추출
                kwargs["x_vector_only_mode"] = True
        else:
            # 참조 오디오 없이 기본 음성 사용
            kwargs["x_vector_only_mode"] = True

        audio_array, sample_rate = self.model.generate_voice_clone(**kwargs)

        # numpy로 변환
        if torch.is_tensor(audio_array):
            audio_array = audio_array.cpu().numpy()

        if audio_array.ndim > 1:
            audio_array = audio_array.squeeze()

        self.sample_rate = sample_rate
        return audio_array

    def _adjust_speed(self, audio, speed):
        """오디오 재생 속도를 조절합니다 (리샘플링 방식)."""
        if speed == 1.0:
            return audio

        indices = np.arange(0, len(audio), speed)
        indices = indices[indices < len(audio)].astype(int)
        return audio[indices]
