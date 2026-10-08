import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-add-transaction-amount-hero',
  standalone: true,
  styleUrls: ['./add-transaction.styles.css'],
  template: `
    <div class="bw-card text-center" style="padding:28px;background:var(--bw-elevated)">
      <div class="text-[12px] font-semibold uppercase tracking-[0.1em] text-bw-ink-3 mb-2">
        Jumlah — ketik angka di keyboard
      </div>
      <div class="mono" style="font-size:56px;font-weight:800;letter-spacing:-0.04em;color:var(--bw-ink)">
        <span class="text-bw-ink-3">Rp </span>{{ formattedAmount }}<span class="amount-caret">|</span>
      </div>
      <div class="flex gap-2 justify-center mt-8 flex-wrap">
        @for (q of quickAmounts; track q.value) {
          <button type="button" class="quick-chip" [class.sel]="rawAmount === q.value"
                  (click)="onQuickSelect(q.value)">{{ q.label }}</button>
        }
      </div>
    </div>
  `,
  styles: [`
    .amount-caret {
      display: inline-block;
      color: var(--bw-ink-3);
      margin-left: 2px;
      animation: blink 1s steps(2) infinite;
    }
    @keyframes blink {
      0%   { opacity: 1; }
      50%  { opacity: 0; }
      100% { opacity: 1; }
    }
  `],
})
export class AddTransactionAmountHeroComponent {
  @Input() formattedAmount = '0';
  @Input() rawAmount = 0;
  @Input() quickAmounts: { label: string; value: number }[] = [];
  @Input() onQuickSelect: (value: number) => void = () => {};
}