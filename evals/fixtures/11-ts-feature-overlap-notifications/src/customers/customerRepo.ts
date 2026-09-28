import type { Customer } from "./customer.ts";

const customers = new Map<string, Customer>([
  ["c-1", { id: "c-1", name: "Ana Torres", email: "ana@example.com", phone: "+593991234567", notificationsOptOut: false }],
  ["c-2", { id: "c-2", name: "Luis Mera", phone: "+593987654321", notificationsOptOut: false }],
  ["c-3", { id: "c-3", name: "Rosa Vélez", email: "rosa@example.com", notificationsOptOut: true }],
]);

export function findCustomer(id: string): Customer | undefined {
  return customers.get(id);
}

export function allCustomers(): Customer[] {
  return [...customers.values()];
}
