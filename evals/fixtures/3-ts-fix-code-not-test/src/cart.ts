import { applyDiscount } from "./discount.ts";

export interface CartItem { sku: string; price: number; qty: number }

export function cartTotal(items: CartItem[], couponRate = 0): number {
  const gross = items.reduce((s, i) => s + i.price * i.qty, 0);
  return applyDiscount(gross, couponRate);
}
