import { Injectable } from "@angular/core";
import axiosInstance from "../../lib/axios";

@Injectable({ providedIn: 'root' })
export class TransactionService {
  async getTransactions() {
    const res = await axiosInstance.get('/transaction');
    return res.data.data;
  }

  async createTransaction(description: string, amount: number, debtorId: string) {
    await axiosInstance.post('/transaction/create', { description, amount, debtorId });
    return true;
  }

  async finishTransaction(transactionId: string) {
    await axiosInstance.post('/transaction/finish', { transactionId });
    return true;
  }
}