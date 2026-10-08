export type Debt = {
  id: string;
  amount: number;
  description: string;
  category: string;
  debtorId: string;
  debtor: { id: string; username: string };
  ownerId: string;
  status: 'pending' | 'completed';
}
