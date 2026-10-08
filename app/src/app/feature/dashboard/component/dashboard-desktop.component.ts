import { Component, Input } from '@angular/core';
import { Record, UserRecord } from '../../../core/model/record.model';
import { Debt } from '../../../core/model/debt.model';
import { DashboardHeroDesktopComponent } from '../ui/dashboard/dashboard-hero-desktop.component';
import { DashboardStatRowDesktopComponent } from '../ui/dashboard/dashboard-stat-row-desktop.component';
import { DashboardRecentTransactionsDesktopComponent } from '../ui/dashboard/dashboard-recent-transactions-desktop.component';
import { DashboardQuickActionsDesktopComponent } from '../ui/dashboard/dashboard-quick-actions-desktop.component';
import { DashboardDebtorsComponent } from '../ui/dashboard/dashboard-debtors.component';
import { DashboardTipsCardComponent } from '../ui/dashboard/dashboard-tips-card.component';

@Component({
  selector: 'app-dashboard-desktop',
  standalone: true,
  imports: [
    DashboardHeroDesktopComponent,
    DashboardStatRowDesktopComponent,
    DashboardRecentTransactionsDesktopComponent,
    DashboardQuickActionsDesktopComponent,
    DashboardDebtorsComponent,
    DashboardTipsCardComponent,
  ],
  template: `
    <div class="hidden md:grid p-8 gap-6" style="grid-template-columns: 1fr 380px; grid-template-rows: auto;">

      <!-- ─ Left column ─ -->
      <div class="flex flex-col gap-5 min-w-0">

        <app-dashboard-hero-desktop
          [records]="records"
          [currentMonth]="currentMonth"
          [sparkData]="sparkData"
          [monthlyTrendLabel]="monthlyTrendLabel"
          [formatRupiah]="formatRupiah"
        />

        <app-dashboard-stat-row-desktop
          [records]="records"
          [totalIncomeCount]="totalIncomeCount"
          [formatRupiah]="formatRupiah"
        />

        <app-dashboard-recent-transactions-desktop
          [recentTx]="recentTx"
          [formatDate]="formatDate"
          [formatRupiah]="formatRupiah"
          [goToTransactions]="goToTransactions"
          [goToAdd]="goToAdd"
        />

      </div>

      <!-- ─ Right sidebar ─ -->
      <div class="flex flex-col gap-5">

        <app-dashboard-quick-actions-desktop
          [goToAdd]="goToAdd"
          [goToFriends]="goToFriends"
        />

        <app-dashboard-debtors
          [debts]="debts"
          [formatRupiah]="formatRupiah"
          (pay)="onPayDebt($event)"
        />

        <app-dashboard-tips-card />

      </div>
    </div>
  `,
})
export class DashboardDesktopComponent {
  @Input({ required: true }) records: UserRecord | null = null;
  @Input({ required: true }) currentMonth!: string;
  @Input({ required: true }) sparkData!: number[];
  @Input({ required: true }) monthlyTrendLabel!: string;
  @Input({ required: true }) recentTx: Record[] = [];
  @Input({ required: true }) debts: Debt[] = [];
  @Input({ required: true }) totalIncomeCount!: number;
  @Input({ required: true }) formatRupiah!: (n: number) => string;
  @Input({ required: true }) formatDate!: (dateStr: string) => string;
  @Input({ required: true }) goToTransactions!: () => void;
  @Input({ required: true }) goToAdd!: () => void;
  @Input({ required: true }) goToFriends!: () => void;
  @Input({ required: true }) onPayDebt!: (id: string) => void;
}
