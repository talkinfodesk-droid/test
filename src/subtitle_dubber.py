"""SRT 자막 파싱 및 자막 더빙 기능"""

import pysrt
import numpy as np
import soundfile as sf
from pathlib import Path
from dataclasses import dataclass

from config import DEFAULT_SAMPLE_RATE, OUTPUT_DIR
from audio_utils import create_silence, normalize_audio


@dataclass
class SubtitleLine:
    """자막 라인 정보"""

    index: int
    start_seconds: float
    end_seconds: float
    text: str
    duration: float = 0.0

    def __post_init__(self):
        self.duration = self.end_seconds - self.start_seconds


def parse_srt(file_path):
    """SRT 파일을 파싱하여 SubtitleLine 목록을 반환합니다.

    Args:
        file_path: SRT 파일 경로

    Returns:
        list[SubtitleLine]: 자막 라인 목록
    """
    subs = pysrt.open(str(file_path), encoding="utf-8")

    lines = []
    for sub in subs:
        start = _time_to_seconds(sub.start)
        end = _time_to_seconds(sub.end)
        text = sub.text.replace("\n", " ").strip()

        if text:
            lines.append(
                SubtitleLine(
                    index=sub.index,
                    start_seconds=start,
                    end_seconds=end,
                    text=text,
                )
            )

    return lines


def _time_to_seconds(t):
    """pysrt SubRipTime을 초 단위로 변환합니다."""
    return t.hours * 3600 + t.minutes * 60 + t.seconds + t.milliseconds / 1000


def subtitle_lines_to_table(lines):
    """자막 라인 목록을 Gradio 테이블 형식으로 변환합니다."""
    rows = []
    for line in lines:
        start_str = _format_time(line.start_seconds)
        end_str = _format_time(line.end_seconds)
        rows.append([line.index, start_str, end_str, f"{line.duration:.1f}초", line.text])
    return rows


def _format_time(seconds):
    """초를 HH:MM:SS.mmm 형식으로 변환합니다."""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h:02d}:{m:02d}:{s:06.3f}"


class SubtitleDubber:
    """자막 기반 음성 더빙"""

    def __init__(self, tts_engine):
        self.tts_engine = tts_engine

    def dub_subtitles(
        self,
        subtitle_lines,
        language="ko",
        speed=1.0,
        voice_profile_audio=None,
        style_prompt=None,
        output_path=None,
        progress_callback=None,
    ):
        """자막 라인들을 음성으로 변환하여 타임라인에 맞춘 단일 오디오를 생성합니다.

        Args:
            subtitle_lines: SubtitleLine 목록
            language: 언어 코드
            speed: 재생 속도
            voice_profile_audio: 음성 클로닝용 참조 오디오 경로
            style_prompt: 감정/스타일 프롬프트
            output_path: 출력 파일 경로
            progress_callback: 진행률 콜백 함수 (progress_ratio, message)

        Returns:
            str: 생성된 오디오 파일 경로
        """
        if not subtitle_lines:
            raise ValueError("자막 라인이 없습니다.")

        if output_path is None:
            output_path = OUTPUT_DIR / "dubbed_output.wav"
        output_path = Path(output_path)

        # 전체 오디오 길이 계산 (마지막 자막 종료 시간 + 1초 여유)
        total_duration = max(line.end_seconds for line in subtitle_lines) + 1.0
        total_samples = int(total_duration * DEFAULT_SAMPLE_RATE)
        result = np.zeros(total_samples)

        total_lines = len(subtitle_lines)

        for i, line in enumerate(subtitle_lines):
            if progress_callback:
                progress = (i + 1) / total_lines
                progress_callback(progress, f"자막 {i + 1}/{total_lines} 생성 중: {line.text[:30]}...")

            # 각 자막 라인별 TTS 생성
            temp_path = OUTPUT_DIR / f"_temp_sub_{i}.wav"
            audio_path, sr = self.tts_engine.generate_speech(
                text=line.text,
                language=language,
                speed=speed,
                style_prompt=style_prompt,
                reference_audio_path=voice_profile_audio,
                output_path=temp_path,
            )

            # 생성된 오디오 로드
            audio_data, _ = sf.read(str(audio_path))

            # 자막 시간보다 긴 경우 속도 자동 조절
            max_samples = int(line.duration * DEFAULT_SAMPLE_RATE)
            if len(audio_data) > max_samples and max_samples > 0:
                audio_data = self._fit_to_duration(audio_data, max_samples)

            # 볼륨 정규화
            audio_data = normalize_audio(audio_data)

            # 타임스탬프에 맞춰 배치
            start_sample = int(line.start_seconds * DEFAULT_SAMPLE_RATE)
            end_sample = min(start_sample + len(audio_data), total_samples)
            actual_length = end_sample - start_sample

            if actual_length > 0:
                result[start_sample:end_sample] = audio_data[:actual_length]

            # 임시 파일 삭제
            if temp_path.exists():
                temp_path.unlink()

        # 최종 오디오 저장
        sf.write(str(output_path), result, DEFAULT_SAMPLE_RATE)

        if progress_callback:
            progress_callback(1.0, "더빙 완료!")

        return str(output_path)

    def _fit_to_duration(self, audio_data, target_samples):
        """오디오를 목표 길이에 맞게 압축합니다."""
        indices = np.linspace(0, len(audio_data) - 1, target_samples).astype(int)
        return audio_data[indices]
