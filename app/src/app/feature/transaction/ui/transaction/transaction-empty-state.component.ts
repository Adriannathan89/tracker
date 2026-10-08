import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideReceipt } from '@lucide/angular';

@Component({
  selector: 'app-transaction-empty-state',
  standalone: true,
  imports: [CommonModule, LucideReceipt],
  styleUrls: ['./transaction-ui.styles.css'],
  template: `
    @if (variant === 'card') {
      <div class="bw-card flex flex-col items-center py-16 text-center">
        <svg lucideReceipt class="w-12 h-12 text-bw-ink-4 mb-3" style="stroke-width:1.5"></svg>
        <div class="text-[15px] font-semibold text-bw-ink-2">Tidak ada transaksi</div>
        <div class="text-[13px] text-bw-ink-3 mt-1">{{ subtitle }}</div>
      </div>
    } @else {
      <div class="text-center py-12 text-bw-ink-3 text-[13px]">Tidak ada transaksi</div>
    }
  `,
})
export class TransactionEmptyStateComponent {
  @Input() variant: 'card' | 'text' = 'card';
  @Input() subtitle = '';
}
