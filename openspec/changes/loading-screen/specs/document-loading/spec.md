## Purpose

Manages the document loading lifecycle, ensuring an immediate dedicated loading screen with a continuously rotating icon during document loading and preventing empty state flashes on launch.

## ADDED Requirements

### Requirement: Launch state resolution
The system SHALL determine whether a previous document exists upon application launch and immediately present the corresponding view on the first rendered frame.

#### Scenario: Launch with existing saved document
- **WHEN** the application launches and persistent storage contains a valid previously opened document path that exists on disk
- **THEN** the system SHALL immediately display the loading screen without showing the empty state screen first

#### Scenario: Launch without saved document
- **WHEN** the application launches and persistent storage does not contain a saved document path
- **THEN** the system SHALL immediately display the empty state screen without showing a loading screen

#### Scenario: Launch with missing saved document file
- **WHEN** the application launches and the saved document path does not exist on disk
- **THEN** the system SHALL clear the invalid session and display the empty state screen

### Requirement: Dedicated loading screen display
The system SHALL present a dedicated loading screen whenever a document is being parsed, initialized, or chunked.

#### Scenario: Display loading screen during file selection
- **WHEN** the user selects a supported document (PDF or EPUB) from the file picker
- **THEN** the system SHALL immediately transition to the loading screen showing the document name and preparation status

#### Scenario: Display loading screen during launch restoration
- **WHEN** an existing document is being loaded on launch
- **THEN** the system SHALL display the loading screen until all initial text and chunk metadata are ready

### Requirement: Continuously rotating loading icon
The loading screen SHALL display a continuously rotating icon that animates smoothly without freezing or stalling during document processing.

#### Scenario: Uninterrupted icon rotation
- **WHEN** a document is being parsed and loaded
- **THEN** the loading icon SHALL continuously rotate at standard display refresh rates (60/120 FPS) without pausing or freezing

### Requirement: Transition to reader upon load completion
The system SHALL transition from the loading screen to the player view once document processing is finished.

#### Scenario: Successful load transition
- **WHEN** document parsing and initial text extraction succeed
- **THEN** the loading screen SHALL be dismissed and the player view SHALL be displayed with the restored or selected chunk
