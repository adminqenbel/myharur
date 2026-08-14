# MyHarur UI direction

## Visual language from the reference

- White canvas with very light blue/gray section backgrounds.
- Generous top spacing and large, calm typography.
- Rounded cards and pill controls with thin gray borders and soft shadows.
- Black/dark charcoal primary text with a restrained red accent for urgent/active states and blue for links/actions.
- Letter-spaced uppercase section labels such as `LOCAL UPDATE`, `NEARBY HELP`, and `EXPLORE MYHARUR`.
- Horizontal icon categories near the top of the home screen.
- Large featured content card followed by compact service cards.
- Persistent rounded bottom navigation with four primary destinations.
- Hamburger menu for the full module list and a compact scan/action button in the top bar.

## MyHarur adaptation

Primary bottom navigation:

1. Home — local summary, map, weather, news, shortcuts.
2. Explore — news, marketplace, jobs, events, shops, rankings.
3. Alerts — emergency, government announcements, notifications, tracking.
4. Account — profile, roles, support, settings, privacy.

The hamburger drawer contains Chat, Government, Submit, Admin (role-gated), and Help. Emergency remains reachable from Home and Alerts without making the user search through the drawer.

## First home-screen composition

```text
App bar: menu | MyHarur / location pill | search / scan
Location awareness: "Harur" or "Choose your town"
Category rail: News, Weather, Help, Market, Jobs, Events, Chat
Featured card: top local update or urgent government notice
Quick actions: Report issue, Ask nearby, Submit news, View events
Mini map: current/selected area with safe privacy copy
Local sections: News feed, weather cards, upcoming events
Bottom navigation: Home, Explore, Alerts, Account
```

## Icon rules

- Use SVG icons consistently; do not mix emoji and platform-specific icon glyphs in core navigation.
- Use a 24 px outline grid with 1.8–2.0 px stroke, round caps, and simple silhouettes.
- Keep filled/colored icons for status or emergency emphasis only.
- Create a named icon registry so the visual system can be swapped without touching feature code.

## Accessibility and localization

- Dynamic text sizing and minimum touch target 44–48 px.
- Tamil and English copy from the beginning; Hindi moderation data is supported even if the first UI is English/Tamil.
- High-contrast state for urgent actions.
- Never communicate an emergency state by color alone.

