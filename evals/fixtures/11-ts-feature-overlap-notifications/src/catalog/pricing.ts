import { roundCents } from "../shared/money.ts";

/** Volume discount: 5 % from 10 units, 10 % from 50 units. */
export function unitPriceFor(basePrice: number, quantity: number): number {
  const rate = quantity >= 50 ? 0.1 : quantity >= 10 ? 0.05 : 0;
  return roundCents(basePrice * (1 - rate));
}
