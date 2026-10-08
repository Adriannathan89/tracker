import { Component, Input } from '@angular/core';
import { LucideCheck } from '@lucide/angular';

@Component({
  selector: 'app-add-transaction-actions-desktop',
  standalone: true,
  imports: [LucideCheck],
  styleUrls: ['./add-transaction.styles.css'],
  template: `
    <div>
      <div class="flex gap-2.5">
        <button type="button" (click)="onSubmitAgain()"
          class="flex-1 flex items-center justify-center py-3.5 rounded-[12px] border border-bw-border-strong text-bw-ink text-[14px] font-semibold hover:bg-bw-sunken transition cursor-pointer">
          Simpan & catat lagi
        </button>
        <button type="button" (click)="onSubmit()" [disabled]="saving"
          class="flex-[2] flex items-center justify-center gap-2 py-3.5 rounded-[12px] bg-bw-ink text-bw-on-ink text-[14px] font-semibold hover:opacity-90 transition cursor-pointer disabled:opacity-50">
          <svg lucideCheck class="w-4 h-4 shrink-0"></svg>
          {{ saving ? 'Menyimpan…' : 'Simpan transaksi' }}
        </button>
      </div>
      <div class="flex items-center justify-center gap-3 flex-wrap mt-1">
        <span class="text-[11px] text-bw-ink-4 flex items-center gap-1">
          <kbd class="px-1.5 py-0.5 rounded-[4px] bg-bw-sunken font-mono text-[10px]">0–9</kbd> nominal
        </span>
        <span class="text-[11px] text-bw-ink-4 flex items-center gap-1">
          <kbd class="px-1.5 py-0.5 rounded-[4px] bg-bw-sunken font-mono text-[10px]">← →</kbd> tipe
        </span>
        <span class="text-[11px] text-bw-ink-4 flex items-center gap-1">
          <kbd class="px-1.5 py-0.5 rounded-[4px] bg-bw-sunken font-mono text-[10px]">⌘ Enter</kbd> simpan
        </span>
        <span class="text-[11px] text-bw-ink-4 flex items-center gap-1">
          <kbd class="px-1.5 py-0.5 rounded-[4px] bg-bw-sunken font-mono text-[10px]">Esc</kbd> batal
        </span>
      </div>
    </div>
  `,
})
export class AddTransactionActionsDesktopComponent {
  @Input() saving = false;
  @Input() onSubmitAgain: () => void = () => {};
  @Input() onSubmit: () => void = () => {};
}
