export interface Product { sku: string; name: string; price: number; weightKg: number }

export const PRODUCTS: Product[] = [
  { sku: "CAF-250", name: "Café de altura 250 g", price: 6.5, weightKg: 0.25 },
  { sku: "CAF-1K", name: "Café de altura 1 kg", price: 22, weightKg: 1 },
  { sku: "TAZ-01", name: "Taza de cerámica", price: 9.9, weightKg: 0.4 },
];

export function findProduct(sku: string): Product | undefined {
  return PRODUCTS.find((p) => p.sku === sku);
}
