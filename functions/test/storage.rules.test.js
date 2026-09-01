const { after, before, beforeEach, test } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { deleteObject, getBytes, ref, uploadBytes } = require("firebase/storage");

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

function attachment(storage, fileName) {
  return ref(
    storage,
    `conversation_uploads/${ownerId}/${conversationId}/${fileName}`,
  );
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    storage: {
      rules: fs.readFileSync(
        path.join(__dirname, "..", "..", "storage.rules"),
        "utf8",
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearStorage();
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
