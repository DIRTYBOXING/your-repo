# DFC Handbook: Operational Guide & Learning

## Platform Navigation

- Use VS Code editor for all coding, editing, and project management.
- Ctrl+P: Quick file search and open.
- Ctrl+Shift+P: Command Palette for running VS Code commands.
- Ctrl+Tab: Switch between open files/tabs.
- Use the Explorer sidebar to view project structure and open files.

## Platform Layout Best Practices

- Home Screen: Quick access to Events, Messenger, Promotions, Dashboard.
- Bottom Navigation Bar: Tabs for Events, Messenger, Marketplace, Profile, Dashboard.
- Events Tab: List all events (including legend events) with posters, titles, dates.
- Event Details Screen: Poster image, legend name, event title, date, description, action buttons (RSVP, Share, Comment).
- Messenger Tab: Chat and contact management.
- Promotions Tab: Campaigns and promotional tools.
- Profile Tab: User info, settings, account management.
- Dashboard Tab: Analytics, stats, admin tools.

## Event Production Workflow

1. Create event screen in `lib/features/events/screens/`.
2. Add event details: legend name, title, date, description.
3. Store poster images in `assets/events/` or `assets/events/legends/`.
4. Reference images in code using `Image.asset('assets/events/legend_poster.jpg')`.
5. Connect event screen to navigation (Events tab, event list, or button).
6. Use DFC features for promotion, attendance, comments, and engagement.

## Learning & Onboarding

- Ask questions in chat, upload files/images using the plus sign (➕).
- Review this handbook for step-by-step guidance.
- Practice by creating and wiring legend events, adding images, and connecting screens.

## Common Terms

- Tab: Open file at the top of the editor.
- Panel: Bottom sections (Terminal, Output, Problems).
- Widget: Flutter UI building block.
- Card: Grouped content widget.
- Scaffold: Main layout structure for a screen.
- AppBar: Top bar of a screen.
- Column/Row: Layout widgets.
- Container: Box for layout/styling.
- ListView: Scrollable list.
- State: Data that can change in a widget.
- StatelessWidget: Widget with fixed content.
- StatefulWidget: Widget that can change.

## Tips

- Keep legend events inside Events section.
- Use clear images/posters for all events.
- Make navigation simple with tabs or sidebar.
- Use VS Code shortcuts for efficient workflow.

---

This handbook is your personal guide for DFC operations, learning, and production. Update as you learn and grow!
