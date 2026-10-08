import { Component, Input } from '@angular/core';
import { CommonModule, DecimalPipe } from '@angular/common';

interface CategoryBreakdown {
  label: string;
  pct: number;
  color: string;
}

@Component({
  selector: 'app-transaction-monthly-summary',
  standalone: true,
  imports: [CommonModule, DecimalPipe],
  styleUrls: ['./transaction-ui.styles.css'],
  template: `
    <div class="bw-card p-5 animate-fade-slide-up" style="animation-delay:60ms">
      <div class="text-[12px] font-semibold uppercase tracking-[0.04em] text-bw-ink-3 mb-2">Bulan ini</div>
      <div class="flex items-baseline gap-2 mb-4">
        <div class="mono text-[28px] font-extrabold tracking-[-0.03em] text-bw-ink">
          Rp {{ formatRupiahShort(totalExpenseMonth) }}
        </div>
        <span class="text-[12px] font-semibold px-2 py-0.5 rounded-full"
              style="background:var(--bw-red-soft);color:var(--bw-red)">
          pengeluaran
        </span>
      </div>
      @for (b of categoryBreakdown; track b.label) {
        <div class="mb-3">
          <div class="flex justify-between text-[12px] font-semibold mb-1.5">
            <span class="text-bw-ink">{{ b.label }}</span>
            <span class="mono text-bw-ink-3">{{ b.pct | number:'1.0-0' }}%</span>
          </div>
          <div class="h-1.5 rounded-full bg-bw-sunken overflow-hidden">
            <div class="bar-fill h-full" [style.width.%]="b.pct" [style.background]="b.color"></div>
          </div>
        </div>
      }
    </div>
  `,
})
export class TransactionMonthlySummaryComponent {
  @Input() totalExpenseMonth = 0;
  @Input() categoryBreakdown: CategoryBreakdown[] = [];
  @Input() formatRupiahShort!: (n: number) => string;
}
