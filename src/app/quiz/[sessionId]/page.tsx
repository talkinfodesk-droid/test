'use client'

import { useEffect, useState, useCallback } from 'react'
import { useParams, useRouter } from 'next/navigation'

interface Problem {
  sessionProblemId: number
  orderIndex: number
  problemId: number
  sentence: string
  choices: string[]
  difficulty: number
  topic: string
  word: string
}

interface SessionData {
  sessionId: string
  status: string
  problems: Problem[]
}

// 문제별 상태 (티켓 14: 초기화 대상)
interface ProblemState {
  selectedChoice: number | null
  attemptStep: number        // 0=미제출, 1=첫시도완료, 2=두번째시도완료
  meaningShown: boolean
  meaningKo: string | null
  feedbackMessage: string | null
  feedbackType: 'correct' | 'wrong' | null
  canRetry: boolean
  isFinished: boolean
  submitting: boolean
}

const initialProblemState: ProblemState = {
  selectedChoice: null,
  attemptStep: 0,
  meaningShown: false,
  meaningKo: null,
  feedbackMessage: null,
  feedbackType: null,
  canRetry: false,
  isFinished: false,
  submitting: false,
}

export default function QuizPage() {
  const params = useParams()
  const router = useRouter()
  const sessionId = params.sessionId as string

  const [session, setSession] = useState<SessionData | null>(null)
  const [currentIndex, setCurrentIndex] = useState(0)
  const [loading, setLoading] = useState(true)
  const [state, setState] = useState<ProblemState>({ ...initialProblemState })

  useEffect(() => {
    fetch(`/api/learning/sessions/${sessionId}/problems`)
      .then((res) => res.json())
      .then((data) => {
        setSession(data)
        setLoading(false)
      })
  }, [sessionId])

  const problem = session?.problems?.[currentIndex]
  const totalProblems = session?.problems?.length ?? 0
  const isLastProblem = currentIndex >= totalProblems - 1

  // 티켓 7: 선택지 클릭
  const handleChoiceSelect = (choiceIndex: number) => {
    if (state.isFinished || state.submitting) return
    // 첫 시도 후 재도전 시에만 선택 변경 가능 (canRetry 상태)
    if (state.attemptStep === 1 && !state.canRetry) return
    setState((prev) => ({ ...prev, selectedChoice: choiceIndex }))
  }

  // 티켓 8, 12: 답안 제출
  const handleSubmit = useCallback(async () => {
    if (!problem || state.selectedChoice === null || state.submitting) return

    setState((prev) => ({ ...prev, submitting: true }))

    const res = await fetch(`/api/learning/sessions/${sessionId}/attempts`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sessionProblemId: problem.sessionProblemId,
        selectedChoice: state.selectedChoice,
      }),
    })

    const result = await res.json()

    if (!res.ok) {
      setState((prev) => ({
        ...prev,
        submitting: false,
        feedbackMessage: result.error || '제출에 실패했습니다.',
        feedbackType: 'wrong',
      }))
      return
    }

    if (result.attemptNumber === 1) {
      if (result.isCorrect) {
        // 티켓 9: 첫 정답
        setState((prev) => ({
          ...prev,
          submitting: false,
          attemptStep: 1,
          feedbackMessage: '정답입니다!',
          feedbackType: 'correct',
          isFinished: true,
          canRetry: false,
        }))
      } else {
        // 티켓 10, 11: 첫 오답 → 뜻 노출 + 재도전 가능
        setState((prev) => ({
          ...prev,
          submitting: false,
          attemptStep: 1,
          meaningShown: true,
          meaningKo: result.meaningKo,
          feedbackMessage: '오답입니다. 뜻을 확인하고 다시 도전하세요!',
          feedbackType: 'wrong',
          canRetry: true,
          selectedChoice: null,
        }))
      }
    } else {
      // 티켓 13: 두 번째 시도 결과
      if (result.isCorrect) {
        setState((prev) => ({
          ...prev,
          submitting: false,
          attemptStep: 2,
          feedbackMessage: '재도전 정답!',
          feedbackType: 'correct',
          isFinished: true,
          canRetry: false,
        }))
      } else {
        setState((prev) => ({
          ...prev,
          submitting: false,
          attemptStep: 2,
          feedbackMessage: '아쉽네요. 다음에 다시 도전해보세요.',
          feedbackType: 'wrong',
          isFinished: true,
          canRetry: false,
        }))
      }
    }
  }, [problem, state.selectedChoice, state.submitting, sessionId])

  // 티켓 14: 다음 문제로 이동 (상태 초기화)
  const handleNext = () => {
    if (isLastProblem) {
      // 티켓 15: 마지막 문제 → 결과 화면
      router.push(`/result/${sessionId}`)
      return
    }
    setCurrentIndex((prev) => prev + 1)
    setState({ ...initialProblemState })
  }

  // 로딩 / 에러 화면
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-500">문제를 불러오는 중...</p>
      </div>
    )
  }

  if (!session || !session.problems || totalProblems === 0) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-gray-500">문제를 찾을 수 없습니다.</p>
      </div>
    )
  }

  if (!problem) return null

  return (
    <div className="min-h-screen bg-white">
      <div className="max-w-lg mx-auto px-4 py-6">
        {/* 진행률 */}
        <div className="mb-6">
          <div className="flex justify-between text-sm text-gray-500 mb-2">
            <span>문제 {currentIndex + 1} / {totalProblems}</span>
            <span>{Math.round(((currentIndex + 1) / totalProblems) * 100)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all"
              style={{ width: `${((currentIndex + 1) / totalProblems) * 100}%` }}
            />
          </div>
        </div>

        {/* 문제 */}
        <div className="mb-6">
          <p className="text-sm text-gray-500 mb-2">{problem.topic}</p>
          <h2 className="text-xl font-bold text-gray-900 mb-1">{problem.word}</h2>
          <p className="text-gray-700">{problem.sentence}</p>
        </div>

        {/* 티켓 11: 뜻 박스 (첫 오답 시 노출) */}
        {state.meaningShown && state.meaningKo && (
          <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-xl">
            <p className="text-sm text-yellow-700 font-medium mb-1">뜻</p>
            <p className="text-yellow-900 font-bold">{state.meaningKo}</p>
          </div>
        )}

        {/* 선택지 */}
        <div className="space-y-3 mb-6">
          {(problem.choices as string[]).map((choice, index) => {
            const isSelected = state.selectedChoice === index
            let btnClass = 'w-full text-left px-4 py-3 border rounded-lg transition '

            if (state.isFinished || (state.attemptStep === 1 && !state.canRetry)) {
              btnClass += 'opacity-60 cursor-not-allowed border-gray-200'
              if (isSelected && state.feedbackType === 'correct') {
                btnClass = 'w-full text-left px-4 py-3 border rounded-lg bg-green-50 border-green-500 text-green-800'
              } else if (isSelected && state.feedbackType === 'wrong') {
                btnClass = 'w-full text-left px-4 py-3 border rounded-lg bg-red-50 border-red-400 text-red-700'
              }
            } else if (isSelected) {
              btnClass += 'border-blue-500 bg-blue-50 text-blue-800'
            } else {
              btnClass += 'border-gray-300 hover:border-blue-400 hover:bg-blue-50'
            }

            return (
              <button
                key={index}
                onClick={() => handleChoiceSelect(index)}
                disabled={state.isFinished || (state.attemptStep === 1 && !state.canRetry)}
                className={btnClass}
              >
                {index + 1}. {choice}
              </button>
            )
          })}
        </div>

        {/* 피드백 메시지 */}
        {state.feedbackMessage && (
          <div
            className={`mb-6 p-4 rounded-xl text-center font-medium ${
              state.feedbackType === 'correct'
                ? 'bg-green-50 text-green-700 border border-green-200'
                : 'bg-red-50 text-red-700 border border-red-200'
            }`}
          >
            {state.feedbackMessage}
          </div>
        )}

        {/* 액션 버튼 */}
        <div className="flex gap-3">
          {!state.isFinished ? (
            <button
              onClick={handleSubmit}
              disabled={state.selectedChoice === null || state.submitting}
              className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition disabled:opacity-50"
            >
              {state.submitting
                ? '제출 중...'
                : state.canRetry
                ? '재도전 제출'
                : '제출'}
            </button>
          ) : (
            <button
              onClick={handleNext}
              className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition"
            >
              {isLastProblem ? '결과 보기' : '다음 문제'}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
