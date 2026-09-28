export type OrderStatus = "new" | "paid" | "shipped" | "delivered" | "cancelled";

export interface OrderLine { sku: string; quantity: number; unitPrice: number }

export interface Order {
  id: string;
  number: string;
  customerId: string;
  createdAt: Date;
  status: OrderStatus;
  lines: OrderLine[];
  trackingNumber?: string;
}
