export type Category = {
  id: string;
  name: string;
  type: 'primary' | 'secondary';
}

export type Record = {
  id: string;
  title: string;
  description: string;
  amount: number;
  categories: Category[];
  type: string;
  createdAt: string;
  isCommitted: boolean;
}

export type UserRecord = {
  expenses: Record[];
  incomes: Record[];
  debts: Record[];
  cash: number;
  debt: number;
  receivable: number;
  balance: number;
}