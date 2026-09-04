const { after, before, beforeEach, test } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { deleteObject, getBytes, ref, uploadBytes } = require("firebase/storage");
const {doc, setDoc} = require("firebase/firestore");

const projectId = "demo-ayitikonekt-security";
const ownerId = "message-owner";
const otherId = "message-other";
const conversationId = "product123_message-other_message-owner";
let testEnv;

function ownerStorage() {
  return testEnv.authenticatedContext(ownerId).storage();
}

function otherStorage() {
  return testEnv.authenticatedContext(otherId).storage();
}

function supportStorage() {
  return testEnv.authenticatedContext("support-agent", {
    support: true,
    firebase: {sign_in_second_factor: "phone"},
  }).storage();
}

function supportWithoutMfaStorage() {
  return testEnv.authenticatedContext("support-no-mfa", {support: true}).storage();
}

function attachment(storage, fileName) {
  return ref(
    storage,
    `conversation_uploads/${ownerId}/${conversationId}/${fileName}`,
  );
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, "..", "..", "firestore.rules"),
        "utf8",
      ),
    },
    storage: {
      rules: fs.readFileSync(
        path.join(__dirname, "..", "..", "storage.rules"),
        "utf8",
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "products/product-1"), {
      sellerId: ownerId,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

test("el propietario puede subir y leer una imagen valida", async () => {
  const imageRef = attachment(ownerStorage(), "photo-1.jpg");
  const image = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);

  await assertSucceeds(uploadBytes(imageRef, image, { contentType: "image/jpeg" }));
  await assertSucceeds(getBytes(imageRef));
});

test("un participante no puede escribir en el espacio de otro usuario", async () => {
  const imageRef = attachment(otherStorage(), "intrusion.png");

  await assertFails(
    uploadBytes(imageRef, new Uint8Array([1]), { contentType: "image/png" }),
  );
});

test("rechaza tipos de archivo no permitidos", async () => {
  const scriptRef = attachment(ownerStorage(), "payload.txt");

  await assertFails(
    uploadBytes(scriptRef, new TextEncoder().encode("codigo"), {
      contentType: "text/plain",
    }),
  );
});

test("rechaza archivos superiores a ocho megabytes", async () => {
  const largeRef = attachment(ownerStorage(), "large.pdf");
  const oversized = new Uint8Array(8 * 1024 * 1024 + 1);

  await assertFails(
    uploadBytes(largeRef, oversized, { contentType: "application/pdf" }),
  );
});

test("solo el propietario puede leer o eliminar el archivo temporal", async () => {
  const ownerRef = attachment(ownerStorage(), "document.pdf");
  await assertSucceeds(
    uploadBytes(ownerRef, new Uint8Array([0x25, 0x50, 0x44, 0x46]), {
      contentType: "application/pdf",
    }),
  );

  const otherRef = attachment(otherStorage(), "document.pdf");
  await assertFails(getBytes(otherRef));
  await assertFails(deleteObject(otherRef));
  await assertSucceeds(deleteObject(ownerRef));
});

test("evidencias de soporte validan propietario, tipo y acceso del personal", async () => {
  const path = `support_tickets/${ownerId}/ticket-1/evidence.png`;
  const ownerRef = ref(ownerStorage(), path);
  await assertSucceeds(
    uploadBytes(ownerRef, new Uint8Array([1, 2, 3]), { contentType: "image/png" }),
  );
  await assertSucceeds(getBytes(ref(supportStorage(), path)));
  await assertFails(getBytes(ref(supportWithoutMfaStorage(), path)));
  await assertFails(
    uploadBytes(ref(otherStorage(), path), new Uint8Array([1]), {
      contentType: "image/png",
    }),
  );
  await assertFails(
    uploadBytes(
      ref(ownerStorage(), `support_tickets/${ownerId}/ticket-1/script.svg`),
      new Uint8Array([1]),
      { contentType: "image/svg+xml" },
    ),
  );
});

test("fotos de productos exigen producto existente, propietario y nombre seguro", async () => {
  const validPath = `products/${ownerId}/product-1/1788000000000000.jpg`;
  const validRef = ref(ownerStorage(), validPath);
  await assertSucceeds(
    uploadBytes(validRef, new Uint8Array([0xff, 0xd8, 0xff]), {
      contentType: "image/jpeg",
    }),
  );
  await assertFails(
    uploadBytes(ref(otherStorage(), validPath), new Uint8Array([1]), {
      contentType: "image/jpeg",
    }),
  );
  await assertFails(
    uploadBytes(
      ref(ownerStorage(), `products/${ownerId}/missing/1788000000000001.jpg`),
      new Uint8Array([1]),
      {contentType: "image/jpeg"},
    ),
  );
  await assertFails(
    uploadBytes(
      ref(ownerStorage(), `products/${ownerId}/product-1/unsafe name.jpg`),
      new Uint8Array([1]),
      {contentType: "image/jpeg"},
    ),
  );
  await assertFails(
    uploadBytes(validRef, new Uint8Array([0xff, 0xd8, 0xff]), {
      contentType: "image/jpeg",
    }),
  );
});
