import { Component, Input } from '@angular/core';
import { Record, UserRecord } from '../../../core/model/record.model';
import { DashboardHeroMobileComponent } from '../ui/dashboard/dashboard-hero-mobile.component';
import { DashboardStatStripMobileComponent } from '../ui/dashboard/dashboard-stat-strip-mobile.component';
import { DashboardQuickActionsMobileComponent } from '../ui/dashboard/dashboard-quick-actions-mobile.component';
import { DashboardRecentTransactionsMobileComponent } from '../ui/dashboard/dashboard-recent-transactions-mobile.component';

@Component({
  selector: 'app-dashboard-mobile',
  standalone: true,
  imports: [
    DashboardHeroMobileComponent,
    DashboardStatStripMobileComponent,
    DashboardQuickActionsMobileComponent,
    DashboardRecentTransactionsMobileComponent,
  ],
  template: `
    <div class="flex flex-col gap-4 md:hidden px-5 pb-6 pt-2">

      <app-dashboard-hero-mobile
        [records]="records"
        [sparkData]="sparkData"
        [monthlyTrendLabel]="monthlyTrendLabel"
        [formatRupiah]="formatRupiah"
      />

      <app-dashboard-stat-strip-mobile
        [records]="records"
        [formatRupiah]="formatRupiah"
      />

      <app-dashboard-quick-actions-mobile
        [goToAdd]="goToAdd"
        [goToFriends]="goToFriends"
      />

      <app-dashboard-recent-transactions-mobile
        [recentTx]="recentTx"
        [formatDate]="formatDate"
        [formatRupiahShort]="formatRupiahShort"
        [goToTransactions]="goToTransactions"
      />

    </div>
  `,
})
export class DashboardMobileComponent {
  @Input({ required: true }) records: UserRecord | null = null;
  @Input({ required: true }) sparkData!: number[];
  @Input({ required: true }) monthlyTrendLabel!: string;
  @Input({ required: true }) recentTx: Record[] = [];
  @Input({ required: true }) formatRupiah!: (n: number) => string;
  @Input({ required: true }) formatRupiahShort!: (n: number) => string;
  @Input({ required: true }) formatDate!: (dateStr: string) => string;
  @Input({ required: true }) goToTransactions!: () => void;
  @Input({ required: true }) goToAdd!: () => void;
  @Input({ required: true }) goToFriends!: () => void;
}
