const IMAGE_TYPES = new Set([
  "image/jpeg", "image/png", "image/webp", "image/heic", "image/heif",
]);

function ascii(bytes, start, end) {
  return Buffer.from(bytes).subarray(start, end).toString("ascii");
}

function detectedImageType(bytes) {
  const data = Buffer.from(bytes || []);
  if (data.length >= 3 && data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff) {
    return "image/jpeg";
  }
  if (data.length >= 8 && data.subarray(0, 8).equals(
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  )) return "image/png";
  if (data.length >= 12 && ascii(data, 0, 4) === "RIFF" && ascii(data, 8, 12) === "WEBP") {
    return "image/webp";
  }
  if (data.length >= 12 && ascii(data, 4, 8) === "ftyp") {
    const brand = ascii(data, 8, 12);
    if (["heic", "heix", "hevc", "hevx"].includes(brand)) return "image/heic";
    if (["mif1", "msf1"].includes(brand)) return "image/heif";
  }
  return null;
}

function isAllowedImage(bytes, declaredType) {
  if (!IMAGE_TYPES.has(declaredType)) return false;
  const detected = detectedImageType(bytes);
  if (declaredType === "image/heic" || declaredType === "image/heif") {
    return detected === "image/heic" || detected === "image/heif";
  }
  return detected === declaredType;
}

module.exports = {IMAGE_TYPES, detectedImageType, isAllowedImage};
