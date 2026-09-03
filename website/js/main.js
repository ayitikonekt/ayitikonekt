const translations = {
  ht: {
    pageTitle: "AyitiKonekt | N ap konekte kominote nou an",
    navHome: "Akèy",
    navAbout: "Konsènan nou",
    navServices: "Sèvis",
    navContact: "Kontak",
    languageButton: "Lang",
    heroTitle: "Nou konekte kominote nou an",
    heroDescription: "Achte, vann, ofri sèvis epi dekouvri opòtinite nan kominotew la.",
    heroAvailability: "Aplikasyon pou Android ak iPhone ap vini byento.",
    aboutTitle: "Ki sa AyitiKonekt ye?",
    aboutDescription: "AyitiKonekt kreye yon espas pou koneksyon, konfyans ak opòtinite pou kominote ayisyèn nan tout kote.",
    servicesTitle: "Tout bagay nan yon sèl kote",
    productsTitle: "Pwodwi",
    productsDescription: "Jwenn epi pibliye pwodwi nan kominote a.",
    serviceCardTitle: "Sèvis",
    serviceCardDescription: "Jwenn moun ki ofri sèvis ou bezwen yo.",
    opportunitiesTitle: "Opòtinite",
    opportunitiesDescription: "Konekte ak nouvo opòtinite nan kominote a.",
    contactTitle: "Kontak",
    emailLabel: "Imèl:",
    footer: "© 2026 AyitiKonekt. Tout dwa rezève.",
  },
  es: {
    pageTitle: "AyitiKonekt | Conectando nuestra comunidad",
    navHome: "Inicio",
    navAbout: "Nosotros",
    navServices: "Servicios",
    navContact: "Contacto",
    languageButton: "Idioma",
    heroTitle: "Conectamos nuestra comunidad",
    heroDescription: "Compra, vende, ofrece servicios y descubre oportunidades dentro de la comunidad AyitiKonekt.",
    heroAvailability: "Aplicación para Android y iPhone próximamente.",
    aboutTitle: "¿Qué es AyitiKonekt?",
    aboutDescription: "AyitiKonekt crea un espacio de conexión, confianza y oportunidades para la comunidad haitiana en todas partes.",
    servicesTitle: "Todo en un mismo lugar",
    productsTitle: "Productos",
    productsDescription: "Encuentra y publica productos dentro de la comunidad.",
    serviceCardTitle: "Servicios",
    serviceCardDescription: "Encuentra personas que ofrecen los servicios que necesitas.",
    opportunitiesTitle: "Oportunidades",
    opportunitiesDescription: "Conecta con nuevas oportunidades dentro de la comunidad.",
    contactTitle: "Contacto",
    emailLabel: "Correo:",
    footer: "© 2026 AyitiKonekt. Todos los derechos reservados.",
  },
  en: {
    pageTitle: "AyitiKonekt | Connecting our community",
    navHome: "Home",
    navAbout: "About us",
    navServices: "Services",
    navContact: "Contact",
    languageButton: "Language",
    heroTitle: "We connect our community",
    heroDescription: "Buy, sell, offer services and discover opportunities within the AyitiKonekt community.",
    heroAvailability: "The Android and iPhone app is coming soon.",
    aboutTitle: "What is AyitiKonekt?",
    aboutDescription: "AyitiKonekt creates a space for connection, trust and opportunities for the Haitian community everywhere.",
    servicesTitle: "Everything in one place",
    productsTitle: "Products",
    productsDescription: "Find and publish products within the community.",
    serviceCardTitle: "Services",
    serviceCardDescription: "Find people who offer the services you need.",
    opportunitiesTitle: "Opportunities",
    opportunitiesDescription: "Connect with new opportunities within the community.",
    contactTitle: "Contact",
    emailLabel: "Email:",
    footer: "© 2026 AyitiKonekt. All rights reserved.",
  },
  fr: {
    pageTitle: "AyitiKonekt | Connecter notre communauté",
    navHome: "Accueil",
    navAbout: "À propos",
    navServices: "Services",
    navContact: "Contact",
    languageButton: "Langue",
    heroTitle: "Nous connectons notre communauté",
    heroDescription: "Achetez, vendez, proposez des services et découvrez des opportunités au sein de la communauté AyitiKonekt.",
    heroAvailability: "L’application Android et iPhone arrive bientôt.",
    aboutTitle: "Qu’est-ce qu’AyitiKonekt ?",
    aboutDescription: "AyitiKonekt crée un espace de connexion, de confiance et d’opportunités pour la communauté haïtienne partout dans le monde.",
    servicesTitle: "Tout au même endroit",
    productsTitle: "Produits",
    productsDescription: "Trouvez et publiez des produits au sein de la communauté.",
    serviceCardTitle: "Services",
    serviceCardDescription: "Trouvez des personnes qui offrent les services dont vous avez besoin.",
    opportunitiesTitle: "Opportunités",
    opportunitiesDescription: "Découvrez de nouvelles opportunités au sein de la communauté.",
    contactTitle: "Contact",
    emailLabel: "E-mail :",
    footer: "© 2026 AyitiKonekt. Tous droits réservés.",
  },
  pt: {
    pageTitle: "AyitiKonekt | Conectando nossa comunidade",
    navHome: "Início",
    navAbout: "Sobre nós",
    navServices: "Serviços",
    navContact: "Contato",
    languageButton: "Idioma",
    heroTitle: "Conectamos nossa comunidade",
    heroDescription: "Compre, venda, ofereça serviços e descubra oportunidades na comunidade AyitiKonekt.",
    heroAvailability: "O aplicativo para Android e iPhone estará disponível em breve.",
    aboutTitle: "O que é AyitiKonekt?",
    aboutDescription: "AyitiKonekt cria um espaço de conexão, confiança e oportunidades para a comunidade haitiana em todos os lugares.",
    servicesTitle: "Tudo em um só lugar",
    productsTitle: "Produtos",
    productsDescription: "Encontre e publique produtos dentro da comunidade.",
    serviceCardTitle: "Serviços",
    serviceCardDescription: "Encontre pessoas que oferecem os serviços de que você precisa.",
    opportunitiesTitle: "Oportunidades",
    opportunitiesDescription: "Conecte-se a novas oportunidades dentro da comunidade.",
    contactTitle: "Contato",
    emailLabel: "E-mail:",
    footer: "© 2026 AyitiKonekt. Todos os direitos reservados.",
  },
};

const languageToggle = document.querySelector("#language-toggle");
const languageMenu = document.querySelector("#language-menu");
const languageOptions = document.querySelectorAll("[data-language]");

function closeLanguageMenu() {
  languageMenu.hidden = true;
  languageToggle.setAttribute("aria-expanded", "false");
}

function applyLanguage(language) {
  const copy = translations[language];
  document.documentElement.lang = language;
  document.title = copy.pageTitle;
  document.querySelectorAll("[data-i18n]").forEach((element) => {
    element.textContent = copy[element.dataset.i18n];
  });
  languageOptions.forEach((option) => {
    option.setAttribute("aria-current", String(option.dataset.language === language));
  });
  closeLanguageMenu();
}

languageToggle.addEventListener("click", () => {
  const willOpen = languageMenu.hidden;
  languageMenu.hidden = !willOpen;
  languageToggle.setAttribute("aria-expanded", String(willOpen));
});

languageOptions.forEach((option) => {
  option.addEventListener("click", () => applyLanguage(option.dataset.language));
});

document.addEventListener("click", (event) => {
  if (!event.target.closest(".language-selector")) closeLanguageMenu();
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    closeLanguageMenu();
    languageToggle.focus();
  }
});

applyLanguage("ht");
