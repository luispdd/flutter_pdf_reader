## MODIFIED Requirements

### Requirement: Dedicated loading screen display
The system SHALL present a dedicated loading screen strictly during full document initialization, launch restoration, and new file selection/downloading, and SHALL NOT present the dedicated loading screen during page or chunk navigation.

#### Scenario: Display loading screen during file selection
- **WHEN** the user selects a supported document (PDF or EPUB) from the file picker
- **THEN** the system SHALL immediately transition to the dedicated loading screen showing the document name and preparation status

#### Scenario: Display loading screen during launch restoration
- **WHEN** an existing document is being loaded on launch
- **THEN** the system SHALL display the dedicated loading screen until all initial text and chunk metadata are ready

#### Scenario: No loading screen during page navigation
- **WHEN** the user flips to another page or chunk within an already loaded document
- **THEN** the system SHALL NOT display the dedicated loading screen and SHALL keep the player view mounted

## ADDED Requirements

### Requirement: Immediate page navigation display
The system SHALL display target page text immediately during in-document navigation without visual loading delays or transitional animation interruptions.

#### Scenario: Immediate text update on page turn
- **WHEN** the user navigates to a different page or chunk using player controls (previous, next, or slider)
- **THEN** the reader view SHALL immediately update the chunk number and extract the text without leaving the player view

### Requirement: Prevent concurrent document selection
The system SHALL disable file selection actions while a document is actively being loaded or downloaded.

#### Scenario: File selection disabled during loading
- **WHEN** a document is in the process of loading or downloading from cloud storage
- **THEN** file selection buttons SHALL be disabled to prevent starting concurrent file loading operations
