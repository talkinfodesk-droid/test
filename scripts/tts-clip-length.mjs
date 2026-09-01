#!/usr/bin/env node
/**
 * 쇼츠 대본 → 타입캐스트 TTS → 음성 길이 측정 → 클립 길이(6/8/10초) 자동 결정
 *
 * 사용법:
 *   node scripts/tts-clip-length.mjs <대본파일> [출력폴더]
 *
 *   대본파일: 빈 줄로 구분된 4개(또는 N개) 구간의 텍스트 파일
 *   출력폴더: 기본값 ./tts-output (구간별 wav + result.json 저장)
 *
 * .env / .env.local 에 필요한 값:
 *   TYPECAST_API_KEY=...      (필수)
 *   TYPECAST_VOICE_ID=tc_...  (필수)
 *   TYPECAST_MODEL=ssfm-v30   (선택, 기본 ssfm-v30)
 *   TYPECAST_LANGUAGE=kor     (선택, 기본 kor)
 *
 * 클립 길이 규칙 (음성 길이 + 0.5~1초 패딩 확보):
 *   음성 ≤ 5초  → 6초 클립
 *   음성 ≤ 7초  → 8초 클립
 *   음성 ≤ 9초  → 10초 클립
 *   음성 > 9초  → 클립 불가: 대본을 줄이거나 구간을 다시 나눠야 함
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import path from 'node:path';

const API_URL = 'https://api.typecast.ai/v1/text-to-speech';

function loadEnv(dir) {
  const env = {};
  for (const name of ['.env', '.env.local']) {
    const p = path.join(dir, name);
    if (!existsSync(p)) continue;
    for (const line of readFileSync(p, 'utf8').split('\n')) {
      const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
      if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  }
  return { ...env, ...process.env };
}

// WAV 헤더의 fmt 청크(byteRate)와 data 청크 크기로 재생 길이를 계산한다.
function wavDurationSeconds(buf) {
  if (buf.toString('ascii', 0, 4) !== 'RIFF' || buf.toString('ascii', 8, 12) !== 'WAVE') {
    throw new Error('WAV 형식이 아닌 응답입니다.');
  }
  let offset = 12;
  let byteRate = null;
  let dataSize = null;
  while (offset + 8 <= buf.length) {
    const id = buf.toString('ascii', offset, offset + 4);
    const size = buf.readUInt32LE(offset + 4);
    if (id === 'fmt ') byteRate = buf.readUInt32LE(offset + 16);
    if (id === 'data') dataSize = size;
    offset += 8 + size + (size % 2);
  }
  if (!byteRate || dataSize == null) throw new Error('WAV 헤더를 해석할 수 없습니다.');
  return dataSize / byteRate;
}

function clipLengthFor(voiceSec) {
  if (voiceSec <= 5) return 6;
  if (voiceSec <= 7) return 8;
  if (voiceSec <= 9) return 10;
  return null; // 대본 축소 필요
}

async function tts(env, text) {
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-KEY': env.TYPECAST_API_KEY,
    },
    body: JSON.stringify({
      text,
      voice_id: env.TYPECAST_VOICE_ID,
      model: env.TYPECAST_MODEL || 'ssfm-v30',
      language: env.TYPECAST_LANGUAGE || 'kor',
      output: { audio_format: 'wav' },
    }),
  });
  if (!res.ok) {
    throw new Error(`Typecast API ${res.status}: ${(await res.text()).slice(0, 300)}`);
  }
  return Buffer.from(await res.arrayBuffer());
}

async function main() {
  const [scriptFile, outDir = 'tts-output'] = process.argv.slice(2);
  if (!scriptFile) {
    console.error('사용법: node scripts/tts-clip-length.mjs <대본파일> [출력폴더]');
    process.exit(1);
  }

  const env = loadEnv(process.cwd());
  if (!env.TYPECAST_API_KEY || !env.TYPECAST_VOICE_ID) {
    console.error('.env 또는 .env.local 에 TYPECAST_API_KEY, TYPECAST_VOICE_ID 를 설정하세요.');
    process.exit(1);
  }

  const segments = readFileSync(scriptFile, 'utf8')
    .split(/\n\s*\n/)
    .map((s) => s.trim())
    .filter(Boolean);
  if (segments.length === 0) {
    console.error('대본 파일에서 구간을 찾지 못했습니다. 구간은 빈 줄로 구분하세요.');
    process.exit(1);
  }

  mkdirSync(outDir, { recursive: true });
  const results = [];

  for (let i = 0; i < segments.length; i++) {
    const text = segments[i];
    process.stderr.write(`[${i + 1}/${segments.length}] TTS 생성 중...\n`);
    const audio = await tts(env, text);
    const wavPath = path.join(outDir, `segment-${i + 1}.wav`);
    writeFileSync(wavPath, audio);

    const voiceSec = wavDurationSeconds(audio);
    const clipSec = clipLengthFor(voiceSec);
    results.push({
      segment: i + 1,
      text,
      audioFile: wavPath,
      voiceSeconds: Math.round(voiceSec * 100) / 100,
      clipSeconds: clipSec,
      padding: clipSec ? Math.round((clipSec - voiceSec) * 100) / 100 : null,
      ok: clipSec !== null,
    });
  }

  const totalVoice = results.reduce((s, r) => s + r.voiceSeconds, 0);
  const totalClip = results.reduce((s, r) => s + (r.clipSeconds ?? 0), 0);
  const summary = {
    createdAt: new Date().toISOString(),
    model: env.TYPECAST_MODEL || 'ssfm-v30',
    segments: results,
    totalVoiceSeconds: Math.round(totalVoice * 100) / 100,
    totalClipSeconds: totalClip,
  };
  const jsonPath = path.join(outDir, 'result.json');
  writeFileSync(jsonPath, JSON.stringify(summary, null, 2));

  console.log('\n구간 | 음성 길이 | 클립 길이 | 여유');
  console.log('-----|-----------|-----------|------');
  for (const r of results) {
    const clip = r.ok ? `${r.clipSeconds}초` : '초과!';
    const pad = r.ok ? `${r.padding}초` : '대본 축소 필요';
    console.log(`  ${r.segment}  |  ${r.voiceSeconds}초  |  ${clip}  | ${pad}`);
  }
  console.log(`\n합계: 음성 ${summary.totalVoiceSeconds}초 / 클립 ${totalClip}초`);
  console.log(`결과 저장: ${jsonPath}`);

  const over = results.filter((r) => !r.ok);
  if (over.length) {
    console.log(`\n경고: 구간 ${over.map((r) => r.segment).join(', ')} 의 음성이 9초를 넘습니다.`);
    console.log('해당 구간의 대본을 줄이거나 의미 단위를 다시 나눈 뒤 재실행하세요.');
    process.exit(2);
  }
}

main().catch((e) => {
  console.error(`오류: ${e.message}`);
  process.exit(1);
});
