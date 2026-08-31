class LegalTermsSection {
  final String title;
  final String body;

  const LegalTermsSection(this.title, this.body);
}

class LegalTermsContent {
  final String version;
  final String versionLabel;
  final String countryLabel;
  final String draftNotice;
  final String introduction;
  final String countryAnnexTitle;
  final String countryAnnex;
  final List<LegalTermsSection> sections;

  const LegalTermsContent({
    required this.version,
    required this.versionLabel,
    required this.countryLabel,
    required this.draftNotice,
    required this.introduction,
    required this.countryAnnexTitle,
    required this.countryAnnex,
    required this.sections,
  });
}

LegalTermsContent legalTermsContent({
  required String languageCode,
  required String country,
}) {
  final code = const {'es', 'en', 'fr', 'ht', 'pt'}.contains(languageCode)
      ? languageCode
      : 'es';
  final copy = _copy[code]!;
  final framework = _countryFramework[country] ?? _countryFramework['Chile']!;

  return LegalTermsContent(
    version: copy['draftVersion']!,
    versionLabel: copy['version']!,
    countryLabel: copy['country']!,
    draftNotice: copy['draft']!,
    introduction: copy['introduction']!,
    countryAnnexTitle: '${copy['annex']} — $country',
    countryAnnex:
        '${copy['annexBody']}\n\n${copy['legalFramework']}: $framework'
        '${country == 'Haití' ? '\n\n${copy['haitiReview']}' : ''}',
    sections: _sectionKeys
        .map(
          (key) => LegalTermsSection(
            copy['${key}Title']!,
            copy['${key}Body']!,
          ),
        )
        .toList(growable: false),
  );
}

const _sectionKeys = [
  'service',
  'accounts',
  'listings',
  'transactions',
  'prohibited',
  'safety',
  'moderation',
  'content',
  'notifications',
  'liability',
  'changes',
  'contact',
];

const Map<String, String> _countryFramework = {
  'Chile':
      'Ley N.º 19.496; Reglamento de Comercio Electrónico; Ley N.º 19.628 y sus modificaciones vigentes.',
  'Estados Unidos':
      'Federal Trade Commission Act; COPPA, when applicable; applicable state privacy and consumer-protection laws.',
  'Canadá':
      'PIPEDA; applicable provincial privacy and consumer-protection laws, including those of Québec, Alberta and British Columbia.',
  'República Dominicana':
      'Ley N.º 358-05; Ley N.º 172-13; normativa aplicable al comercio electrónico.',
  'Haití':
      'Lwa obligatwa ki aplikab ann Ayiti sou kontra, konsomatè, kominikasyon ak done pèsonèl.',
  'Francia':
      'Règlement général sur la protection des données (RGPD); Digital Services Act; droit européen de la consommation; droit français applicable.',
  'México':
      'Ley Federal de Protección al Consumidor; Ley Federal de Protección de Datos Personales en Posesión de los Particulares.',
  'Brasil':
      'Código de Defesa do Consumidor; Lei Geral de Proteção de Dados Pessoais (LGPD); Marco Civil da Internet.',
};

const Map<String, Map<String, String>> _copy = {
  'es': {
    'draftVersion': 'Borrador 1.0',
    'version': 'Versión',
    'country': 'País',
    'draft':
        'Documento preliminar sujeto a revisión jurídica antes de su publicación definitiva.',
    'introduction':
        'Estos términos regulan el acceso y uso de AyitiKonekt. Al crear una cuenta o utilizar el marketplace, aceptas estas reglas y el anexo obligatorio correspondiente a tu país, sin renunciar a los derechos que la ley te reconoce.',
    'annex': 'Anexo legal local',
    'legalFramework': 'Marco jurídico de referencia',
    'haitiReview':
        'Este anexo requiere validación jurídica local antes del lanzamiento comercial en Haití.',
    'annexBody':
        'Las normas obligatorias del país seleccionado prevalecen cuando otorguen al usuario una protección que estos términos no puedan limitar. AyitiKonekt atenderá solicitudes y reclamaciones mediante el canal de soporte informado en la aplicación.',
    'serviceTitle': '1. Función de AyitiKonekt',
    'serviceBody':
        'AyitiKonekt permite publicar, descubrir y contactar a personas interesadas en productos y servicios. Actualmente no vende los artículos, no recibe pagos, no organiza entregas y no es parte del contrato celebrado entre usuarios.',
    'accountsTitle': '2. Cuentas y edad mínima',
    'accountsBody':
        'El marketplace está destinado a personas de 18 años o más. Debes entregar información verdadera, mantenerla actualizada y proteger tus credenciales. No puedes suplantar identidades, transferir tu cuenta ni utilizarla para perjudicar a terceros.',
    'listingsTitle': '3. Publicaciones y vendedores',
    'listingsBody':
        'El vendedor debe tener derecho a ofrecer el artículo o servicio y describir con claridad su precio, estado, ubicación, disponibilidad, defectos y condiciones relevantes. La información, imágenes y promesas publicadas deben ser auténticas y respetarse.',
    'transactionsTitle': '4. Acuerdos entre usuarios',
    'transactionsBody':
        'Comprador y vendedor acuerdan directamente el pago, entrega, comprobantes, garantías, cambios y devoluciones. Cada parte debe verificar la identidad de la contraparte y conservar evidencia del acuerdo. Los derechos obligatorios del consumidor no pueden excluirse.',
    'prohibitedTitle': '5. Contenido y productos prohibidos',
    'prohibitedBody':
        'Se prohíben productos robados, falsificados o ilegales; armas o sustancias prohibidas; documentos personales; ofertas fraudulentas; explotación, discriminación o amenazas; y contenido que vulnere privacidad, propiedad intelectual o derechos de terceros.',
    'safetyTitle': '6. Seguridad y prevención de fraude',
    'safetyBody':
        'Verifica el producto y la identidad antes de pagar, evita enlaces desconocidos y códigos de verificación, y realiza encuentros en lugares seguros. AyitiKonekt nunca solicitará tu contraseña por mensajes entre usuarios.',
    'moderationTitle': '7. Moderación, denuncias y suspensión',
    'moderationBody':
        'AyitiKonekt puede revisar, limitar o retirar contenido y suspender cuentas para proteger a la comunidad o cumplir la ley. Cuando corresponda, informará el motivo y permitirá solicitar una revisión mediante soporte.',
    'contentTitle': '8. Licencia sobre el contenido',
    'contentBody':
        'Conservas la propiedad de tus textos e imágenes. Concedes a AyitiKonekt una licencia no exclusiva y limitada para alojarlos, adaptarlos técnicamente y mostrarlos con el fin de operar y promocionar tu publicación dentro del servicio.',
    'notificationsTitle': '9. Comunicaciones y notificaciones',
    'notificationsBody':
        'Podemos enviar avisos necesarios sobre cuentas, seguridad, mensajes, favoritos y publicaciones. Las comunicaciones promocionales se enviarán únicamente cuando estén permitidas y podrán desactivarse por los medios disponibles.',
    'liabilityTitle': '10. Disponibilidad y responsabilidad',
    'liabilityBody':
        'No garantizamos la identidad, solvencia o conducta de cada usuario ni la calidad de cada publicación. Aplicaremos medidas razonables de seguridad y moderación. Nada en estos términos elimina responsabilidades ni derechos que legalmente no puedan limitarse.',
    'changesTitle': '11. Cambios y terminación',
    'changesBody':
        'Puedes dejar de usar el servicio y solicitar el cierre de tu cuenta. Los cambios importantes se comunicarán con antelación razonable y, cuando sea necesario, requerirán una nueva aceptación.',
    'contactTitle': '12. Soporte y reclamaciones',
    'contactBody':
        'Las consultas, denuncias, apelaciones y solicitudes legales podrán enviarse al canal de soporte publicado por AyitiKonekt. La versión definitiva identificará al responsable legal, domicilio y correo de contacto.',
  },
  'en': {
    'draftVersion': 'Draft 1.0',
    'version': 'Version',
    'country': 'Country',
    'draft': 'Preliminary document subject to legal review before final release.',
    'introduction':
        'These terms govern access to and use of AyitiKonekt. By creating an account or using the marketplace, you agree to these rules and the mandatory annex for your country, without waiving rights granted by law.',
    'annex': 'Local legal annex',
    'legalFramework': 'Reference legal framework',
    'haitiReview':
        'This annex requires local legal validation before commercial launch in Haiti.',
    'annexBody':
        'Mandatory rules in the selected country prevail when they provide protections that these terms cannot limit. AyitiKonekt will handle requests and complaints through the support channel shown in the app.',
    'serviceTitle': '1. Role of AyitiKonekt',
    'serviceBody':
        'AyitiKonekt lets people list, discover and contact others about products and services. It currently does not sell items, receive payments, arrange delivery or become a party to agreements between users.',
    'accountsTitle': '2. Accounts and minimum age',
    'accountsBody':
        'The marketplace is intended for people aged 18 or older. You must provide accurate information, keep it current and protect your credentials. You may not impersonate others, transfer your account or use it to harm anyone.',
    'listingsTitle': '3. Listings and sellers',
    'listingsBody':
        'Sellers must have the right to offer an item or service and clearly describe its price, condition, location, availability, defects and relevant terms. Published information, images and promises must be authentic and honored.',
    'transactionsTitle': '4. Agreements between users',
    'transactionsBody':
        'Buyer and seller directly arrange payment, delivery, receipts, warranties, exchanges and returns. Each party should verify the other and keep evidence of the agreement. Mandatory consumer rights cannot be excluded.',
    'prohibitedTitle': '5. Prohibited content and products',
    'prohibitedBody':
        'Stolen, counterfeit or illegal goods; weapons or prohibited substances; personal documents; fraudulent offers; exploitation, discrimination or threats; and content infringing privacy, intellectual property or third-party rights are prohibited.',
    'safetyTitle': '6. Safety and fraud prevention',
    'safetyBody':
        'Verify the item and identity before paying, avoid unknown links and verification codes, and meet in safe places. AyitiKonekt will never request your password through user messages.',
    'moderationTitle': '7. Moderation, reports and suspension',
    'moderationBody':
        'AyitiKonekt may review, restrict or remove content and suspend accounts to protect the community or comply with law. When appropriate, it will state the reason and provide a support review process.',
    'contentTitle': '8. Content license',
    'contentBody':
        'You retain ownership of your text and images. You grant AyitiKonekt a limited, non-exclusive license to host, technically adapt and display them to operate and promote your listing within the service.',
    'notificationsTitle': '9. Communications and notifications',
    'notificationsBody':
        'We may send necessary account, security, message, favorite and listing notices. Marketing communications will only be sent where permitted and can be disabled through available controls.',
    'liabilityTitle': '10. Availability and responsibility',
    'liabilityBody':
        'We do not guarantee every user’s identity, solvency or conduct, or every listing’s quality. We will apply reasonable security and moderation measures. Nothing here removes liabilities or rights that cannot legally be limited.',
    'changesTitle': '11. Changes and termination',
    'changesBody':
        'You may stop using the service and request account closure. Material changes will be communicated with reasonable notice and will require renewed acceptance when necessary.',
    'contactTitle': '12. Support and complaints',
    'contactBody':
        'Questions, reports, appeals and legal requests may be submitted through AyitiKonekt’s published support channel. The final version will identify the legal operator, address and contact email.',
  },
  'fr': {
    'draftVersion': 'Brouillon 1.0',
    'version': 'Version', 'country': 'Pays',
    'draft': 'Document préliminaire soumis à une révision juridique avant sa publication définitive.',
    'introduction': 'Ces conditions régissent l’accès à AyitiKonekt et son utilisation. En créant un compte ou en utilisant la marketplace, vous acceptez ces règles et l’annexe obligatoire de votre pays, sans renoncer à vos droits légaux.',
    'annex': 'Annexe juridique locale',
    'legalFramework': 'Cadre juridique de référence',
    'haitiReview':
        'Cette annexe nécessite une validation juridique locale avant le lancement commercial en Haïti.',
    'annexBody': 'Les règles impératives du pays sélectionné prévalent lorsqu’elles accordent une protection que ces conditions ne peuvent limiter. Les demandes seront traitées par le canal d’assistance affiché dans l’application.',
    'serviceTitle': '1. Rôle d’AyitiKonekt', 'serviceBody': 'AyitiKonekt permet de publier, découvrir et contacter des personnes au sujet de produits et services. La plateforme ne vend pas les articles, ne reçoit pas les paiements, n’organise pas la livraison et n’est pas partie aux contrats entre utilisateurs.',
    'accountsTitle': '2. Comptes et âge minimum', 'accountsBody': 'La marketplace est réservée aux personnes âgées d’au moins 18 ans. Vous devez fournir des informations exactes, les actualiser et protéger vos identifiants. L’usurpation d’identité, le transfert de compte et tout usage nuisible sont interdits.',
    'listingsTitle': '3. Annonces et vendeurs', 'listingsBody': 'Le vendeur doit avoir le droit d’offrir le bien ou service et décrire clairement son prix, son état, sa localisation, sa disponibilité, ses défauts et ses conditions. Les informations, images et promesses doivent être authentiques et respectées.',
    'transactionsTitle': '4. Accords entre utilisateurs', 'transactionsBody': 'Acheteur et vendeur organisent directement paiement, livraison, reçus, garanties, échanges et retours. Chacun doit vérifier l’autre partie et conserver les preuves. Les droits impératifs des consommateurs restent applicables.',
    'prohibitedTitle': '5. Contenus et produits interdits', 'prohibitedBody': 'Sont interdits les biens volés, contrefaits ou illégaux, armes, substances prohibées, documents personnels, fraudes, exploitation, discrimination, menaces et atteintes à la vie privée ou aux droits de tiers.',
    'safetyTitle': '6. Sécurité et prévention de la fraude', 'safetyBody': 'Vérifiez le produit et l’identité avant de payer, évitez les liens inconnus et codes de vérification, et rencontrez-vous dans un lieu sûr. AyitiKonekt ne demandera jamais votre mot de passe dans la messagerie.',
    'moderationTitle': '7. Modération, signalements et suspension', 'moderationBody': 'AyitiKonekt peut examiner, limiter ou retirer du contenu et suspendre des comptes pour protéger la communauté ou respecter la loi. Lorsque nécessaire, le motif sera communiqué et un recours auprès du support sera possible.',
    'contentTitle': '8. Licence de contenu', 'contentBody': 'Vous restez propriétaire de vos textes et images. Vous accordez à AyitiKonekt une licence non exclusive et limitée permettant de les héberger, adapter techniquement et afficher pour exploiter et promouvoir votre annonce.',
    'notificationsTitle': '9. Communications et notifications', 'notificationsBody': 'Nous pouvons envoyer les avis nécessaires concernant le compte, la sécurité, les messages, favoris et annonces. Les communications promotionnelles ne seront envoyées que si elles sont autorisées et pourront être désactivées.',
    'liabilityTitle': '10. Disponibilité et responsabilité', 'liabilityBody': 'Nous ne garantissons pas l’identité, la solvabilité ou le comportement de chaque utilisateur, ni la qualité de chaque annonce. Des mesures raisonnables de sécurité et de modération seront appliquées sans limiter les droits impératifs.',
    'changesTitle': '11. Modifications et résiliation', 'changesBody': 'Vous pouvez cesser d’utiliser le service et demander la fermeture du compte. Les changements importants seront annoncés dans un délai raisonnable et nécessiteront une nouvelle acceptation lorsque requis.',
    'contactTitle': '12. Assistance et réclamations', 'contactBody': 'Questions, signalements, recours et demandes légales peuvent être transmis au support publié par AyitiKonekt. La version définitive identifiera l’exploitant légal, son adresse et son courriel.',
  },
  'ht': {
    'draftVersion': 'Bouyon 1.0',
    'version': 'Vèsyon', 'country': 'Peyi',
    'draft': 'Dokiman preliminè sa a dwe revize pa yon pwofesyonèl legal anvan piblikasyon final li.',
    'introduction': 'Tèm sa yo dirije aksè ak itilizasyon AyitiKonekt. Lè ou kreye yon kont oswa itilize mache a, ou dakò ak règ sa yo ak anèks obligatwa peyi ou, san ou pa abandone dwa lalwa ba ou.',
    'annex': 'Anèks legal lokal',
    'legalFramework': 'Kad legal referans',
    'haitiReview':
        'Anèks sa a bezwen yon validasyon legal lokal anvan lansman komèsyal ann Ayiti.',
    'annexBody': 'Règ obligatwa peyi ou chwazi a gen priyorite lè yo bay pwoteksyon tèm sa yo pa ka limite. AyitiKonekt ap trete demann ak plent nan kanal sipò ki nan aplikasyon an.',
    'serviceTitle': '1. Wòl AyitiKonekt', 'serviceBody': 'AyitiKonekt pèmèt moun pibliye, dekouvri epi kontakte lòt moun pou pwodwi ak sèvis. Kounye a li pa vann atik, li pa resevwa peman, li pa òganize livrezon epi li pa yon pati nan kontra ant itilizatè yo.',
    'accountsTitle': '2. Kont ak laj minimòm', 'accountsBody': 'Mache a fèt pou moun ki gen 18 an oswa plis. Ou dwe bay enfòmasyon ki vre, mete yo ajou epi pwoteje modpas ou. Ou pa ka pran idantite lòt moun, transfere kont ou oswa sèvi avè l pou fè mal.',
    'listingsTitle': '3. Anons ak vandè', 'listingsBody': 'Vandè a dwe gen dwa ofri pwodwi oswa sèvis la epi dekri pri, eta, kote, disponiblite, defo ak kondisyon enpòtan yo klèman. Enfòmasyon, foto ak pwomès yo dwe otantik epi respekte.',
    'transactionsTitle': '4. Akò ant itilizatè', 'transactionsBody': 'Achtè ak vandè dakò dirèkteman sou peman, livrezon, resi, garanti, echanj ak retou. Chak moun dwe verifye lòt la epi kenbe prèv akò a. Dwa konsomatè lalwa egzije yo toujou valab.',
    'prohibitedTitle': '5. Kontni ak pwodwi ki entèdi', 'prohibitedBody': 'Pwodwi vòlè, fo oswa ilegal, zam, sibstans entèdi, dokiman pèsonèl, fwod, eksplwatasyon, diskriminasyon, menas ak kontni ki vyole vi prive oswa dwa lòt moun entèdi.',
    'safetyTitle': '6. Sekirite ak prevansyon fwod', 'safetyBody': 'Verifye pwodwi a ak idantite moun nan anvan ou peye, evite lyen enkoni ak kòd verifikasyon, epi rankontre nan kote ki an sekirite. AyitiKonekt pap janm mande modpas ou nan mesaj.',
    'moderationTitle': '7. Moderasyon, rapò ak sispansyon', 'moderationBody': 'AyitiKonekt ka revize, limite oswa retire kontni epi sispann kont pou pwoteje kominote a oswa respekte lalwa. Lè sa nesesè, li ap bay rezon an epi pèmèt yon demann revizyon nan sipò.',
    'contentTitle': '8. Lisans sou kontni', 'contentBody': 'Ou rete pwopriyetè tèks ak foto ou yo. Ou bay AyitiKonekt yon lisans limite, ki pa eksklizif, pou konsève, adapte teknikman epi montre yo pou opere ak ankouraje anons ou.',
    'notificationsTitle': '9. Kominikasyon ak notifikasyon', 'notificationsBody': 'Nou ka voye avi nesesè sou kont, sekirite, mesaj, favori ak anons. N ap voye pwomosyon sèlman lè sa otorize epi ou kapab dezaktive yo.',
    'liabilityTitle': '10. Disponiblite ak responsablite', 'liabilityBody': 'Nou pa garanti idantite, kapasite finansye oswa konpòtman chak itilizatè, ni kalite chak anons. N ap pran mezi rezonab pou sekirite ak moderasyon san nou pa limite dwa lalwa pwoteje.',
    'changesTitle': '11. Chanjman ak fèmen kont', 'changesBody': 'Ou ka sispann itilize sèvis la epi mande fèmen kont ou. N ap anonse gwo chanjman davans nan yon delè rezonab epi n ap mande nouvo akseptasyon lè sa nesesè.',
    'contactTitle': '12. Sipò ak plent', 'contactBody': 'Kesyon, rapò, apèl ak demann legal ka voye nan kanal sipò AyitiKonekt pibliye a. Vèsyon final la ap idantifye responsab legal la, adrès li ak imèl kontak li.',
  },
  'pt': {
    'draftVersion': 'Rascunho 1.0',
    'version': 'Versão', 'country': 'País',
    'draft': 'Documento preliminar sujeito a revisão jurídica antes da publicação definitiva.',
    'introduction': 'Estes termos regulam o acesso e uso do AyitiKonekt. Ao criar uma conta ou utilizar o marketplace, você aceita estas regras e o anexo obrigatório do seu país, sem renunciar aos direitos garantidos por lei.',
    'annex': 'Anexo jurídico local',
    'legalFramework': 'Marco jurídico de referência',
    'haitiReview':
        'Este anexo requer validação jurídica local antes do lançamento comercial no Haiti.',
    'annexBody': 'As normas obrigatórias do país selecionado prevalecem quando concedem proteção que estes termos não podem limitar. Solicitações e reclamações serão atendidas pelo canal de suporte exibido no aplicativo.',
    'serviceTitle': '1. Função do AyitiKonekt', 'serviceBody': 'O AyitiKonekt permite anunciar, descobrir e contatar pessoas sobre produtos e serviços. Atualmente não vende itens, recebe pagamentos, organiza entregas nem participa dos contratos entre usuários.',
    'accountsTitle': '2. Contas e idade mínima', 'accountsBody': 'O marketplace destina-se a maiores de 18 anos. Você deve fornecer informações verdadeiras, mantê-las atualizadas e proteger suas credenciais. É proibido assumir outra identidade, transferir a conta ou usá-la para prejudicar terceiros.',
    'listingsTitle': '3. Anúncios e vendedores', 'listingsBody': 'O vendedor deve ter o direito de oferecer o item ou serviço e descrever claramente preço, estado, localização, disponibilidade, defeitos e condições relevantes. Informações, imagens e promessas devem ser autênticas e respeitadas.',
    'transactionsTitle': '4. Acordos entre usuários', 'transactionsBody': 'Comprador e vendedor combinam diretamente pagamento, entrega, comprovantes, garantias, trocas e devoluções. Cada parte deve verificar a outra e guardar provas. Direitos obrigatórios do consumidor não podem ser excluídos.',
    'prohibitedTitle': '5. Conteúdo e produtos proibidos', 'prohibitedBody': 'São proibidos produtos roubados, falsificados ou ilegais, armas, substâncias proibidas, documentos pessoais, fraudes, exploração, discriminação, ameaças e conteúdo que viole privacidade ou direitos de terceiros.',
    'safetyTitle': '6. Segurança e prevenção de fraude', 'safetyBody': 'Verifique o produto e a identidade antes de pagar, evite links desconhecidos e códigos de verificação, e encontre-se em locais seguros. O AyitiKonekt nunca solicitará sua senha nas mensagens.',
    'moderationTitle': '7. Moderação, denúncias e suspensão', 'moderationBody': 'O AyitiKonekt pode revisar, limitar ou remover conteúdo e suspender contas para proteger a comunidade ou cumprir a lei. Quando apropriado, informará o motivo e permitirá pedir revisão pelo suporte.',
    'contentTitle': '8. Licença de conteúdo', 'contentBody': 'Você mantém a propriedade dos seus textos e imagens. Concede ao AyitiKonekt licença limitada e não exclusiva para hospedar, adaptar tecnicamente e exibir o conteúdo a fim de operar e promover seu anúncio.',
    'notificationsTitle': '9. Comunicações e notificações', 'notificationsBody': 'Podemos enviar avisos necessários sobre conta, segurança, mensagens, favoritos e anúncios. Comunicações promocionais serão enviadas apenas quando permitidas e poderão ser desativadas.',
    'liabilityTitle': '10. Disponibilidade e responsabilidade', 'liabilityBody': 'Não garantimos a identidade, solvência ou conduta de cada usuário nem a qualidade de cada anúncio. Aplicaremos medidas razoáveis de segurança e moderação sem limitar direitos ou responsabilidades legalmente obrigatórios.',
    'changesTitle': '11. Alterações e encerramento', 'changesBody': 'Você pode deixar de usar o serviço e solicitar o encerramento da conta. Alterações importantes serão comunicadas com antecedência razoável e exigirão nova aceitação quando necessário.',
    'contactTitle': '12. Suporte e reclamações', 'contactBody': 'Dúvidas, denúncias, recursos e solicitações legais podem ser enviados ao canal de suporte publicado pelo AyitiKonekt. A versão final identificará o operador legal, endereço e e-mail de contato.',
  },
};
