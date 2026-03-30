export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          nickname: string
          created_at: string
          learning_started_at: string | null
        }
        Insert: {
          id: string
          nickname: string
          created_at?: string
          learning_started_at?: string | null
        }
        Update: {
          id?: string
          nickname?: string
          created_at?: string
          learning_started_at?: string | null
        }
      }
      words: {
        Row: {
          id: number
          word: string
          meaning_ko: string
          example_en: string
          example_ko: string
          difficulty: number
          topic: string
          is_active: boolean
          created_at: string
        }
        Insert: {
          id?: number
          word: string
          meaning_ko: string
          example_en: string
          example_ko: string
          difficulty: number
          topic: string
          is_active?: boolean
          created_at?: string
        }
        Update: {
          word?: string
          meaning_ko?: string
          example_en?: string
          example_ko?: string
          difficulty?: number
          topic?: string
          is_active?: boolean
        }
      }
      problems: {
        Row: {
          id: number
          word_id: number
          sentence: string
          choices: Json
          correct_choice: number
          difficulty: number
          topic: string
          is_active: boolean
          created_at: string
        }
        Insert: {
          id?: number
          word_id: number
          sentence: string
          choices: Json
          correct_choice: number
          difficulty: number
          topic: string
          is_active?: boolean
          created_at?: string
        }
        Update: {
          word_id?: number
          sentence?: string
          choices?: Json
          correct_choice?: number
          difficulty?: number
          topic?: string
          is_active?: boolean
        }
      }
      learning_sessions: {
        Row: {
          id: string
          user_id: string
          month_number: number
          difficulty: number
          started_at: string
          completed_at: string | null
          status: 'in_progress' | 'completed'
        }
        Insert: {
          id?: string
          user_id: string
          month_number: number
          difficulty: number
          started_at?: string
          completed_at?: string | null
          status?: 'in_progress' | 'completed'
        }
        Update: {
          completed_at?: string | null
          status?: 'in_progress' | 'completed'
        }
      }
      session_problems: {
        Row: {
          id: number
          session_id: string
          problem_id: number
          order_index: number
        }
        Insert: {
          id?: number
          session_id: string
          problem_id: number
          order_index: number
        }
        Update: {
          order_index?: number
        }
      }
      attempts: {
        Row: {
          id: number
          session_problem_id: number
          attempt_number: number
          selected_choice: number
          is_correct: boolean
          meaning_shown: boolean
          created_at: string
        }
        Insert: {
          id?: number
          session_problem_id: number
          attempt_number: number
          selected_choice: number
          is_correct: boolean
          meaning_shown?: boolean
          created_at?: string
        }
        Update: {
          is_correct?: boolean
          meaning_shown?: boolean
        }
      }
      user_words: {
        Row: {
          id: number
          user_id: string
          word_id: number
          wrong_count: number
          save_count: number
          last_wrong_at: string
          last_saved_at: string
        }
        Insert: {
          id?: number
          user_id: string
          word_id: number
          wrong_count?: number
          save_count?: number
          last_wrong_at?: string
          last_saved_at?: string
        }
        Update: {
          wrong_count?: number
          save_count?: number
          last_wrong_at?: string
          last_saved_at?: string
        }
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
  }
}
