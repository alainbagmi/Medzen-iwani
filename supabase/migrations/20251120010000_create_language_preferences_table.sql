-- Migration: Create language_preferences table
-- Purpose: Store user language preferences for UI, audio, subtitles, and TTS
-- Created: 2025-11-20

-- Create language_preferences table
CREATE TABLE IF NOT EXISTS language_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- UI Language (FlutterFlow i18n)
  ui_language VARCHAR(10) DEFAULT 'en',

  -- Audio/Transcription Language (AWS Transcribe)
  audio_language VARCHAR(10) DEFAULT 'en-US',

  -- Subtitle Language (can differ from audio for translation)
  subtitle_language VARCHAR(10),

  -- TTS Voice Preference (AWS Polly voice ID)
  tts_voice_id VARCHAR(50),
  tts_engine VARCHAR(20) DEFAULT 'neural', -- neural, generative, standard

  -- Auto-detection settings
  auto_detect_language BOOLEAN DEFAULT true,
  detect_code_switching BOOLEAN DEFAULT true,

  -- Preferred languages (for multi-language support)
  preferred_languages JSONB DEFAULT '["en-US"]'::jsonb,

  -- Regional preferences
  region_code VARCHAR(5), -- e.g., 'ZA', 'NG', 'KE'
  timezone VARCHAR(50),

  -- Accessibility settings
  show_subtitles BOOLEAN DEFAULT false,
  subtitle_font_size INT DEFAULT 16,
  high_contrast_subtitles BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure one preference record per user
  UNIQUE(user_id)
);

-- Add comments for documentation
COMMENT ON TABLE language_preferences IS 'User language preferences for multilingual features across UI, audio, and TTS';
COMMENT ON COLUMN language_preferences.ui_language IS 'FlutterFlow UI language (en, fr, af, zu, am, sg, ff, ln, wo, tw, sw)';
COMMENT ON COLUMN language_preferences.audio_language IS 'Preferred language for audio transcription (AWS Transcribe language code)';
COMMENT ON COLUMN language_preferences.subtitle_language IS 'Preferred subtitle language (can be different from audio for translation)';
COMMENT ON COLUMN language_preferences.tts_voice_id IS 'AWS Polly voice ID (e.g., Joanna, Ayanda, Léa)';
COMMENT ON COLUMN language_preferences.tts_engine IS 'AWS Polly engine type: neural (best quality), generative, or standard';
COMMENT ON COLUMN language_preferences.auto_detect_language IS 'Enable automatic language detection for transcription';
COMMENT ON COLUMN language_preferences.detect_code_switching IS 'Detect and handle code-switching/multilingual conversations';
COMMENT ON COLUMN language_preferences.preferred_languages IS 'Array of preferred languages in priority order for auto-detection';
COMMENT ON COLUMN language_preferences.region_code IS 'ISO 3166-1 alpha-2 country code for regional customization';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_language_preferences_user_id
ON language_preferences(user_id);

CREATE INDEX IF NOT EXISTS idx_language_preferences_audio_language
ON language_preferences(audio_language);

CREATE INDEX IF NOT EXISTS idx_language_preferences_region_code
ON language_preferences(region_code);

-- Create index for JSONB preferred_languages
CREATE INDEX IF NOT EXISTS idx_language_preferences_preferred_languages
ON language_preferences USING GIN(preferred_languages);

-- Create function to get or create default preferences
CREATE OR REPLACE FUNCTION get_or_create_language_preferences(p_user_id UUID)
RETURNS language_preferences
LANGUAGE plpgsql
AS $$
DECLARE
  preferences language_preferences;
  user_profile users%ROWTYPE;
BEGIN
  -- Try to get existing preferences
  SELECT * INTO preferences
  FROM language_preferences
  WHERE user_id = p_user_id;

  -- If not found, create default based on user profile
  IF NOT FOUND THEN
    -- Get user's preferred language from profile
    SELECT * INTO user_profile
    FROM users
    WHERE id = p_user_id;

    -- Insert default preferences
    INSERT INTO language_preferences (
      user_id,
      ui_language,
      audio_language,
      subtitle_language,
      tts_voice_id,
      preferred_languages
    )
    VALUES (
      p_user_id,
      COALESCE(user_profile.preferred_language, 'en'),
      'en-US', -- Default to US English for audio
      COALESCE(user_profile.preferred_language, 'en'),
      'Joanna', -- Default TTS voice
      jsonb_build_array(COALESCE(user_profile.preferred_language || '-US', 'en-US'))
    )
    RETURNING * INTO preferences;
  END IF;

  RETURN preferences;
END;
$$;

COMMENT ON FUNCTION get_or_create_language_preferences IS 'Get existing language preferences or create defaults based on user profile';

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_language_preferences_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER language_preferences_updated_at
BEFORE UPDATE ON language_preferences
FOR EACH ROW
EXECUTE FUNCTION update_language_preferences_updated_at();

-- Create trigger to sync with users.preferred_language
CREATE OR REPLACE FUNCTION sync_user_preferred_language()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- When language preferences are updated, sync UI language to users table
  UPDATE users
  SET preferred_language = NEW.ui_language
  WHERE id = NEW.user_id
    AND (preferred_language IS NULL OR preferred_language != NEW.ui_language);

  RETURN NEW;
END;
$$;

CREATE TRIGGER sync_language_preferences_to_users
AFTER INSERT OR UPDATE OF ui_language ON language_preferences
FOR EACH ROW
EXECUTE FUNCTION sync_user_preferred_language();

COMMENT ON TRIGGER sync_language_preferences_to_users ON language_preferences IS 'Keep users.preferred_language in sync with language_preferences.ui_language';

-- Enable RLS
ALTER TABLE language_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own preferences
CREATE POLICY "Users can view own language preferences"
ON language_preferences
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can insert their own preferences
CREATE POLICY "Users can insert own language preferences"
ON language_preferences
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own preferences
CREATE POLICY "Users can update own language preferences"
ON language_preferences
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own preferences
CREATE POLICY "Users can delete own language preferences"
ON language_preferences
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Service role has full access (for cloud functions)
CREATE POLICY "Service role has full access to language preferences"
ON language_preferences
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON language_preferences TO authenticated;
GRANT ALL ON language_preferences TO service_role;
GRANT EXECUTE ON FUNCTION get_or_create_language_preferences TO authenticated;
GRANT EXECUTE ON FUNCTION get_or_create_language_preferences TO service_role;

-- Create default preferences for existing users
INSERT INTO language_preferences (user_id, ui_language, audio_language, preferred_languages)
SELECT
  id,
  COALESCE(preferred_language, 'en'),
  'en-US',
  jsonb_build_array(COALESCE(preferred_language || '-US', 'en-US'))
FROM users
WHERE id NOT IN (SELECT user_id FROM language_preferences)
ON CONFLICT (user_id) DO NOTHING;
