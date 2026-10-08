import { Component, OnInit, signal, inject } from '@angular/core';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { UserRecordsService } from '../../core/service/user/user-records.service';
import { DebtService } from '../../core/service/debt/debt.service';
import { UserRecord, Record } from '../../core/model/record.model';
import { Debt } from '../../core/model/debt.model';
import { DashboardDesktopComponent } from './component/dashboard-desktop.component';
import { DashboardMobileComponent } from './component/dashboard-mobile.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [DashboardDesktopComponent, DashboardMobileComponent],
  template: `
    <app-dashboard-desktop
      [records]="records()"
      [currentMonth]="currentMonth"
      [sparkData]="sparkData()"
      [monthlyTrendLabel]="monthlyTrendLabel()"
      [recentTx]="recentTx()"
      [debts]="debts()"
      [totalIncomeCount]="totalIncomeCount()"
      [formatRupiah]="formatRupiah"
      [formatDate]="formatDate"
      [goToTransactions]="goToTransactions"
      [goToAdd]="goToAdd"
      [goToFriends]="goToFriends"
      [onPayDebt]="onPayDebt"
    />
    <app-dashboard-mobile
      [records]="records()"
      [sparkData]="sparkData()"
      [monthlyTrendLabel]="monthlyTrendLabel()"
      [recentTx]="recentTx()"
      [formatRupiah]="formatRupiah"
      [formatRupiahShort]="formatRupiahShort"
      [formatDate]="formatDate"
      [goToTransactions]="goToTransactions"
      [goToAdd]="goToAdd"
      [goToFriends]="goToFriends"
    />
  `,
})
export class DashboardPage implements OnInit {
  private recordsService = inject(UserRecordsService);
  private debtService = inject(DebtService);
  private router = inject(Router);
  private snackBar = inject(MatSnackBar);

  records = signal<UserRecord | null>(null);
  debts = signal<Debt[]>([]);
  loading = signal(true);

  readonly currentMonth = new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' }).format(new Date());

  async ngOnInit() {
    try {
      const [recordData, debtData] = await Promise.all([
        this.recordsService.getCommittedRecords(),
        this.debtService.loadAllDebts(),
      ]);
      this.records.set(recordData);
      this.debts.set(debtData.filter(d => d.status === 'pending'));
    } catch {
      // keep null state
    } finally {
      this.loading.set(false);
    }
  }

  onPayDebt = async (debtId: string) => {
    try {
      await this.debtService.finishDebt(debtId);
      this.debts.update(ds => ds.filter(d => d.id !== debtId));
      this.snackBar.open('Hutang berhasil dilunasi.', 'Tutup', { duration: 3000 });
    } catch {
      this.snackBar.open('Gagal melunasi hutang.', 'Tutup', { duration: 3000 });
    }
  };

  recentTx() {
    const r = this.records();
    if (!r) return [];
    const all: Record[] = [...r.expenses, ...r.incomes, ...r.debts];
    return all
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, 5);
  }

  sparkData(): number[] {
    const r = this.records();
    if (!r) return [0, 0, 0, 0, 0, 0, 0];
    const now = new Date();
    return Array.from({ length: 7 }, (_, i) => {
      const d = new Date(now.getFullYear(), now.getMonth() - (6 - i), 1);
      const ym = d.getFullYear() * 100 + d.getMonth();
      const inc = r.incomes.filter(x => {
        const rd = new Date(x.createdAt);
        return rd.getFullYear() * 100 + rd.getMonth() === ym;
      }).reduce((s, x) => s + x.amount, 0);
      const exp = r.expenses.filter(x => {
        const rd = new Date(x.createdAt);
        return rd.getFullYear() * 100 + rd.getMonth() === ym;
      }).reduce((s, x) => s + x.amount, 0);
      return Math.max(0, inc - exp) / 1_000_000;
    });
  }

  monthlyTrendLabel(): string {
    const data = this.sparkData();
    if (data.length < 2) return '+0%';
    const prev = data[data.length - 2];
    const curr = data[data.length - 1];
    if (prev === 0) return curr > 0 ? '+100%' : '0%';
    const pct = ((curr - prev) / prev * 100).toFixed(1);
    return `${Number(pct) >= 0 ? '+' : ''}${pct}% bulan ini`;
  }

  totalIncomeCount(): number {
    return this.records()?.incomes.length ?? 0;
  }

  formatRupiah = (n: number): string => new Intl.NumberFormat('id-ID').format(n);

  formatRupiahShort = (n: number): string => {
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(1).replace('.0', '') + 'jt';
    if (n >= 1_000) return (n / 1_000).toFixed(0) + 'rb';
    return String(n);
  };

  formatDate = (dateStr: string): string => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    const now = new Date();
    const diff = Math.floor((now.getTime() - d.getTime()) / 86400000);
    if (diff === 0) return 'Hari ini · ' + d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
    if (diff === 1) return 'Kemarin · ' + d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
    return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short' }).format(d);
  };

  goToTransactions = () => this.router.navigate(['/transaction']);
  goToAdd = () => this.router.navigate(['/transaction/add']);
  goToAddType = (type: string) => this.router.navigate(['/transaction/add'], { queryParams: { type } });
  goToFriends = () => this.router.navigate(['/friends']);
}
