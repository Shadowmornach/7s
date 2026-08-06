---
name: ui_ux_pro_max
description: GitHub UI/UX Pro Max & AAS design intelligence skill — AI-augmented mobile/web design system, 1:1 visual ratio matching, 8dp spatial scale, typography hierarchy, micro-animations, and enterprise surface physics.
---

# GitHub UI/UX Pro Max & AAS Skill Specification
`saifyxpro/ui-ux-design-pro-skill` & `sickn33/agentic-awesome-skills` — Enterprise Design Intelligence

---

## 1. System Philosophy & Target Standards
- **Design Benchmarks**: Apple iOS, Uber, Revolut, Airbnb, Linear.
- **8dp Spatial Rhythm**: All padding, margins, heights, and gaps MUST align to the 8dp spatial scale (`4, 8, 12, 16, 20, 24, 32, 40, 48, 64`).
- **Zero Hallucination Rule**: Use exact tokenized dimensions and curated colors. Never invent random pixel offsets or unaligned margins.

---

## 2. Layout & Viewport Rules
- **Non-Scroll Viewport Rule**: Mobile form screens must fit 100% within the device viewport without clipping or forcing awkward scrollbars.
- **Container Layout**:
  - `LayoutBuilder` + `SingleChildScrollView(physics: ClampingScrollPhysics())` + `ConstrainedBox`.
  - Outer screen horizontal margin: `24px`.
  - Outer card internal padding: `24px` to `32px`.
  - Outer card corner radius: `28px`.

---

## 3. Surface Physics & Elevation Systems
- **Surface Geometry**:
  - Screen Background: Soft neutral off-white (`#FAFAFA` or `#F8FAFC`).
  - Card Surface: Pure White (`#FFFFFF`).
  - Card Radius: `BorderRadius.circular(28)`.
- **Soft Ambient Elevation**:
  - Outer Card Elevation: `BoxShadow(color: Color(0x14000000), blurRadius: 40, spreadRadius: 0, offset: Offset(0, 16))` (0.08 opacity, floating appearance).
  - Primary CTA Button Elevation: `BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 30, spreadRadius: 0, offset: Offset(0, 10))`.
  - Input Field Focus Elevation: `BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 12, spreadRadius: 0, offset: Offset(0, 4))`.

---

## 4. Form Component Specifications
- **Input Field Container**:
  - Height: `64dp`.
  - Corner Radius: `BorderRadius.circular(20)`.
  - Border: `1px` stroke `#E8E8E8`.
  - Floating Label Control: Always set `floatingLabelBehavior: FloatingLabelBehavior.never` to guarantee zero height shifting or floating text jump.
  - Prefix Section: Flag emoji 🇰🇪, dropdown chevron `v`, bold country code `+254` (`#FA5B16`, 18px w700), 1px vertical divider (`#E8E8E8`, 28dp height).
  - Placeholder: Light gray `#A0A0A0` (20px, w400).
- **Primary CTA Button**:
  - Height: `60dp`.
  - Corner Radius: `BorderRadius.circular(20)`.
  - Fill Color: Brand Orange (`#FA5B16`).
  - Typography: 20px, w700, pure white, centered.
  - Icon: Right-aligned arrow icon `→` inside the button bounds.
  - Tactile Feedback: Press scale down to `0.98` with smooth 100ms spring curve.

---

## 5. Micro-Information Badges & Security Typography
- **OTP Information Banner**:
  - Height: `92dp`, corner radius `20dp`.
  - Background: Soft peach tint (`#FFF8F3`), border `#FED7AA` (`1.0px`).
  - Badge Icon: White circular container with orange outline (`1.5px`) and `Icons.shield_outlined` in `#FA5B16`.
  - Highlight Text: Bold `via SMS` in `#FA5B16`.
- **Lock Divider**:
  - 40px top margin, thin 1px horizontal rule (`#E8E8E8`).
  - Centered 36x36 white circular lock badge with 1px `#E8E8E8` outline and centered `Icons.lock_outline_rounded` (`16px`, `#9AA0A6`).
- **Security & Legal Typography**:
  - Security caption: `"Secured with encrypted OTP verification"` (15px, w500, `#9AA0A6`, centered).
  - Legal disclaimer: `"By continuing, you agree to our Terms & Conditions and Privacy Policy"` (13px, `#64748B`, height 1.4) with clickable bold orange `#FA5B16` links.
