// The site map. One entry per page. `nav: true` puts it in the top navigation.
// `slug` is the output filename (without .html); "index" becomes index.html.
export const pages = [
  { slug: "index", nav: false, navLabel: "Home",
    title: "See where your money stands",
    description: "DebtShield is a private, on-device iPhone app that shows how your money stands this month — no account, no bank connection, nothing leaves your phone." },

  { slug: "how-it-works", nav: true, navLabel: "How it works",
    title: "How it works",
    description: "The Safe Line, the monthly verdict, the year-ahead simulation, spending comparisons, and the deterministic Ask feature — in plain terms." },

  { slug: "methodology", nav: true, navLabel: "Methodology",
    title: "Methodology",
    description: "How DebtShield computes the Safe Line, the verdict, and the year-ahead odds — with assumptions and limitations, and no false precision." },

  { slug: "privacy", nav: true, navLabel: "Privacy",
    title: "Privacy",
    description: "Your financial numbers stay on your phone. No servers, no accounts, no tracking. Here's exactly what that means — and what the website does differently." },

  { slug: "data-sources", nav: false, navLabel: "Data sources",
    title: "Data sources",
    description: "The public datasets behind DebtShield's comparisons: U.S. Census (rent and income), EIA (energy), and BLS (food) — with years and definitions." },

  { slug: "accessibility", nav: false, navLabel: "Accessibility",
    title: "Accessibility",
    description: "DebtShield's accessibility commitments: Dynamic Type, VoiceOver, WCAG-AA contrast, Reduce Motion, and how to report an accessibility issue." },

  { slug: "waitlist", nav: false, navLabel: "Join the beta",
    title: "Join the beta",
    description: "Get notified when the DebtShield TestFlight beta opens. Email and an optional first name — no financial details, ever." },

  { slug: "for-organizations", nav: true, navLabel: "For organizations",
    title: "For organizations",
    description: "Colleges, nonprofits, workforce, and employer financial-wellness programs can sponsor access without ever seeing anyone's individual financial data." },

  { slug: "reviewers", nav: false, navLabel: "For reviewers",
    title: "For professional reviewers",
    description: "Financial educators, counselors, accessibility and privacy experts: help review DebtShield's methodology, claims, and accessibility." },

  { slug: "404", nav: false, navLabel: "Not found",
    title: "Page not found",
    description: "That page doesn't exist. Head back to the DebtShield home." },

  { slug: "impact", nav: false, navLabel: "Impact",
    title: "Impact",
    description: "What DebtShield measures, how, and honestly — with a clear separation between self-report, correlation, and demonstrated causation. No fabricated numbers." },

  { slug: "help", nav: true, navLabel: "Help",
    title: "Help resources",
    description: "Free, reputable help: 211, HUD-approved housing counseling, and Benefits.gov. DebtShield is not an emergency service." },

  { slug: "about", nav: false, navLabel: "About",
    title: "About",
    description: "DebtShield's mission: a calm, private, honest way to see your money — built privacy-first, for people worried about slipping into debt." },

  { slug: "privacy-policy", nav: false, navLabel: "Privacy policy",
    title: "Privacy policy",
    description: "How the DebtShield app and website handle information. The app collects nothing; the website collects only what you submit in a form." },

  { slug: "terms", nav: false, navLabel: "Terms of use",
    title: "Terms of use",
    description: "Terms of use and the educational disclaimer for DebtShield. Educational software, not financial, legal, tax, or housing advice." },
];
