/**
 * Applies a percentage discount. `rate` is a fraction: 0.1 means 10 % off.
 */
export function applyDiscount(price: number, rate: number): number {
  if (rate < 0 || rate > 1) throw new RangeError(`rate must be between 0 and 1, got ${rate}`);
  return Math.round((price - rate) * 100) / 100;
}
