# SparkDo - Todo & Schedule App

A comprehensive Flutter todo application with calendar scheduling and shareable links functionality.

## Features

### ✅ Core Todo List Features
- **Create and Save Todo Lists**: Create multiple todo lists with titles and descriptions
- **Todo Items Management**: Add, edit, delete, and check off individual tasks
- **Priority Levels**: Set priority levels (Low, Medium, High, Urgent) for tasks
- **Due Dates**: Assign due dates to individual tasks
- **Progress Tracking**: Visual progress indicators for todo lists

### 📅 Calendar Scheduling
- **Schedule Todo Lists**: Assign specific dates to todo lists for rigid time management
- **Calendar View**: Visual calendar showing all scheduled todo lists
- **Overdue Detection**: Automatic detection and highlighting of overdue lists
- **Reschedule**: Easy rescheduling of todo lists

### 🔗 Linking System
- **Link Todo Lists**: Connect related todo lists together
- **View Linked Lists**: Navigate between linked todo lists
- **Dependency Management**: Organize complex projects with linked lists

### 🌐 Shareable Links
- **Generate Share Links**: Create shareable URLs for specific todo lists
- **Read-Only Access**: Shared lists are viewable but not editable by others
- **GitHub Pages Compatible**: Works with GitHub Pages deployment
- **Deep Linking**: Direct access to specific todo lists via URLs

## How Shareable Links Work

When you create a todo list with "Generate shareable link" enabled:

1. **Link Generation**: The app creates a unique URL like `https://your-username.github.io/your-repo/#/shared/uuid`
2. **Share the Link**: Send this link to anyone you want to share the todo list with
3. **Access**: When someone opens the link, they'll see the todo list in read-only mode
4. **Updates**: The shared view reflects the current state of your todo list

### Example Sharing Workflow
1. Create a project todo list for your team
2. Enable "Generate shareable link" when creating
3. Share the generated link with team members
4. Team members can view progress without needing the app installed
5. Updates you make are visible to everyone with the link

## Installation and Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- A code editor (VS Code recommended)

### Local Development
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Web Deployment (GitHub Pages)

1. **Build for Web**:
   ```bash
   flutter build web --release
   ```

2. **Deploy to GitHub Pages**:
   - Create a new repository on GitHub
   - Copy the contents of `build/web/` to your repository
   - Enable GitHub Pages in repository settings
   - Set source to main branch

3. **Update Base URL**: In `lib/services/todo_service.dart`, update the `_generateShareableLink` method with your actual GitHub Pages URL:
   ```dart
   String _generateShareableLink(String listId) {
     return 'https://your-username.github.io/your-repo-name/#/shared/$listId';
   }
   ```

4. **Enable Web Features**: The app includes web-specific deep linking functionality for shareable links.

## Usage Guide

### Creating Todo Lists

1. **Basic Creation**:
   - Tap the "+" button on the home screen
   - Enter a title and optional description
   - Tap "Create"

2. **With Scheduling**:
   - Follow basic creation steps
   - Tap "Select Date" to choose a schedule date
   - The list will appear in the calendar view

3. **With Sharing**:
   - Enable "Generate shareable link" during creation
   - Copy the generated link to share with others

### Managing Tasks

1. **Adding Tasks**:
   - Open a todo list
   - Tap the "+" button
   - Fill in task details (title, description, priority, due date)

2. **Editing Tasks**:
   - Tap the menu (⋮) on any task
   - Select "Edit" to modify details

3. **Completing Tasks**:
   - Tap the checkbox next to any task
   - Completed tasks are crossed out and grayed

### Calendar Scheduling

1. **View Schedule**:
   - Switch to the "Calendar" tab
   - See all scheduled todo lists by date
   - Tap on any date to see that day's lists

2. **Schedule Existing Lists**:
   - Open any todo list
   - Tap the menu (⋮) in the app bar
   - Select "Schedule"
   - Choose a date

### Linking Lists

1. **Create Links**:
   - Open the source todo list
   - Tap the menu (⋮) in the app bar
   - Select "Link Lists"
   - Choose which list to link to

2. **View Linked Lists**:
   - Open any todo list
   - Tap the menu (⋮) in the app bar
   - Select "View Linked Lists"
   - Tap on any linked list to open it

## Data Storage

- **Local Storage**: All data is stored locally using SharedPreferences
- **Persistence**: Data persists between app sessions
- **Export/Import**: Currently not implemented (future feature)

## Technical Architecture

### State Management
- **Provider**: Used for state management across the app
- **TodoProvider**: Central provider managing all todo lists and items
- **Reactive UI**: UI automatically updates when data changes

### Data Models
- **TodoList**: Represents a collection of todo items with metadata
- **TodoItem**: Individual tasks with properties like priority, due date, completion status
- **Storage Service**: Handles data persistence and retrieval

### Routing
- **App Router**: Handles navigation and deep linking
- **Deep Link Support**: Web-compatible URL routing for shared lists
- **Route Parameters**: Supports parameterized routes for shared content

## Customization

### Themes
- Modify `ThemeData` in `main.dart` to customize app appearance
- Built with Material 3 design system
- Supports both light and dark themes (automatic)

### Colors and Styling
- Priority colors can be customized in `todo_item.dart`
- Calendar styling in `calendar_screen.dart`
- Card layouts and spacing throughout the app

### Features Extension
- Add new todo item properties in `TodoItem` model
- Extend sharing functionality in `TodoService`
- Add new calendar views or filters

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Feel free to use, modify, and distribute as needed.

## Future Enhancements

- [ ] Cloud synchronization
- [ ] Collaborative editing
- [ ] Export to different formats
- [ ] Advanced filtering and search
- [ ] Notifications and reminders
- [ ] Multiple calendar views (week, month, year)
- [ ] Drag and drop task reordering
- [ ] Task templates
- [ ] Bulk operations
- [ ] Data analytics and insights
