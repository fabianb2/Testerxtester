export function iconSize(width, height) {
  if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) throw Error('Imagen inválida.');
  const scale = Math.min(1, 512 / Math.max(width, height));
  return [Math.max(1, Math.round(width * scale)), Math.max(1, Math.round(height * scale))];
}

export async function optimizeIcon(file) {
  const url = URL.createObjectURL(file);
  try {
    const image = new Image();
    await new Promise((resolve, reject) => {
      image.onload = resolve;
      image.onerror = () => reject(Error('No se pudo leer la imagen.'));
      image.src = url;
    });
    if (image.naturalWidth * image.naturalHeight > 40000000) throw Error('Elige una imagen de menos de 40 megapíxeles.');
    const canvas = document.createElement('canvas');
    [canvas.width, canvas.height] = iconSize(image.naturalWidth, image.naturalHeight);
    const context = canvas.getContext('2d');
    if (!context) throw Error('Este navegador no permite optimizar imágenes.');
    context.imageSmoothingEnabled = true;
    context.imageSmoothingQuality = 'high';
    context.drawImage(image, 0, 0, canvas.width, canvas.height);
    for (const quality of [0.82, 0.7, 0.55]) {
      const blob = await new Promise(resolve => canvas.toBlob(resolve, 'image/webp', quality));
      if (!blob || blob.type !== 'image/webp') throw Error('Usa un navegador actualizado para comprimir el icono.');
      if (blob.size <= 204800) return blob;
    }
    throw Error('No se pudo reducir el icono a 200 KB. Prueba con otra imagen.');
  } finally {
    URL.revokeObjectURL(url);
  }
}
