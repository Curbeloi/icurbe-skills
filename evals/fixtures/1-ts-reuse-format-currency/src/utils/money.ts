export type CurrencyCode = "USD" | "EUR" | "PEN";

const LOCALE_BY_CURRENCY: Record<CurrencyCode, string> = {
  USD: "en-US",
  EUR: "es-ES",
  PEN: "es-PE",
};

/** Formats an amount as money, e.g. formatCurrency(1234.5, "USD") -> "$1,234.50". */
export function formatCurrency(amount: number, currency: CurrencyCode = "USD"): string {
  return new Intl.NumberFormat(LOCALE_BY_CURRENCY[currency], {
    style: "currency",
    currency,
    minimumFractionDigits: 2,
  }).format(amount);
}

export function roundCents(amount: number): number {
  return Math.round(amount * 100) / 100;
}
