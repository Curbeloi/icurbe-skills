export interface Customer {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  /** The customer asked not to receive any notification (email or SMS). */
  notificationsOptOut: boolean;
}
