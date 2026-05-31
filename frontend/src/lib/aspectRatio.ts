export function parseAspectRatio(value?: string) {
  if (!value) return null;
  const normalized = value.trim();
  const ratioMatch = normalized.match(/^(\d+(?:\.\d+)?)\s*:\s*(\d+(?:\.\d+)?)$/);
  if (ratioMatch) {
    const width = Number(ratioMatch[1]);
    const height = Number(ratioMatch[2]);
    if (width > 0 && height > 0) return `${width} / ${height}`;
  }

  const sizeMatch = normalized.match(/^(\d+(?:\.\d+)?)\s*[xX]\s*(\d+(?:\.\d+)?)$/);
  if (sizeMatch) {
    const width = Number(sizeMatch[1]);
    const height = Number(sizeMatch[2]);
    if (width > 0 && height > 0) return `${width} / ${height}`;
  }

  return null;
}

export function getAspectRatioFromTaskSize(size?: string, customSize?: string) {
  return parseAspectRatio(size) || parseAspectRatio(customSize) || "1 / 1";
}

export function getAspectRatioValue(ratio: string) {
  const [widthText, heightText] = ratio.split("/").map((item) => item.trim());
  const width = Number(widthText);
  const height = Number(heightText);
  if (!width || !height) return 1;
  return width / height;
}

export function extractDroppedFiles(dataTransfer: DataTransfer | null) {
  if (!dataTransfer) return [] as File[];
  const directFiles = Array.from(dataTransfer.files || []);
  if (directFiles.length) return directFiles;
  return Array.from(dataTransfer.items || [])
    .filter((item) => item.kind === "file")
    .map((item) => item.getAsFile())
    .filter((file): file is File => !!file);
}
