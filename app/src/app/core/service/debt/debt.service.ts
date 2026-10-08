import { Injectable } from "@angular/core";
import axiosInstance from "../../lib/axios";
import { Debt } from "../../model/debt.model";

@Injectable({ providedIn: 'root' })
export class DebtService {
  async loadAllDebts(): Promise<Debt[]> {
    const res = await axiosInstance.get('/debt');
    const raw = res.data.data?.debts ?? [];
    return raw.map((d: any) => ({
      id: d.id,
      amount: d.amount,
      description: d.description,
      category: d.category ?? '',
      debtorId: d.debtorId ?? d.debtor_id,
      debtor: { id: d.debtor?.id ?? '', username: d.debtor?.username ?? '' },
      ownerId: d.ownerId ?? d.owner_id,
      status: d.status,
    })) as Debt[];
  }

  async loadOwedDebts(): Promise<Debt[]> {
    const res = await axiosInstance.get('/debt/owed');
    const raw = res.data.data?.debts ?? [];
    return raw.map((d: any) => ({
      id: d.id,
      amount: d.amount,
      description: d.description,
      category: d.category ?? '',
      debtorId: d.debtorId ?? d.debtor_id,
      debtor: { id: d.debtor?.id ?? '', username: d.debtor?.username ?? '' },
      ownerId: d.ownerId ?? d.owner_id,
      status: d.status,
    })) as Debt[];
  }

  async createDebt(amount: number, description: string, debtorId: string): Promise<void> {
    await axiosInstance.post('/debt/create', { amount, description, debtorId });
  }

  async finishDebt(debtId: string): Promise<void> {
    await axiosInstance.put('/debt/finish', { debtId });
  }
}
