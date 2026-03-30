"""오디오 변환 및 병합 유틸리티"""

import numpy as np
import soundfile as sf
from pathlib import Path
from pydub import AudioSegment

from config import DEFAULT_SAMPLE_RATE, OUTPUT_DIR


def wav_to_mp3(wav_path, mp3_path=None, bitrate="192k"):
    """WAV 파일을 MP3로 변환합니다."""
    wav_path = Path(wav_path)
    if mp3_path is None:
        mp3_path = wav_path.with_suffix(".mp3")

    audio = AudioSegment.from_wav(str(wav_path))
    audio.export(str(mp3_path), format="mp3", bitrate=bitrate)
    return str(mp3_path)


def convert_format(input_path, output_format="mp3"):
    """오디오 파일을 지정 형식으로 변환합니다."""
    input_path = Path(input_path)
    output_path = input_path.with_suffix(f".{output_format}")

    if output_format == "mp3":
        return wav_to_mp3(input_path, output_path)
    elif output_format == "wav":
        audio = AudioSegment.from_file(str(input_path))
        audio.export(str(output_path), format="wav")
        return str(output_path)
    else:
        raise ValueError(f"지원하지 않는 형식: {output_format}")


def merge_audio_files(audio_paths, output_path=None, gap_seconds=0.3):
    """여러 오디오 파일을 하나로 병합합니다.

    Args:
        audio_paths: 병합할 오디오 파일 경로 목록
        output_path: 출력 파일 경로
        gap_seconds: 파일 사이 무음 간격 (초)

    Returns:
        str: 병합된 오디오 파일 경로
    """
    if not audio_paths:
        raise ValueError("병합할 오디오 파일이 없습니다.")

    if output_path is None:
        output_path = OUTPUT_DIR / "merged_output.wav"

    segments = []
    for path in audio_paths:
        data, sr = sf.read(str(path))
        # 샘플레이트가 다르면 리샘플링
        if sr != DEFAULT_SAMPLE_RATE:
            data = _resample(data, sr, DEFAULT_SAMPLE_RATE)
        segments.append(data)

    # 무음 간격
    silence = np.zeros(int(DEFAULT_SAMPLE_RATE * gap_seconds))

    combined = []
    for i, seg in enumerate(segments):
        combined.append(seg)
        if i < len(segments) - 1:
            combined.append(silence)

    final = np.concatenate(combined)
    sf.write(str(output_path), final, DEFAULT_SAMPLE_RATE)
    return str(output_path)


def create_silence(duration_seconds, sample_rate=None):
    """지정 길이의 무음 오디오를 생성합니다."""
    sr = sample_rate or DEFAULT_SAMPLE_RATE
    return np.zeros(int(sr * duration_seconds))


def insert_audio_at_timestamp(
    base_duration_seconds, audio_segments_with_timestamps, sample_rate=None
):
    """타임스탬프에 맞춰 오디오 세그먼트를 배치합니다.

    Args:
        base_duration_seconds: 전체 오디오 길이 (초)
        audio_segments_with_timestamps: [(start_sec, audio_array), ...] 목록
        sample_rate: 샘플레이트

    Returns:
        numpy.ndarray: 배치된 오디오 배열
    """
    sr = sample_rate or DEFAULT_SAMPLE_RATE
    total_samples = int(base_duration_seconds * sr)
    result = np.zeros(total_samples)

    for start_sec, audio_array in audio_segments_with_timestamps:
        start_sample = int(start_sec * sr)
        end_sample = min(start_sample + len(audio_array), total_samples)
        actual_length = end_sample - start_sample

        if actual_length > 0:
            result[start_sample:end_sample] = audio_array[:actual_length]

    return result


def get_audio_duration(file_path):
    """오디오 파일의 재생 시간(초)을 반환합니다."""
    data, sr = sf.read(str(file_path))
    return len(data) / sr


def normalize_audio(audio_array, target_db=-20.0):
    """오디오 볼륨을 정규화합니다."""
    if len(audio_array) == 0:
        return audio_array

    rms = np.sqrt(np.mean(audio_array**2))
    if rms == 0:
        return audio_array

    current_db = 20 * np.log10(rms)
    gain = 10 ** ((target_db - current_db) / 20)
    return audio_array * gain


def _resample(data, orig_sr, target_sr):
    """간단한 리샘플링 (선형 보간)."""
    if orig_sr == target_sr:
        return data

    ratio = target_sr / orig_sr
    new_length = int(len(data) * ratio)
    indices = np.linspace(0, len(data) - 1, new_length)
    return np.interp(indices, np.arange(len(data)), data)
