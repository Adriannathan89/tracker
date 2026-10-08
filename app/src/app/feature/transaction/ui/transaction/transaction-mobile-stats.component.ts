import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-transaction-mobile-stats',
  standalone: true,
  styleUrls: ['./transaction-ui.styles.css'],
  template: `
    <div class="grid grid-cols-2 gap-2">
      <div class="bw-card p-3">
        <div class="text-[11px] font-semibold uppercase tracking-wider text-bw-ink-3 mb-1">Pengeluaran</div>
        <div class="mono text-[17px] font-bold text-bw-red">{{ formatRupiahShort(totalExpenseMonth) }}</div>
      </div>
      <div class="bw-card p-3">
        <div class="text-[11px] font-semibold uppercase tracking-wider text-bw-ink-3 mb-1">Pemasukan</div>
        <div class="mono text-[17px] font-bold text-bw-green">{{ formatRupiahShort(totalIncomeMonth) }}</div>
      </div>
    </div>
  `,
})
export class TransactionMobileStatsComponent {
  @Input() totalExpenseMonth = 0;
  @Input() totalIncomeMonth = 0;
  @Input() formatRupiahShort!: (n: number) => string;
}
