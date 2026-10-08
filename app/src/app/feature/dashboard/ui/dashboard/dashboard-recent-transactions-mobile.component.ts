import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideArrowUp, LucideArrowDown, LucideArrowRight, LucideUsers } from '@lucide/angular';
import { Record } from '../../../../core/model/record.model';

@Component({
  selector: 'app-dashboard-recent-transactions-mobile',
  standalone: true,
  imports: [CommonModule, LucideArrowUp, LucideArrowDown, LucideArrowRight, LucideUsers],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="bw-card p-4">
      <div class="flex justify-between items-center mb-2.5">
        <h3 class="text-[15px] font-bold text-bw-ink m-0">Transaksi terakhir</h3>
        <button (click)="goToTransactions()" class="text-[12px] font-semibold text-bw-ink-2 cursor-pointer flex items-center gap-1">
          Semua <svg lucideArrowRight class="w-3 h-3"></svg>
        </button>
      </div>
      @for (tx of recentTx; track tx.id; let i = $index) {
        <div class="flex items-center gap-3 py-2" [class.tx-row]="i > 0">
          <div class="icon-box w-8 h-8 rounded-[8px]">
            @if (tx.type === 'expense') {
              <svg lucideArrowUp class="w-4 h-4" style="color:var(--bw-red);stroke-width:1.8"></svg>
            } @else if (tx.type === 'income') {
              <svg lucideArrowDown class="w-4 h-4" style="color:var(--bw-green);stroke-width:1.8"></svg>
            } @else {
              <svg lucideUsers class="w-4 h-4" style="color:var(--bw-amber);stroke-width:1.8"></svg>
            }
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-[13px] font-semibold text-bw-ink truncate">{{ tx.title }}</div>
            <div class="text-[11px] text-bw-ink-3">{{ formatDate(tx.createdAt) }}</div>
          </div>
          <div class="mono text-[13px] font-semibold shrink-0"
               [style.color]="tx.type === 'expense' ? 'var(--bw-red)' : 'var(--bw-green)'">
            {{ tx.type === 'expense' ? '−' : '+' }}{{ formatRupiahShort(tx.amount) }}
          </div>
        </div>
      }
      @if (recentTx.length === 0) {
        <div class="text-center py-6 text-bw-ink-3 text-[13px]">Belum ada transaksi</div>
      }
    </div>
  `,
})
export class DashboardRecentTransactionsMobileComponent {
  @Input({ required: true }) recentTx: Record[] = [];
  @Input({ required: true }) formatDate!: (dateStr: string) => string;
  @Input({ required: true }) formatRupiahShort!: (n: number) => string;
  @Input({ required: true }) goToTransactions!: () => void;
}
