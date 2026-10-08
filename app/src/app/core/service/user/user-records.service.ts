import { Injectable } from "@angular/core";
import axiosInstance from "../../lib/axios";
import { Record, UserRecord } from "@/core/model/record.model";

@Injectable({ providedIn: 'root' })
export class UserRecordsService {
  async createRecord(title: string, description: string, amount: number, date: string) {
    await axiosInstance.post('/user/record', { title, description, amount, date });
    return true;
  }

  private mapToUserRecord(data: any): Record {
    return {
      id: data.id,
      title: data.title,
      description: data.description,
      amount: data.amount,
      categories: data.categories ?? [],
      type: data.type,
      createdAt: data.createdAt ?? data.created_at ?? '',
      isCommitted: data.isCommitted ?? false,
    };
  }

  async getRecords(): Promise<UserRecord> {
    const res = await axiosInstance.get('/user/records');
    const data = res.data.data;
    console.log(data);
    return {
      expenses: data.expenses ? data.expenses.map((r: any) => this.mapToUserRecord(r)) : [],
      incomes: data.incomes ? data.incomes.map((r: any) => this.mapToUserRecord(r)) : [],
      debts: data.debts ? data.debts.map((r: any) => this.mapToUserRecord(r)) : [],
      cash: data.cash,
      debt: data.debt,
      receivable: data.receivable,
      balance: data.balance
    };
  }

  async getCommittedRecords(): Promise<UserRecord> {
    const records = await this.getRecords();
    return {
      ...records,
      expenses: records.expenses.filter(r => r.isCommitted),
      incomes: records.incomes.filter(r => r.isCommitted),
    };
  }

  async commitRecord(recordId: string, category?: string, secondaryCategory?: string): Promise<void> {
    const payload: any = { recordId };
    if (category) payload.category = category;
    if (secondaryCategory) payload.secondaryCategory = secondaryCategory;
    await axiosInstance.put('/user/record/commit', payload);
  }

  async deleteRecord(recordId: string): Promise<void> {
    await axiosInstance.delete(`/user/record/${recordId}`);
  }
}
