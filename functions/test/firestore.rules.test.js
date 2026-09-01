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
  setDoc,
  updateDoc,
} = require("firebase/firestore");

const projectId = "demo-ayitikonekt-security";
let env;

const user = (uid) => env.authenticatedContext(uid).firestore();
const admin = () => env.authenticatedContext("admin", {admin: true}).firestore();
const anonymous = () => env.unauthenticatedContext().firestore();

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
      city: "Santiago",
      country: "Chile",
      images: [],
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
  await assertSucceeds(setDoc(doc(user("alice"), "products/product-alice"), {
    id: "product-alice",
    sellerId: "alice",
    title: "Producto",
    views: 0,
    favorites: 0,
    isFeatured: false,
  }));
});

test("Alice no puede crear un producto en nombre de Bob", async () => {
  await assertFails(setDoc(doc(user("alice"), "products/falso"), {
    id: "falso",
    sellerId: "bob",
    views: 0,
    favorites: 0,
    isFeatured: false,
  }));
});

test("Alice no puede editar ni eliminar el producto de Bob", async () => {
  await assertFails(updateDoc(doc(user("alice"), "products/product-bob"), {title: "Robado"}));
  await assertFails(deleteDoc(doc(user("alice"), "products/product-bob")));
});

test("Bob puede editar su producto pero no sus contadores ni propietario", async () => {
  await assertSucceeds(updateDoc(doc(user("bob"), "products/product-bob"), {title: "Título correcto"}));
  await assertFails(updateDoc(doc(user("bob"), "products/product-bob"), {views: 9999}));
  await assertFails(updateDoc(doc(user("bob"), "products/product-bob"), {favorites: 9999}));
  await assertFails(updateDoc(doc(user("bob"), "products/product-bob"), {sellerId: "alice"}));
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

test("reseñas y eventos de visualización no admiten escritura directa", async () => {
  await assertFails(setDoc(doc(user("alice"), "reviews/review-falsa"), {rating: 5}));
  await assertFails(setDoc(doc(user("alice"), "products/product-bob/viewEvents/alice"), {viewerId: "alice"}));
});

test("las rutas no declaradas permanecen cerradas", async () => {
  await assertFails(setDoc(doc(user("alice"), "administration/config"), {owner: true}));
  await assertFails(getDoc(doc(user("alice"), "administration/config")));
});
