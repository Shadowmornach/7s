---
name: flutter_ui_reconstruction
description: Pixel-perfect Flutter UI reconstruction, layout responsiveness, card constraints, and visual design matching guidelines.
---

# Flutter UI Reconstruction Skill

This skill provides precise rules and design patterns for building pixel-perfect, responsive, production-grade Flutter screens matching design mockups and target screenshots.

## 1. Responsive Viewport Constraints & Non-Scroll Guarantees
- Use `LayoutBuilder` with `ConstrainedBox` and `SingleChildScrollView(physics: ClampingScrollPhysics())` to ensure the layout fits naturally across screen sizes without overflow.
- Avoid raw `Expanded` + `MainAxisAlignment.spaceEvenly` inside scrollable viewports, as it stretches widgets unnaturally on taller screens.
- Use explicit, consistent spacing gaps (`SizedBox(height: 8, 12, 16, 20)`) based on an 8dp grid system.

## 2. Card Surface & Shadow Design System
- **Floating White Card**: Background `#FFFFFF`, rounded corners `BorderRadius.circular(24)` or `28`.
- **Soft Ambient Elevation**: Use low opacity `BoxShadow(color: Color(0x0E000000), blurRadius: 24, offset: Offset(0, 8))` with a subtle border `Border.all(color: Color(0xFFF1F5F9), width: 1.0)`.
- **Inner Padding**: `EdgeInsets.symmetric(horizontal: 18, vertical: 20)` for optimal content density.

## 3. Input Fields & Focus Mechanics
- **Height**: Fixed 52–54dp height with `BorderRadius.circular(14)`.
- **Floating Label Behavior**: Always set `floatingLabelBehavior: FloatingLabelBehavior.never` to prevent input box height shifts or placeholder movement.
- **Prefix Component Alignment**: Country code pill, flag emoji 🇰🇪, dropdown chevron, bold `+254` text, and thin 1px vertical divider (`Color(0xFFE2E8F0)`).
- **Text Alignment**: `contentPadding: EdgeInsets.symmetric(vertical: 14)` for exact vertical baseline alignment.

## 4. Primary CTA Buttons
- **Height**: Standard 50–52dp touch target.
- **Background**: Solid primary emerald `Color(0xFF047857)` with `BorderRadius.circular(16)`.
- **Shadow**: `BoxShadow(color: Color(0xFF047857).withOpacity(0.28), blurRadius: 14, offset: Offset(0, 5))`.
- **Press Animation**: Scale down to `0.98` on touch with `LightImpact` haptics.

## 5. Information Badges & Footer Section
- **SMS Info Card**: Light mint green `#F0FDF4` card with `#DCFCE7` border, rounded corners `14px`, shield checkmark icon badge, and bold `via SMS` text span.
- **Lock Divider**: Thin 1px horizontal divider (`#E2E8F0`) broken by a centered circular lock badge (`#CBD5E1` outline, `13px` lock icon).
- **Text Contrast**: Use readable slate gray `#64748B` for security captions and legal disclaimer body text (`fontSize: 12px`, `height: 1.4`).
