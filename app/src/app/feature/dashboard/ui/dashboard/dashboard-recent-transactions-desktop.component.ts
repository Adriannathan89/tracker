import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideArrowUp, LucideArrowDown, LucideArrowRight, LucideUsers, LucideReceipt } from '@lucide/angular';
import { Record } from '../../../../core/model/record.model';

@Component({
  selector: 'app-dashboard-recent-transactions-desktop',
  standalone: true,
  imports: [CommonModule, LucideArrowUp, LucideArrowDown, LucideArrowRight, LucideUsers, LucideReceipt],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="bw-card p-5 animate-fade-slide-up" style="animation-delay:200ms">
      <div class="flex justify-between items-center mb-3">
        <h3 class="text-[15px] font-bold text-bw-ink m-0">Transaksi terakhir</h3>
        <button (click)="goToTransactions()"
          class="text-[13px] font-semibold text-bw-ink-2 hover:text-bw-ink transition-colors cursor-pointer flex items-center gap-1">
          Lihat semua <svg lucideArrowRight class="w-3.5 h-3.5"></svg>
        </button>
      </div>

      @if (recentTx.length === 0) {
        <div class="flex flex-col items-center py-10 text-center">
          <svg lucideReceipt class="w-10 h-10 text-bw-ink-4 mb-3" style="stroke-width:1.5"></svg>
          <div class="text-[14px] font-semibold text-bw-ink-2">Belum ada transaksi</div>
          <div class="text-[13px] text-bw-ink-3 mt-1 mb-4">Yuk catat yang pertama →</div>
          <button (click)="goToAdd()"
            class="px-4 py-2 rounded-[10px] bg-bw-ink text-bw-on-ink text-[13px] font-semibold cursor-pointer">
            Catat sekarang
          </button>
        </div>
      } @else {
        @for (tx of recentTx; track tx.id; let i = $index) {
          <div class="flex items-center gap-3.5 py-2.5" [class.tx-row]="i > 0">
            <div class="icon-box">
              @if (tx.type === 'expense') {
                <svg lucideArrowUp class="w-[18px] h-[18px]" style="color:var(--bw-red);stroke-width:1.8"></svg>
              } @else if (tx.type === 'income') {
                <svg lucideArrowDown class="w-[18px] h-[18px]" style="color:var(--bw-green);stroke-width:1.8"></svg>
              } @else {
                <svg lucideUsers class="w-[18px] h-[18px]" style="color:var(--bw-amber);stroke-width:1.8"></svg>
              }
            </div>
            <div class="flex-1 min-w-0">
              <div class="text-[14px] font-semibold text-bw-ink truncate">{{ tx.title }}</div>
              <div class="text-[12px] text-bw-ink-3 mt-0.5">{{ formatDate(tx.createdAt) }}</div>
            </div>
            <div class="mono text-[14px] font-semibold shrink-0"
                 [style.color]="tx.type === 'expense' ? 'var(--bw-red)' : 'var(--bw-green)'">
              {{ tx.type === 'expense' ? '−' : '+' }}Rp {{ formatRupiah(tx.amount) }}
            </div>
          </div>
        }
      }
    </div>
  `,
})
export class DashboardRecentTransactionsDesktopComponent {
  @Input({ required: true }) recentTx: Record[] = [];
  @Input({ required: true }) formatDate!: (dateStr: string) => string;
  @Input({ required: true }) formatRupiah!: (n: number) => string;
  @Input({ required: true }) goToTransactions!: () => void;
  @Input({ required: true }) goToAdd!: () => void;
}
