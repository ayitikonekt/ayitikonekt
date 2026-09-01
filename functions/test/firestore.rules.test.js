const {after, before, beforeEach, test} = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require("firebase/firestore");

const projectId = "demo-ayitikonekt-security";
let env;

const user = (uid) => env.authenticatedContext(uid).firestore();
const admin = () => env.authenticatedContext("admin", {admin: true}).firestore();
const moderator = () => env.authenticatedContext("moderator", {moderator: true}).firestore();
const anonymous = () => env.unauthenticatedContext().firestore();

function validProduct(id, sellerId, overrides = {}) {
  return {
    id,
    title: "Producto válido",
    description: "Descripción válida",
    price: 10,
    category: "Otros",
    listingType: "product",
    priceNegotiable: false,
    serviceArea: "",
    availability: "",
    city: "Santiago",
    country: "Chile",
    address: "",
    latitude: 0,
    longitude: 0,
    images: [],
    sellerId,
    sellerName: "Vendedor",
    sellerPhoto: "",
    sellerPhone: "",
    sellerEmail: "",
    condition: "Usado",
    isFeatured: false,
    isSold: false,
    views: 0,
    favorites: 0,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

async function seed() {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "users/alice"), {
      uid: "alice",
      name: "Alice",
      lastName: "A",
      phone: "111",
      reputation: 5,
    });
    await setDoc(doc(db, "users/bob"), {
      uid: "bob",
      name: "Bob",
      lastName: "B",
      phone: "222",
      reputation: 5,
    });
    await setDoc(doc(db, "publicProfiles/bob"), {
      uid: "bob",
      name: "Bob",
      lastName: "B",
      country: "Chile",
      city: "Santiago",
      photo: "",
      verified: false,
      reputation: 5,
      reviewCount: 0,
    });
    await setDoc(doc(db, "products/product-bob"), {
      id: "product-bob",
      sellerId: "bob",
      title: "Producto de Bob",
      description: "Prueba",
      price: 10,
      category: "Otros",
      listingType: "product",
      priceNegotiable: false,
      serviceArea: "",
      availability: "",
      city: "Santiago",
      country: "Chile",
      address: "",
      latitude: 0,
      longitude: 0,
      images: [],
      sellerName: "Bob",
      sellerPhoto: "",
      sellerPhone: "",
      sellerEmail: "",
      condition: "Usado",
      views: 0,
      favorites: 0,
      isFeatured: false,
      isSold: false,
      createdAt: "2026-08-31T00:00:00.000Z",
      updatedAt: "2026-08-31T00:00:00.000Z",
    });
    await setDoc(doc(db, "users/bob/favorites/product-bob"), {
      productId: "product-bob",
    });
    await setDoc(doc(db, "users/bob/notifications/notification-1"), {
      read: false,
      type: "favorite",
    });
    await setDoc(doc(db, "supportTickets/ticket-bob"), {
      userId: "bob",
      status: "received",
      message: "Privado",
    });
    await setDoc(doc(db, "conversations/alice-bob"), {
      participantIds: ["alice", "bob"],
    });
    await setDoc(doc(db, "conversations/alice-bob/messages/message-1"), {
      senderId: "bob",
      text: "Hola",
    });
    await setDoc(doc(db, "conversations/invalid-duplicate"), {
      participantIds: ["alice", "alice"],
    });
    await setDoc(doc(db, "reviewInteractions/product-bob_alice"), {
      productId: "product-bob",
      sellerId: "bob",
      reviewerId: "alice",
      status: "eligible",
    });
    await setDoc(doc(db, "reviews/product-bob_alice"), {
      productId: "product-bob",
      operationId: "product-bob_alice",
      sellerId: "bob",
      reviewerId: "alice",
      rating: 5,
      status: "published",
    });
    await setDoc(doc(db, "reviews/hidden-review"), {
      productId: "product-bob",
      operationId: "hidden-operation",
      sellerId: "bob",
      reviewerId: "charlie",
      rating: 1,
      status: "hidden",
    });
    await setDoc(doc(db, "reviewReports/product-bob_alice_bob"), {
      reviewId: "product-bob_alice",
      reporterId: "bob",
      status: "open",
    });
    await setDoc(doc(db, "moderationAudit/audit-1"), {
      type: "review_moderation",
      moderatorId: "moderator",
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, "../../firestore.rules"), "utf8"),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed();
});

after(async () => {
  await env.cleanup();
});

test("un usuario anónimo no puede escribir", async () => {
  await assertFails(setDoc(doc(anonymous(), "users/anonymous"), {uid: "anonymous", reputation: 5}));
});

test("Alice puede editar campos permitidos de su perfil", async () => {
  await assertSucceeds(updateDoc(doc(user("alice"), "users/alice"), {city: "Santiago"}));
});

test("Alice no puede editar el perfil de Bob", async () => {
  await assertFails(updateDoc(doc(user("alice"), "users/bob"), {name: "Manipulado"}));
});

test("el perfil privado de Bob no puede ser leído por Alice", async () => {
  await assertFails(getDoc(doc(user("alice"), "users/bob")));
  await assertSucceeds(getDoc(doc(user("bob"), "users/bob")));
  await assertSucceeds(getDoc(doc(admin(), "users/bob")));
});

test("el perfil público es visible pero nadie puede falsificarlo directamente", async () => {
  await assertSucceeds(getDoc(doc(anonymous(), "publicProfiles/bob")));
  await assertSucceeds(getDoc(doc(user("alice"), "publicProfiles/bob")));
  await assertFails(updateDoc(doc(user("bob"), "publicProfiles/bob"), {reputation: 100}));
  await assertFails(setDoc(doc(user("alice"), "publicProfiles/alice"), {
    uid: "alice",
    reputation: 100,
  }));
});

test("Alice no puede elevar su reputación ni darse rol administrativo", async () => {
  await assertFails(updateDoc(doc(user("alice"), "users/alice"), {reputation: 100}));
  await assertFails(updateDoc(doc(user("alice"), "users/alice"), {admin: true}));
});

test("Alice puede crear su producto con contadores seguros", async () => {
  await assertSucceeds(setDoc(
    doc(user("alice"), "products/product-alice"),
    validProduct("product-alice", "alice"),
  ));
});

test("Alice no puede crear un producto en nombre de Bob", async () => {
  await assertFails(setDoc(
    doc(user("alice"), "products/falso"),
    validProduct("falso", "bob"),
  ));
});

test("Alice no puede editar ni eliminar el producto de Bob", async () => {
  await assertFails(updateDoc(doc(user("alice"), "products/product-bob"), {title: "Robado"}));
  await assertFails(deleteDoc(doc(user("alice"), "products/product-bob")));
});

test("Bob puede editar su producto pero no sus contadores ni propietario", async () => {
  await assertSucceeds(updateDoc(doc(user("bob"), "products/product-bob"), {
    title: "Título correcto",
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(user("bob"), "products/product-bob"), {
    views: 9999,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(user("bob"), "products/product-bob"), {
    favorites: 9999,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(user("bob"), "products/product-bob"), {
    sellerId: "alice",
    updatedAt: serverTimestamp(),
  }));
});

test("un producto no admite campos administrativos ocultos", async () => {
  await assertFails(setDoc(
    doc(user("alice"), "products/admin-field"),
    validProduct("admin-field", "alice", {adminApproved: true}),
  ));
});

test("precio y longitudes inválidas son rechazados", async () => {
  await assertFails(setDoc(
    doc(user("alice"), "products/negative-price"),
    validProduct("negative-price", "alice", {price: -1}),
  ));
  await assertFails(setDoc(
    doc(user("alice"), "products/long-title"),
    validProduct("long-title", "alice", {title: "x".repeat(121)}),
  ));
  await assertFails(setDoc(
    doc(user("alice"), "products/string-price"),
    validProduct("string-price", "alice", {price: "10"}),
  ));
});

test("solo se permiten hasta ocho imágenes válidas", async () => {
  await assertSucceeds(setDoc(
    doc(user("alice"), "products/eight-images"),
    validProduct("eight-images", "alice", {images: Array(8).fill("https://example.com/image.jpg")}),
  ));
  await assertFails(setDoc(
    doc(user("alice"), "products/nine-images"),
    validProduct("nine-images", "alice", {images: Array(9).fill("https://example.com/image.jpg")}),
  ));
  await assertFails(setDoc(
    doc(user("alice"), "products/non-string-image"),
    validProduct("non-string-image", "alice", {images: [123]}),
  ));
});

test("las fechas de productos deben ser generadas por el servidor", async () => {
  await assertFails(setDoc(
    doc(user("alice"), "products/fake-date"),
    validProduct("fake-date", "alice", {
      createdAt: "2026-08-31T12:00:00.000Z",
      updatedAt: "2026-08-31T12:00:00.000Z",
    }),
  ));
  await assertFails(updateDoc(doc(user("bob"), "products/product-bob"), {
    title: "Fecha manipulada",
    updatedAt: "2026-08-31T12:00:00.000Z",
  }));
});

test("un servicio válido puede publicarse con precio a convenir", async () => {
  await assertSucceeds(setDoc(
    doc(user("alice"), "products/service-alice"),
    validProduct("service-alice", "alice", {
      title: "Servicio de gasfitería",
      category: "Gasfitería",
      listingType: "service",
      price: 0,
      priceNegotiable: true,
      serviceArea: "Santiago Centro",
      availability: "Lunes a sábado",
      condition: "No aplica",
    }),
  ));
});

test("un servicio incompleto o un producto negociable son rechazados", async () => {
  await assertFails(setDoc(
    doc(user("alice"), "products/incomplete-service"),
    validProduct("incomplete-service", "alice", {
      listingType: "service",
      price: 0,
      priceNegotiable: true,
      condition: "No aplica",
    }),
  ));
  await assertFails(setDoc(
    doc(user("alice"), "products/negotiable-product"),
    validProduct("negotiable-product", "alice", {
      price: 0,
      priceNegotiable: true,
    }),
  ));
});

test("favoritos y notificaciones son privados y no admiten creación directa", async () => {
  await assertSucceeds(getDoc(doc(user("bob"), "users/bob/favorites/product-bob")));
  await assertFails(getDoc(doc(user("alice"), "users/bob/favorites/product-bob")));
  await assertFails(setDoc(doc(user("alice"), "users/alice/favorites/product-bob"), {productId: "product-bob"}));
  await assertSucceeds(getDoc(doc(user("bob"), "users/bob/notifications/notification-1")));
  await assertFails(getDoc(doc(user("alice"), "users/bob/notifications/notification-1")));
  await assertFails(setDoc(doc(user("alice"), "users/bob/notifications/falsa"), {read: false}));
});

test("solo el dueño puede marcar su notificación como leída", async () => {
  await assertSucceeds(updateDoc(doc(user("bob"), "users/bob/notifications/notification-1"), {read: true}));
  await assertFails(updateDoc(doc(user("alice"), "users/bob/notifications/notification-1"), {read: true}));
  await assertFails(updateDoc(doc(user("bob"), "users/bob/notifications/notification-1"), {type: "falsa"}));
});

test("los tickets solamente son visibles por su dueño o un administrador", async () => {
  await assertSucceeds(getDoc(doc(user("bob"), "supportTickets/ticket-bob")));
  await assertFails(getDoc(doc(user("alice"), "supportTickets/ticket-bob")));
  await assertSucceeds(getDoc(doc(admin(), "supportTickets/ticket-bob")));
});

test("un usuario no puede crear un ticket para otra cuenta", async () => {
  await assertFails(addDoc(collection(user("alice"), "supportTickets"), {
    userId: "bob",
    status: "received",
  }));
});

test("los mensajes solo son visibles por participantes", async () => {
  await assertSucceeds(getDoc(doc(user("alice"), "conversations/alice-bob/messages/message-1")));
  await assertSucceeds(getDoc(doc(user("bob"), "conversations/alice-bob/messages/message-1")));
  await assertFails(getDoc(doc(user("charlie"), "conversations/alice-bob/messages/message-1")));
});

test("un usuario no puede enviar mensajes con la identidad de otro", async () => {
  await assertFails(setDoc(doc(user("alice"), "conversations/alice-bob/messages/falso"), {
    senderId: "bob",
    text: "Mensaje falso",
  }));
});

test("conversaciones y mensajes solo pueden ser creados por el backend", async () => {
  await assertFails(setDoc(doc(user("alice"), "conversations/directa"), {
    participantIds: ["alice", "bob"],
    productId: "product-bob",
  }));
  await assertFails(setDoc(doc(user("alice"), "conversations/alice-bob/messages/directo"), {
    senderId: "alice",
    text: "Mensaje directo",
    attachments: [],
    createdAt: serverTimestamp(),
  }));
});

test("una conversación con participantes repetidos es inválida", async () => {
  await assertFails(getDoc(doc(user("alice"), "conversations/invalid-duplicate")));
});

test("reseñas y eventos de visualización no admiten escritura directa", async () => {
  await assertFails(setDoc(doc(user("alice"), "reviews/review-falsa"), {rating: 5}));
  await assertFails(setDoc(doc(user("alice"), "products/product-bob/viewEvents/alice"), {viewerId: "alice"}));
});

test("las interacciones de reseña son privadas e inmutables", async () => {
  await assertSucceeds(getDoc(doc(user("alice"), "reviewInteractions/product-bob_alice")));
  await assertSucceeds(getDoc(doc(user("bob"), "reviewInteractions/product-bob_alice")));
  await assertFails(getDoc(doc(user("charlie"), "reviewInteractions/product-bob_alice")));
  await assertFails(setDoc(doc(user("alice"), "reviewInteractions/falsa"), {
    sellerId: "bob", reviewerId: "alice", status: "eligible",
  }));
});

test("una reseña oculta solo es visible para las partes o moderación", async () => {
  await assertSucceeds(getDoc(doc(user("bob"), "reviews/hidden-review")));
  await assertSucceeds(getDoc(doc(user("charlie"), "reviews/hidden-review")));
  await assertSucceeds(getDoc(doc(moderator(), "reviews/hidden-review")));
  await assertFails(getDoc(doc(user("alice"), "reviews/hidden-review")));
});

test("las denuncias solo son visibles para quien denuncia y moderación", async () => {
  await assertSucceeds(getDoc(doc(user("bob"), "reviewReports/product-bob_alice_bob")));
  await assertSucceeds(getDoc(doc(moderator(), "reviewReports/product-bob_alice_bob")));
  await assertFails(getDoc(doc(user("alice"), "reviewReports/product-bob_alice_bob")));
  await assertFails(setDoc(doc(user("alice"), "reviewReports/falsa"), {
    reviewId: "product-bob_alice", reporterId: "alice", status: "open",
  }));
});

test("la auditoría de moderación no puede ser falsificada", async () => {
  await assertSucceeds(getDoc(doc(moderator(), "moderationAudit/audit-1")));
  await assertFails(getDoc(doc(user("alice"), "moderationAudit/audit-1")));
  await assertFails(setDoc(doc(admin(), "moderationAudit/falsa"), {action: "hide"}));
});

test("las rutas no declaradas permanecen cerradas", async () => {
  await assertFails(setDoc(doc(user("alice"), "administration/config"), {owner: true}));
  await assertFails(getDoc(doc(user("alice"), "administration/config")));
});
