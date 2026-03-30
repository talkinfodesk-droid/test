"""Qwen3-TTS Studio - Gradio UI 메인 엔트리포인트"""

import sys
from pathlib import Path

# src 디렉토리를 모듈 경로에 추가
sys.path.insert(0, str(Path(__file__).parent))

import gradio as gr

from config import (
    APP_TITLE,
    APP_DESCRIPTION,
    LANGUAGES,
    MIN_SPEED,
    MAX_SPEED,
    DEFAULT_SPEED,
    AUDIO_FORMATS,
    DEFAULT_FORMAT,
    SERVER_PORT,
    OUTPUT_DIR,
)
from tts_engine import TTSEngine
from voice_cloner import VoiceCloner
from subtitle_dubber import SubtitleDubber, parse_srt, subtitle_lines_to_table
from audio_utils import convert_format, get_audio_duration

# 전역 인스턴스
engine = TTSEngine.get_instance()
cloner = VoiceCloner()
dubber = SubtitleDubber(engine)

# 파싱된 자막 라인 저장용
_current_subtitle_lines = []


# ─────────────────────────────────────────────
# Tab 1: 텍스트 → 음성 변환
# ─────────────────────────────────────────────
def generate_tts(text, language, speed, style_prompt, voice_profile, output_format, progress=gr.Progress()):
    """텍스트에서 음성을 생성합니다."""
    if not text.strip():
        return None, "텍스트를 입력해주세요."

    if not engine.is_loaded():
        progress(0.1, desc="모델 로딩 중...")
        engine.load_model(progress_callback=lambda p, m: progress(p * 0.5, desc=m))

    progress(0.6, desc="음성 생성 중...")

    # 음성 프로필 참조 오디오 경로 및 텍스트
    ref_audio = None
    ref_text = None
    if voice_profile and voice_profile != "기본 음성":
        ref_audio = cloner.get_reference_audio_path(voice_profile)
        ref_text = cloner.get_reference_text(voice_profile)

    lang_code = LANGUAGES.get(language, "ko")

    output_path, sr = engine.generate_speech(
        text=text,
        language=lang_code,
        speed=speed,
        style_prompt=style_prompt if style_prompt else None,
        reference_audio_path=ref_audio,
        reference_text=ref_text,
    )

    # 형식 변환
    if output_format == "mp3":
        output_path = convert_format(output_path, "mp3")

    progress(1.0, desc="완료!")
    duration = get_audio_duration(output_path)
    status = f"생성 완료! (길이: {duration:.1f}초, 형식: {output_format.upper()})"

    return output_path, status


def get_voice_choices():
    """사용 가능한 음성 프로필 목록을 반환합니다."""
    profiles = cloner.list_profiles()
    return ["기본 음성"] + profiles


# ─────────────────────────────────────────────
# Tab 2: 음성 클로닝
# ─────────────────────────────────────────────
def create_voice_profile(audio_file, profile_name, reference_text):
    """참조 오디오로 음성 프로필을 생성합니다."""
    if audio_file is None:
        return "참조 오디오를 업로드해주세요.", get_profile_list_display()

    if not profile_name.strip():
        return "프로필 이름을 입력해주세요.", get_profile_list_display()

    try:
        ref_text = reference_text.strip() if reference_text else None
        profile = cloner.create_profile(profile_name.strip(), audio_file, ref_text)
        info = cloner.get_audio_info(audio_file)
        status = (
            f"프로필 '{profile.name}' 생성 완료! "
            f"(참조 오디오: {info['duration_seconds']}초)"
        )
        return status, get_profile_list_display()
    except Exception as e:
        return f"오류: {str(e)}", get_profile_list_display()


def delete_voice_profile(profile_name):
    """음성 프로필을 삭제합니다."""
    if not profile_name:
        return "삭제할 프로필을 선택해주세요.", get_profile_list_display()

    try:
        cloner.delete_profile(profile_name)
        return f"프로필 '{profile_name}' 삭제 완료.", get_profile_list_display()
    except Exception as e:
        return f"오류: {str(e)}", get_profile_list_display()


def test_cloned_voice(profile_name, test_text, progress=gr.Progress()):
    """클로닝된 음성으로 테스트 문장을 생성합니다."""
    if not profile_name:
        return None, "프로필을 선택해주세요."

    if not test_text.strip():
        return None, "테스트 문장을 입력해주세요."

    if not engine.is_loaded():
        progress(0.1, desc="모델 로딩 중...")
        engine.load_model(progress_callback=lambda p, m: progress(p * 0.5, desc=m))

    ref_audio = cloner.get_reference_audio_path(profile_name)
    if not ref_audio:
        return None, "프로필의 참조 오디오를 찾을 수 없습니다."

    ref_text = cloner.get_reference_text(profile_name)

    progress(0.6, desc="클로닝 음성 생성 중...")
    output_path, sr = engine.generate_speech(
        text=test_text,
        reference_audio_path=ref_audio,
        reference_text=ref_text,
    )

    progress(1.0, desc="완료!")
    return output_path, f"테스트 음성 생성 완료! (프로필: {profile_name})"


def get_profile_list_display():
    """프로필 목록을 표시용 문자열로 반환합니다."""
    profiles = cloner.list_profiles()
    if not profiles:
        return "저장된 음성 프로필이 없습니다."

    lines = ["### 저장된 음성 프로필"]
    for i, name in enumerate(profiles, 1):
        ref_path = cloner.get_reference_audio_path(name)
        if ref_path:
            info = cloner.get_audio_info(ref_path)
            lines.append(f"{i}. **{name}** (참조: {info['duration_seconds']}초)")
        else:
            lines.append(f"{i}. **{name}**")
    return "\n".join(lines)


# ─────────────────────────────────────────────
# Tab 3: 자막 더빙
# ─────────────────────────────────────────────
def load_srt_file(srt_file):
    """SRT 파일을 로드하고 자막 테이블을 표시합니다."""
    global _current_subtitle_lines

    if srt_file is None:
        return None, "SRT 파일을 업로드해주세요.", 0

    try:
        _current_subtitle_lines = parse_srt(srt_file)
        table = subtitle_lines_to_table(_current_subtitle_lines)

        total_duration = max(line.end_seconds for line in _current_subtitle_lines)
        status = f"자막 {len(_current_subtitle_lines)}개 로드 완료 (총 길이: {total_duration:.1f}초)"

        return table, status, len(_current_subtitle_lines)
    except Exception as e:
        _current_subtitle_lines = []
        return None, f"SRT 파싱 오류: {str(e)}", 0


def dub_subtitles(
    language, speed, voice_profile, style_prompt, output_format, progress=gr.Progress()
):
    """자막을 음성으로 더빙합니다."""
    global _current_subtitle_lines

    if not _current_subtitle_lines:
        return None, "먼저 SRT 파일을 로드해주세요."

    if not engine.is_loaded():
        progress(0.1, desc="모델 로딩 중...")
        engine.load_model(progress_callback=lambda p, m: progress(p * 0.3, desc=m))

    # 음성 프로필
    ref_audio = None
    ref_text = None
    if voice_profile and voice_profile != "기본 음성":
        ref_audio = cloner.get_reference_audio_path(voice_profile)
        ref_text = cloner.get_reference_text(voice_profile)

    lang_code = LANGUAGES.get(language, "ko")

    def dub_progress(ratio, msg):
        progress(0.3 + ratio * 0.65, desc=msg)

    output_path = dubber.dub_subtitles(
        subtitle_lines=_current_subtitle_lines,
        language=lang_code,
        speed=speed,
        voice_profile_audio=ref_audio,
        voice_profile_text=ref_text,
        style_prompt=style_prompt if style_prompt else None,
        progress_callback=dub_progress,
    )

    # 형식 변환
    if output_format == "mp3":
        output_path = convert_format(output_path, "mp3")

    progress(1.0, desc="더빙 완료!")
    duration = get_audio_duration(output_path)
    status = f"더빙 완료! ({len(_current_subtitle_lines)}개 자막, 길이: {duration:.1f}초)"

    return output_path, status


# ─────────────────────────────────────────────
# Gradio UI 구성
# ─────────────────────────────────────────────
def build_ui():
    with gr.Blocks(title=APP_TITLE, theme=gr.themes.Soft()) as app:
        gr.Markdown(f"# {APP_TITLE}")
        gr.Markdown(f"*{APP_DESCRIPTION}*")

        with gr.Tabs():
            # ── Tab 1: 텍스트 → 음성 ──
            with gr.Tab("텍스트 → 음성"):
                with gr.Row():
                    with gr.Column(scale=2):
                        tts_text = gr.Textbox(
                            label="텍스트 입력",
                            placeholder="변환할 텍스트를 입력하세요...",
                            lines=8,
                        )
                        with gr.Row():
                            tts_language = gr.Dropdown(
                                choices=list(LANGUAGES.keys()),
                                value="한국어",
                                label="언어",
                            )
                            tts_speed = gr.Slider(
                                minimum=MIN_SPEED,
                                maximum=MAX_SPEED,
                                value=DEFAULT_SPEED,
                                step=0.1,
                                label="속도",
                            )
                            tts_format = gr.Dropdown(
                                choices=AUDIO_FORMATS,
                                value=DEFAULT_FORMAT,
                                label="출력 형식",
                            )
                        tts_style = gr.Textbox(
                            label="스타일/감정 프롬프트 (선택)",
                            placeholder="예: 밝고 활기찬 목소리, 차분한 나레이션...",
                        )
                        tts_voice = gr.Dropdown(
                            choices=get_voice_choices(),
                            value="기본 음성",
                            label="음성 선택",
                        )
                        tts_btn = gr.Button("음성 생성", variant="primary", size="lg")

                    with gr.Column(scale=1):
                        tts_output = gr.Audio(label="생성된 음성", type="filepath")
                        tts_status = gr.Textbox(label="상태", interactive=False)

                tts_btn.click(
                    fn=generate_tts,
                    inputs=[tts_text, tts_language, tts_speed, tts_style, tts_voice, tts_format],
                    outputs=[tts_output, tts_status],
                )

            # ── Tab 2: 음성 클로닝 ──
            with gr.Tab("음성 클로닝"):
                with gr.Row():
                    with gr.Column():
                        gr.Markdown("### 새 음성 프로필 만들기")
                        clone_audio = gr.Audio(
                            label="참조 오디오 업로드 (5~30초 권장)",
                            type="filepath",
                        )
                        clone_name = gr.Textbox(
                            label="프로필 이름",
                            placeholder="예: 내 목소리, 나레이터1...",
                        )
                        clone_ref_text = gr.Textbox(
                            label="참조 오디오 텍스트 전사 (선택, 입력 시 품질 향상)",
                            placeholder="참조 오디오에서 말하는 내용을 텍스트로 입력하세요...",
                            lines=2,
                        )
                        clone_btn = gr.Button("프로필 저장", variant="primary")
                        clone_status = gr.Textbox(label="상태", interactive=False)

                    with gr.Column():
                        gr.Markdown("### 저장된 프로필")
                        profile_list = gr.Markdown(value=get_profile_list_display())
                        delete_profile_name = gr.Dropdown(
                            choices=cloner.list_profiles(),
                            label="삭제할 프로필",
                        )
                        delete_btn = gr.Button("프로필 삭제", variant="stop")

                gr.Markdown("---")
                gr.Markdown("### 클로닝 음성 테스트")
                with gr.Row():
                    with gr.Column():
                        test_profile = gr.Dropdown(
                            choices=cloner.list_profiles(),
                            label="테스트할 프로필",
                        )
                        test_text = gr.Textbox(
                            label="테스트 문장",
                            placeholder="테스트할 문장을 입력하세요...",
                            value="안녕하세요, 이것은 음성 클로닝 테스트입니다.",
                        )
                        test_btn = gr.Button("테스트 생성", variant="primary")

                    with gr.Column():
                        test_output = gr.Audio(label="테스트 음성", type="filepath")
                        test_status = gr.Textbox(label="상태", interactive=False)

                # 프로필 생성/삭제 후 UI 업데이트
                def refresh_profiles():
                    profiles = cloner.list_profiles()
                    return (
                        gr.update(choices=profiles),
                        gr.update(choices=profiles),
                        gr.update(choices=get_voice_choices()),
                    )

                clone_btn.click(
                    fn=create_voice_profile,
                    inputs=[clone_audio, clone_name, clone_ref_text],
                    outputs=[clone_status, profile_list],
                ).then(
                    fn=refresh_profiles,
                    outputs=[delete_profile_name, test_profile, tts_voice],
                )

                delete_btn.click(
                    fn=delete_voice_profile,
                    inputs=[delete_profile_name],
                    outputs=[clone_status, profile_list],
                ).then(
                    fn=refresh_profiles,
                    outputs=[delete_profile_name, test_profile, tts_voice],
                )

                test_btn.click(
                    fn=test_cloned_voice,
                    inputs=[test_profile, test_text],
                    outputs=[test_output, test_status],
                )

            # ── Tab 3: 자막 더빙 ──
            with gr.Tab("자막 더빙"):
                with gr.Row():
                    with gr.Column(scale=2):
                        srt_file = gr.File(
                            label="SRT 자막 파일 업로드",
                            file_types=[".srt"],
                        )
                        srt_table = gr.Dataframe(
                            headers=["#", "시작", "종료", "길이", "텍스트"],
                            label="자막 내용",
                            interactive=False,
                        )
                        srt_status = gr.Textbox(label="상태", interactive=False)
                        srt_count = gr.Number(visible=False)

                    with gr.Column(scale=1):
                        dub_language = gr.Dropdown(
                            choices=list(LANGUAGES.keys()),
                            value="한국어",
                            label="언어",
                        )
                        dub_speed = gr.Slider(
                            minimum=MIN_SPEED,
                            maximum=MAX_SPEED,
                            value=DEFAULT_SPEED,
                            step=0.1,
                            label="속도",
                        )
                        dub_voice = gr.Dropdown(
                            choices=get_voice_choices(),
                            value="기본 음성",
                            label="음성 선택",
                        )
                        dub_style = gr.Textbox(
                            label="스타일/감정 프롬프트 (선택)",
                            placeholder="예: 뉴스 앵커 스타일...",
                        )
                        dub_format = gr.Dropdown(
                            choices=AUDIO_FORMATS,
                            value=DEFAULT_FORMAT,
                            label="출력 형식",
                        )
                        dub_btn = gr.Button("더빙 시작", variant="primary", size="lg")
                        dub_output = gr.Audio(label="더빙 결과", type="filepath")
                        dub_result_status = gr.Textbox(label="결과", interactive=False)

                srt_file.change(
                    fn=load_srt_file,
                    inputs=[srt_file],
                    outputs=[srt_table, srt_status, srt_count],
                )

                dub_btn.click(
                    fn=dub_subtitles,
                    inputs=[dub_language, dub_speed, dub_voice, dub_style, dub_format],
                    outputs=[dub_output, dub_result_status],
                )

    return app


if __name__ == "__main__":
    app = build_ui()
    app.launch(server_port=SERVER_PORT, share=False)
