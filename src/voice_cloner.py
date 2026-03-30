"""음성 클로닝 및 음성 프로필 관리"""

import json
import shutil
import soundfile as sf
from pathlib import Path
from datetime import datetime

from config import VOICES_DIR


class VoiceProfile:
    """저장된 음성 프로필"""

    def __init__(self, name, audio_path, created_at=None):
        self.name = name
        self.audio_path = Path(audio_path)
        self.created_at = created_at or datetime.now().isoformat()

    def to_dict(self):
        return {
            "name": self.name,
            "audio_path": str(self.audio_path),
            "created_at": self.created_at,
        }

    @classmethod
    def from_dict(cls, data):
        return cls(
            name=data["name"],
            audio_path=data["audio_path"],
            created_at=data.get("created_at"),
        )


class VoiceCloner:
    """음성 프로필 생성 및 관리"""

    PROFILES_FILE = VOICES_DIR / "profiles.json"

    def __init__(self):
        self.profiles = self._load_profiles()

    def _load_profiles(self):
        """저장된 프로필 목록을 로드합니다."""
        if not self.PROFILES_FILE.exists():
            return {}

        with open(self.PROFILES_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)

        profiles = {}
        for name, info in data.items():
            profile = VoiceProfile.from_dict(info)
            if profile.audio_path.exists():
                profiles[name] = profile

        return profiles

    def _save_profiles(self):
        """프로필 목록을 디스크에 저장합니다."""
        data = {name: p.to_dict() for name, p in self.profiles.items()}
        with open(self.PROFILES_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    def create_profile(self, name, reference_audio_path):
        """참조 오디오로부터 음성 프로필을 생성합니다.

        Args:
            name: 프로필 이름
            reference_audio_path: 참조 오디오 파일 경로

        Returns:
            VoiceProfile: 생성된 프로필
        """
        reference_audio_path = Path(reference_audio_path)

        if not reference_audio_path.exists():
            raise FileNotFoundError(f"참조 오디오를 찾을 수 없습니다: {reference_audio_path}")

        # 프로필 이름 정리
        safe_name = "".join(c for c in name if c.isalnum() or c in "-_ ").strip()
        if not safe_name:
            raise ValueError("유효한 프로필 이름을 입력하세요.")

        # 참조 오디오를 voices/ 디렉토리에 복사
        dest_path = VOICES_DIR / f"{safe_name}.wav"

        # 오디오 파일 읽기 및 WAV로 변환 저장
        data, sr = sf.read(str(reference_audio_path))
        sf.write(str(dest_path), data, sr)

        # 프로필 저장
        profile = VoiceProfile(name=safe_name, audio_path=dest_path)
        self.profiles[safe_name] = profile
        self._save_profiles()

        return profile

    def delete_profile(self, name):
        """음성 프로필을 삭제합니다."""
        if name not in self.profiles:
            raise KeyError(f"프로필을 찾을 수 없습니다: {name}")

        profile = self.profiles[name]

        # 오디오 파일 삭제
        if profile.audio_path.exists():
            profile.audio_path.unlink()

        del self.profiles[name]
        self._save_profiles()

    def get_profile(self, name):
        """이름으로 프로필을 가져옵니다."""
        return self.profiles.get(name)

    def list_profiles(self):
        """저장된 모든 프로필 이름 목록을 반환합니다."""
        return list(self.profiles.keys())

    def get_reference_audio_path(self, name):
        """프로필의 참조 오디오 경로를 반환합니다."""
        profile = self.profiles.get(name)
        if profile and profile.audio_path.exists():
            return str(profile.audio_path)
        return None

    def get_audio_info(self, audio_path):
        """오디오 파일의 정보를 반환합니다."""
        data, sr = sf.read(str(audio_path))
        duration = len(data) / sr
        return {
            "duration_seconds": round(duration, 2),
            "sample_rate": sr,
            "channels": 1 if data.ndim == 1 else data.shape[1],
        }
