# Voice Notification System PRD

## Overview
Implement a sophisticated voice notification system for Claude Code that provides audible feedback when Claude completes tasks or is waiting for input, using Gemini API text-to-speech with project-specific voices and dynamic speech styles.

## Problem Statement
Currently, users have only visual indicators when Claude finishes tasks. This creates a need to constantly monitor the terminal, reducing productivity during long-running operations. A voice notification system would provide hands-free awareness of Claude's status.

## Goals

### Primary Goals
- **Immediate Awareness**: Notify users vocally when Claude completes tasks or encounters errors
- **Contextual Communication**: Use different voices and speech styles based on project and content type
- **Non-Intrusive Integration**: Seamlessly integrate with existing Claude hooks without disrupting workflow

### Secondary Goals
- **Personality Customization**: Allow different voice personalities per project
- **Accessibility**: Improve accessibility for users who benefit from audio cues
- **Emotional Context**: Convey success, error, or waiting states through voice tone

## User Stories

### Core Functionality
- **As a developer**, I want to hear when Claude finishes a task so I can return to work without constantly checking the terminal
- **As a multi-project developer**, I want different voice personalities for different projects to provide context switching cues
- **As a user**, I want the voice notifications to reflect the emotional context (success, error, waiting) of Claude's status

### Advanced Features
- **As a power user**, I want to customize speech styles based on the type of content Claude processed
- **As a remote worker**, I want discrete notification options that won't disturb others
- **As an accessibility-focused user**, I want reliable audio cues for Claude's operational status

## Technical Requirements

### Voice Generation
- **Primary**: Gemini API text-to-speech with 30+ voice options (default - uses GEMINI_API_KEY)
- **Fallback**: macOS `say` command for reliability when API key not available
- **Audio Format**: 24kHz output for high quality

### Voice Configuration System
```json
{
  "enabled": true,
  "default_voice": "Zephyr",
  "default_style": "cheerful",
  "volume": 0.7,
  "projects": {
    "chezmoi": {
      "voice": "Kore",
      "style": "professional",
      "description": "Firm, authoritative voice for system configurations"
    },
    "personal-app": {
      "voice": "Puck",
      "style": "upbeat",
      "description": "Bright, energetic voice for creative projects"
    }
  },
  "message_styles": {
    "success": "cheerfully",
    "error": "with concern",
    "waiting": "patiently",
    "tool_use": "professionally"
  }
}
```

### Available Gemini Voices
Based on Gemini API documentation:
- **Zephyr**: Bright, clear voice
- **Puck**: Upbeat, energetic
- **Kore**: Firm, professional
- **Additional voices**: 30+ options with various characteristics (breathy, gravelly, smooth)

### Integration Points
- **Hook Events**: Integrate with existing Claude Code hooks
  - `Stop`: When Claude completes responses
  - `UserPromptSubmit`: Optional acknowledgment of user input
  - `PreToolUse`: Optional tool usage announcements
- **Context Detection**: Analyze Claude's response content to determine appropriate voice style
- **Project Detection**: Use git repository name for project-specific voice selection

## Implementation Architecture

### Core Components

#### 1. Voice Notification Engine (`~/.claude/hooks/voice-notify.py`)
```python
class VoiceNotifier:
    def __init__(self, config_path):
        self.config = self.load_config(config_path)
        # Default to Gemini API, initialized with GEMINI_API_KEY from environment
        self.gemini_client = self.init_gemini_client()

    def notify(self, message, project=None, style=None):
        voice_config = self.get_voice_config(project)
        audio = self.generate_speech(message, voice_config, style)
        self.play_audio(audio)

    def generate_speech(self, text, voice_config, style):
        # Gemini API TTS generation
        pass

    def play_audio(self, audio_data):
        # Play generated audio using afplay
        pass
```

#### 2. Configuration Manager (`~/.claude/voice-config.json`)
- Project-to-voice mapping
- Style definitions
- Global settings (volume, enabled/disabled)
- Fallback configurations

#### 3. Hook Integration Scripts
- Modified `assistant-response-complete.sh`
- Content analysis for style selection
- Error handling and fallback mechanisms

### Message Analysis System
```python
def analyze_message_style(message_content):
    """Determine appropriate speech style based on message content"""
    if any(keyword in message.lower() for keyword in ['error', 'failed', 'exception']):
        return 'error'
    elif any(keyword in message.lower() for keyword in ['completed', 'done', 'success']):
        return 'success'
    elif 'waiting' in message.lower() or message.endswith('?'):
        return 'waiting'
    else:
        return 'neutral'
```

### Audio Caching Strategy
- Cache frequently used phrases to reduce API calls
- Project-specific cache directories
- TTL-based cache invalidation

## User Experience

### Notification Examples

#### Success Scenarios
- **Repository Updates**: "cheerfully: I've successfully updated your dotfiles configuration!"
- **Code Generation**: "with satisfaction: Your new Python module is ready for testing!"
- **Bug Fixes**: "proudly: I've resolved the TypeScript errors in your component!"

#### Error Scenarios
- **Build Failures**: "with concern: I encountered compilation errors that need your attention."
- **API Issues**: "apologetically: I'm having trouble accessing the external service."

#### Waiting Scenarios
- **Ready State**: "patiently: I'm ready for your next request."
- **Input Required**: "gently: I need more information to proceed."

### Voice Personality Examples

#### Professional Projects (Kore voice)
- Infrastructure repositories
- Production systems
- Documentation projects

#### Creative Projects (Puck voice)
- Personal apps
- Experimental code
- Hobby projects

#### System Projects (Zephyr voice)
- Dotfiles and configurations
- Shell scripts
- Development tools

## Configuration and Customization

### Initial Setup
1. **API Key Configuration**: Set GEMINI_API_KEY environment variable (defaults to this if available)
2. **Voice Testing**: Interactive voice selection wizard using Gemini API voices
3. **Project Mapping**: Automatic detection of repositories with manual override
4. **Style Preferences**: User preference gathering for notification styles

### Runtime Configuration
- **Enable/Disable**: Global toggle and per-session control
- **Volume Control**: Adaptive volume based on time of day
- **Style Override**: Manual style selection for specific notifications

### Advanced Features
- **Sentiment Analysis**: Enhanced content analysis for nuanced voice selection
- **Time-based Profiles**: Different voices/volumes for work hours vs. evening
- **Integration Webhooks**: Extend notifications to other services (Slack, Discord)

## Technical Implementation Details

### API Integration
```python
# Gemini TTS Configuration (default - uses GEMINI_API_KEY environment variable)
import os
client = genai.configure(api_key=os.environ.get('GEMINI_API_KEY'))
response = client.models.generate_content(
    model="gemini-2.5-flash-preview-tts",
    contents=f"Say {style}: {message}",
    config=types.GenerateContentConfig(
        response_modalities=["AUDIO"],
        speech_config=types.SpeechConfig(
            voice_config=types.VoiceConfig(
                prebuilt_voice_config=types.PrebuiltVoiceConfig(
                    voice_name=voice_name,
                )
            )
        ),
    )
)
```

### Error Handling
- **API Key Missing**: Check for GEMINI_API_KEY environment variable, fallback to macOS `say` if not present
- **API Failures**: Automatic fallback to macOS `say` command
- **Network Issues**: Cached responses for common messages
- **Rate Limiting**: Intelligent queuing and API quota management

### Performance Considerations
- **Async Processing**: Non-blocking audio generation
- **Cache Optimization**: Reduce API calls for repeated messages
- **Background Processing**: Don't delay Claude's response delivery

## Testing Strategy

### Unit Tests
- Voice configuration loading
- Message style analysis
- API integration with mocked responses

### Integration Tests
- End-to-end hook triggering
- Audio playback verification
- Project detection accuracy

### User Acceptance Tests
- Voice clarity and appropriateness
- Timing and non-intrusiveness
- Configuration ease of use

## Success Metrics

### Adoption Metrics
- Configuration completion rate
- Daily notification usage
- Feature enable/disable patterns

### User Experience Metrics
- Notification appropriateness (user feedback)
- Response time impact (< 100ms delay)
- Error rate and fallback usage

### Technical Metrics
- API call efficiency and caching hit rate
- Audio generation latency
- System resource usage

## Rollout Plan

### Phase 1: Core Implementation
- Basic voice notification with single voice using Gemini API (default)
- Hook integration for `Stop` events
- Simple configuration system with GEMINI_API_KEY detection

### Phase 2: Enhanced Features
- Multi-voice support
- Project-specific configurations
- Style-based message delivery

### Phase 3: Advanced Capabilities
- Sentiment analysis
- Time-based profiles
- Integration with external services

## Risk Mitigation

### Technical Risks
- **API Dependency**: Defaults to Gemini API when GEMINI_API_KEY present, robust fallback to system TTS otherwise
- **Audio Issues**: Graceful failure without blocking workflow
- **Performance Impact**: Async processing and caching

### User Experience Risks
- **Notification Fatigue**: Configurable frequency and styles
- **Inappropriate Content**: Content filtering and style matching
- **Accessibility Concerns**: Volume control and disable options

## Future Enhancements

### Advanced Voice Features
- **Multi-speaker Conversations**: Different voices for different agents
- **Emotional Intelligence**: Voice modulation based on work context
- **Language Support**: Multi-language voice notifications

### Integration Expansions
- **IDE Integration**: Direct integration with VS Code, Neovim
- **Team Notifications**: Shared project voice configurations
- **Analytics Dashboard**: Voice notification usage patterns

## Conclusion

This voice notification system will significantly enhance the Claude Code user experience by providing contextual, project-aware audio feedback. The implementation leverages cutting-edge Gemini API text-to-speech technology while maintaining robust fallback mechanisms and extensive customization options.

The system's success will be measured by user adoption, configuration engagement, and the seamless integration into existing development workflows without introducing friction or distraction.
