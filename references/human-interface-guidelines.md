# Apple Human Interface Guidelines

## Core Principles

### Clarity
- **Text legibility**: Use Dynamic Type, maintain sufficient contrast ratios (WCAG AA: 4.5:1 for normal text, 3:1 for large text)
- **Visual hierarchy**: Establish clear information architecture through size, weight, color
- **Purposeful design**: Every element serves a clear function

### Deference
- **Content focus**: UI defers to content, not vice versa
- **Subtle animations**: Use motion to enhance understanding, not distract
- **Translucency**: Materials provide context while maintaining focus

### Depth
- **Layering**: Use visual layers to convey hierarchy and relationships
- **Realistic motion**: Physics-based animations feel natural
- **Spatial relationships**: Maintain consistent spatial model across platforms

## Platform-Specific Guidelines

### iOS & iPadOS

#### Layout
- **Safe areas**: Respect safe area insets for notch, home indicator, rounded corners
- **Margins**: Standard margins are 16pt on iPhone, 20pt on iPad
- **Spacing**: Use 8pt grid system for consistent spacing
- **Adaptive layouts**: Support all device sizes and orientations

#### Navigation Patterns
- **Tab Bar**: 2-5 top-level destinations, always visible
- **Navigation Bar**: Hierarchical navigation, back button on leading edge
- **Modal sheets**: For focused tasks, dismissible with swipe
- **Split View** (iPad): Primary-secondary content relationship

#### Gestures
- **Standard gestures**: Tap, swipe, pinch, rotate, long press
- **System gestures**: Don't override home indicator swipe, control center
- **Discoverability**: Provide visual hints for custom gestures

#### Components
- **SF Symbols**: Use system symbols for consistency (9,000+ symbols)
- **System colors**: Adapt to light/dark mode automatically
- **Native controls**: Prefer system controls over custom

### macOS

#### Layout
- **Window management**: Support full screen, split view, tabs
- **Toolbar**: Place primary actions in toolbar
- **Sidebar**: 200-300pt wide, collapsible
- **Content area**: Flexible, scrollable main content

#### Navigation
- **Sidebar navigation**: Primary navigation method
- **Toolbar items**: Quick access to common actions
- **Menu bar**: Complete feature access
- **Keyboard shortcuts**: Essential for productivity

#### Interaction
- **Pointer precision**: Design for precise cursor control
- **Right-click menus**: Contextual actions
- **Keyboard navigation**: Full keyboard accessibility
- **Touch Bar**: Supplementary, not required

#### macOS-Specific
- **Title bar**: Unified title/toolbar or separate
- **Window controls**: Traffic lights (close, minimize, zoom)
- **Preferences**: Use standard preferences window pattern

### watchOS

#### Design Principles
- **Glanceable**: Information at a glance
- **Actionable**: Quick, focused interactions
- **Responsive**: Immediate feedback

#### Layout
- **Screen sizes**: 40mm, 44mm, 45mm, 49mm
- **Bezel**: Account for rounded corners
- **Digital Crown**: Primary input method

### tvOS

#### Design Principles
- **Cinematic**: Immersive, full-screen experiences
- **Focused**: One element in focus at a time
- **Fluid**: Smooth, responsive animations

#### Layout
- **Safe zones**: Overscan-safe area (90px from edges)
- **Focus engine**: Automatic focus management
- **Parallax**: Layered images for depth

## Typography

### San Francisco Font
- **SF Pro**: iOS, macOS, watchOS
- **SF Compact**: watchOS
- **SF Mono**: Code and tabular data

### Dynamic Type
- **Text styles**: Large Title, Title 1-3, Headline, Body, Callout, Subheadline, Footnote, Caption 1-2
- **Scaling**: Support all accessibility sizes
- **Line height**: Automatic adjustment for readability

### Best Practices
- Use system text styles
- Test with largest accessibility sizes
- Avoid fixed font sizes
- Use weight for hierarchy, not size alone

## Color

### System Colors
- **Semantic colors**: Label, secondaryLabel, tertiaryLabel, quaternaryLabel
- **Background colors**: systemBackground, secondarySystemBackground, tertiarySystemBackground
- **Grouped backgrounds**: systemGroupedBackground variants
- **Adaptive**: Automatically adapt to light/dark mode

### Custom Colors
- Provide light and dark variants
- Test with increased contrast mode
- Ensure sufficient contrast ratios
- Use Color Sets in asset catalogs

### Accent Colors
- User-customizable app accent color
- Use `accentColor` modifier in SwiftUI
- Falls back to system blue if not set

## Dark Mode

### Implementation
- Use semantic colors
- Test in both appearances
- Avoid pure black (#000000), use system backgrounds
- Elevate layers with subtle color differences

### Best Practices
- Don't invert images/icons
- Reduce white point for comfort
- Maintain contrast ratios
- Test with True Tone

## Accessibility

### VoiceOver
- Provide meaningful labels for all interactive elements
- Use accessibility traits appropriately
- Group related elements
- Announce dynamic changes

### Dynamic Type
- Support all text sizes (XS to XXXL)
- Use `@ScaledMetric` for custom spacing
- Test with largest sizes
- Allow horizontal scrolling if needed

### Reduce Motion
- Provide alternatives to animations
- Use `accessibilityReduceMotion` environment value
- Crossfade instead of sliding

### Color Blindness
- Don't rely on color alone
- Use shapes, icons, labels
- Test with color blindness simulators

### Other Considerations
- Button minimum size: 44x44pt (iOS), 28x28pt (macOS)
- Keyboard navigation support
- Closed captions for video
- Haptic feedback for important events

## App Architecture

### App Structure
- **Single-window apps**: Most iOS apps
- **Multi-window apps**: iPad, macOS support
- **Document-based apps**: Multiple documents
- **Scenes**: Manage multiple instances

### Settings
- **In-app settings**: Frequently changed settings
- **System Settings**: Rarely changed, system-wide settings
- **Defaults**: Sensible defaults, minimal required setup

### Onboarding
- **Progressive disclosure**: Teach features in context
- **Skip option**: Allow users to skip tutorials
- **Value first**: Show value before asking for permissions

### Launch
- **Fast launch**: < 400ms to first frame
- **Launch screen**: Static image matching first screen
- **No splash screens**: Don't show branded splash screens

## Interaction Patterns

### Feedback
- **Visual feedback**: Highlight on touch
- **Haptic feedback**: Confirm actions (iOS)
- **Sound effects**: Optional, respect silent mode
- **Progress indicators**: For operations > 2 seconds

### Modality
- **Sheets**: Focused tasks, easily dismissible
- **Full screen**: Immersive experiences
- **Popovers**: Contextual information (iPad, macOS)
- **Alerts**: Important decisions only

### Data Entry
- **Minimize typing**: Use pickers, toggles, selections
- **Smart defaults**: Pre-fill when possible
- **Validation**: Real-time, helpful error messages
- **Keyboard types**: Match input type

## Platform Integration

### System Features
- **Widgets**: Glanceable information
- **App Clips**: Lightweight, focused experiences
- **Shortcuts**: Siri integration
- **Handoff**: Continue across devices
- **Spotlight**: Search integration

### Privacy
- **Permissions**: Request in context, explain why
- **Transparency**: Clear about data usage
- **User control**: Allow users to manage data
- **Privacy nutrition labels**: Accurate reporting

## Performance Guidelines

### Responsiveness
- **60 fps**: Maintain smooth animations
- **120 fps**: ProMotion displays
- **Touch response**: < 100ms
- **Launch time**: < 400ms

### Energy
- **Background execution**: Minimize background work
- **Location**: Use appropriate accuracy
- **Networking**: Batch requests, use efficient protocols
- **Animations**: Use Core Animation, avoid CPU-intensive effects

## Design Resources

### Tools
- **SF Symbols app**: Browse and export symbols
- **Sketch/Figma**: Apple design templates available
- **Xcode**: Interface Builder, SwiftUI previews

### Assets
- **App icons**: Required sizes for each platform
- **Launch screens**: Use storyboards, not images
- **SF Symbols**: Custom symbols with SF Symbols app
- **Asset catalogs**: Organize all visual assets
